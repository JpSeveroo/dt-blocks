"""Ponto de entrada do Processo FastAPI (1 worker · Sessões em memória)."""

from fastapi import FastAPI

app = FastAPI(
    title="DT-Blocks 2.0 API",
    description="Ferramenta web colaborativa em tempo real para Diagramas de Blocos de Confiabilidade (RBD)",
    version="2.0.0",
)


@app.get("/api/health", tags=["health"])
async def health_check() -> dict[str, str]:
    """Endpoint de verificação de disponibilidade (Monitor externo / Nginx)."""
    return {"status": "ok", "service": "dt-blocks-fastapi"}
