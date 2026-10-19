from fastapi import FastAPI

app = FastAPI(
    title="Sales Management System API",
    version="1.0.0",
)


@app.get("/")
def root():
    return {"message": "Sales Management System API is running"}


@app.get("/health")
def health_check():
    return {"status": "ok"}