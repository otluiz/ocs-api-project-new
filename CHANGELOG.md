# 📜 Changelog

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
- Local de instalação: `/opt/ocs-api`
- Status: ✅ Testado e rodando sem erros
