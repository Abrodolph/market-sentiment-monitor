from sqlalchemy import Column, Integer, String, DateTime, JSON, Text
from datetime import datetime, timezone

from .database import Base

class AnalysisRequest(Base):
    __tablename__ = "analysis_requests"

    id = Column(Integer, primary_key=True, index=True)
    ticker = Column(String, index=True)
    ip_address = Column(String, nullable=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class SentimentResult(Base):
    __tablename__ = "sentiment_results"

    id = Column(Integer, primary_key=True, index=True)
    ticker = Column(String, index=True)
    yfinance_data = Column(JSON)
    tavily_news = Column(JSON)
    ai_score = Column(Integer)
    ai_summary = Column(Text)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))
