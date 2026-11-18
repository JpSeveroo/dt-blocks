# DT-Blocks 2.0

Ferramenta web colaborativa em tempo real para modelagem e análise de **Diagramas de Blocos de Confiabilidade (RBD)**.

## Documentação e Arquitetura

- [Documento de Requisitos (RBD)](./docs/Documento%20de%20requisitos%20-%20RBD.pdf)
- [Desenho de Arquitetura — DT-Blocks 2.0](./docs/arquitetura/Arquitetura-DT-Blocks-2.0.md)
- [Modelo C4 em Structurizr DSL](./docs/arquitetura/workspace.dsl)

## Estrutura do Projeto

O repositório segue uma organização modular alinhada diretamente aos diagramas C4 da arquitetura:

```text
dt-blocks/
├── docs/                   # Requisitos e diagramas de arquitetura (C4, Mermaid, PlantUML)
├── backend/                # Processo FastAPI (1 worker, sessões em memória) + SQLite (WAL)
│   ├── app/
│   │   ├── api/            # Endpoints HTTP e WebSocket
│   │   ├── modules/        # Componentes do Nível 2A:
│   │   │   ├── rate_limit/         # Limites de uso
│   │   │   ├── memory_sessions/    # Sessões em memória (Decisão Central ★)
│   │   │   ├── field_locks/        # Travas de campo (heartbeat e lease de até 30s)
│   │   │   ├── reliability/        # Cálculo de confiabilidade (R(t), MTTF, MTBF, LaTeX)
│   │   │   ├── repository/         # Repositório de sessões (escrita em lote 1–2s)
│   │   │   └── metrics/            # Métricas por hora (anônimas / LGPD)
│   │   ├── schemas/        # Contratos Pydantic
│   │   └── db/             # Configuração SQLAlchemy / SQLite (modo WAL)
│   └── tests/              # Testes unitários e de integração
├── frontend/               # Aplicação Web (React + TypeScript + Vite)
│   ├── src/
│   │   ├── modules/        # Componentes do Nível 2B:
│   │   │   ├── model-layout/       # Modelo e layout recursivo (série, paralelo, k-de-n)
│   │   │   ├── svg-canvas/         # Desenho vetorial em SVG
│   │   │   ├── interaction/        # Edição, travas, undo (até 100 ações) e WebSocket
│   │   │   └── export/             # Exportação client-side (SVG, PNG, JSON, função estrutural)
│   │   ├── pages/          # Páginas da aplicação
│   │   └── shared/         # Componentes de UI e tipos compartilhados
│   └── tests/              # Testes do frontend
├── infra/                  # Configuração do Nginx e scripts operacionais (backup e métricas)
├── data/                   # Diretório de volume local para o banco SQLite (modo WAL)
└── docker-compose.yml      # Orquestração dos contêineres (Nginx + FastAPI + volume SQLite)
```
