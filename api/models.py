"""
Modelos Pydantic para validação de dados da API OCS Inventory
"""
from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, IPvAnyAddress


# Modelos de entrada (recebidos dos agentes OCS)
class SoftwareItem(BaseModel):
    name: str
    version: Optional[str] = None
    publisher: Optional[str] = None
    install_date: Optional[str] = None


class StorageItem(BaseModel):
    disk_name: str
    disk_type: Optional[str] = None
    capacity_gb: Optional[int] = None
    serial_number: Optional[str] = None


class NetworkInterface(BaseModel):
    interface_name: str
    mac_address: Optional[str] = None
    ip_address: Optional[str] = None
    netmask: Optional[str] = None
    gateway: Optional[str] = None
    dhcp_enabled: Optional[bool] = False
    status: Optional[str] = "unknown"


class LoggedUser(BaseModel):
    username: str
    domain: Optional[str] = None
    last_login: Optional[datetime] = None


class InventoryPayload(BaseModel):
    """Payload completo enviado pelo agente OCS"""
    device_id: str = Field(..., description="ID único do dispositivo")
    hostname: str = Field(..., description="Nome do host")
    ip_address: Optional[str] = None
    mac_address: Optional[str] = None
    os_name: Optional[str] = None
    os_version: Optional[str] = None
    os_architecture: Optional[str] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    serial_number: Optional[str] = None
    cpu_name: Optional[str] = None
    cpu_cores: Optional[int] = None
    ram_mb: Optional[int] = None
    software: Optional[List[SoftwareItem]] = []
    storage: Optional[List[StorageItem]] = []
    network_interfaces: Optional[List[NetworkInterface]] = []
    logged_users: Optional[List[LoggedUser]] = []
    metadata: Optional[Dict[str, Any]] = {}

    class Config:
        json_schema_extra = {
            "example": {
                "device_id": "DEVICE001",
                "hostname": "workstation-01",
                "ip_address": "192.168.1.100",
                "mac_address": "00:11:22:33:44:55",
                "os_name": "Windows 10",
                "os_version": "10.0.19045",
                "os_architecture": "x64",
                "manufacturer": "Dell Inc.",
                "model": "OptiPlex 7090",
                "serial_number": "ABC123XYZ",
                "cpu_name": "Intel Core i7-10700",
                "cpu_cores": 8,
                "ram_mb": 16384,
                "software": [
                    {"name": "Google Chrome", "version": "120.0.6099.109", "publisher": "Google LLC"}
                ],
                "storage": [
                    {"disk_name": "C:", "disk_type": "SSD", "capacity_gb": 512}
                ],
                "network_interfaces": [
                    {
                        "interface_name": "Ethernet",
                        "mac_address": "00:11:22:33:44:55",
                        "ip_address": "192.168.1.100",
                        "dhcp_enabled": True
                    }
                ],
                "logged_users": [
                    {"username": "john.doe", "domain": "COMPANY"}
                ]
            }
        }


# Modelos de resposta
class DeviceResponse(BaseModel):
    id: int
    device_id: str
    hostname: str
    ip_address: Optional[str] = None
    os_name: Optional[str] = None
    os_version: Optional[str] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    cpu_name: Optional[str] = None
    cpu_cores: Optional[int] = None
    ram_mb: Optional[int] = None
    last_seen: datetime
    first_seen: datetime

    class Config:
        from_attributes = True


class IngestResponse(BaseModel):
    status: str
    message: str
    device_id: str
    timestamp: datetime


class HealthResponse(BaseModel):
    status: str
    database: str
    timestamp: datetime

