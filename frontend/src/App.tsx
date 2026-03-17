import React, { useState } from 'react';
import { SearchBar } from './components/SearchBar';
import { SentimentDisplay } from './components/SentimentDisplay';
import { analyzeTicker } from './api';
import type { SentimentResponse } from './api';

function App() {
  const [ticker, setTicker] = useState<string>('');
  const [sentimentData, setSentimentData] = useState<SentimentResponse | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const handleSearch = async (searchTicker: string) => {
    setTicker(searchTicker);
    setIsLoading(true);
    setError(null);
    setSentimentData(null);

    try {
      const data = await analyzeTicker(searchTicker);
      setSentimentData(data);
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 font-sans text-slate-100 flex items-center justify-center p-6">
      <div className="w-full max-w-5xl">
        <header className="mb-12 text-center">
          <h1 className="text-4xl md:text-6xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-cyan-400 tracking-tight">
            AI Market Sentiment Monitor
          </h1>
          <p className="mt-4 text-slate-400 text-lg md:text-xl max-w-2xl mx-auto">
            Get instant, AI-driven insights on your favorite stocks based on real-time market data and late-breaking financial news.
          </p>
        </header>

        <SearchBar onSearch={handleSearch} />

        {error && (
          <div className="max-w-md mx-auto mt-8 bg-red-900/50 border border-red-500 text-red-200 px-6 py-4 rounded-lg text-center">
            {error}
          </div>
        )}

        <div className="mt-12 transition-all duration-500 ease-in-out">
          {(isLoading || sentimentData) && (
            <SentimentDisplay
              isLoading={isLoading}
              score={sentimentData?.score}
              summary={sentimentData?.summary}
            />
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
