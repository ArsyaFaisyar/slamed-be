
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.routers.customers import router as customers_router
from app.routers.projects import router as projects_router
from app.routers.rkh import router as rkh_router
from app.routers.lkh import router as lkh_router
from app.routers.lkh_attachment import (
    router as lkh_attachments_router,
)
from app.routers.auth import router as auth_router
from app.routers.profile import router as profile_router
from app.routers.users import router as user

app = FastAPI(title="Sales Management System API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(user)
app.include_router(customers_router)
app.include_router(projects_router)
app.include_router(rkh_router)
app.include_router(lkh_router)
app.include_router(lkh_attachments_router)


@app.get("/")
def root():
    return {"message": "Sales Management System API is running"}


@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {"status": "ok", "database": "connected"}
