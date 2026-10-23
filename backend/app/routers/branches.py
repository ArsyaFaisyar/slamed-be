from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
import uuid
from pathlib import Path
from app.db.database import get_db
from app.models.branch import Branch
from app.schemas.branch import (
    BranchCreate,
    BranchUpdate,
    BranchResponse,
)
from app.core.dependencies import get_current_user, require_roles


router = APIRouter(
    prefix="/branches",
    tags=["Branch"],
)


@router.get(
    "/",
    response_model=list[BranchResponse],
)
def get_branches(
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN", "SPV")),
):
    return db.query(Branch).order_by(Branch.id.desc()).all()


@router.get(
    "/{branch_id}",
    response_model=BranchResponse,
)
def get_branch(
    branch_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN", "SPV")),
):
    branch = db.query(Branch).filter(Branch.id == branch_id).first()

    if not branch:
        raise HTTPException(
            status_code=404,
            detail="Branch tidak ditemukan",
        )

    return branch


@router.post(
    "/",
    response_model=BranchResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_branch(
    data: BranchCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    existing = db.query(Branch).filter(
        (Branch.nama == data.nama) |
        (Branch.kode == data.kode)
    ).first()

    if existing:
        raise HTTPException(
            status_code=409,
            detail="Nama atau kode branch sudah digunakan",
        )

    branch = Branch(**data.model_dump())

    db.add(branch)
    db.commit()
    db.refresh(branch)

    return branch


@router.patch(
    "/{branch_id}",
    response_model=BranchResponse,
)
def update_branch(
    branch_id: int,
    data: BranchUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    branch = db.query(Branch).filter(Branch.id == branch_id).first()

    if not branch:
        raise HTTPException(
            status_code=404,
            detail="Branch tidak ditemukan",
        )

    updates = data.model_dump(exclude_unset=True)

    for field, value in updates.items():
        setattr(branch, field, value)

    if "nama" in updates or "kode" in updates:
        duplicate = db.query(Branch).filter(
            Branch.id != branch_id,
            (Branch.nama == branch.nama) |
            (Branch.kode == branch.kode),
        ).first()

        if duplicate:
            raise HTTPException(
                status_code=409,
                detail="Nama atau kode branch sudah digunakan",
            )

    db.commit()
    db.refresh(branch)

    return branch


@router.delete(
    "/{branch_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_branch(
    branch_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    branch = db.query(Branch).filter(Branch.id == branch_id).first()

    if not branch:
        raise HTTPException(
            status_code=404,
            detail="Branch tidak ditemukan",
        )

    db.delete(branch)
    db.commit()

UPLOAD_DIR = Path("uploads/branches")
ALLOWED_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}
MAX_FILE_SIZE = 5 * 1024 * 1024


@router.post("/{branch_id}/logo", response_model=BranchResponse)
def upload_branch_logo(
    branch_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    branch = db.query(Branch).filter(
        Branch.id == branch_id
    ).first()

    if not branch:
        raise HTTPException(
            status_code=404,
            detail="Branch tidak ditemukan",
        )

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Format logo harus JPG, PNG, atau WEBP",
        )

    content = file.file.read(MAX_FILE_SIZE + 1)

    if not content:
        raise HTTPException(
            status_code=400,
            detail="File logo kosong",
        )

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="Ukuran logo maksimal 5 MB",
        )

    extension = ALLOWED_TYPES[file.content_type]
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    filename = f"{uuid.uuid4().hex}{extension}"
    file_path = UPLOAD_DIR / filename

    with open(file_path, "wb") as output:
        output.write(content)

    # Hapus logo lama jika sebelumnya diunggah melalui endpoint ini.
    if branch.logo:
        old_path = Path(branch.logo)

        if old_path.exists() and old_path.is_file():
            try:
                old_path.unlink()
            except OSError:
                pass

    branch.logo = str(file_path).replace("\\", "/")

    db.commit()
    db.refresh(branch)

    return branch

def save_branch_image(
    branch: Branch,
    file: UploadFile,
    field_name: str,
    image_label: str,
    db: Session,
):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Format {image_label} harus JPG, PNG, atau WEBP",
        )

    content = file.file.read(MAX_FILE_SIZE + 1)

    if not content:
        raise HTTPException(
            status_code=400,
            detail=f"File {image_label} kosong",
        )

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Ukuran {image_label} maksimal 5 MB",
        )

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    extension = ALLOWED_TYPES[file.content_type]
    filename = f"{uuid.uuid4().hex}{extension}"
    file_path = UPLOAD_DIR / filename

    with open(file_path, "wb") as output:
        output.write(content)

    old_image = getattr(branch, field_name)

    setattr(
        branch,
        field_name,
        str(file_path).replace("\\", "/"),
    )

    try:
        db.commit()
        db.refresh(branch)
    except Exception:
        db.rollback()
        if file_path.exists():
            file_path.unlink()
        raise

    if old_image:
        old_path = Path(old_image)
        if old_path.exists() and old_path.is_file():
            try:
                old_path.unlink()
            except OSError:
                pass

    return branch


@router.post(
    "/{branch_id}/cover-image",
    response_model=BranchResponse,
)
def upload_branch_cover_image(
    branch_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    branch = db.query(Branch).filter(
        Branch.id == branch_id
    ).first()

    if not branch:
        raise HTTPException(
            status_code=404,
            detail="Branch tidak ditemukan",
        )

    return save_branch_image(
        branch=branch,
        file=file,
        field_name="cover_image",
        image_label="cover image",
        db=db,
    )


@router.post(
    "/{branch_id}/signature-image",
    response_model=BranchResponse,
)
def upload_branch_signature_image(
    branch_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user=Depends(require_roles("SUPERADMIN")),
):
    branch = db.query(Branch).filter(
        Branch.id == branch_id
    ).first()

    if not branch:
        raise HTTPException(
            status_code=404,
            detail="Branch tidak ditemukan",
        )

    return save_branch_image(
        branch=branch,
        file=file,
        field_name="signature_image",
        image_label="signature image",
        db=db,
    )