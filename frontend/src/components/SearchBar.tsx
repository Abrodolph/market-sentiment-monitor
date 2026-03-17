import React, { useState } from 'react';

interface SearchBarProps {
  onSearch: (ticker: string) => void;
}

export const SearchBar: React.FC<SearchBarProps> = ({ onSearch }) => {
  const [ticker, setTicker] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (ticker.trim()) {
      onSearch(ticker.trim().toUpperCase());
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex w-full max-w-md mx-auto mt-8">
      <input
        type="text"
        value={ticker}
        onChange={(e) => setTicker(e.target.value.toUpperCase())}
        placeholder="Enter Stock Ticker (e.g. AAPL)"
        className="flex-grow px-4 py-3 text-gray-700 bg-white border border-gray-300 rounded-l-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 font-semibold"
      />
      <button
        type="submit"
        className="px-6 py-3 text-white bg-indigo-600 rounded-r-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 font-semibold transition-colors duration-200"
      >
        Analyze
      </button>
    </form>
  );
};
