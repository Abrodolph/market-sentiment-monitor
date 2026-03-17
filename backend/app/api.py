from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
import asyncio

from . import models, services
from .database import get_db

router = APIRouter()

@router.get("/analyze/{ticker}")
async def analyze_sentiment(ticker: str, request: Request, db: Session = Depends(get_db)):
    ticker = ticker.upper()

    # Log incoming request
    ip_address = request.client.host if request.client else None
    analysis_req = models.AnalysisRequest(ticker=ticker, ip_address=ip_address)
    db.add(analysis_req)
    db.commit()

    try:
        # Fetch market data and news concurrently
        market_data_task = asyncio.create_task(services.fetch_market_data(ticker))
        news_data_task = asyncio.create_task(services.fetch_market_news(ticker))

        market_data, news_data = await asyncio.gather(market_data_task, news_data_task)
        
        # Check if market data actually fetched something useful
        if market_data.get("error"):
            raise HTTPException(status_code=400, detail=f"Failed to fetch market data: {market_data['error']}")
        
        # Call LLM for sentiment score
        sentiment = await services.generate_sentiment_analysis(ticker, market_data, news_data)

        # Log results to SentimentResult
        sentiment_result = models.SentimentResult(
            ticker=ticker,
            yfinance_data=market_data,
            tavily_news=news_data,
            ai_score=sentiment.get("score"),
            ai_summary=sentiment.get("summary")
        )
        db.add(sentiment_result)
        db.commit()

        # Return to client
        return {
            "ticker": ticker,
            "status": "success",
            "score": sentiment.get("score"),
            "summary": sentiment.get("summary"),
        }
    except HTTPException:
        raise
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error processing /analyze/{ticker}: {e}")
        raise HTTPException(status_code=500, detail="An error occurred processing the analysis request.")
