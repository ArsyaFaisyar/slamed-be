
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.branch import Branch
from app.db.database import get_db
from app.models.user import User
from app.schemas.users import UserCreate, UserUpdate, UserResponse, UserPasswordReset
from app.core.security import hash_password
from app.core.dependencies import get_current_user, require_roles
from app.models.area import Area

router = APIRouter(prefix="/users", tags=["Users"])

def validate_branch(db: Session, branch_id: int | None):
    if branch_id is None:
        return
    branch = db.query(Branch).filter(Branch.id == branch_id).first()
    if not branch:
        raise HTTPException(
            status_code=400,
            detail="Branch tidak ditemukan",
        )
def validate_area(db: Session, area_id: int | None):
    if area_id is None:
        return

    area = db.query(Area).filter(Area.id == area_id).first()

    if not area:
        raise HTTPException(
            status_code=400,
            detail="Area tidak ditemukan",
        )

@router.get("/", response_model=list[UserResponse])
def get_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    query = db.query(User)
    if current_user.role == "SPV":
        query = query.filter(User.role == "SALES")

    return query.order_by(User.id.desc()).all()

@router.get("/by-area/{area_id}", response_model=list[UserResponse])
def get_sales_by_area(
    area_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    area = db.query(Area).filter(Area.id == area_id).first()
    if not area:
        raise HTTPException(
            status_code=404,
            detail="Area tidak ditemukan",
        )
    return db.query(User).filter(
        User.area_id == area_id,
        User.role == "SALES",
        User.is_active == 1,
    ).order_by(User.nama.asc()).all()

@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Pengguna tidak ditemukan",
        )

    if current_user.role == "SPV" and user.role != "SALES":
        raise HTTPException(
            status_code=403,
            detail="SPV hanya dapat melihat akun SALES",
        )

    return user


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_user(
    data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    if current_user.role == "SPV" and data.role != "SALES":
        raise HTTPException(
            status_code=403,
            detail="SPV hanya dapat membuat akun SALES",
        )

    existing_user = db.query(User).filter(
        (User.username == data.username)
        | (User.email == data.email)
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail="Username atau email sudah digunakan",
        )

    validate_branch(db, data.branch_id)
    validate_area(db, data.area_id)
    user = User(
        nama=data.nama,
        username=data.username,
        email=str(data.email),
        password_hash=hash_password(data.password),
        role=data.role,
        is_active=1,
        branch_id=data.branch_id,
        area_id=data.area_id
    )

    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal membuat akun",
        )

    return user


@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN", "SPV")
    ),
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Pengguna tidak ditemukan",
        )

    if current_user.role == "SPV":
        if user.role != "SALES":
            raise HTTPException(
                status_code=403,
                detail="SPV hanya dapat mengelola akun SALES",
            )

        if data.role is not None and data.role != "SALES":
            raise HTTPException(
                status_code=403,
                detail="SPV tidak dapat mengubah role SALES",
            )

    updates = data.model_dump(exclude_unset=True)
    if "branch_id" in updates:
        validate_branch(db, updates["branch_id"])

    if "area_id" in updates:
        validate_area(db, updates["area_id"])

    if "email" in updates and updates["email"] is not None:
        updates["email"] = str(updates["email"])

        duplicate_email = db.query(User).filter(
            User.email == updates["email"],
            User.id != user_id,
        ).first()

        if duplicate_email:
            raise HTTPException(
                status_code=409,
                detail="Email sudah digunakan",
            )

    for field, value in updates.items():
        if field in {"branch_id", "area_id"} or value is not None:
            setattr(user, field, value)

    try:
        db.commit()
        db.refresh(user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal memperbarui akun",
        )

    return user

@router.patch("/{user_id}/password")
def reset_user_password(
    user_id: int,
    data: UserPasswordReset,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles("SUPERADMIN")
    ),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="Pengguna tidak ditemukan",
        )
    user.password_hash = hash_password(data.password)
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Gagal mengubah password",
        )
    return {"message": "Password berhasil diubah"}
