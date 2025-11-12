#!/bin/bash
#
# Script de Configuração do Metabase
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


echo "========================================="
echo "  Configuração do Metabase (BI)"
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
if ! $DOCKER_COMPOSE ps db | grep -q "Up"; then
    print_error "Container PostgreSQL não está rodando!"
    print_info "Execute primeiro: sudo ./scripts/setup-database.sh"
    exit 1
fi

# 1. Iniciar container do Metabase
print_info "Iniciando container Metabase..."
print_warn "ATENÇÃO: O Metabase pode levar 2-3 minutos para inicializar completamente"
$DOCKER_COMPOSE up -d metabase

# 2. Aguardar Metabase ficar pronto
print_info "Aguardando Metabase inicializar (isso pode demorar)..."
echo "  Progresso: "

MAX_ATTEMPTS=180  # 3 minutos
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        echo ""
        print_info "✓ Metabase está pronto e respondendo!"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    
    # Mostrar progresso a cada 10 segundos
    if [ $((ATTEMPT % 10)) -eq 0 ]; then
        echo -n " ${ATTEMPT}s"
    else
        echo -n "."
    fi
    
    sleep 1
done

echo ""

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    print_error "Metabase não ficou pronto após $MAX_ATTEMPTS segundos"
    print_info "Verificando logs..."
    $DOCKER_COMPOSE logs --tail=50 metabase
    print_warn "O Metabase pode estar ainda inicializando. Aguarde mais alguns minutos."
    exit 1
fi

# 3. Verificar se Metabase está acessível
print_info "Verificando acessibilidade do Metabase..."
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    print_info "✓ Interface web do Metabase acessível"
else
    print_warn "Interface web pode ainda estar carregando"
fi

# 4. Obter IP do servidor
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo "  ✓ Configuração do Metabase Concluída!"
echo "========================================="
echo ""
echo "Metabase disponível em:"
echo "  • Local: http://localhost:3000"
echo "  • Rede: http://$SERVER_IP:3000"
echo ""
print_warn "CONFIGURAÇÃO INICIAL NECESSÁRIA:"
echo ""
echo "1. Acesse http://$SERVER_IP:3000 no navegador"
echo ""
echo "2. Na primeira vez, você verá o assistente de configuração:"
echo "   • Crie uma conta de administrador"
echo "   • Escolha idioma (Português ou English)"
echo ""
echo "3. Conecte ao banco de dados PostgreSQL:"
echo "   ┌─────────────────────────────────────────┐"
echo "   │ Tipo de Banco:  PostgreSQL              │"
echo "   │ Nome:           OCS Inventory           │"
echo "   │ Host:           db                      │"
echo "   │ Porta:          5432                    │"
echo "   │ Nome do Banco:  ocsinventory            │"
echo "   │ Usuário:        ocsuser                 │"
echo "   │ Senha:          ocspassword             │"
echo "   └─────────────────────────────────────────┘"
echo ""
echo "4. Após conectar, você poderá:"
echo "   • Explorar as tabelas de inventário"
echo "   • Criar dashboards personalizados"
echo "   • Gerar relatórios e gráficos"
echo ""
echo "Tabelas disponíveis:"
echo "  • devices - Dispositivos inventariados"
echo "  • software - Software instalado"
echo "  • hardware_storage - Armazenamento"
echo "  • network_interfaces - Interfaces de rede"
echo "  • logged_users - Usuários logados"
echo "  • v_devices_summary - View consolidada"
echo ""
echo "Comandos úteis:"
echo "  • Ver logs:"
echo "    docker compose logs -f metabase"
echo "ou (em sistemas mais antigos): docker-compose logs -f metabase"
echo ""
echo "  • Reiniciar Metabase:"
echo "    docker compose restart metabase"
echo "ou (em sistemas mais antigos): docker-compose restart metabase"
echo ""
echo "  • Acessar dados do Metabase:"
echo "    docker compose exec metabase ls -la /metabase-data"
echo "ou (em sistemas mais antigos): docker-compose exec metabase ls -la /metabase-data"
echo ""
print_info "Configuração do Metabase concluída!"
print_warn "Acesse http://$SERVER_IP:3000 para completar a configuração inicial"

