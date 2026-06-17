import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.routers import transcript

load_dotenv(Path(__file__).with_name(".env"))


def allowed_origins() -> list[str]:
    raw = os.getenv("CORS_ALLOW_ORIGINS", "").strip()
    if raw:
        origins = [item.strip() for item in raw.split(",") if item.strip()]
        if origins:
            return origins
    return ["*"]

app = FastAPI(
    title="AI Resume Generator OCR API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins(),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(transcript.router, prefix="/api/transcript", tags=["transcript"])


@app.get("/")
def read_root():
    return {
        "message": "AI Resume Generator API",
        "service": "ocr-transcript",
        "status": "ok",
    }
