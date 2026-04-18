# Guia de Sobrevivência Urbana

[![Site ao vivo](https://img.shields.io/badge/Site-ao_vivo-e8c547?style=flat-square&logo=github)](https://arthurfh.github.io/guia-sobrevivencia-urbana/)
[![Licença CC BY-SA 4.0](https://img.shields.io/badge/Licença-CC_BY--SA_4.0-lightgrey?style=flat-square)](LICENSE)
[![Última revisão](https://img.shields.io/badge/Revisão-Abr_2026-informational?style=flat-square)](#)

**Site público e gratuito para Portugal 🇵🇹 e Brasil 🇧🇷.** Informação prática e densa sobre dinheiro, carreira, segurança digital, saúde e lei — para quem enfrenta crises reais. Sem publicidade. Sem afiliados. Sem agenda.

---

## Missão

O Guia de Sobrevivência Urbana existe para dar a qualquer pessoa as ferramentas de informação que normalmente só chegam a quem tem acesso a advogados, contabilistas ou consultores. O conteúdo é verificável, bilíngue (PT-PT e PT-BR), e actualizado regularmente com alertas de golpes e mudanças legais relevantes.

---

## Capítulos

| # | Título | Estado |
|---|--------|--------|
| 01 | Dinheiro sob Pressão | ✅ Publicado |
| 02 | Segurança Digital e Golpes | ✅ Publicado |
| 03 | Planejamento Financeiro em Contexto Difícil | 🔒 Em construção |
| 04 | Carreira em Mercado Difícil | 🔒 Em construção |
| 05 | Conhecimento que Não se Perde | 🔒 Em construção |
| 06 | Noções Jurídicas Básicas de Sobrevivência | 🔒 Em construção |
| 07 | Casa e Vida Doméstica em Crise | 🔒 Em construção |
| 08 | Saúde quando o Sistema Aperta | 🔒 Em construção |
| 09 | Empreender Pequeno, com Pouco Risco | 🔒 Em construção |
| 10 | Protocolos de Emergência (Checklists) | 🔒 Em construção |

---

## Stack Técnica

- **Frontend:** HTML/CSS/JS estático — zero dependências de build
- **Hosting:** GitHub Pages (branch `main`)
- **Base de dados:** Supabase (PostgreSQL) — votos anónimos por entrada + registo de conteúdo
- **Atualização:** Ciclo manual a cada 2–4 semanas via automação

### Estrutura de ficheiros

```
/
├── index.html       # Página inicial com alertas, changelog e navegação
├── cap1.html        # Capítulo 1 — Dinheiro sob Pressão
├── cap2.html        # Capítulo 2 — Segurança Digital e Golpes
├── cap3..10.html    # Em construção
├── README.md
└── LICENSE
```

---

## Sistema de Votos

Cada alerta e entrada do changelog tem botões de voto (👍 / 👎) anónimos, sem login e sem cookies. Os votos são armazenados no Supabase com um fingerprint não reversível. Os resultados são usados para priorizar conteúdo nas actualizações seguintes.

---

## Como Contribuir

Não são aceites pull requests de conteúdo por enquanto — o editorial é mantido manualmente para garantir rigor factual. Podes ajudar abrindo uma **Issue**:

- **Erro factual:** título "Correcção: [tema]" + fonte oficial
- **Golpe novo:** título "Alerta: [descrição]" + fonte (CNCS, BPortugal, BACEN, Procon...)

---

## Aviso Legal

Conteúdo **educacional e informativo**. Não constitui aconselhamento financeiro, jurídico, fiscal ou médico. Verifica nas fontes oficiais indicadas em cada capítulo.

---

## Licença

[Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](LICENSE)

Podes partilhar e adaptar, incluindo comercialmente, desde que atribuas a autoria e uses a mesma licença.

---

*Sem publicidade · Sem afiliados · Sem agenda · Conteúdo verificável*
