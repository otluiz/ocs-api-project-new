#!/bin/bash
#
# Script de Instalação do OCS API Server
# Para Ubuntu 22.04 LTS
#

set -e

echo "========================================="
echo "  OCS Inventory API - Setup do Servidor"
echo "========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para printar com cor
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Por favor, execute como root (sudo)"
    exit 1
fi

# Obter IP do servidor
SERVER_IP=$(hostname -I | awk '{print $1}')
print_info "IP do servidor detectado: $SERVER_IP"

# 1. Atualizar sistema
print_info "Atualizando sistema..."
apt-get update -qq
apt-get upgrade -y -qq

# =========================================
#  Detectar ou instalar Docker Compose (padrão unificado)
# =========================================

# Verifica se o Docker Compose (v2 plugin ou v1 standalone) está presente
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
    echo "[INFO] Usando Docker Compose v2 (plugin integrado)"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
    echo "[INFO] Usando Docker Compose v1 (binário standalone)"
else
    echo "[WARN] Docker Compose não encontrado — instalando automaticamente..."
    apt-get update -y
    apt-get install -y docker-compose-plugin
    if docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE="docker compose"
        echo "[INFO] Docker Compose v2 instalado com sucesso"
    else
        echo "[WARN] Falha ao instalar o plugin oficial, tentando fallback standalone..."
        curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        DOCKER_COMPOSE="docker-compose"
        echo "[INFO] Docker Compose (standalone) instalado como fallback"
    fi
fi


# 2. Instalar Docker
if ! command -v docker &> /dev/null; then
    print_info "Instalando Docker..."
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Adicionar repositório oficial do Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Iniciar e habilitar Docker
    systemctl start docker
    systemctl enable docker
    
    print_info "✓ Docker instalado com sucesso"
else
    print_info "✓ Docker já está instalado"
fi

# 3. Instalar Docker Compose (plugin oficial ou fallback)
if $DOCKER_COMPOSE version >/dev/null 2>&1; then
    print_info "✓ Docker Compose v2 (plugin oficial) já está instalado"
elif command -v $DOCKER_COMPOSE >/dev/null 2>&1; then
    print_warn "Docker Compose (standalone v1) detectado — considere atualizar para o plugin v2"
else
    print_info "Instalando Docker Compose Plugin (v2)..."
    apt-get update -y
    apt-get install -y docker-compose-plugin
    if $DOCKER_COMPOSE version >/dev/null 2>&1; then
        print_info "✓ Docker Compose Plugin (v2) instalado com sucesso"
    else
        print_warn "Falha ao instalar o plugin oficial, tentando versão standalone..."
        curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        print_info "✓ Docker Compose (standalone) instalado como fallback"
    fi
fi


# 4. Instalar utilitários
print_info "Instalando utilitários..."
apt-get install -y git curl wget nano vim htop net-tools

# 5. Configurar firewall (UFW)
print_info "Configurando firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp comment 'SSH'
    ufw allow 8000/tcp comment 'OCS API'
    ufw allow 3000/tcp comment 'Metabase'
    ufw --force enable
    print_info "✓ Firewall configurado"
fi

# 6. Criar diretório do projeto
PROJECT_DIR="/opt/ocs-api"
print_info "Criando diretório do projeto em $PROJECT_DIR..."

if [ -d "$PROJECT_DIR" ]; then
    print_warn "Diretório já existe. Fazendo backup..."
    mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$PROJECT_DIR"

# 7. Copiar arquivos do projeto
print_info "Copiando arquivos do projeto..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cp -r "$SCRIPT_DIR"/* "$PROJECT_DIR/"

# 8. Ajustar permissões
chmod +x "$PROJECT_DIR"/scripts/*.sh

# 9. Criar arquivo .env
print_info "Criando arquivo de configuração..."
cat > "$PROJECT_DIR/.env" << EOF
# Configurações do Banco de Dados
POSTGRES_DB=ocsinventory
POSTGRES_USER=ocsuser
POSTGRES_PASSWORD=ocspassword

# Configurações da API
DATABASE_URL=postgresql://ocsuser:ocspassword@db:5432/ocsinventory
API_PORT=8000

# Configurações do Metabase
METABASE_PORT=3000
EOF

print_info "✓ Arquivo .env criado"

# 10. Iniciar serviços
print_info "Iniciando serviços Docker..."
cd "$PROJECT_DIR"
$DOCKER_COMPOSE down 2>/dev/null || true
$DOCKER_COMPOSE up -d

# Aguardar serviços ficarem prontos
print_info "Aguardando serviços iniciarem..."
sleep 10

# Verificar status
print_info "Verificando status dos serviços..."
$DOCKER_COMPOSE ps

echo ""
echo "========================================="
echo "  ✓ Instalação Concluída com Sucesso!"
echo "========================================="
echo ""
echo "Serviços disponíveis:"
echo ""
echo "  • API OCS Inventory:"
echo "    http://$SERVER_IP:8000"
echo "    Documentação: http://$SERVER_IP:8000/docs"
echo ""
echo "  • Metabase (BI):"
echo "    http://$SERVER_IP:3000"
echo "    (Configuração inicial necessária no primeiro acesso)"
echo ""
echo "  • PostgreSQL:"
echo "    Host: $SERVER_IP:5432"
echo "    Database: ocsinventory"
echo "    User: ocsuser"
echo "    Password: ocspassword"
echo ""
echo "Endpoint para agentes OCS:"
echo "  http://$SERVER_IP:8000/ocsinventory"
echo ""
echo "Comandos úteis:"
echo "  • Ver logs: cd $PROJECT_DIR && docker-compose logs -f"
echo "  • Parar: cd $PROJECT_DIR && docker-compose stop"
echo "  • Iniciar: cd $PROJECT_DIR && docker-compose start"
echo "  • Reiniciar: cd $PROJECT_DIR && docker-compose restart"
echo ""
print_info "Instalação finalizada!"

