"""FastAPI app layer entry — Class A/B/C tool HTTP surface (Fase 2+)."""
from fastapi import FastAPI

app = FastAPI(title="Goodang App Layer", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
