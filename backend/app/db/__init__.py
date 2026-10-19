from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.db.database import get_db

app = FastAPI(
    title="Sales Management System API",
    version="1.0.0",
)
@app.get("/")
def root():
    return {"message": "Sales Management System API is running"}
@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {
        "status": "ok",
        "database": "connected",
    }