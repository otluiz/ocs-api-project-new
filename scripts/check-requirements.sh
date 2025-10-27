#!/bin/bash
#
# Script de Verificação de Requisitos - OCS Inventory API
# Verifica se o sistema atende aos requisitos mínimos
#

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0
WARNINGS=0

echo "================================================================="
echo "  OCS Inventory API - Verificação de Requisitos do Sistema"
echo "================================================================="
echo ""

# Função para printar resultados
print_check() {
    local status=$1
    local message=$2
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $message"
        ((FAILED++))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
        ((WARNINGS++))
    else
        echo -e "${BLUE}ℹ${NC} $message"
    fi
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# 1. SISTEMA OPERACIONAL
print_section "Sistema Operacional"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  Distribuição: $NAME $VERSION"
    
    if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "22.04" ]]; then
        print_check "PASS" "Ubuntu 22.04 LTS detectado (recomendado)"
    elif [[ "$ID" == "ubuntu" && "$VERSION_ID" == "20.04" ]]; then
        print_check "WARN" "Ubuntu 20.04 LTS detectado (suportado, mas 22.04 é recomendado)"
    elif [[ "$ID" == "debian" ]]; then
        print_check "WARN" "Debian detectado (suportado, mas pode precisar ajustes)"
    else
        print_check "FAIL" "Sistema operacional não testado: $NAME $VERSION"
    fi
else
    print_check "FAIL" "Não foi possível detectar o sistema operacional"
fi

# Arquitetura
ARCH=$(uname -m)
echo "  Arquitetura: $ARCH"
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    print_check "PASS" "Arquitetura x86_64 suportada"
else
    print_check "WARN" "Arquitetura $ARCH pode não ser totalmente suportada"
fi

# 2. RECURSOS DE HARDWARE
print_section "Recursos de Hardware"

# CPU
CPU_CORES=$(nproc)
echo "  CPUs: $CPU_CORES vCPU(s)"
if [ "$CPU_CORES" -ge 2 ]; then
    print_check "PASS" "CPU: $CPU_CORES vCPU(s) (recomendado: 2+)"
elif [ "$CPU_CORES" -eq 1 ]; then
    print_check "WARN" "CPU: $CPU_CORES vCPU (mínimo, recomendado: 2+)"
else
    print_check "FAIL" "CPU insuficiente"
fi

# RAM
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(echo "scale=1; $TOTAL_RAM_KB / 1024 / 1024" | bc)
echo "  RAM Total: ${TOTAL_RAM_GB} GB"

if (( $(echo "$TOTAL_RAM_GB >= 4" | bc -l) )); then
    print_check "PASS" "RAM: ${TOTAL_RAM_GB} GB (recomendado: 4+ GB)"
elif (( $(echo "$TOTAL_RAM_GB >= 2" | bc -l) )); then
    print_check "WARN" "RAM: ${TOTAL_RAM_GB} GB (mínimo, recomendado: 4+ GB)"
else
    print_check "FAIL" "RAM insuficiente: ${TOTAL_RAM_GB} GB (mínimo: 2 GB)"
fi

# Disco
DISK_AVAILABLE=$(df / | tail -1 | awk '{print $4}')
DISK_AVAILABLE_GB=$(echo "scale=1; $DISK_AVAILABLE / 1024 / 1024" | bc)
echo "  Disco Disponível: ${DISK_AVAILABLE_GB} GB"

if (( $(echo "$DISK_AVAILABLE_GB >= 40" | bc -l) )); then
    print_check "PASS" "Disco: ${DISK_AVAILABLE_GB} GB disponíveis (recomendado: 40+ GB)"
elif (( $(echo "$DISK_AVAILABLE_GB >= 20" | bc -l) )); then
    print_check "WARN" "Disco: ${DISK_AVAILABLE_GB} GB disponíveis (mínimo, recomendado: 40+ GB)"
else
    print_check "FAIL" "Disco insuficiente: ${DISK_AVAILABLE_GB} GB (mínimo: 20 GB)"
fi

# 3. CONECTIVIDADE
print_section "Conectividade de Rede"

# Internet
if ping -c 2 -W 3 8.8.8.8 > /dev/null 2>&1; then
    print_check "PASS" "Conectividade com a internet OK"
else
    print_check "FAIL" "Sem conectividade com a internet"
fi

# DNS
if ping -c 2 -W 3 google.com > /dev/null 2>&1; then
    print_check "PASS" "Resolução DNS funcionando"
else
    print_check "WARN" "Problemas com resolução DNS"
fi

# IP
IP_ADDRESS=$(hostname -I | awk '{print $1}')
if [ -n "$IP_ADDRESS" ]; then
    echo "  Endereço IP: $IP_ADDRESS"
    print_check "PASS" "Endereço IP configurado: $IP_ADDRESS"
else
    print_check "FAIL" "Nenhum endereço IP detectado"
fi

# 4. PORTAS DISPONÍVEIS
print_section "Disponibilidade de Portas"

check_port() {
    local port=$1
    local service=$2
    
    if command -v netstat > /dev/null 2>&1; then
        if ! sudo netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_check "PASS" "Porta $port ($service) disponível"
        else
            print_check "FAIL" "Porta $port ($service) já está em uso"
        fi
    elif command -v ss > /dev/null 2>&1; then
        if ! sudo ss -tuln 2>/dev/null | grep -q ":$port "; then
            print_check "PASS" "Porta $port ($service) disponível"
        else
            print_check "FAIL" "Porta $port ($service) já está em uso"
        fi
    else
        print_check "WARN" "Não foi possível verificar porta $port (netstat/ss não encontrado)"
    fi
}

check_port 8000 "API FastAPI"
check_port 3000 "Metabase"
check_port 5432 "PostgreSQL"

# 5. SOFTWARE NECESSÁRIO
print_section "Software Instalado"

# Docker
if command -v docker > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo "  Docker: $DOCKER_VERSION"
    print_check "PASS" "Docker instalado: $DOCKER_VERSION"
else
    print_check "WARN" "Docker não instalado (será instalado pelo script setup)"
fi

# Docker Compose
if command -v docker-compose > /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $4}')
    echo "  Docker Compose: $COMPOSE_VERSION"
    print_check "PASS" "Docker Compose instalado: $COMPOSE_VERSION"
elif docker compose version > /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo "  Docker Compose: $COMPOSE_VERSION"
    print_check "PASS" "Docker Compose (plugin) instalado: $COMPOSE_VERSION"
else
    print_check "WARN" "Docker Compose não instalado (será instalado pelo script setup)"
fi

# Git
if command -v git > /dev/null 2>&1; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_check "PASS" "Git instalado: $GIT_VERSION"
else
    print_check "WARN" "Git não instalado (recomendado para versionamento)"
fi

# Curl
if command -v curl > /dev/null 2>&1; then
    print_check "PASS" "curl instalado"
else
    print_check "FAIL" "curl não instalado (necessário para instalação)"
fi

# 6. PERMISSÕES
print_section "Permissões e Acesso"

# Sudo
if sudo -n true 2>/dev/null; then
    print_check "PASS" "Usuário tem privilégios sudo sem senha"
elif sudo -v 2>/dev/null; then
    print_check "WARN" "Usuário tem privilégios sudo (requer senha)"
else
    print_check "FAIL" "Usuário não tem privilégios sudo"
fi

# Docker group (se Docker estiver instalado)
if command -v docker > /dev/null 2>&1; then
    if groups | grep -q docker; then
        print_check "PASS" "Usuário no grupo docker"
    else
        print_check "WARN" "Usuário não está no grupo docker (necessário reiniciar sessão após instalação)"
    fi
fi

# 7. FIREWALL
print_section "Firewall"

if command -v ufw > /dev/null 2>&1; then
    UFW_STATUS=$(sudo ufw status | head -1 | awk '{print $2}')
    echo "  UFW Status: $UFW_STATUS"
    
    if [ "$UFW_STATUS" = "inactive" ]; then
        print_check "WARN" "UFW desabilitado (será configurado pelo script setup)"
    else
        print_check "INFO" "UFW ativo (será configurado pelo script setup)"
        
        # Verificar regras
        if sudo ufw status | grep -q "8000"; then
            print_check "PASS" "Porta 8000 permitida no firewall"
        else
            print_check "WARN" "Porta 8000 não configurada no firewall"
        fi
    fi
else
    print_check "INFO" "UFW não instalado (firewall será configurado pelo script setup)"
fi

# 8. RESUMO FINAL
echo ""
echo "================================================================="
echo "  RESUMO DA VERIFICAÇÃO"
echo "================================================================="
echo ""
echo -e "${GREEN}Verificações Aprovadas:${NC} $PASSED"
echo -e "${YELLOW}Avisos:${NC} $WARNINGS"
echo -e "${RED}Falhas:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ Sistema atende a todos os requisitos!${NC}"
        echo "  Você pode prosseguir com a instalação."
        echo ""
        echo "  Execute: sudo ./scripts/setup-server.sh"
        exit 0
    else
        echo -e "${YELLOW}⚠ Sistema atende aos requisitos mínimos com avisos.${NC}"
        echo "  A instalação pode prosseguir, mas revise os avisos acima."
        echo ""
        echo "  Execute: sudo ./scripts/setup-server.sh"
        exit 0
    fi
else
    echo -e "${RED}✗ Sistema NÃO atende aos requisitos mínimos.${NC}"
    echo "  Corrija as falhas acima antes de prosseguir."
    echo ""
    echo "  Consulte: REQUISITOS.md para mais informações"
    exit 1
fi

