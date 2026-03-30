# WizCo — Case Técnico Salesforce

Sistema de gestão de **Pedidos de Suporte** desenvolvido como case técnico para a vaga de Desenvolvedor Salesforce na Wiz Co. O projeto cobre automações, regras de negócio, processamento assíncrono, API REST e portal de autoatendimento no Experience Cloud.

---

## Portal de Suporte

Acesse o portal de autoatendimento do cliente:

**[https://playful-badger-kriaji-dev-ed.trailblaze.my.site.com/Suporte/](https://playful-badger-kriaji-dev-ed.trailblaze.my.site.com/Suporte/)**

---

## Demonstração em Vídeo

> Apresentação completa da solução (máx. 15 minutos)

**[Assistir no YouTube](https://youtu.be/tH6NfaE8CC0)**

---

## Tech Stack

| Camada | Tecnologia |
|---|---|
| Plataforma | Salesforce (org Trailhead) |
| Backend | Apex — Triggers, Batch, Queueable, REST API |
| Automação | Flow Builder (Record-Triggered Flow, Screen Flow) |
| Portal | Experience Cloud |
| Autenticação | OAuth 2.0 JWT Bearer Flow |
| Metadados | Objetos customizados, campos, picklists, Custom Metadata |

---

## Arquitetura

### Objetos Customizados

**`PedidoSuporte__c`**

| Campo | Tipo | Detalhes |
|---|---|---|
| `Cliente__c` | Lookup | Account |
| `Descricao__c` | Long Text Area | — |
| `Status__c` | Picklist | Novo · Aguardando Cliente · Em Atendimento · Resolvido · Cancelado |
| `Prioridade__c` | Picklist | Baixa · Média · Alta |
| `UltimaInteracao__c` | DateTime | — |

**`Interacao__c`**

| Campo | Tipo | Detalhes |
|---|---|---|
| `PedidoSuporte__c` | Master-Detail | PedidoSuporte__c |
| `Mensagem__c` | Long Text Area | — |
| `Data__c` | DateTime | — |
| `Tipo__c` | Picklist | Cliente · Agente |

---

### Automações

#### 1 — Record-Triggered Flow (`Interacao__c`)
Disparado na criação de uma `Interacao__c`:
- Atualiza `PedidoSuporte__c.UltimaInteracao__c` com `Data__c` da interação
- `Tipo__c = Cliente` → `Status__c = Em Atendimento`
- `Tipo__c = Agente` → `Status__c = Aguardando Cliente`

#### 2 — Apex Trigger (`PedidoSuporte__c`)
Contexto `before insert / before update`:
- Se `Prioridade__c = Alta` e `Status__c` sendo alterado para `Resolvido`, exige ao menos uma `Interacao__c` do `Tipo__c = Agente`
- Estrutura: **Handler + Service** (`TriggerHandlerPedidoSuporte` → `PedidoSuporteService`)

#### 3 — Batch + Schedule
- `BatchPedidoSuporte` — processa pedidos com `UltimaInteracao__c < NOW() - 3 dias`
  - Atualiza `Status__c = Aguardando Cliente`
  - Envia e-mail ao cliente via `EnviarEmailService` (consome Email Template)
- `PedidoSuporteBatchSchedule` — agenda a execução do batch

---

#### Criar Pedido de Suporte

```
POST /services/apexrest/pedidos-suporte
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "clienteId": "001XXXXXXXXXXXX",
  "descricao": "Problema no sistema",
  "prioridade": "Alta"
}
```

Resposta `201`:
```json
{
  "pedidoId": "a01XXXXXXXXXXXX",
  "mensagem": "Pedido de suporte criado com sucesso."
}
```

Cria `PedidoSuporte__c` (`Status = Novo`, `UltimaInteracao = NOW()`) e `Interacao__c` (`Tipo = Cliente`) em uma única transação.

Estrutura: **Controller / Service / DTO**

| Código | Situação |
|---|---|
| `201` | Pedido criado com sucesso |
| `400` | Payload inválido ou cliente não encontrado |
| `401` | Token inválido ou usuário sem perfil de integração |
| `500` | Erro interno |

---

### Experience Cloud

- Portal acessível em [/Suporte/](https://playful-badger-kriaji-dev-ed.trailblaze.my.site.com/Suporte/)
- **Screen Flow** para criar `PedidoSuporte__c` e adicionar `Interacao__c`
- Acionado por botão na página de detalhe da **Account**, recebendo o `Id` da conta como parâmetro de entrada

---

## Setup

### Pré-requisitos
- Org Trailhead ativa
- [Salesforce CLI (sf)](https://developer.salesforce.com/tools/salesforcecli) instalado
- VS Code com [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)

### 1. Clonar e autenticar

```bash
git clone <url-do-repositorio>
cd WizCo

sf org login web --alias wizco-org
```

### 2. Deploy

```bash
sf project deploy start --source-dir force-app
```

### 3. Executar testes

```bash
sf apex run test --test-level RunLocalTests --result-format human
```

---

## Convenções de Código

- Triggers sem lógica direta — delegar para **Handler + Service**
- Sem SOQL dentro de loops — sempre bulkify
- Cobertura mínima de testes: **95%**
- DTOs separados por domínio (request / response / erro)
- E-mail centralizado exclusivamente em `EnviarEmailService`
