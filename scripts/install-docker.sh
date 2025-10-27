#!/bin/bash
#
# Script de Instalação do Docker e Docker Compose
# Para Ubuntu 22.04 LTS
#

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================="
echo "  Instalação do Docker e Docker Compose"
echo "========================================="
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    print_error "Por favor, execute como root (sudo)"
    exit 1
fi

# Verificar sistema operacional
if [ ! -f /etc/os-release ]; then
    print_error "Não foi possível detectar o sistema operacional"
    exit 1
fi

. /etc/os-release
print_info "Sistema detectado: $NAME $VERSION"

if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
    print_warn "Este script foi testado apenas em Ubuntu/Debian"
    read -p "Deseja continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# 1. Remover versões antigas do Docker
print_info "Removendo versões antigas do Docker (se existirem)..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 2. Atualizar índice de pacotes
print_info "Atualizando índice de pacotes..."
apt-get update -qq

# 3. Instalar dependências
print_info "Instalando dependências..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 4. Adicionar chave GPG oficial do Docker
print_info "Adicionando chave GPG do Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$ID/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 5. Configurar repositório
print_info "Configurando repositório do Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/$ID \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. Atualizar índice de pacotes novamente
print_info "Atualizando índice de pacotes..."
apt-get update -qq

# 7. Instalar Docker Engine
print_info "Instalando Docker Engine..."
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 8. Iniciar e habilitar Docker
print_info "Iniciando serviço Docker..."
systemctl start docker
systemctl enable docker

# 9. Verificar instalação
print_info "Verificando instalação..."
DOCKER_VERSION=$(docker --version)
COMPOSE_VERSION=$(docker compose version)

echo ""
echo "========================================="
echo "  ✓ Instalação Concluída!"
echo "========================================="
echo ""
echo "Versões instaladas:"
echo "  • $DOCKER_VERSION"
echo "  • $COMPOSE_VERSION"
echo ""

# 10. Testar Docker
print_info "Testando Docker com container hello-world..."
if docker run --rm hello-world > /dev/null 2>&1; then
    print_info "✓ Docker está funcionando corretamente!"
else
    print_warn "Houve um problema ao executar o container de teste"
fi

# 11. Adicionar usuário ao grupo docker (opcional)
if [ -n "$SUDO_USER" ]; then
    print_info "Adicionando usuário $SUDO_USER ao grupo docker..."
    usermod -aG docker $SUDO_USER
    echo ""
    print_warn "IMPORTANTE: O usuário $SUDO_USER precisa fazer logout e login novamente"
    print_warn "para que as permissões do grupo docker sejam aplicadas."
fi

echo ""
print_info "Comandos úteis:"
echo "  • Verificar versão: docker --version"
echo "  • Verificar status: systemctl status docker"
echo "  • Listar containers: docker ps"
echo "  • Listar imagens: docker images"
echo ""
print_info "Instalação do Docker concluída!"

