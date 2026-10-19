import os
import sys
from dotenv import load_dotenv
from sqlalchemy.orm import Session
sys.path.insert(
    0,
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)

load_dotenv()

from app.db.database import SessionLocal
from app.models.user import User
from app.core.security import hash_password


DEMO_PASSWORD = os.getenv("DEMO_USER_PASSWORD")
DEMO_USERS = [
    {
        "nama": "Super Admin Demo",
        "username": "superadmin",
        "email": "superadmin@demo.com",
        "role": "SUPERADMIN",
    },
    {
        "nama": "Supervisor Demo",
        "username": "spv01",
        "email": "spv01@demo.com",
        "role": "SPV",
    },
    {
        "nama": "Sales Demo",
        "username": "sales01",
        "email": "sales01@demo.com",
        "role": "SALES",
    },
    {
        "nama": "PPIC Demo",
        "username": "ppic01",
        "email": "ppic01@demo.com",
        "role": "PPIC",
    },
    {
        "nama": "Marketing Demo",
        "username": "marketing01",
        "email": "marketing01@demo.com",
        "role": "ADMIN_MARKETING",
    },
    {
        "nama": "Keuangan Demo",
        "username": "keuangan01",
    },
]


def seed_users(db: Session):
    if not DEMO_PASSWORD:
        raise RuntimeError(
            "DEMO_USER_PASSWORD belum diatur di file .env"
        )

    for item in DEMO_USERS:
        existing = db.query(User).filter(
            (User.username == item["username"])
            | (User.email == item["email"])
        ).first()

        if existing:
            print(f"Skip: {item['username']} sudah ada")
            continue

        user = User(
            **item,
            password_hash=hash_password(DEMO_PASSWORD),
            is_active=1,
        )

        db.add(user)
        print(f"Disiapkan: {item['username']} ({item['role']})")

    db.commit()
    print("Seeder user selesai.")


def main():
    db = SessionLocal()

    try:
        seed_users(db)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
