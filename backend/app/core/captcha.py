import secrets
import time
from fastapi import HTTPException

CAPTCHA_EXPIRE_SECONDS = 300

_captchas: dict[str, tuple[int, float]] = {}
def create_captcha():
    now = time.time()
    expired = [
        key
        for key, (_, expiry) in _captchas.items()
        if expiry <= now
    ]

    for key in expired:
        _captchas.pop(key, None)
    a = secrets.randbelow(10) + 1
    b = secrets.randbelow(10) + 1
    operator = secrets.choice(["+", "-"])

    if operator == "+":
        answer = a + b
    else:
        a, b = max(a, b), min(a, b)
        answer = a - b

    captcha_id = secrets.token_urlsafe(24)

    _captchas[captcha_id] = (
        answer,
        now + CAPTCHA_EXPIRE_SECONDS,
    )

    return {
        "captcha_id": captcha_id,
        "question": f"{a} {operator} {b} = ?",
        "expires_in": CAPTCHA_EXPIRE_SECONDS,
    }


def verify_captcha(captcha_id: str, answer: int):
    captcha = _captchas.pop(captcha_id, None)
    if captcha is None:
        raise HTTPException(
            status_code=400,
            detail="Captcha tidak valid atau sudah digunakan",
        )
    correct_answer, expiry = captcha
    if time.time() >= expiry:
        raise HTTPException(
            status_code=400,
            detail="Captcha sudah kedaluwarsa. Silakan minta captcha baru",
        )
    if answer != correct_answer:
        raise HTTPException(
            status_code=400,
            detail="Jawaban captcha salah",
        )