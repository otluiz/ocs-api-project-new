# 🚀 Guia Rápido de Início - OCS Inventory API

**Autor:** Othon Teixeira  
**Data:** 26 de Outubro de 2025  
**Versão:** 1.1.1  

## Cenário: VirtualBox/VMware com Ubuntu 22.04 ou superior

### 📋 Pré-requisitos

- **VM Servidor**: Ubuntu 22.04 Server (mínimo 2GB RAM, 20GB disco)
- **VM Cliente** (opcional): Windows 10/11 ou Ubuntu Desktop
- **Rede**: Ambas VMs na mesma rede (modo Bridge ou NAT com port forwarding)

---

## 🖥️ PARTE 1: Configurar Servidor (VM Ubuntu 22.04)

### 1.1. Preparar a VM

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Descobrir IP da VM
ip addr show | grep inet
# Anote o IP (ex: 192.168.1.100)
```

### 1.2. Transferir Projeto para a VM

**Opção A - Via SCP** (da sua máquina host):
```bash
scp -r ocs-api-project/ usuario@192.168.1.100:/home/usuario/
```

**Opção B - Via Git** (na VM):
```bash
cd ~
git clone https://github.com/seu-usuario/ocs-api-project.git
```

**Opção C - Copiar manualmente** (VirtualBox Shared Folder):
```bash
# Configure pasta compartilhada no VirtualBox
# Depois monte na VM:
sudo mount -t vboxsf nome_compartilhamento /mnt
cp -r /mnt/ocs-api-project ~/
```

### 1.3. Executar Instalação Automática

```bash
cd ~/ocs-api-project
chmod +x scripts/setup-server.sh
sudo ./scripts/setup-server.sh
```

⏱️ **Aguarde ~5-10 minutos** para o script concluir.

### 1.4. Verificar Serviços

```bash
cd /opt/ocs-api
docker-compose ps
```

Você deve ver 3 containers rodando:
- `ocs-postgres` (banco de dados)
- `ocs-api` (API FastAPI)
- `ocs-metabase` (BI)

---

## 🧪 PARTE 2: Testar a API

### 2.1. Teste Rápido via Navegador

No seu **navegador** (na máquina host ou na VM cliente), acesse:

```
http://192.168.1.100:8000/docs
```

Você verá a documentação interativa da API (Swagger UI).

### 2.2. Teste com Cliente Python

**Na VM cliente** (ou na própria VM servidor):

```bash
# Instalar Python e requests
sudo apt install python3 python3-pip -y
pip3 install requests

# Copiar o cliente de teste
# (assumindo que você tem o arquivo test_client.py)

# Executar
python3 test_client.py http://192.168.1.100:8000
```

Você verá:
```
✓ API está saudável!
✓ Inventário enviado com sucesso!
✓ Encontrados 1 dispositivos:
```

---

## 💻 PARTE 3: Configurar Cliente OCS (Windows ou Linux)

### Windows 10/11

1. **Baixar Agente OCS**:
   - Acesse: https://github.com/OCSInventory-NG/WindowsAgent/releases
   - Baixe o instalador `.exe` mais recente

2. **Instalar**:
   - Execute o instalador
   - Em "Server URL", digite: `http://192.168.1.100:8000/ocsinventory`
   - **Desmarque** "Validate SSL certificate"
   - Conclua a instalação

3. **Forçar Inventário**:
   ```powershell
   # Abrir PowerShell como Administrador
   cd "C:\Program Files\OCS Inventory Agent"
   .\OCSInventory.exe /force /server=http://192.168.1.100:8000/ocsinventory
   ```

### Linux (Ubuntu Desktop)

1. **Instalar Agente**:
   ```bash
   sudo apt install ocsinventory-agent -y
   ```

2. **Configurar**:
   ```bash
   sudo nano /etc/ocsinventory/ocsinventory-agent.cfg
   ```
   
   Altere a linha `server=` para:
   ```
   server=http://192.168.1.100:8000/ocsinventory
   ```

3. **Forçar Inventário**:
   ```bash
   sudo ocsinventory-agent --server http://192.168.1.100:8000/ocsinventory --debug
   ```

---

## 📊 PARTE 4: Visualizar Dados no Metabase

### 4.1. Acessar Metabase

No navegador, acesse:
```
http://192.168.1.100:3000
```

### 4.2. Configuração Inicial (primeira vez)

1. **Criar conta admin**:
   - Email: seu@email.com
   - Senha: (escolha uma senha)

2. **Conectar ao banco de dados**:
   - Tipo: **PostgreSQL**
   - Nome: `OCS Inventory`
   - Host: `db`
   - Porta: `5432`
   - Nome do banco: `ocsinventory`
   - Usuário: `ocsuser`
   - Senha: `ocspassword`
   - Clique em "Save"

3. **Explorar dados**:
   - Clique em "Browse Data"
   - Selecione o banco "OCS Inventory"
   - Explore as tabelas:
     - `devices` - Dispositivos inventariados
     - `software` - Software instalado
     - `hardware_storage` - Discos e armazenamento
     - `network_interfaces` - Interfaces de rede

### 4.3. Criar um Dashboard Simples

1. Clique em "New" → "Dashboard"
2. Adicione uma pergunta: "Quantos dispositivos por sistema operacional?"
   - Tabela: `devices`
   - Agrupar por: `os_name`
   - Visualização: Gráfico de pizza
3. Salve o dashboard

---

## 🔧 Comandos Úteis

### Ver logs em tempo real:
```bash
cd /opt/ocs-api
docker-compose logs -f api
```

### Parar serviços:
```bash
cd /opt/ocs-api
docker-compose stop
```

### Iniciar serviços:
```bash
cd /opt/ocs-api
docker-compose start
```

### Reiniciar serviços:
```bash
cd /opt/ocs-api
docker-compose restart
```

### Acessar banco de dados diretamente:
```bash
docker exec -it ocs-postgres psql -U ocsuser -d ocsinventory
```

Dentro do PostgreSQL:
```sql
-- Listar dispositivos
SELECT device_id, hostname, ip_address, os_name FROM devices;

-- Contar software por dispositivo
SELECT device_id, COUNT(*) as software_count 
FROM software 
GROUP BY device_id;

-- Sair
\q
```

---

## ❓ Troubleshooting

### API não responde

```bash
# Verificar se container está rodando
docker ps | grep ocs-api

# Ver logs de erro
docker-compose logs api

# Reiniciar
docker-compose restart api
```

### Agente OCS não envia dados

1. Verifique firewall na VM servidor:
   ```bash
   sudo ufw status
   sudo ufw allow 8000/tcp
   ```

2. Teste conectividade do cliente:
   ```bash
   # Windows (PowerShell)
   Test-NetConnection -ComputerName 192.168.1.100 -Port 8000
   
   # Linux
   telnet 192.168.1.100 8000
   ```

3. Verifique logs do agente:
   - **Windows**: `C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.log`
   - **Linux**: `/var/log/ocsinventory-agent/`

### Metabase não conecta ao banco

Verifique se o container do banco está rodando:
```bash
docker ps | grep ocs-postgres
docker-compose logs db
```

---

## 🎉 Pronto!

Agora você tem um servidor OCS Inventory API completo rodando!

**Próximos passos**:
- Configure mais clientes para enviar inventário
- Crie dashboards personalizados no Metabase
- Explore a API REST em `/docs`
- Configure backups automáticos do banco de dados

