# 📦 Guia de Instalação - OCS Inventory API

# Instalação - OCS API Project

**Autor:** Othon Teixeira  
**Data:** 26 de Outubro de 2025  
**Versão:** 1.1.1  

---

Este guia fornece instruções detalhadas para instalação do sistema OCS Inventory API em diferentes cenários.

---

## 🎯 Escolha seu Método de Instalação

### Método 1: Instalação Automática (Recomendado)
✅ **Mais rápido e simples**  
✅ Instala tudo de uma vez  
✅ Ideal para testes e produção  

**Tempo estimado**: 10-15 minutos

[Ir para Instalação Automática](#método-1-instalação-automática)

---

### Método 2: Instalação Manual (Passo a Passo)
✅ **Maior controle**  
✅ Permite verificar cada componente  
✅ Ideal para aprendizado e troubleshooting  

**Tempo estimado**: 20-30 minutos

[Ir para Instalação Manual](#método-2-instalação-manual-passo-a-passo)

---

## 📋 Pré-requisitos (Ambos os Métodos)

Antes de começar, certifique-se de ter:

- [ ] **VM ou servidor** com Ubuntu 22.04 LTS instalado
- [ ] **Recursos mínimos**: 2 GB RAM, 20 GB disco, 1 vCPU
- [ ] **Acesso root** ou privilégios sudo
- [ ] **Conexão com a internet** ativa e estável
- [ ] **Portas disponíveis**: 8000, 3000, 5432
- [ ] **Rede configurada** (IP fixo ou DHCP)

### Verificar Requisitos

Execute o script de verificação para confirmar que seu sistema atende aos requisitos:

```bash
cd ocs-api-project
./scripts/check-requirements.sh
```

Se houver falhas críticas, corrija-as antes de prosseguir.

---

## Método 1: Instalação Automática

Este método executa um único script que instala e configura todos os componentes automaticamente.

### Passo 1: Transferir Projeto para o Servidor

**Opção A - Via SCP** (da sua máquina local):
```bash
scp -r ocs-api-project/ usuario@IP_SERVIDOR:/home/usuario/
```

**Opção B - Via Git**:
```bash
git clone https://github.com/seu-usuario/ocs-api-project.git
cd ocs-api-project
```

**Opção C - Via Pasta Compartilhada** (VirtualBox):
```bash
# Configure pasta compartilhada no VirtualBox
# Depois monte na VM:
sudo mount -t vboxsf nome_compartilhamento /mnt
cp -r /mnt/ocs-api-project ~/
cd ~/ocs-api-project
```

### Passo 2: Executar Script de Instalação

```bash
cd ocs-api-project
sudo ./scripts/setup-server.sh
```

O script irá:
1. ✅ Atualizar o sistema
2. ✅ Instalar Docker e Docker Compose
3. ✅ Configurar firewall (UFW)
4. ✅ Mover projeto para `/opt/ocs-api`
5. ✅ Iniciar todos os serviços (PostgreSQL, API, Metabase)

**Aguarde**: ~10-15 minutos para conclusão.

### Passo 3: Verificar Instalação

Ao final, o script exibirá:

```
========================================
  ✓ Instalação Concluída com Sucesso!
========================================

Serviços disponíveis:

  • API OCS Inventory:
    http://192.168.1.100:8000
    Documentação: http://192.168.1.100:8000/docs

  • Metabase (BI):
    http://192.168.1.100:3000

  • PostgreSQL:
    Host: 192.168.1.100:5432
    Database: ocsinventory
    User: ocsuser
```

### Passo 4: Acessar os Serviços

1. **Testar API**: Abra `http://[IP_SERVIDOR]:8000/docs` no navegador
2. **Configurar Metabase**: Abra `http://[IP_SERVIDOR]:3000` e siga o assistente

**Pronto!** Vá para [Configuração Inicial do Metabase](#configuração-inicial-do-metabase)

---

## Método 2: Instalação Manual (Passo a Passo)

Este método permite instalar cada componente separadamente.

### Passo 1: Preparar o Sistema

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar utilitários básicos
sudo apt install -y curl wget git nano vim htop net-tools
```

### Passo 2: Instalar Docker e Docker Compose

```bash
cd ocs-api-project
sudo ./scripts/install-docker.sh
```

**Verificar instalação**:
```bash
docker --version
docker compose version
```

**Fazer logout e login novamente** para aplicar permissões do grupo docker.

### Passo 3: Configurar Firewall

```bash
# Habilitar UFW
sudo ufw enable

# Permitir portas necessárias
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 8000/tcp comment 'OCS API'
sudo ufw allow 3000/tcp comment 'Metabase'

# Verificar regras
sudo ufw status
```

### Passo 4: Preparar Projeto

```bash
# Mover para /opt (opcional, mas recomendado)
sudo mkdir -p /opt
sudo cp -r ~/ocs-api-project /opt/ocs-api
cd /opt/ocs-api

# Ajustar permissões
sudo chown -R $USER:$USER /opt/ocs-api
```

### Passo 5: Configurar Banco de Dados

```bash
cd /opt/ocs-api
sudo ./scripts/setup-database.sh
```

**Verificar**:
```bash
docker compose ps
# Deve mostrar container 'ocs-postgres' com status 'Up'

# Testar conexão
docker compose exec db psql -U ocsuser -d ocsinventory -c "SELECT COUNT(*) FROM devices;"
```

### Passo 6: Configurar API

```bash
cd /opt/ocs-api
sudo ./scripts/setup-api.sh
```

**Verificar**:
```bash
curl http://localhost:8000/health
# Deve retornar: {"status":"healthy","database":"connected",...}
```

### Passo 7: Configurar Metabase

```bash
cd /opt/ocs-api
sudo ./scripts/setup-metabase.sh
```

**Aguarde**: O Metabase pode levar 2-3 minutos para inicializar.

**Verificar**:
```bash
curl http://localhost:3000/api/health
# Deve retornar: {"status":"ok"}
```

### Passo 8: Verificar Todos os Serviços

```bash
cd /opt/ocs-api
docker compose ps
```

Você deve ver 3 containers rodando:
```
NAME              STATUS
ocs-postgres      Up (healthy)
ocs-api           Up (healthy)
ocs-metabase      Up
```

**Pronto!** Vá para [Configuração Inicial do Metabase](#configuração-inicial-do-metabase)

---

## 📊 Configuração Inicial do Metabase

Após a instalação, configure o Metabase para visualizar os dados:

### 1. Acessar Interface Web

Abra no navegador: `http://[IP_SERVIDOR]:3000`

### 2. Criar Conta de Administrador

- **Email**: seu@email.com
- **Senha**: (escolha uma senha forte)
- **Nome**: Seu Nome
- **Empresa**: (opcional)

### 3. Conectar ao Banco de Dados

Quando solicitado, preencha:

| Campo | Valor |
|:---|:---|
| **Tipo de Banco** | PostgreSQL |
| **Nome** | OCS Inventory |
| **Host** | `db` |
| **Porta** | `5432` |
| **Nome do Banco** | `ocsinventory` |
| **Usuário** | `ocsuser` |
| **Senha** | `ocspassword` |

Clique em **"Salvar"**.

### 4. Explorar Dados

Após conectar:

1. Clique em **"Browse Data"**
2. Selecione o banco **"OCS Inventory"**
3. Explore as tabelas:
   - `devices` - Dispositivos inventariados
   - `software` - Software instalado
   - `hardware_storage` - Discos
   - `network_interfaces` - Interfaces de rede
   - `v_devices_summary` - View consolidada

### 5. Criar Primeiro Dashboard (Opcional)

1. Clique em **"New"** → **"Dashboard"**
2. Adicione uma pergunta:
   - **Pergunta**: "Quantos dispositivos por sistema operacional?"
   - **Tabela**: `devices`
   - **Agrupar por**: `os_name`
   - **Visualização**: Gráfico de pizza
3. Salve o dashboard

---

## 🧪 Testar Ingestão de Dados

### Opção 1: Cliente de Teste Python

```bash
cd /opt/ocs-api/client
python3 test_client.py http://localhost:8000
```

Você verá:
```
✓ API está saudável!
✓ Inventário enviado com sucesso!
✓ Encontrados 1 dispositivos:
```

### Opção 2: Agente OCS Oficial (Windows)

1. Baixe o agente: [OCS Windows Agent](https://github.com/OCSInventory-NG/WindowsAgent/releases)
2. Instale com URL: `http://[IP_SERVIDOR]:8000/ocsinventory`
3. Force inventário:
   ```powershell
   cd "C:\Program Files\OCS Inventory Agent"
   .\OCSInventory.exe /force /server=http://[IP_SERVIDOR]:8000/ocsinventory
   ```

### Opção 3: Agente OCS Oficial (Linux)

```bash
# Instalar
sudo apt install ocsinventory-agent

# Configurar
sudo nano /etc/ocsinventory/ocsinventory-agent.cfg
# Alterar: server=http://[IP_SERVIDOR]:8000/ocsinventory

# Forçar inventário
sudo ocsinventory-agent --server http://[IP_SERVIDOR]:8000/ocsinventory --debug
```

---

## 🔍 Verificar Logs

### Ver logs de todos os serviços:
```bash
cd /opt/ocs-api
docker compose logs -f
```

### Ver logs de um serviço específico:
```bash
docker compose logs -f api        # API
docker compose logs -f db         # PostgreSQL
docker compose logs -f metabase   # Metabase
```

---

## 🔧 Comandos de Gerenciamento

### Parar todos os serviços:
```bash
cd /opt/ocs-api
docker compose stop
```

### Iniciar todos os serviços:
```bash
cd /opt/ocs-api
docker compose start
```

### Reiniciar todos os serviços:
```bash
cd /opt/ocs-api
docker compose restart
```

### Reiniciar apenas a API:
```bash
cd /opt/ocs-api
docker compose restart api
```

### Ver status dos containers:
```bash
cd /opt/ocs-api
docker compose ps
```

---

## 🆘 Troubleshooting

### API não responde

```bash
# Verificar se container está rodando
docker compose ps | grep api

# Ver logs de erro
docker compose logs --tail=50 api

# Reiniciar
docker compose restart api
```

### PostgreSQL não conecta

```bash
# Verificar se está rodando
docker compose ps | grep postgres

# Testar conexão
docker compose exec db pg_isready -U ocsuser

# Ver logs
docker compose logs --tail=50 db
```

### Metabase não carrega

```bash
# Aguardar mais tempo (pode levar 3-5 minutos)
docker compose logs -f metabase

# Verificar recursos (Metabase precisa de RAM)
free -h

# Reiniciar
docker compose restart metabase
```

### Porta já está em uso

```bash
# Verificar qual processo está usando a porta
sudo netstat -tulpn | grep :8000

# Parar o processo ou alterar porta no docker-compose.yml
```

---

## 📚 Próximos Passos

Após a instalação bem-sucedida:

1. ✅ Configure clientes OCS para enviar inventário
2. ✅ Crie dashboards personalizados no Metabase
3. ✅ Configure backup automático do banco
4. ✅ Altere senhas padrão (produção)
5. ✅ Configure HTTPS com Nginx (produção)

**Consulte**:
- [QUICKSTART.md](QUICKSTART.md) - Guia rápido
- [REQUISITOS.md](REQUISITOS.md) - Detalhes de requisitos
- [docs/README.md](docs/README.md) - Documentação técnica

---

## ✅ Checklist de Instalação

- [ ] Sistema atende aos requisitos mínimos
- [ ] Docker e Docker Compose instalados
- [ ] Firewall configurado
- [ ] PostgreSQL rodando e acessível
- [ ] API respondendo em `/health`
- [ ] Metabase acessível na porta 3000
- [ ] Metabase conectado ao banco de dados
- [ ] Teste de ingestão realizado com sucesso
- [ ] Dados visíveis no Metabase

---

**Instalação concluída com sucesso? Parabéns! 🎉**

Se encontrou problemas, consulte a seção de Troubleshooting ou os logs dos serviços.

