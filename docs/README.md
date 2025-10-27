# OCS Inventory API - Protótipo Completo

**Autor**: Othon Teixeira
**Data**: 22 de Outubro de 2025
**Versão**:1.0.0

Este projeto implementa um protótipo completo e funcional de uma API de gestão de dados para o OCS Inventory, utilizando um stack moderno, performático e de fácil deployment. A solução foi desenhada para ser um substituto direto e simplificado do servidor OCS tradicional.

## 1. Arquitetura do Stack

O projeto é orquestrado via Docker Compose e consiste nos seguintes serviços:

- **Backend API**: Uma API **FastAPI** (Python) que serve como o núcleo da solução. Ela é responsável por receber os dados de inventário, processá-los e armazená-los.
- **Banco de Dados**: Um banco de dados **PostgreSQL**, escolhido por sua robustez, performance com dados complexos e suporte nativo a JSONB.
- **BI & Frontend**: Uma instância do **Metabase**, uma poderosa ferramenta de Business Intelligence open-source que se conecta diretamente ao banco de dados e permite a criação de dashboards e relatórios interativos sem a necessidade de código.

![Arquitetura da Solução](https://imgur.com/a/L6uEYOH)  <!-- Placeholder for a diagram -->

## 2. Funcionalidades

- **Compatibilidade com Agente OCS**: O endpoint `/ocsinventory` aceita requisições `POST` com o formato **XML** padrão enviado pelos agentes oficiais do OCS Inventory.
- **API REST JSON**: A API expõe endpoints REST (`/api/*`) para consultar os dados em formato **JSON**, seguindo um padrão similar à API oficial do OCS para facilitar a integração.
- **Ingestão e CRUD**: A API realiza operações de `INSERT` e `UPDATE` (UPSERT) de forma automática, mantendo o inventário sempre atualizado.
- **Deployment Simplificado**: Um único script (`setup-server.sh`) prepara um servidor Ubuntu 22.04 e sobe todo o stack com um comando.
- **Análise de Dados Imediata**: O Metabase permite a exploração visual dos dados de inventário assim que eles são ingeridos.

## 3. Estrutura do Projeto

```
/ocs-api-project
├── api/                     # Código fonte da API FastAPI
│   ├── Dockerfile           # Dockerfile para a API
│   ├── main.py              # Lógica principal e endpoints
│   ├── models.py            # Modelos Pydantic para validação
│   ├── database.py          # Conexão com o banco de dados
│   └── requirements.txt     # Dependências Python
├── client/                  # Cliente de teste
│   └── test_client.py       # Script Python para simular envio de dados
├── database/                # Scripts do banco de dados
│   └── schema.sql           # Schema completo do banco de dados
├── docs/                    # Documentação do projeto
│   ├── README.md            # Este arquivo
│   ├── ocs_rest_api.md      # Análise da API REST do OCS
│   └── ocs_xml_format.md    # Análise do formato XML do OCS
├── scripts/                 # Scripts de automação
│   └── setup-server.sh      # Script de instalação para Ubuntu 22.04
└── docker-compose.yml       # Orquestração dos serviços
```

## 4. Guia de Deployment (Servidor Ubuntu 22.04)

Este guia assume que você está em uma VM Ubuntu 22.04 limpa, como no VirtualBox ou VMware.

### Passo 1: Transferir o Projeto para a VM

Primeiro, copie toda a pasta `ocs-api-project` para a home directory do seu usuário na VM Ubuntu (ex: `/home/ubuntu/`). Você pode usar `scp`, `rsync` ou simplesmente clonar de um repositório Git.

### Passo 2: Executar o Script de Instalação

Conecte-se à sua VM via SSH e execute o seguinte comando:

```bash
# Navegue até a pasta do projeto
cd /home/ubuntu/ocs-api-project

# Dê permissão de execução ao script
chmod +x scripts/setup-server.sh

# Execute o script com privilégios de root
sudo ./scripts/setup-server.sh
```

O script irá automaticamente:
1. Atualizar o sistema.
2. Instalar Docker e Docker Compose.
3. Configurar o firewall (`ufw`) para permitir acesso às portas necessárias (SSH, API e Metabase).
4. Mover o projeto para `/opt/ocs-api`.
5. Iniciar todos os serviços via `docker-compose`.

Ao final, ele exibirá os endereços para acessar a API e o Metabase.

### Passo 3: Acessar os Serviços

Após a execução do script, os serviços estarão disponíveis nos seguintes endereços (substitua `[IP_DO_SERVIDOR]` pelo IP da sua VM):

- **API OCS (Docs)**: `http://[IP_DO_SERVIDOR]:8000/docs`
- **Metabase (BI)**: `http://[IP_DO_SERVIDOR]:3000`

Na primeira vez que acessar o Metabase, você precisará fazer uma configuração inicial. Quando ele pedir os dados do banco, use as informações do `docker-compose.yml`:
- **Tipo de Banco**: PostgreSQL
- **Host**: `db` (o nome do serviço no Docker Compose)
- **Porta**: `5432`
- **Nome do Banco**: `ocsinventory`
- **Usuário**: `ocsuser`
- **Senha**: `ocspassword`

## 5. Testando a Ingestão de Dados

Existem duas formas de testar a ingestão de dados: com o cliente de teste em Python ou com um agente OCS oficial.

### Opção A: Cliente de Teste Python (Recomendado para teste rápido)

O script `test_client.py` simula um agente enviando dados da máquina onde ele é executado.

1. **Instale a dependência**:
   ```bash
   pip install requests
   ```

2. **Execute o cliente** a partir de qualquer máquina que tenha acesso à rede da VM do servidor:
   ```bash
   # Navegue até a pasta do cliente
   cd ocs-api-project/client

   # Execute, passando a URL do servidor como argumento
   python3 test_client.py http://[IP_DO_SERVIDOR]:8000
   ```

O script irá testar a saúde da API, enviar um inventário em formato JSON e listar os dispositivos já cadastrados.

### Opção B: Agente OCS Inventory Oficial (Windows ou Linux)

Esta é a forma de usar a solução em um ambiente real.

1. **Baixe o Agente**: Faça o download do agente OCS para o seu sistema operacional no [site oficial do OCS Inventory](https://ocsinventory-ng.org/?page_id=1548&lang=en).

2. **Instale o Agente**:
   - **Windows**: Durante a instalação, no campo "Server URL", insira o endereço do seu endpoint:
     ```
     http://[IP_DO_SERVIDOR]:8000/ocsinventory
     ```
     Desmarque a opção "Validate SSL certificate".
   - **Linux**: Edite o arquivo de configuração `/etc/ocsinventory/ocsinventory-agent.cfg` e ajuste a linha:
     ```
     server=http://[IP_DO_SERVIDOR]:8000/ocsinventory
     ```

3. **Force um Inventário**:
   - **Windows (PowerShell como Admin)**:
     ```powershell
     cd "C:\Program Files\OCS Inventory Agent"
     .\OCSInventory.exe /force /server=http://[IP_DO_SERVIDOR]:8000/ocsinventory
     ```
   - **Linux**:
     ```bash
     sudo ocsinventory-agent --server http://[IP_DO_SERVIDOR]:8000/ocsinventory --debug
     ```

Após forçar o inventário, você pode verificar os logs da API no servidor para ver a requisição chegando e os dados sendo processados:

```bash
cd /opt/ocs-api
docker-compose logs -f api
```

E, claro, os novos dispositivos aparecerão no Metabase.

