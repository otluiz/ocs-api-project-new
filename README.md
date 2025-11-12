# OCS Inventory API - Protótipo Completo

# OCS API Project

**Autor:** Othon Teixeira  
**Data da última atualização:** 11 de Novembro de 2025  
**Versão:** 1.1.3  

---

Este projeto implementa uma API e pipeline de ingestão de dados para integração com OCS Inventory, com visualização via Metabase.



[![Python](https://img.shields.io/badge/Python-3.11-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green.svg)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)

API moderna e performática para gestão de dados do OCS Inventory, compatível com agentes OCS oficiais.

## 🎯 Visão Geral

Este projeto implementa uma **API REST de ingestão de dados** para o OCS Inventory, substituindo o servidor tradicional por uma solução mais simples, escalável e fácil de manter. A arquitetura utiliza:

- **FastAPI** (Python) - Backend assíncrono de alta performance
- **PostgreSQL** - Banco de dados relacional com suporte JSONB
- **Metabase** - Business Intelligence e dashboards
- **Docker Compose** - Orquestração simplificada

## ✨ Características

- ✅ **Compatível com agentes OCS oficiais** (Windows, Linux, macOS)
- ✅ **API REST JSON** para consultas e integrações
- ✅ **Deployment em 1 comando** via script automatizado
- ✅ **Dashboards interativos** com Metabase
- ✅ **Schema de banco inspirado no OCS original**
- ✅ **Documentação automática** (Swagger/OpenAPI)

## 📁 Estrutura do Projeto

```
ocs-api-project/
├── api/                    # API FastAPI
│   ├── main.py            # Endpoints e lógica principal
│   ├── models.py          # Modelos Pydantic
│   ├── database.py        # Conexão com PostgreSQL
│   ├── Dockerfile         # Container da API
│   └── requirements.txt   # Dependências Python
├── database/
│   └── schema.sql         # Schema do banco de dados
├── client/
│   └── test_client.py     # Cliente de teste Python
├── scripts/
│   └── setup-server.sh    # Script de instalação Ubuntu 22.04
├── docs/                  # Documentação completa
├── docker-compose.yml     # Orquestração dos serviços
├── README.md              # Este arquivo
└── QUICKSTART.md          # Guia rápido de início
```

## 🚀 Início Rápido

### Pré-requisitos

- Ubuntu 22.04 Server (VM ou bare metal)
- Acesso root/sudo
- Conexão com a internet

### Instalação (3 passos)

1. **Copie o projeto para a VM**:
   ```bash
   # Via SCP, Git ou pasta compartilhada
   scp -r ocs-api-project/ usuario@servidor:/home/usuario/
   ```

2. **Execute o script de instalação**:
   ```bash
   cd ocs-api-project
   chmod +x scripts/setup-server.sh
   sudo ./scripts/setup-server.sh
   ```
### 🐋 Requisitos de Docker Compose

Os scripts agora detectam e instalam automaticamente o **Docker Compose**,  
seja a versão **v2 (plugin oficial)** ou a **v1 (standalone)**.

> Nenhuma ação manual é necessária — o instalador fará a detecção e instalação conforme o ambiente.
✅ Testado em:
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Docker 24.x
- Docker Compose v2.24.x e v1.29.x


3. **Acesse os serviços**:
   - API: `http://[IP_SERVIDOR]:8000/docs`
   - Metabase: `http://[IP_SERVIDOR]:3000`

**Leia o [QUICKSTART.md](QUICKSTART.md) para instruções detalhadas.**

## 📊 Endpoints da API

### Ingestão de Dados

- `POST /ocsinventory` - Endpoint compatível com agente OCS (XML)
- `POST /api/ingest` - Endpoint alternativo (JSON)

### Consultas

- `GET /api/devices` - Lista todos os dispositivos
- `GET /api/devices/{device_id}` - Detalhes de um dispositivo
- `GET /health` - Status da API e banco de dados

**Documentação completa**: `http://[IP_SERVIDOR]:8000/docs`

## 🧪 Testando

### Opção 1: Cliente de Teste Python

```bash
cd client
python3 test_client.py http://[IP_SERVIDOR]:8000
```

### Opção 2: Agente OCS Oficial

**Windows**:
```powershell
cd "C:\Program Files\OCS Inventory Agent"
.\OCSInventory.exe /force /server=http://[IP_SERVIDOR]:8000/ocsinventory
```

**Linux**:
```bash
sudo ocsinventory-agent --server http://[IP_SERVIDOR]:8000/ocsinventory
```

## 📈 Schema do Banco de Dados

O banco de dados possui as seguintes tabelas principais:

- `raw_inventory` - Payload JSON completo (auditoria)
- `devices` - Informações normalizadas dos dispositivos
- `software` - Software instalado
- `hardware_storage` - Discos e armazenamento
- `network_interfaces` - Interfaces de rede
- `logged_users` - Usuários logados

**View agregada**: `v_devices_summary` para relatórios consolidados.

## 🔧 Gerenciamento

### Ver logs:
```bash
cd /opt/ocs-api
docker-compose logs -f api
```

### Parar/Iniciar:
```bash
docker-compose stop
docker-compose start
```

### Backup do banco:
```bash
docker exec ocs-postgres pg_dump -U ocsuser ocsinventory > backup.sql
```

## 📖 Documentação Completa

- [README Detalhado](docs/README.md)
- [Guia Rápido](QUICKSTART.md)
- [API REST do OCS](docs/ocs_rest_api.md)
- [Formato XML do OCS](docs/ocs_xml_format.md)

## 🏗️ Arquitetura

```
┌─────────────────┐
│  Agente OCS     │ (Windows/Linux/macOS)
│  (Cliente)      │
└────────┬────────┘
         │ POST XML
         │ http://servidor:8000/ocsinventory
         ▼
┌─────────────────────────────────┐
│   Docker Compose (Servidor)     │
│  ┌──────────────────────────┐   │
│  │   API FastAPI (8000)     │   │
│  │  - Recebe XML/JSON       │   │
│  │  - Valida dados          │   │
│  │  - Armazena no banco     │   │
│  └──────────┬───────────────┘   │
│             │                    │
│             ▼                    │
│  ┌──────────────────────────┐   │
│  │  PostgreSQL (5432)       │   │
│  │  - Armazena inventário   │   │
│  │  - JSONB + tabelas       │   │
│  └──────────┬───────────────┘   │
│             │                    │
│             ▼                    │
│  ┌──────────────────────────┐   │
│  │  Metabase (3000)         │   │
│  │  - Dashboards            │   │
│  │  - Relatórios            │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Navegador Web  │ (Visualização)
└─────────────────┘
```

## 🤝 Contribuindo

Este é um protótipo desenvolvido para demonstração. Sugestões de melhorias:

- [ ] Autenticação JWT para a API
- [ ] Rate limiting
- [ ] Suporte a múltiplos tenants
- [ ] Webhooks para notificações
- [ ] Exportação de relatórios em PDF
- [ ] Interface web administrativa

## 📄 Licença

Este projeto é fornecido como está, para fins educacionais e de demonstração.

## 👤 Autor

**Othon Teixeira**
Data: 26 de Outubro de 2025


**⭐ Se este projeto foi útil, considere dar uma estrela!**

