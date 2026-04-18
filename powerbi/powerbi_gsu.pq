// ============================================================
// GUIA DE SOBREVIVÊNCIA URBANA — Power BI M Queries
// Conexão direta ao Supabase via REST API (sem SDK)
// Autor: ArthurFH | Última revisão: Abril 2026
// ============================================================
//
// INSTRUÇÕES DE USO:
//   1. No Power BI Desktop → Obter Dados → Consulta em Branco
//   2. Abre o Editor Avançado (View → Advanced Editor)
//   3. Cola cada secção abaixo como uma Query separada
//   4. Na Query "Config", actualiza SUPABASE_URL e ANON_KEY se mudarem
//   5. Actualiza tudo (Refresh All) para carregar os dados
//
// NOTA: O Anon Key é público por design — só tem permissão de leitura.
// ============================================================


// ── QUERY: Config ──────────────────────────────────────────
// Parâmetros globais reutilizados em todas as queries
let
    Config = [
        SUPABASE_URL = "https://bktsmktrvsjcarjxmpub.supabase.co",
        ANON_KEY     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrdHNta3RydnNqY2FyanhtcHViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0NTI5MjgsImV4cCI6MjA5MjAyODkyOH0.WRxyX0hOs-gSEEvV5u76ZqvSWMorH5mH1bpQAha2nTY"
    ]
in
    Config


// ── QUERY: GSU_Entries ─────────────────────────────────────
// Todas as entradas publicadas (alertas + changelog)
let
    cfg    = Config,
    url    = cfg[SUPABASE_URL] & "/rest/v1/entries?select=*&order=published.desc",
    raw    = Web.Contents(url, [
                 Headers = [
                     #"apikey"        = cfg[ANON_KEY],
                     #"Authorization" = "Bearer " & cfg[ANON_KEY],
                     #"Content-Type"  = "application/json"
                 ]
             ]),
    parsed = Json.Document(raw),
    table  = Table.FromList(parsed, Splitter.SplitByNothing()),
    expand = Table.ExpandRecordColumn(
                 table, "Column1",
                 {"id","type","title","body","badge","flags","published","active","created_at"}
             ),
    // Tipagem
    typed  = Table.TransformColumnTypes(expand, {
                 {"published",   type date},
                 {"active",      type logical},
                 {"created_at",  type datetimezone}
             })
in
    typed


// ── QUERY: GSU_Votes ───────────────────────────────────────
// Todos os votos individuais (granular)
let
    cfg    = Config,
    url    = cfg[SUPABASE_URL] & "/rest/v1/votes?select=entry_id,vote_type,created_at&order=created_at.desc",
    raw    = Web.Contents(url, [
                 Headers = [
                     #"apikey"        = cfg[ANON_KEY],
                     #"Authorization" = "Bearer " & cfg[ANON_KEY],
                     #"Content-Type"  = "application/json"
                 ]
             ]),
    parsed = Json.Document(raw),
    table  = Table.FromList(parsed, Splitter.SplitByNothing()),
    expand = Table.ExpandRecordColumn(
                 table, "Column1",
                 {"entry_id","vote_type","created_at"}
             ),
    typed  = Table.TransformColumnTypes(expand, {
                 {"created_at", type datetimezone}
             }),
    // Coluna auxiliar: data do voto (sem hora)
    addDate = Table.AddColumn(typed, "vote_date", each Date.From([created_at]), type date)
in
    addDate


// ── QUERY: GSU_VoteScores ──────────────────────────────────
// View agregada (up/down/score por entry_id)
let
    cfg    = Config,
    url    = cfg[SUPABASE_URL] & "/rest/v1/vote_scores?select=*&order=score.desc",
    raw    = Web.Contents(url, [
                 Headers = [
                     #"apikey"        = cfg[ANON_KEY],
                     #"Authorization" = "Bearer " & cfg[ANON_KEY],
                     #"Content-Type"  = "application/json"
                 ]
             ]),
    parsed = Json.Document(raw),
    table  = Table.FromList(parsed, Splitter.SplitByNothing()),
    expand = Table.ExpandRecordColumn(
                 table, "Column1",
                 {"entry_id","up_count","down_count","score"}
             ),
    typed  = Table.TransformColumnTypes(expand, {
                 {"up_count",   Int64.Type},
                 {"down_count", Int64.Type},
                 {"score",      Int64.Type}
             })
in
    typed


// ── QUERY: GSU_EntriesWithScores ───────────────────────────
// JOIN: entradas + scores — tabela principal para dashboards
let
    entries = GSU_Entries,
    scores  = GSU_VoteScores,
    joined  = Table.NestedJoin(
                  entries, "id",
                  scores,  "entry_id",
                  "VoteData", JoinKind.LeftOuter
              ),
    expand  = Table.ExpandTableColumn(
                  joined, "VoteData",
                  {"up_count","down_count","score"},
                  {"up_count","down_count","vote_score"}
              ),
    // Score nulo → 0 para entradas sem votos
    fillNull = Table.ReplaceValue(expand, null, 0, Replacer.ReplaceValue,
                   {"up_count","down_count","vote_score"}),
    // Coluna de classificação editorial
    addClass = Table.AddColumn(fillNull, "editorial_status", each
                   if [vote_score] >= 5  then "DESTACAR"
                   else if [vote_score] <= -3 then "REVER"
                   else "MANTER"
               , type text),
    // Coluna mês/ano para agrupamento temporal
    addMonth = Table.AddColumn(addClass, "published_month",
                   each Date.ToText([published], "yyyy-MM"), type text)
in
    addMonth


// ── QUERY: GSU_VotesByDay ──────────────────────────────────
// Votos agregados por dia — para gráfico de tendência
let
    votes   = GSU_Votes,
    grouped = Table.Group(votes, {"vote_date","vote_type"}, {
                  {"count", each Table.RowCount(_), Int64.Type}
              }),
    pivot   = Table.Pivot(grouped, {"up","down"}, "vote_type", "count",
                  List.Sum),
    fillNull = Table.ReplaceValue(pivot, null, 0, Replacer.ReplaceValue,
                   {"up","down"}),
    addScore = Table.AddColumn(fillNull, "daily_score",
                   each [up] - [down], Int64.Type),
    sorted  = Table.Sort(addScore, {{"vote_date", Order.Ascending}})
in
    sorted


// ── QUERY: GSU_ContentByFlag ───────────────────────────────
// Contagem de entradas por país (PT / BR / PT,BR) e tipo
let
    entries  = GSU_Entries,
    filtered = Table.SelectRows(entries, each [active] = true),
    grouped  = Table.Group(filtered, {"flags","type","badge"}, {
                   {"total", each Table.RowCount(_), Int64.Type}
               }),
    sorted   = Table.Sort(grouped, {{"total", Order.Descending}})
in
    sorted
