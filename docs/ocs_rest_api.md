# API REST do OCS Inventory - Formato JSON

Fonte: https://wiki.ocsinventory-ng.org/11.Rest-API/GET-Routes/

## Descoberta Importante

O OCS Inventory **JÁ POSSUI** uma API REST que retorna dados em formato **JSON**!

A API REST do OCS é usada para **consultar** dados de inventário já armazenados no servidor OCS, não para ingestão de novos dados dos agentes.

## URL Base

```
http://myocsserver/ocsapi/v1/
```

## Principais Endpoints (GET)

### 1. Listar IDs de Computadores
```
GET /ocsapi/v1/computers/listID
```
Retorna:
```json
[
  {"ID": 1942},
  {"ID": 1974}
]
```

### 2. Listar Detalhes de Computadores
```
GET /ocsapi/v1/computers?start=0&limit=10
```
Retorna:
```json
{
  "16": {
    "accountinfo": [{"HARDWARE_ID": 16, "TAG": "DEV-MACHINE"}],
    "bios": [{
      "BDATE": "04/16/2021",
      "BMANUFACTURER": "Dell Inc.",
      "BVERSION": "2.5.1",
      "SMODEL": "PowerEdge R340"
    }],
    "software": [...],
    "storage": [...]
  }
}
```

### 3. Detalhes de um Computador Específico
```
GET /ocsapi/v1/computer/:id
GET /ocsapi/v1/computer/:id/:section
```

Exemplo com seção específica:
```
GET /ocsapi/v1/computer/16/bios
GET /ocsapi/v1/computer/16/software
GET /ocsapi/v1/computer/16/storage
```

### 4. Buscar com Filtros
```
GET /ocsapi/v1/computer/16/software?where=NAME&operator=like&value=bash
```

### 5. Busca Geral
```
GET /ocsapi/v1/computers/search?start=0&limit=10&userid=root&orderby=lastdate;desc
```

## Estrutura de Dados JSON

### Exemplo de Computador Completo
```json
{
  "16": {
    "bios": [{
      "ASSETTAG": "",
      "BDATE": "04/16/2021",
      "BMANUFACTURER": "Dell Inc.",
      "BVERSION": "2.5.1",
      "MMANUFACTURER": "Dell Inc.",
      "MMODEL": "045M96",
      "SMODEL": "PowerEdge R340",
      "TYPE": "Rack Mount Chassis"
    }],
    "software": [{
      "NAME": "bash",
      "VERSION": "5.0-6ubuntu1.2",
      "PUBLISHER": "http://tiswww.case.edu/php/chet/bash/bashtop.html",
      "INSTALLDATE": "2022-04-03 12:59:54",
      "FILESIZE": 1699840
    }],
    "storage": [...],
    "networks": [...]
  }
}
```

## Implicação para Nossa API

**Decisão de Arquitetura:**

1. **Ingestão de Dados**: Manter endpoint `/ocsinventory` compatível com XML do agente OCS oficial
2. **Consulta de Dados**: Criar endpoints REST JSON similares à API do OCS para compatibilidade
3. **Vantagem**: Nossa API pode ser um **drop-in replacement** do servidor OCS tradicional

Isso significa que:
- Agentes OCS enviam dados via XML (POST)
- Aplicações de terceiros consultam via REST/JSON (GET)
- Mantemos compatibilidade total com ecossistema OCS existente

