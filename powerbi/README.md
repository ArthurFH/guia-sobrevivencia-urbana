# Power BI — Guia de Sobrevivência Urbana
## Documentação de Conexão ao Supabase

**Última revisão:** Abril 2026

---

## Visão Geral da Arquitetura

```
Site HTML (GitHub Pages)
       ↕ REST API
  Supabase (PostgreSQL)
       ↕ REST API (JSON)
  Power BI Desktop
       ↓
  Dashboards / Relatórios
```

O Power BI liga ao Supabase via **REST API com autenticação por Anon Key**.
Não é necessário driver ODBC nem conexão direta ao PostgreSQL.

---

## Tabelas e Views no Supabase

### `entries` — conteúdo publicado
| Coluna       | Tipo    | Descrição                                          |
|--------------|---------|----------------------------------------------------|
| id           | text PK | Slug único (ex: `alert-irs-phishing-abr26`)        |
| type         | text    | `alert` ou `changelog`                             |
| title        | text    | Título da entrada                                  |
| body         | text    | Corpo (1-2 frases)                                 |
| badge        | text    | `GOLPE`, `LEI`, `FERRAMENTA`, `ACTUALIZACAO`       |
| flags        | text    | `PT`, `BR`, ou `PT,BR`                             |
| published    | date    | Data de publicação                                 |
| active       | boolean | Se está visível no site                            |
| created_at   | tstz    | Timestamp de criação                               |

### `votes` — votos dos leitores
| Coluna       | Tipo    | Descrição                                          |
|--------------|---------|----------------------------------------------------|
| id           | uuid PK | Auto-gerado                                        |
| entry_id     | text    | FK → entries.id                                    |
| vote_type    | text    | `up` ou `down`                                     |
| fingerprint  | text    | Hash anónimo do dispositivo (16 hex chars)         |
| created_at   | tstz    | Timestamp do voto                                  |

### `vote_scores` — view agregada
| Coluna       | Tipo    | Descrição                                          |
|--------------|---------|----------------------------------------------------|
| entry_id     | text    | ID da entrada                                      |
| up_count     | bigint  | Total de votos positivos                           |
| down_count   | bigint  | Total de votos negativos                           |
| score        | bigint  | up_count - down_count                              |

---

## Endpoints REST para Power BI

Base URL: `https://bktsmktrvsjcarjxmpub.supabase.co/rest/v1/`

```
Headers obrigatórios:
  apikey:        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

| Query Power BI         | Endpoint                                      |
|------------------------|-----------------------------------------------|
| GSU_Entries            | /entries?select=*&order=published.desc        |
| GSU_Votes              | /votes?select=entry_id,vote_type,created_at   |
| GSU_VoteScores         | /vote_scores?select=*&order=score.desc        |
| GSU_EntriesWithScores  | JOIN calculado em M (ver .pq)                 |
| GSU_VotesByDay         | Agregação calculada em M (ver .pq)            |
| GSU_ContentByFlag      | Agregação calculada em M (ver .pq)            |

---

## Como Instalar no Power BI Desktop

### Passo 1 — Abrir o Editor de Consultas
1. Abre Power BI Desktop
2. Clica **Obter Dados → Consulta em Branco**
3. No editor: **Ver → Editor Avançado**

### Passo 2 — Criar a Query de Configuração
Cola o bloco `Config` do ficheiro `powerbi_gsu.pq`.
Nome da query: **Config**

### Passo 3 — Criar cada tabela
Repete o processo para cada query no ficheiro `.pq`:
- **GSU_Entries** — entradas publicadas
- **GSU_Votes** — votos individuais
- **GSU_VoteScores** — scores agregados
- **GSU_EntriesWithScores** — tabela principal para relatórios
- **GSU_VotesByDay** — tendência temporal
- **GSU_ContentByFlag** — distribuição por país/tipo

### Passo 4 — Configurar privacidade
Se o Power BI pedir nível de privacidade da fonte:
`Ficheiro → Opções → Privacidade → Ignorar níveis de privacidade`
(aceitável porque o Anon Key é público por design)

---

## Modelo de Dados (Relações)

```
GSU_Entries (id) ─────────── GSU_VoteScores (entry_id)
      │                                │
      └── GSU_Votes (entry_id) ────────┘
      │
      └── GSU_EntriesWithScores [tabela principal]
```

**Relação recomendada no Power BI:**
- `GSU_Entries[id]` → `GSU_Votes[entry_id]` (1:N)
- `GSU_Entries[id]` → `GSU_VoteScores[entry_id]` (1:1)

---

## Visuais Sugeridos para o Dashboard

### Página 1 — Visão Geral do Conteúdo
- **Cartão:** Total de entradas ativas
- **Cartão:** Total de votos registados
- **Gráfico de barras:** Entradas por badge (GOLPE, LEI, FERRAMENTA...)
- **Gráfico de rosca:** Distribuição PT vs BR vs PT,BR
- **Tabela:** Top 5 entradas por score (com título + score)

### Página 2 — Análise de Votos
- **Gráfico de linhas:** Votos por dia (up/down/score)
- **Matriz:** entry_id × mês × score
- **Dispersão:** up_count vs down_count (identificar outliers)
- **Segmentação:** filtro por tipo (alert/changelog)

### Página 3 — Priorização Editorial
- **Tabela condicional:** todas as entradas com coluna `editorial_status`
  - Verde: DESTACAR (score ≥ +5)
  - Amarelo: MANTER (-2 a +4)
  - Vermelho: REVER (score ≤ -3)
- **Gráfico de funil:** entradas por estado editorial

---

## Medidas DAX Sugeridas

```dax
-- Total votos
Total Votos = COUNTROWS(GSU_Votes)

-- Score médio por tipo
Score Médio Alertas =
    CALCULATE(
        AVERAGE(GSU_EntriesWithScores[vote_score]),
        GSU_EntriesWithScores[type] = "alert"
    )

-- Entradas sem votos após 7 dias
Sem Votos 7d =
    CALCULATE(
        COUNTROWS(GSU_EntriesWithScores),
        GSU_EntriesWithScores[vote_score] = 0,
        GSU_EntriesWithScores[published] <= TODAY() - 7
    )

-- Taxa de aprovação
Taxa Aprovação =
    DIVIDE(
        SUMX(GSU_Votes, IF([vote_type] = "up", 1, 0)),
        COUNTROWS(GSU_Votes),
        0
    )
```

---

## Atualização Automática

Para dados sempre atualizados sem publicar no Power BI Service:
- **Power BI Desktop:** clica **Actualizar Tudo** quando abrires o ficheiro
- **Power BI Service (Pro):** publica o relatório e configura agendamento de atualização
  - O endpoint REST não requer gateway (fonte na nuvem)
  - Frequência máxima no plano gratuito: 8x/dia

---

*Conexão via Supabase Anon Key — só leitura — sem exposição de dados sensíveis*
