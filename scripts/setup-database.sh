#!/bin/bash
#
# Script de Configuração do Banco de Dados PostgreSQL
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
echo "  Configuração do Banco de Dados"
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

# 1. Iniciar apenas o container do PostgreSQL
print_info "Iniciando container PostgreSQL..."
docker compose up -d db

# 2. Aguardar PostgreSQL ficar pronto
print_info "Aguardando PostgreSQL inicializar..."
sleep 5

# Verificar se está rodando
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker compose exec -T db pg_isready -U ocsuser -d ocsinventory > /dev/null 2>&1; then
        print_info "✓ PostgreSQL está pronto!"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 1
done

echo ""

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    print_error "PostgreSQL não ficou pronto após $MAX_ATTEMPTS segundos"
    print_info "Verificando logs..."
    docker compose logs db
    exit 1
fi

# 3. Verificar se schema foi aplicado
print_info "Verificando schema do banco de dados..."
TABLE_COUNT=$(docker compose exec -T db psql -U ocsuser -d ocsinventory -t -c \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')

if [ "$TABLE_COUNT" -gt 0 ]; then
    print_info "✓ Schema aplicado com sucesso! ($TABLE_COUNT tabelas criadas)"
else
    print_warn "Schema não foi aplicado automaticamente. Aplicando manualmente..."
    
    if [ -f "database/schema.sql" ]; then
        docker compose exec -T db psql -U ocsuser -d ocsinventory < database/schema.sql
        print_info "✓ Schema aplicado manualmente"
    else
        print_error "Arquivo database/schema.sql não encontrado!"
        exit 1
    fi
fi

# 4. Listar tabelas criadas
print_info "Tabelas criadas:"
docker compose exec -T db psql -U ocsuser -d ocsinventory -c \
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" | \
    grep -v "^-" | grep -v "row" | grep -v "^$" | sed 's/^/  • /'

# 5. Verificar dados de exemplo
print_info "Verificando dados de exemplo..."
DEVICE_COUNT=$(docker compose exec -T db psql -U ocsuser -d ocsinventory -t -c \
    "SELECT COUNT(*) FROM devices;" | tr -d ' ')

if [ "$DEVICE_COUNT" -gt 0 ]; then
    print_info "✓ $DEVICE_COUNT dispositivo(s) de exemplo encontrado(s)"
else
    print_warn "Nenhum dispositivo de exemplo encontrado (normal em instalação limpa)"
fi

echo ""
echo "========================================="
echo "  ✓ Configuração do Banco Concluída!"
echo "========================================="
echo ""
echo "Informações de conexão:"
echo "  • Host: localhost (ou IP do servidor)"
echo "  • Porta: 5432"
echo "  • Database: ocsinventory"
echo "  • Usuário: ocsuser"
echo "  • Senha: ocspassword"
echo ""
print_warn "IMPORTANTE: Altere a senha padrão em ambiente de produção!"
echo ""
echo "Comandos úteis:"
echo "  • Conectar ao banco:"
echo "    docker compose exec db psql -U ocsuser -d ocsinventory"
echo ""
echo "  • Fazer backup:"
echo "    docker compose exec db pg_dump -U ocsuser ocsinventory > backup.sql"
echo ""
echo "  • Restaurar backup:"
echo "    docker compose exec -T db psql -U ocsuser -d ocsinventory < backup.sql"
echo ""
echo "  • Ver logs:"
echo "    docker compose logs -f db"
echo ""
print_info "Configuração concluída!"

