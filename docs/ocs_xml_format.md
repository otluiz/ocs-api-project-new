# Formato XML do OCS Inventory

Fonte: https://wiki.ocsinventory-ng.org/12.Developers/XML-Format/

## Estrutura

O OCS Inventory usa XML para quase todas as transações. Existem 7 DTDs diferentes:

- `inventory_request.dtd` - Requisição de inventário do agente
- `inventory_reply.dtd` - Resposta do servidor
- `update_request.dtd` - Requisição de atualização
- `update_reply.dtd` - Resposta de atualização
- `prolog_request.dtd` - Prólogo (handshake inicial)
- `prolog_reply.dtd` - Resposta do prólogo
- `file_request.dtd` - Requisição de arquivo

## Exemplo: STORAGES (Armazenamento)

```xml
<STORAGES>
  <DESCRIPTION>SATA</DESCRIPTION>
  <DISKSIZE>117220</DISKSIZE>
  <FIRMWARE>3.AD</FIRMWARE>
  <MANUFACTURER>Seagate</MANUFACTURER>
  <MODEL>ST9120823AS</MODEL>
  <NAME>sda</NAME>
  <SERIALNUMBER>5NJ0NJ09</SERIALNUMBER>
  <TYPE>disk</TYPE>
</STORAGES>
```

## Endpoint do Servidor OCS Original

O agente OCS envia dados para: `http://servidor/ocsinventory`

## Adaptação para Nossa API

Nossa API FastAPI precisará:
1. Aceitar XML no formato OCS (endpoint `/ocsinventory`)
2. Parsear o XML e extrair os dados
3. Armazenar no PostgreSQL
4. Retornar resposta XML compatível com o agente

Isso permitirá usar o agente OCS oficial sem modificações.

