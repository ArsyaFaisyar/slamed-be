from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.customer_category import CustomerCategory
from app.models.user import User
from app.schemas.customer_category import (
    CustomerCategoryCreate,
    CustomerCategoryUpdate,
    CustomerCategoryResponse,
)
from app.core.dependencies import get_current_user, require_roles

router = APIRouter(
    prefix="/customer-categories",
    tags=["Customer Categories"],
)


@router.get("/", response_model=list[CustomerCategoryResponse])
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(CustomerCategory).order_by(
        CustomerCategory.nama.asc()
    ).all()

@router.get("/{category_id}", response_model=CustomerCategoryResponse)
def get_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    category = db.query(CustomerCategory).filter(
        CustomerCategory.id == category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")

    return category

@router.post(
    "/",
    response_model=CustomerCategoryResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_category(
    data: CustomerCategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("SUPERADMIN")),
):
    nama = data.nama.strip()
    if not nama:
        raise HTTPException(status_code=400, detail="Nama kategori wajib diisi")
    existing = db.query(CustomerCategory).filter(
        CustomerCategory.nama.ilike(nama)
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="Kategori sudah tersedia")
    category = CustomerCategory(nama=nama)
    db.add(category)

    try:
        db.commit()
        db.refresh(category)
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Gagal membuat kategori")

    return category


@router.patch("/{category_id}", response_model=CustomerCategoryResponse)
def update_category(
    category_id: int,
    data: CustomerCategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("SUPERADMIN")),
):
    category = db.query(CustomerCategory).filter(
        CustomerCategory.id == category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")

    updates = data.model_dump(exclude_unset=True)

    if "nama" in updates:
        nama = updates["nama"].strip() if updates["nama"] else ""

        if not nama:
            raise HTTPException(status_code=400, detail="Nama kategori wajib diisi")

        duplicate = db.query(CustomerCategory).filter(
            CustomerCategory.nama.ilike(nama),
            CustomerCategory.id != category_id,
        ).first()

        if duplicate:
            raise HTTPException(status_code=409, detail="Kategori sudah tersedia")

        category.nama = nama

    try:
        db.commit()
        db.refresh(category)
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Gagal memperbarui kategori")

    return category


@router.delete("/{category_id}")
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("SUPERADMIN")),
):
    category = db.query(CustomerCategory).filter(
        CustomerCategory.id == category_id
    ).first()

    if not category:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")

    db.delete(category)

    try:
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="Kategori tidak dapat dihapus karena masih digunakan",
        )

    return {"message": "Kategori berhasil dihapus"}