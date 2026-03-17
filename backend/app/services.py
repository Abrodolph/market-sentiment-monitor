import os
import asyncio
import logging
import json
import yfinance as yf
from typing import Any
from tavily import TavilyClient
from dotenv import load_dotenv
from google import genai
from pydantic import BaseModel

load_dotenv()

logger = logging.getLogger(__name__)

TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")
tavily_client = TavilyClient(api_key=TAVILY_API_KEY) if TAVILY_API_KEY else None

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
genai_client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

class SentimentResponse(BaseModel):
    score: int
    summary: str

async def fetch_market_data(ticker: str) -> dict[str, Any]:
    try:
        def _fetch() -> dict[str, Any]:
            stock = yf.Ticker(ticker)
            info = stock.info
            return {
                "current_price": info.get("currentPrice", info.get("regularMarketPrice")),
                "regular_market_high": info.get("regularMarketDayHigh", info.get("dayHigh")),
                "regular_market_low": info.get("regularMarketDayLow", info.get("dayLow")),
                "volume": info.get("volume", info.get("regularMarketVolume"))
            }
        
        return await asyncio.to_thread(_fetch)
    except Exception as e:
        logger.error(f"Error fetching market data for {ticker}: {e}")
        return {
            "current_price": None,
            "regular_market_high": None,
            "regular_market_low": None,
            "volume": None,
            "error": str(e)
        }

async def fetch_market_news(ticker: str) -> list[str]:
    if not tavily_client:
        logger.warning(f"TavilyClient is not initialized, skipping news for {ticker}")
        return []
    
    try:
        def _fetch_news() -> dict[str, Any]:
            query = f"{ticker} stock financial news"
            if tavily_client is not None:
                return tavily_client.search(
                    query=query,
                    search_depth="basic",
                    max_results=3,
                ) # type: ignore
            return {}
        
        response = await asyncio.to_thread(_fetch_news) # type: ignore
        results = response.get("results", [])
        return [res.get("content", "") for res in results if res.get("content")]
    except Exception as e:
        logger.error(f"Error fetching market news for {ticker}: {e}")
        return []

async def generate_sentiment_analysis(ticker: str, market_data: dict, news_data: list) -> dict:
    if not genai_client:
        logger.error("GEMINI_API_KEY is not configured")
        return {"error": "GEMINI_API_KEY not configured", "score": 0, "summary": ""}
    
    prompt = f"""
    You are a strict, highly analytical financial analyst. I am providing you with the latest market data and recent news summaries for the stock ticker {ticker}.
    Your task is to analyze this data objectively and ruthlessly to determine the current market sentiment and potential near-term price direction.
    
    Data Provided:
    - Target Ticker: {ticker}
    - Market Data: {json.dumps(market_data, indent=2)}
    - Recent News Summaries: {json.dumps(news_data, indent=2)}
    
    Based on the above data, provide your expert financial analysis. Return the response as a valid JSON object with EXACTLY these two keys:
    - "score": An integer from 1 to 100. 1 means extremely bearish (sell immediately), 50 is neutral, and 100 is extremely bullish (strong buy). Be strict in your scoring; do not give high scores unless justified by strong fundamentals or overwhelmingly positive catalysts.
    - "summary": A single, concise paragraph explaining the reasoning behind the score based on the provided data.
    """
    
    try:
        def _generate() -> dict:
            assert genai_client is not None
            response = genai_client.models.generate_content(
                model='gemini-3.1-pro-preview',
                contents=prompt,
                config={
                    "response_mime_type": "application/json",
                    "response_schema": SentimentResponse,
                }
            )
            try:
                return json.loads(response.text)
            except (json.JSONDecodeError, TypeError) as e:
                logger.error(f"JSON parsing error for {ticker}: {e} - Response text: {response.text}")
                return {"score": 50, "summary": f"Failed to parse LLM response: {e}"}
        
        return await asyncio.to_thread(_generate) # type: ignore
    except Exception as e:
        logger.error(f"Error generating sentiment analysis for {ticker}: {e}")
        return {"score": 50, "summary": f"Error: {e}"}
