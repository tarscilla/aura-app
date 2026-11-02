
from fastapi import FastAPI

app = FastAPI(
    title="AURA API",
    description="API do sistema AURA",
    version="1.0.0"
)

@app.get("/")
def inicio():
    return {"mensagem": "API do AURA funcionando!"}
