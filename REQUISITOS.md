# 📋 Requisitos Mínimos do Sistema

**Projeto**: OCS Inventory API  
**Versão**: 1.0.0  
**Data**: 22 de Outubro de 2025

---

## 🖥️ Requisitos de Hardware

### Servidor (VM Ubuntu 22.04)

| Componente | Mínimo | Recomendado | Produção |
|:---|:---:|:---:|:---:|
| **CPU** | 1 vCPU | 2 vCPUs | 4+ vCPUs |
| **RAM** | 2 GB | 4 GB | 8+ GB |
| **Disco** | 20 GB | 40 GB | 100+ GB |
| **Rede** | 100 Mbps | 1 Gbps | 1+ Gbps |

### Cliente (Agente OCS)

| Sistema Operacional | RAM Mínima | Disco |
|:---|:---:|:---:|
| Windows 10/11 | 512 MB | 100 MB |
| Linux Desktop | 256 MB | 50 MB |
| macOS | 512 MB | 100 MB |

---

## 💿 Requisitos de Software

### Sistema Operacional (Servidor)

| SO | Versão Suportada | Status |
|:---|:---:|:---:|
| **Ubuntu Server** | 22.04 LTS | ✅ Recomendado |
| Ubuntu Server | 20.04 LTS | ✅ Suportado |
| Debian | 11 (Bullseye) | ✅ Suportado |
| CentOS/RHEL | 8+ | ⚠️ Requer adaptações |
| Windows Server | 2019+ | ❌ Não suportado nativamente |

**Nota**: Os scripts foram desenvolvidos e testados para **Ubuntu 22.04 LTS**.

---

## 🐳 Docker e Docker Compose

### Versões Necessárias

| Componente | Versão Mínima | Versão Recomendada |
|:---|:---:|:---:|
| **Docker Engine** | 20.10.0 | 24.0.0+ |
| **Docker Compose** | 2.0.0 | 2.24.0+ |

### Instalação Automática

O script `setup-server.sh` instala automaticamente as versões mais recentes.

### Instalação Manual

```bash
# Remover versões antigas (se existirem)
sudo apt-get remove docker docker-engine docker.io containerd runc

# Instalar dependências
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Adicionar chave GPG oficial do Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Adicionar repositório
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verificar instalação
docker --version
docker compose version
```

---

## 🗄️ PostgreSQL (via Docker)

### Versão Utilizada

- **PostgreSQL**: 15-alpine (via imagem Docker oficial)

### Configurações do Container

| Parâmetro | Valor Padrão | Descrição |
|:---|:---:|:---|
| **Porta** | 5432 | Porta exposta para conexões |
| **Database** | ocsinventory | Nome do banco de dados |
| **Usuário** | ocsuser | Usuário do banco |
| **Senha** | ocspassword | Senha do usuário (⚠️ alterar em produção) |
| **Volume** | postgres_data | Volume persistente para dados |

### Extensões PostgreSQL Necessárias

Nenhuma extensão adicional é necessária. O PostgreSQL padrão já inclui:
- ✅ Suporte a JSONB
- ✅ Índices GIN
- ✅ Triggers e Functions

### Requisitos de Disco (PostgreSQL)

| Cenário | Dispositivos | Espaço Estimado |
|:---|:---:|:---:|
| Teste | 1-10 | ~100 MB |
| Pequeno | 10-100 | ~500 MB |
| Médio | 100-1000 | ~5 GB |
| Grande | 1000-10000 | ~50 GB |

**Nota**: Estimativas baseadas em ~500 KB por dispositivo (incluindo software e histórico).

---

## 🚀 API FastAPI (via Docker)

### Versão Python

- **Python**: 3.11 (via imagem Docker oficial)

### Dependências Python

Todas as dependências estão listadas em `api/requirements.txt`:

```txt
fastapi==0.115.0
uvicorn[standard]==0.32.0
pydantic==2.9.2
pydantic-settings==2.6.0
psycopg2-binary==2.9.9
sqlalchemy==2.0.35
python-multipart==0.0.12
python-dateutil==2.9.0
```

### Configurações do Container

| Parâmetro | Valor Padrão | Descrição |
|:---|:---:|:---|
| **Porta** | 8000 | Porta da API |
| **Workers** | 1 | Processos Uvicorn (ajustar conforme CPU) |
| **Reload** | Habilitado | Auto-reload em desenvolvimento |

### Variáveis de Ambiente

| Variável | Valor Padrão | Obrigatória |
|:---|:---:|:---:|
| `DATABASE_URL` | postgresql://ocsuser:ocspassword@db:5432/ocsinventory | ✅ Sim |

---

## 📊 Metabase (via Docker)

### Versão Utilizada

- **Metabase**: latest (via imagem Docker oficial)

### Configurações do Container

| Parâmetro | Valor Padrão | Descrição |
|:---|:---:|:---|
| **Porta** | 3000 | Porta da interface web |
| **MB_DB_TYPE** | postgres | Tipo de banco para metadados do Metabase |
| **MB_DB_HOST** | db | Host do PostgreSQL |
| **Volume** | metabase_data | Volume persistente para configurações |

### Requisitos de Disco (Metabase)

- **Mínimo**: 500 MB
- **Recomendado**: 2 GB (para cache e metadados)

---

## 🌐 Requisitos de Rede

### Portas Necessárias (Firewall)

| Porta | Serviço | Protocolo | Acesso |
|:---:|:---|:---:|:---|
| **22** | SSH | TCP | Administração |
| **8000** | API FastAPI | TCP | Agentes OCS + Consultas |
| **3000** | Metabase | TCP | Interface Web (BI) |
| **5432** | PostgreSQL | TCP | ⚠️ Apenas interno (Docker) |

### Configuração de Firewall (UFW)

```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH
sudo ufw allow 22/tcp comment 'SSH'

# Permitir API
sudo ufw allow 8000/tcp comment 'OCS API'

# Permitir Metabase
sudo ufw allow 3000/tcp comment 'Metabase'

# Verificar regras
sudo ufw status numbered
```

### Configuração de Rede (VirtualBox/VMware)

| Modo de Rede | Acesso Externo | Acesso entre VMs | Recomendado Para |
|:---|:---:|:---:|:---|
| **Bridge** | ✅ Sim | ✅ Sim | ✅ Produção/Testes |
| **NAT** | ⚠️ Port Forwarding | ❌ Não | Desenvolvimento |
| **Host-Only** | ❌ Não | ✅ Sim | Testes isolados |

**Recomendação**: Use **Bridge** para facilitar a comunicação entre servidor e clientes.

---

## 🔧 Utilitários do Sistema

### Instalados Automaticamente pelo Script

```bash
# Ferramentas de rede
net-tools           # ifconfig, netstat
curl                # Cliente HTTP
wget                # Download de arquivos

# Editores de texto
nano                # Editor simples
vim                 # Editor avançado

# Monitoramento
htop                # Monitor de processos

# Versionamento
git                 # Controle de versão
```

### Instalação Manual (se necessário)

```bash
sudo apt-get update
sudo apt-get install -y \
  curl \
  wget \
  git \
  nano \
  vim \
  htop \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release
```

---

## 📱 Requisitos do Cliente (Agente OCS)

### Windows

| Requisito | Versão/Especificação |
|:---|:---|
| **Sistema Operacional** | Windows 7+ (recomendado: Windows 10/11) |
| **Agente OCS** | 2.10.0+ |
| **PowerShell** | 5.1+ (para comandos de teste) |
| **.NET Framework** | 4.5+ (instalado com o agente) |

**Download**: [OCS Inventory Windows Agent](https://github.com/OCSInventory-NG/WindowsAgent/releases)

### Linux

| Requisito | Versão/Especificação |
|:---|:---|
| **Sistema Operacional** | Ubuntu 18.04+, Debian 10+, RHEL 7+ |
| **Agente OCS** | 2.9.0+ |
| **Perl** | 5.10+ (geralmente já instalado) |

**Instalação**:
```bash
# Ubuntu/Debian
sudo apt-get install ocsinventory-agent

# RHEL/CentOS
sudo yum install ocsinventory-agent
```

### macOS

| Requisito | Versão/Especificação |
|:---|:---|
| **Sistema Operacional** | macOS 10.12+ |
| **Agente OCS** | 2.9.0+ |

**Download**: [OCS Inventory macOS Agent](https://github.com/OCSInventory-NG/UnixAgent/releases)

---

## 🔐 Requisitos de Segurança

### Produção (Recomendações)

- ✅ Alterar senhas padrão do PostgreSQL
- ✅ Configurar HTTPS/TLS na API (usar Nginx como reverse proxy)
- ✅ Implementar autenticação JWT
- ✅ Configurar backup automático do banco de dados
- ✅ Limitar acesso ao PostgreSQL (apenas localhost/Docker network)
- ✅ Habilitar logs de auditoria

### Desenvolvimento/Teste

- ⚠️ Senhas padrão são aceitáveis
- ⚠️ HTTP sem TLS é aceitável
- ⚠️ Firewall pode ser mais permissivo

---

## 📦 Espaço em Disco Total Estimado

### Instalação Inicial

| Componente | Espaço |
|:---|---:|
| Docker Engine | ~500 MB |
| Imagem PostgreSQL | ~200 MB |
| Imagem Python (API) | ~300 MB |
| Imagem Metabase | ~400 MB |
| **Total Inicial** | **~1.4 GB** |

### Em Operação (exemplo com 100 dispositivos)

| Componente | Espaço |
|:---|---:|
| Banco de dados | ~500 MB |
| Logs da API | ~100 MB |
| Metabase (cache) | ~200 MB |
| **Total Operação** | **~800 MB** |

**Total Estimado**: ~2.2 GB para instalação + 100 dispositivos

---

## ✅ Checklist Pré-Instalação

Antes de executar o script de instalação, verifique:

- [ ] VM com Ubuntu 22.04 LTS instalado
- [ ] Mínimo 2 GB RAM, 20 GB disco
- [ ] Acesso root/sudo
- [ ] Conexão com a internet ativa
- [ ] Portas 8000 e 3000 disponíveis
- [ ] Rede configurada (IP fixo ou DHCP estável)
- [ ] Firewall permite SSH (porta 22)

---

## 🆘 Verificação de Requisitos

Execute este script para verificar se o sistema atende aos requisitos:

```bash
#!/bin/bash
# Script de verificação de requisitos

echo "=== Verificação de Requisitos OCS API ==="
echo ""

# Verificar SO
echo "Sistema Operacional:"
lsb_release -d
echo ""

# Verificar RAM
echo "Memória RAM:"
free -h | grep Mem
echo ""

# Verificar Disco
echo "Espaço em Disco:"
df -h / | tail -1
echo ""

# Verificar conexão com internet
echo "Conectividade:"
ping -c 2 8.8.8.8 > /dev/null 2>&1 && echo "✓ Internet OK" || echo "✗ Sem internet"
echo ""

# Verificar portas
echo "Portas disponíveis:"
for port in 8000 3000 5432; do
  if ! sudo netstat -tuln | grep -q ":$port "; then
    echo "✓ Porta $port disponível"
  else
    echo "✗ Porta $port em uso"
  fi
done
```

Salve como `check-requirements.sh`, dê permissão de execução (`chmod +x`) e execute.

---

## 📞 Suporte

Se encontrar problemas com requisitos, consulte:
- **Documentação**: `docs/README.md`
- **Guia Rápido**: `QUICKSTART.md`
- **Troubleshooting**: Seção no QUICKSTART.md

