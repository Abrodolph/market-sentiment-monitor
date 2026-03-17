from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.schema import CreateTable

from .database import engine, Base
from .api import router as api_router

app = FastAPI(title="Market Sentiment Monitor API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for now
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the main API router
app.include_router(api_router, prefix="/api")

@app.on_event("startup")
def on_startup():
    # Ensure all tables are created in the database
    Base.metadata.create_all(bind=engine)
