from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, TokenResponse
from app.core.security import verify_password, create_access_token
from app.core.dependencies import get_current_user
from app.schemas.users import ChangePasswordRequest
from app.core.security import hash_password
from app.core.captcha import create_captcha, verify_captcha

from pathlib import Path
from uuid import uuid4


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


@router.post("/login", response_model=TokenResponse)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    verify_captcha(
        data.captcha_id,
        data.captcha_answer,
    )
    user = db.query(User).filter(
        (User.username == data.username)
        | (User.email == data.username)
    ).first()

    if not user or not verify_password(
        data.password,
        user.password_hash,
    ):
        raise HTTPException(
            status_code=401,
            detail="Username/email atau password salah",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="Akun tidak aktif",
        )

    token = create_access_token(
        user_id=user.id,
        role=user.role,
    )

    return {
    "access_token": token,
    "token_type": "bearer",
    "message": "Login berhasil",
    "user": {
        "id": user.id,
        "nama": user.nama,
        "username": user.username,
        "email": user.email,
        "role": user.role,
        "foto_profil": user.foto_profil,
    },
}
@router.get("/captcha")
def get_captcha():
    return create_captcha()

