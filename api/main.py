"""
API FastAPI para Ingestão de Dados OCS Inventory
Compatível com agente OCS oficial (XML) e também aceita JSON
"""
from fastapi import FastAPI, Request, Depends, HTTPException, status
from fastapi.responses import Response, JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime
from typing import List, Optional
import xml.etree.ElementTree as ET
import json
import logging

from database import get_db, test_connection
from models import InventoryPayload, DeviceResponse, IngestResponse, HealthResponse

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Criar aplicação FastAPI
app = FastAPI(
    title="OCS Inventory API",
    description="API de ingestão de dados de inventário compatível com agente OCS",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)


@app.on_event("startup")
async def startup_event():
    """Evento executado no startup da aplicação"""
    logger.info("Iniciando OCS Inventory API...")
    if test_connection():
        logger.info("✓ Conexão com banco de dados OK")
    else:
        logger.error("✗ Falha na conexão com banco de dados")


@app.get("/", tags=["Health"])
async def root():
    """Endpoint raiz"""
    return {
        "message": "OCS Inventory API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check(db: Session = Depends(get_db)):
    """Verifica saúde da API e conexão com banco"""
    try:
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        logger.error(f"Erro no health check: {e}")
        db_status = "disconnected"
        raise HTTPException(status_code=503, detail="Database unavailable")
    
    return HealthResponse(
        status="healthy",
        database=db_status,
        timestamp=datetime.now()
    )


def parse_ocs_xml(xml_content: str) -> dict:
    """
    Parseia XML do agente OCS e converte para dicionário Python
    """
    try:
        root = ET.fromstring(xml_content)
        
        # Extrair informações principais
        device_data = {
            "device_id": None,
            "hostname": None,
            "ip_address": None,
            "mac_address": None,
            "os_name": None,
            "os_version": None,
            "os_architecture": None,
            "manufacturer": None,
            "model": None,
            "serial_number": None,
            "cpu_name": None,
            "cpu_cores": None,
            "ram_mb": None,
            "software": [],
            "storage": [],
            "network_interfaces": [],
            "logged_users": []
        }
        
        # HARDWARE section
        hardware = root.find(".//HARDWARE")
        if hardware is not None:
            device_data["device_id"] = hardware.findtext("UUID") or hardware.findtext("NAME")
            device_data["hostname"] = hardware.findtext("NAME")
            device_data["ip_address"] = hardware.findtext("IPADDR")
            device_data["os_name"] = hardware.findtext("OSNAME")
            device_data["os_version"] = hardware.findtext("OSVERSION")
            device_data["os_architecture"] = hardware.findtext("ARCH")
            device_data["manufacturer"] = hardware.findtext("SMANUFACTURER") or hardware.findtext("MANUFACTURER")
            device_data["model"] = hardware.findtext("SMODEL") or hardware.findtext("MODEL")
            device_data["serial_number"] = hardware.findtext("SSN")
            device_data["cpu_name"] = hardware.findtext("PROCESSORT")
            device_data["cpu_cores"] = int(hardware.findtext("PROCESSORN", 0))
            device_data["ram_mb"] = int(hardware.findtext("MEMORY", 0))
        
        # STORAGES section
        for storage in root.findall(".//STORAGES"):
            device_data["storage"].append({
                "disk_name": storage.findtext("NAME", ""),
                "disk_type": storage.findtext("TYPE", ""),
                "capacity_gb": int(int(storage.findtext("DISKSIZE", 0)) / 1024) if storage.findtext("DISKSIZE") else 0,
                "serial_number": storage.findtext("SERIALNUMBER", "")
            })
        
        # NETWORKS section
        for network in root.findall(".//NETWORKS"):
            device_data["network_interfaces"].append({
                "interface_name": network.findtext("DESCRIPTION", ""),
                "mac_address": network.findtext("MACADDR", ""),
                "ip_address": network.findtext("IPADDRESS", ""),
                "netmask": network.findtext("IPMASK", ""),
                "gateway": network.findtext("IPGATEWAY", ""),
                "dhcp_enabled": network.findtext("IPDHCP") == "1",
                "status": network.findtext("STATUS", "unknown")
            })
        
        # SOFTWARES section
        for software in root.findall(".//SOFTWARES"):
            device_data["software"].append({
                "name": software.findtext("NAME", ""),
                "version": software.findtext("VERSION", ""),
                "publisher": software.findtext("PUBLISHER", ""),
                "install_date": software.findtext("INSTALLDATE", "")
            })
        
        # USERS section
        for user in root.findall(".//USERS"):
            device_data["logged_users"].append({
                "username": user.findtext("LOGIN", ""),
                "domain": user.findtext("DOMAIN", "")
            })
        
        return device_data
        
    except ET.ParseError as e:
        logger.error(f"Erro ao parsear XML: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid XML: {str(e)}")
    except Exception as e:
        logger.error(f"Erro inesperado ao processar XML: {e}")
        raise HTTPException(status_code=500, detail=f"Error processing XML: {str(e)}")


def store_inventory(data: dict, db: Session) -> str:
    """
    Armazena dados de inventário no banco de dados
    """
    try:
        # 1. Armazenar payload bruto em raw_inventory
        db.execute(
            text("""
                INSERT INTO raw_inventory (device_id, hostname, payload, received_at)
                VALUES (:device_id, :hostname, :payload, :received_at)
            """),
            {
                "device_id": data["device_id"],
                "hostname": data["hostname"],
                "payload": json.dumps(data),
                "received_at": datetime.now()
            }
        )
        
        # 2. Inserir ou atualizar na tabela devices
        db.execute(
            text("""
                INSERT INTO devices (
                    device_id, hostname, ip_address, mac_address, os_name, os_version,
                    os_architecture, manufacturer, model, serial_number, cpu_name,
                    cpu_cores, ram_mb, last_seen, first_seen
                ) VALUES (
                    :device_id, :hostname, :ip_address, :mac_address, :os_name, :os_version,
                    :os_architecture, :manufacturer, :model, :serial_number, :cpu_name,
                    :cpu_cores, :ram_mb, :last_seen, :first_seen
                )
                ON CONFLICT (device_id) DO UPDATE SET
                    hostname = EXCLUDED.hostname,
                    ip_address = EXCLUDED.ip_address,
                    mac_address = EXCLUDED.mac_address,
                    os_name = EXCLUDED.os_name,
                    os_version = EXCLUDED.os_version,
                    os_architecture = EXCLUDED.os_architecture,
                    manufacturer = EXCLUDED.manufacturer,
                    model = EXCLUDED.model,
                    serial_number = EXCLUDED.serial_number,
                    cpu_name = EXCLUDED.cpu_name,
                    cpu_cores = EXCLUDED.cpu_cores,
                    ram_mb = EXCLUDED.ram_mb,
                    last_seen = EXCLUDED.last_seen
            """),
            {
                **data,
                "last_seen": datetime.now(),
                "first_seen": datetime.now()
            }
        )
        
        # 3. Limpar e inserir software
        db.execute(
            text("DELETE FROM software WHERE device_id = :device_id"),
            {"device_id": data["device_id"]}
        )
        for sw in data.get("software", []):
            if sw.get("name"):
                db.execute(
                    text("""
                        INSERT INTO software (device_id, name, version, publisher, install_date)
                        VALUES (:device_id, :name, :version, :publisher, :install_date)
                        ON CONFLICT (device_id, name, version) DO NOTHING
                    """),
                    {
                        "device_id": data["device_id"],
                        **sw
                    }
                )
        
        # 4. Limpar e inserir storage
        db.execute(
            text("DELETE FROM hardware_storage WHERE device_id = :device_id"),
            {"device_id": data["device_id"]}
        )
        for storage in data.get("storage", []):
            if storage.get("disk_name"):
                db.execute(
                    text("""
                        INSERT INTO hardware_storage (device_id, disk_name, disk_type, capacity_gb, serial_number)
                        VALUES (:device_id, :disk_name, :disk_type, :capacity_gb, :serial_number)
                        ON CONFLICT (device_id, disk_name) DO NOTHING
                    """),
                    {
                        "device_id": data["device_id"],
                        **storage
                    }
                )
        
        # 5. Limpar e inserir network interfaces
        db.execute(
            text("DELETE FROM network_interfaces WHERE device_id = :device_id"),
            {"device_id": data["device_id"]}
        )
        for net in data.get("network_interfaces", []):
            if net.get("interface_name"):
                db.execute(
                    text("""
                        INSERT INTO network_interfaces (
                            device_id, interface_name, mac_address, ip_address,
                            netmask, gateway, dhcp_enabled, status
                        ) VALUES (
                            :device_id, :interface_name, :mac_address, :ip_address,
                            :netmask, :gateway, :dhcp_enabled, :status
                        )
                        ON CONFLICT (device_id, interface_name) DO NOTHING
                    """),
                    {
                        "device_id": data["device_id"],
                        **net
                    }
                )
        
        # 6. Limpar e inserir logged users
        db.execute(
            text("DELETE FROM logged_users WHERE device_id = :device_id"),
            {"device_id": data["device_id"]}
        )
        for user in data.get("logged_users", []):
            if user.get("username"):
                db.execute(
                    text("""
                        INSERT INTO logged_users (device_id, username, domain)
                        VALUES (:device_id, :username, :domain)
                        ON CONFLICT (device_id, username) DO NOTHING
                    """),
                    {
                        "device_id": data["device_id"],
                        **user
                    }
                )
        
        db.commit()
        logger.info(f"✓ Inventário armazenado: {data['device_id']}")
        return data["device_id"]
        
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao armazenar inventário: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.post("/ocsinventory", tags=["OCS Agent"])
async def ocs_inventory_endpoint(request: Request, db: Session = Depends(get_db)):
    """
    Endpoint compatível com agente OCS Inventory oficial
    Aceita XML no formato OCS e retorna resposta XML
    """
    try:
        # Ler corpo da requisição
        body = await request.body()
        content_type = request.headers.get("content-type", "")
        
        logger.info(f"Recebida requisição OCS - Content-Type: {content_type}")
        
        # Parsear XML
        xml_content = body.decode("utf-8")
        device_data = parse_ocs_xml(xml_content)
        
        # Armazenar no banco
        device_id = store_inventory(device_data, db)
        
        # Retornar resposta XML compatível com OCS
        response_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <RESPONSE>SEND</RESPONSE>
    <PROLOG_FREQ>24</PROLOG_FREQ>
</REPLY>"""
        
        return Response(content=response_xml, media_type="application/xml")
        
    except Exception as e:
        logger.error(f"Erro no endpoint OCS: {e}")
        error_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<REPLY>
    <RESPONSE>ERROR</RESPONSE>
    <ERROR>{str(e)}</ERROR>
</REPLY>"""
        return Response(content=error_xml, media_type="application/xml", status_code=500)


@app.post("/api/ingest", response_model=IngestResponse, tags=["API"])
async def ingest_json(payload: InventoryPayload, db: Session = Depends(get_db)):
    """
    Endpoint alternativo que aceita JSON (para testes e integrações customizadas)
    """
    try:
        data = payload.model_dump()
        device_id = store_inventory(data, db)
        
        return IngestResponse(
            status="success",
            message="Inventory data received and stored",
            device_id=device_id,
            timestamp=datetime.now()
        )
    except Exception as e:
        logger.error(f"Erro no ingest JSON: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/devices", response_model=List[DeviceResponse], tags=["API"])
async def list_devices(
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Lista todos os dispositivos inventariados"""
    try:
        result = db.execute(
            text("""
                SELECT id, device_id, hostname, ip_address, os_name, os_version,
                       manufacturer, model, cpu_name, cpu_cores, ram_mb,
                       last_seen, first_seen
                FROM devices
                ORDER BY last_seen DESC
                LIMIT :limit OFFSET :offset
            """),
            {"limit": limit, "offset": offset}
        )
        
        devices = []
        for row in result:
            devices.append(DeviceResponse(
                id=row.id,
                device_id=row.device_id,
                hostname=row.hostname,
                ip_address=str(row.ip_address) if row.ip_address else None,
                os_name=row.os_name,
                os_version=row.os_version,
                manufacturer=row.manufacturer,
                model=row.model,
                cpu_name=row.cpu_name,
                cpu_cores=row.cpu_cores,
                ram_mb=row.ram_mb,
                last_seen=row.last_seen,
                first_seen=row.first_seen
            ))
        
        return devices
        
    except Exception as e:
        logger.error(f"Erro ao listar dispositivos: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/devices/{device_id}", tags=["API"])
async def get_device_details(device_id: str, db: Session = Depends(get_db)):
    """Obtém detalhes completos de um dispositivo"""
    try:
        # Buscar device
        device = db.execute(
            text("SELECT * FROM devices WHERE device_id = :device_id"),
            {"device_id": device_id}
        ).fetchone()
        
        if not device:
            raise HTTPException(status_code=404, detail="Device not found")
        
        # Buscar software
        software = db.execute(
            text("SELECT name, version, publisher FROM software WHERE device_id = :device_id"),
            {"device_id": device_id}
        ).fetchall()
        
        # Buscar storage
        storage = db.execute(
            text("SELECT * FROM hardware_storage WHERE device_id = :device_id"),
            {"device_id": device_id}
        ).fetchall()
        
        # Buscar network
        network = db.execute(
            text("SELECT * FROM network_interfaces WHERE device_id = :device_id"),
            {"device_id": device_id}
        ).fetchall()
        
        return {
            "device": dict(device._mapping),
            "software": [dict(s._mapping) for s in software],
            "storage": [dict(s._mapping) for s in storage],
            "network_interfaces": [dict(n._mapping) for n in network]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar dispositivo: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

