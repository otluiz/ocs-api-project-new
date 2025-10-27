#!/usr/bin/env python3
"""
Cliente de Teste para OCS Inventory API
Simula envio de dados de inventário em formato JSON
"""
import requests
import json
import sys
import platform
import socket
import uuid
from datetime import datetime

# Configuração do servidor
SERVER_URL = "http://localhost:8000"  # Altere para o IP do servidor


def get_system_info():
    """Coleta informações do sistema atual"""
    hostname = socket.gethostname()
    
    # Gerar device_id único baseado no hostname e MAC
    device_id = f"{hostname}-{uuid.getnode()}"
    
    # Obter IP
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip_address = s.getsockname()[0]
        s.close()
    except:
        ip_address = "127.0.0.1"
    
    # Informações do sistema
    system_info = {
        "device_id": device_id,
        "hostname": hostname,
        "ip_address": ip_address,
        "os_name": platform.system(),
        "os_version": platform.release(),
        "os_architecture": platform.machine(),
        "manufacturer": "Generic",
        "model": "Test Machine",
        "cpu_name": platform.processor() or "Unknown CPU",
        "cpu_cores": 4,  # Simplificado
        "ram_mb": 8192,  # Simplificado
        "software": [
            {
                "name": "Python",
                "version": platform.python_version(),
                "publisher": "Python Software Foundation"
            },
            {
                "name": "Test Application",
                "version": "1.0.0",
                "publisher": "Test Publisher"
            }
        ],
        "storage": [
            {
                "disk_name": "C:" if platform.system() == "Windows" else "/dev/sda1",
                "disk_type": "SSD",
                "capacity_gb": 256
            }
        ],
        "network_interfaces": [
            {
                "interface_name": "eth0",
                "ip_address": ip_address,
                "dhcp_enabled": True,
                "status": "up"
            }
        ],
        "logged_users": [
            {
                "username": "testuser",
                "domain": "TESTDOMAIN"
            }
        ]
    }
    
    return system_info


def test_health():
    """Testa endpoint de health"""
    print("🔍 Testando endpoint /health...")
    try:
        response = requests.get(f"{SERVER_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ API está saudável!")
            print(f"  Status: {data['status']}")
            print(f"  Database: {data['database']}")
            return True
        else:
            print(f"✗ Erro: Status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"✗ Erro: Não foi possível conectar ao servidor {SERVER_URL}")
        print("  Verifique se o servidor está rodando e o endereço está correto.")
        return False
    except Exception as e:
        print(f"✗ Erro: {e}")
        return False


def send_inventory_json():
    """Envia inventário usando endpoint JSON"""
    print("\n📤 Enviando inventário (JSON)...")
    
    system_info = get_system_info()
    
    try:
        response = requests.post(
            f"{SERVER_URL}/api/ingest",
            json=system_info,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Inventário enviado com sucesso!")
            print(f"  Device ID: {data['device_id']}")
            print(f"  Status: {data['status']}")
            print(f"  Timestamp: {data['timestamp']}")
            return True
        else:
            print(f"✗ Erro ao enviar: Status {response.status_code}")
            print(f"  Resposta: {response.text}")
            return False
            
    except Exception as e:
        print(f"✗ Erro: {e}")
        return False


def list_devices():
    """Lista dispositivos inventariados"""
    print("\n📋 Listando dispositivos...")
    
    try:
        response = requests.get(f"{SERVER_URL}/api/devices?limit=10", timeout=5)
        
        if response.status_code == 200:
            devices = response.json()
            print(f"✓ Encontrados {len(devices)} dispositivos:")
            print()
            
            for device in devices:
                print(f"  • {device['hostname']} ({device['device_id']})")
                print(f"    IP: {device['ip_address']}")
                print(f"    OS: {device['os_name']} {device['os_version']}")
                print(f"    Última atualização: {device['last_seen']}")
                print()
            
            return True
        else:
            print(f"✗ Erro: Status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"✗ Erro: {e}")
        return False


def get_device_details(device_id):
    """Obtém detalhes de um dispositivo específico"""
    print(f"\n🔍 Buscando detalhes do dispositivo {device_id}...")
    
    try:
        response = requests.get(f"{SERVER_URL}/api/devices/{device_id}", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print("✓ Detalhes do dispositivo:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            return True
        elif response.status_code == 404:
            print(f"✗ Dispositivo não encontrado")
            return False
        else:
            print(f"✗ Erro: Status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"✗ Erro: {e}")
        return False


def main():
    """Função principal"""
    print("=" * 60)
    print("  Cliente de Teste - OCS Inventory API")
    print("=" * 60)
    print(f"Servidor: {SERVER_URL}")
    print()
    
    # 1. Testar health
    if not test_health():
        print("\n⚠️  Servidor não está acessível. Verifique a configuração.")
        sys.exit(1)
    
    # 2. Enviar inventário
    if not send_inventory_json():
        print("\n⚠️  Falha ao enviar inventário.")
        sys.exit(1)
    
    # 3. Listar dispositivos
    list_devices()
    
    # 4. Buscar detalhes do dispositivo atual
    system_info = get_system_info()
    get_device_details(system_info['device_id'])
    
    print("\n" + "=" * 60)
    print("✓ Testes concluídos com sucesso!")
    print("=" * 60)


if __name__ == "__main__":
    # Permitir passar URL do servidor como argumento
    if len(sys.argv) > 1:
        SERVER_URL = sys.argv[1].rstrip('/')
        print(f"Usando servidor: {SERVER_URL}")
    
    main()

