# WizCo — Case Técnico Salesforce

Sistema de gestão de **Pedidos de Suporte** desenvolvido como case técnico para a vaga de Desenvolvedor Salesforce na Wiz Co. O projeto cobre automações, regras de negócio, processamento assíncrono, API REST autenticada via JWT e portal de autoatendimento no Experience Cloud.

---

## Portal de Suporte

Acesse o portal de autoatendimento do cliente:

**[https://playful-badger-kriaji-dev-ed.trailblaze.my.site.com/Suporte/](https://playful-badger-kriaji-dev-ed.trailblaze.my.site.com/Suporte/)**

---

## Demonstração em Vídeo

> Apresentação completa da solução (máx. 15 minutos)

**[Assistir no YouTube](https://www.youtube.com/watch?v=SEU_VIDEO_ID_AQUI)**

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

### API REST

#### Autenticação — JWT Bearer Flow

```
POST /services/apexrest/auth
Content-Type: application/json

{ "username": "integracao@wizco.com" }
```

Resposta `200`:
```json
{ "token": "00Dxxx....<access_token>" }
```

**Fluxo interno:**
1. Valida que o `username` é o usuário de integração configurado (`ConfiguracaoAuth__mdt`)
2. Gera um JWT assinado com o certificado da org (`Crypto.signWithCertificate`)
3. Troca o JWT pelo `access_token` no endpoint `POST /services/oauth2/token` com `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer`

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

### 3. Configurar o JWT Bearer

1. **Setup > Certificate and Key Management** → criar ou importar certificado (ex: `WizCoJWT`)
2. **Setup > App Manager > New Connected App** → habilitar OAuth, marcar *Enable JWT-based Flow*, anexar o certificado
3. **Setup > Custom Metadata Types > ConfiguracaoAuth > Manage Records > Default** → preencher:

| Campo | Valor |
|---|---|
| `ClientId__c` | Consumer Key do Connected App |
| `CertificateName__c` | Nome do certificado (ex: `WizCoJWT`) |
| `OrgUrl__c` | `https://login.salesforce.com` |
| `PerfilIntegracao__c` | Nome do perfil do usuário de integração |
| `UsuarioIntegracao__c` | Username do usuário de integração |

4. **Setup > Remote Site Settings** → adicionar `https://login.salesforce.com`

### 4. Executar testes

```bash
sf apex run test --test-level RunLocalTests --result-format human
```

---

## Testando com Postman

### Importar a collection

1. Abra o Postman
2. Clique em **Import**
3. Selecione o arquivo `postman/WizCo_API.postman_collection.json`
4. A collection **WizCo — Pedidos de Suporte API** aparecerá na barra lateral

### Configurar as variáveis

Na collection, clique em **Variables** e preencha:

| Variável | Valor |
|---|---|
| `base_url` | `https://playful-badger-kriaji-dev-ed.trailblaze.my.salesforce.com` |
| `integration_user` | Username do usuário de integração (ex: `integracao@wizco.com`) |
| `account_id` | Id de uma Account da org (ex: `001Xx000000XXXXX`) |

> `access_token` é preenchido automaticamente após a autenticação.

### Passo 1 — Autenticar via JWT

Selecione **[Auth] Obter Token JWT** e clique em **Send**.

```
POST {{base_url}}/services/apexrest/auth
Content-Type: application/json

{
  "username": "integracao@wizco.com"
}
```

Resposta esperada (`200`):
```json
{
  "token": "00Dg8000002cKUP!...",
  "mensagem": "Autenticado com sucesso.",
  "expiresIn": 3600
}
```

O script de teste da request salva o `token` automaticamente em `{{access_token}}`.

### Passo 2 — Criar Pedido de Suporte

Selecione **[Pedidos] Criar Pedido de Suporte** e clique em **Send**.

```
POST {{base_url}}/services/apexrest/pedidos-suporte
Authorization: Bearer {{access_token}}
Content-Type: application/json

{
  "clienteId": "{{account_id}}",
  "descricao": "Problema de acesso ao sistema após atualização.",
  "prioridade": "Alta"
}
```

Resposta esperada (`201`):
```json
{
  "pedidoId": "a01Xx000000XXXXX",
  "mensagem": "Pedido de suporte criado com sucesso."
}
```

### Respostas de erro

| Código | Causa | Como resolver |
|---|---|---|
| `400` | `clienteId` ausente ou Account não encontrada | Verifique o Id da Account na org |
| `401` | Token expirado ou usuário sem perfil de integração | Execute novamente o endpoint de auth |
| `500` | Erro interno no servidor | Verifique os logs em Setup > Apex Jobs |

---

## Comandos Úteis

```bash
# Deploy completo
sf project deploy start --source-dir force-app

# Acompanhar resultado do último deploy
sf project deploy report

# Rodar testes com cobertura
sf apex run test --test-level RunLocalTests --code-coverage

# Abrir org no browser
sf org open

# Agendar o batch de inatividade (via Developer Console / Anonymous Apex)
# System.schedule('Batch Pedido Suporte', '0 0 8 * * ?', new PedidoSuporteBatchSchedule());
```

---

## Convenções de Código

- Triggers sem lógica direta — delegar para **Handler + Service**
- Sem SOQL dentro de loops — sempre bulkify
- Cobertura mínima de testes: **95%**
- DTOs separados por domínio (request / response / erro)
- E-mail centralizado exclusivamente em `EnviarEmailService`
