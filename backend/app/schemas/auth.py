from pydantic import BaseModel, Field

class LoginRequest(BaseModel):
    username: str
    password: str
    captcha_id: str
    captcha_answer: int
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    message: str = "Login berhasil"
    user: dict