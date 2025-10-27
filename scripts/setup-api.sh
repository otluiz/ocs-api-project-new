#!/bin/bash
#
# Script de Configuração da API FastAPI
# Executa via Docker Compose
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
echo "  Configuração da API FastAPI"
echo "========================================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    print_info "Execute primeiro: sudo ./scripts/install-docker.sh"
    exit 1
fi

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    print_error "Arquivo docker-compose.yml não encontrado!"
    print_info "Execute este script a partir do diretório raiz do projeto"
    exit 1
fi

# Verificar se PostgreSQL está rodando
if ! docker compose ps db | grep -q "Up"; then
    print_error "Container PostgreSQL não está rodando!"
    print_info "Execute primeiro: sudo ./scripts/setup-database.sh"
    exit 1
fi

# 1. Construir imagem da API
print_info "Construindo imagem Docker da API..."
docker compose build api

# 2. Iniciar container da API
print_info "Iniciando container da API..."
docker compose up -d api

# 3. Aguardar API ficar pronta
print_info "Aguardando API inicializar..."
sleep 5

# Verificar se está rodando
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_info "✓ API está pronta e respondendo!"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 1
done

echo ""

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    print_error "API não ficou pronta após $MAX_ATTEMPTS segundos"
    print_info "Verificando logs..."
    docker compose logs api
    exit 1
fi

# 4. Testar endpoints
print_info "Testando endpoints da API..."

# Health check
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_info "✓ Endpoint /health OK"
else
    print_warn "Problema no endpoint /health"
fi

# Root endpoint
if curl -f http://localhost:8000/ > /dev/null 2>&1; then
    print_info "✓ Endpoint raiz (/) OK"
else
    print_warn "Problema no endpoint raiz"
fi

# Docs endpoint
if curl -f http://localhost:8000/docs > /dev/null 2>&1; then
    print_info "✓ Documentação (/docs) OK"
else
    print_warn "Problema no endpoint de documentação"
fi

# 5. Obter IP do servidor
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo "  ✓ Configuração da API Concluída!"
echo "========================================="
echo ""
echo "API disponível em:"
echo "  • Local: http://localhost:8000"
echo "  • Rede: http://$SERVER_IP:8000"
echo ""
echo "Endpoints principais:"
echo "  • Documentação: http://$SERVER_IP:8000/docs"
echo "  • Health Check: http://$SERVER_IP:8000/health"
echo "  • OCS Agent: http://$SERVER_IP:8000/ocsinventory"
echo "  • Listar Devices: http://$SERVER_IP:8000/api/devices"
echo ""
echo "Comandos úteis:"
echo "  • Ver logs em tempo real:"
echo "    docker compose logs -f api"
echo ""
echo "  • Reiniciar API:"
echo "    docker compose restart api"
echo ""
echo "  • Acessar shell do container:"
echo "    docker compose exec api /bin/bash"
echo ""
echo "  • Testar endpoint:"
echo "    curl http://localhost:8000/health"
echo ""
print_info "Configuração da API concluída!"

