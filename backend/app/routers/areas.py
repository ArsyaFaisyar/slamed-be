from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.area import Area
from app.models.user import User
from app.schemas.area import AreaCreate, AreaUpdate, AreaResponse

router = APIRouter(prefix="/areas", tags=["Area"])


def validate_spv(db: Session, spv_id: int):
    spv = db.query(User).filter(User.id == spv_id).first()

    if not spv or spv.role != "SPV" or not spv.is_active:
        raise HTTPException(
            status_code=400,
            detail="SPV tidak ditemukan atau akun tidak aktif",
        )


@router.get("/", response_model=list[AreaResponse])
def get_areas(
       db: Session = Depends(get_db),
       current_user=Depends(get_current_user),
   ):
    return db.query(Area).order_by(Area.id.desc()).all()


@router.get("/{area_id}", response_model=AreaResponse)
def get_area(
    area_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN", "SPV")),
):
    area = db.query(Area).filter(Area.id == area_id).first()

    if not area:
        raise HTTPException(status_code=404, detail="Area tidak ditemukan")

    return area


@router.post(
    "/",
    response_model=AreaResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_area(
    data: AreaCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    validate_spv(db, data.spv_id)

    if db.query(Area).filter(Area.nama == data.nama).first():
        raise HTTPException(status_code=409, detail="Nama area sudah digunakan")

    area = Area(**data.model_dump())
    db.add(area)
    db.commit()
    db.refresh(area)

    return area


@router.patch("/{area_id}", response_model=AreaResponse)
def update_area(
    area_id: int,
    data: AreaUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    area = db.query(Area).filter(Area.id == area_id).first()
    if not area:
        raise HTTPException(status_code=404, detail="Area tidak ditemukan")
    updates = data.model_dump(exclude_unset=True)
    if "nama" in updates and updates["nama"] != area.nama:
        duplicate = db.query(Area).filter(
            Area.nama == updates["nama"],
            Area.id != area_id,
        ).first()

        if duplicate:
            raise HTTPException(status_code=409, detail="Nama area sudah digunakan")
    if "spv_id" in updates:
        validate_spv(db, updates["spv_id"])
    for field, value in updates.items():
        setattr(area, field, value)
    db.commit()
    db.refresh(area)
    return area


@router.delete("/{area_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_area(
    area_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    area = db.query(Area).filter(Area.id == area_id).first()

    if not area:
        raise HTTPException(status_code=404, detail="Area tidak ditemukan")

    db.delete(area)
    db.commit()