-- Schema do Banco de Dados OCS Inventory API
-- Inspirado no schema original do OCS Inventory, simplificado para PostgreSQL

-- Tabela para armazenar dados brutos de inventário (JSON completo)
CREATE TABLE IF NOT EXISTS raw_inventory (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    hostname VARCHAR(255),
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    payload JSONB NOT NULL,
    UNIQUE(device_id, received_at)
);

-- Índices para performance em queries JSON
CREATE INDEX IF NOT EXISTS idx_raw_inventory_device_id ON raw_inventory(device_id);
CREATE INDEX IF NOT EXISTS idx_raw_inventory_received_at ON raw_inventory(received_at DESC);
CREATE INDEX IF NOT EXISTS idx_raw_inventory_payload ON raw_inventory USING GIN(payload);

-- Tabela principal de dispositivos (normalizada)
CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    hostname VARCHAR(255),
    ip_address INET,
    mac_address VARCHAR(17),
    os_name VARCHAR(255),
    os_version VARCHAR(255),
    os_architecture VARCHAR(50),
    manufacturer VARCHAR(255),
    model VARCHAR(255),
    serial_number VARCHAR(255),
    cpu_name VARCHAR(255),
    cpu_cores INTEGER,
    ram_mb INTEGER,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para a tabela devices
CREATE INDEX IF NOT EXISTS idx_devices_hostname ON devices(hostname);
CREATE INDEX IF NOT EXISTS idx_devices_ip ON devices(ip_address);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen DESC);

-- Tabela de software instalado
CREATE TABLE IF NOT EXISTS software (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    name VARCHAR(500) NOT NULL,
    version VARCHAR(255),
    publisher VARCHAR(255),
    install_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, name, version)
);

CREATE INDEX IF NOT EXISTS idx_software_device_id ON software(device_id);
CREATE INDEX IF NOT EXISTS idx_software_name ON software(name);

-- Tabela de hardware (discos, memória, etc)
CREATE TABLE IF NOT EXISTS hardware_storage (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    disk_name VARCHAR(255),
    disk_type VARCHAR(50),
    capacity_gb INTEGER,
    serial_number VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, disk_name)
);

CREATE INDEX IF NOT EXISTS idx_hardware_storage_device_id ON hardware_storage(device_id);

-- Tabela de interfaces de rede
CREATE TABLE IF NOT EXISTS network_interfaces (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    interface_name VARCHAR(255),
    mac_address VARCHAR(17),
    ip_address INET,
    netmask VARCHAR(15),
    gateway INET,
    dhcp_enabled BOOLEAN DEFAULT FALSE,
    status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, interface_name)
);

CREATE INDEX IF NOT EXISTS idx_network_interfaces_device_id ON network_interfaces(device_id);
CREATE INDEX IF NOT EXISTS idx_network_interfaces_ip ON network_interfaces(ip_address);

-- Tabela de usuários logados
CREATE TABLE IF NOT EXISTS logged_users (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    username VARCHAR(255),
    domain VARCHAR(255),
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, username)
);

CREATE INDEX IF NOT EXISTS idx_logged_users_device_id ON logged_users(device_id);

-- View para relatório consolidado de dispositivos
CREATE OR REPLACE VIEW v_devices_summary AS
SELECT 
    d.device_id,
    d.hostname,
    d.ip_address,
    d.os_name,
    d.os_version,
    d.manufacturer,
    d.model,
    d.cpu_name,
    d.cpu_cores,
    d.ram_mb,
    d.last_seen,
    COUNT(DISTINCT s.id) as software_count,
    COUNT(DISTINCT hs.id) as storage_count,
    COUNT(DISTINCT ni.id) as network_interfaces_count
FROM devices d
LEFT JOIN software s ON d.device_id = s.device_id
LEFT JOIN hardware_storage hs ON d.device_id = hs.device_id
LEFT JOIN network_interfaces ni ON d.device_id = ni.device_id
GROUP BY d.id, d.device_id, d.hostname, d.ip_address, d.os_name, d.os_version, 
         d.manufacturer, d.model, d.cpu_name, d.cpu_cores, d.ram_mb, d.last_seen;

-- Função para atualizar timestamp de updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at na tabela devices
CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Inserir dados de exemplo para testes
INSERT INTO devices (device_id, hostname, ip_address, mac_address, os_name, os_version, os_architecture, 
                     manufacturer, model, cpu_name, cpu_cores, ram_mb)
VALUES 
    ('DEVICE001', 'workstation-01', '192.168.1.100', '00:11:22:33:44:55', 'Windows 10', '10.0.19045', 'x64',
     'Dell Inc.', 'OptiPlex 7090', 'Intel Core i7-10700', 8, 16384),
    ('DEVICE002', 'server-db-01', '192.168.1.10', 'AA:BB:CC:DD:EE:FF', 'Ubuntu', '22.04 LTS', 'x86_64',
     'HP', 'ProLiant DL380 Gen10', 'Intel Xeon Gold 6248R', 16, 65536)
ON CONFLICT (device_id) DO NOTHING;

-- Comentários nas tabelas para documentação
COMMENT ON TABLE raw_inventory IS 'Armazena payload JSON completo recebido dos agentes OCS';
COMMENT ON TABLE devices IS 'Tabela principal com informações normalizadas dos dispositivos';
COMMENT ON TABLE software IS 'Software instalado em cada dispositivo';
COMMENT ON TABLE hardware_storage IS 'Informações de armazenamento (discos)';
COMMENT ON TABLE network_interfaces IS 'Interfaces de rede de cada dispositivo';
COMMENT ON TABLE logged_users IS 'Usuários que fizeram login nos dispositivos';

