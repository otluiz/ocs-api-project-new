# 📜 Changelog

## [1.1.3] - 2025-11-12
### Adicionado
- Bloco unificado de detecção e instalação automática do Docker Compose (v1 e v2)
- Variável `$DOCKER_COMPOSE` padronizada em todos os scripts (`setup-server.sh`, `setup-database.sh`, `setup-metabase.sh`)
- Compatibilidade total com Ubuntu 22.04+ e Docker Compose Plugin moderno

### Corrigido
- Fluxo de instalação não encerra mais quando Docker Compose não está instalado
- Scripts agora funcionam em ambientes sem Compose pré-instalado

### Melhorias
- Logs e mensagens padronizados em todos os scripts
- Atualização incremental da infraestrutura de setup (pré-instalação automatizada)


## [1.1.2] - 2025-11-11
### Adicionado
- Suporte completo a PostgreSQL (schema.sql)
- Nova imagem `api/Dockerfile` com `main:app`
- Arquivo `inventario_teste.xml` para validação local
- Arquitetura atualizada (`ocs-arquitetura.png`)

### Corrigido
- Erro de `ModuleNotFoundError: No module named 'api'`
- Conflito de container `db` removido (renomeado para `ocs-postgres`)
- Docker Compose ajustado com rede `ocs-api-project_ocs-network`

### Melhorias
- Healthcheck no Postgres
- Compatibilidade com Metabase
- Simplificação da configuração (`DATABASE_URL`)


## [1.1.1] - 2025-10-27
### Adicionado
- Inclusão de autoria (Othon Teixeira) em todos os arquivos de documentação
- Adicionado arquivo `LICENSE` (GPL v3.0)
- Atualizado `REQUISITOS.md` para “Ubuntu 22.04 Server ou superior”
- Revisão e padronização das datas de versão 1.1.1


## [1.1.0] - 2025-10-26
### Alterações principais
- Correção de erros na inicialização dos containers (`setup-server.sh`, `setup-api.sh`, `setup-metabase.sh`)
- Ajuste no `docker-compose.yml` para compatibilidade com PostgreSQL 16
- Melhoria de logs e validação no script `check-requirements.sh`
- Refatoração das variáveis de ambiente e suporte à instalação automatizada
- Documentação revisada: `INSTALACAO.md`, `QUICKSTART.md` e `REQUISITOS.md`

### Ambiente validado
- Host: `quantumSystem`
- Local de instalação: `/home/otluiz/ocs-api`
- Status: ✅ Testado e rodando sem erros
