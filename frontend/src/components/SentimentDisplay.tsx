import React from 'react';
import { CircularProgressbar, buildStyles } from 'react-circular-progressbar';
import 'react-circular-progressbar/dist/styles.css';

interface SentimentDisplayProps {
  score?: number;
  summary?: string;
  isLoading: boolean;
}

export const SentimentDisplay: React.FC<SentimentDisplayProps> = ({
  score,
  summary,
  isLoading,
}) => {
  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center mt-12">
        <div className="w-16 h-16 border-4 border-slate-200 border-t-indigo-600 rounded-full animate-spin"></div>
        <p className="mt-4 text-slate-600 font-medium animate-pulse">Analyzing Market Data...</p>
      </div>
    );
  }

  if (score === undefined || !summary) {
    return null;
  }

  let color = '#ef4444'; // red
  if (score >= 60) {
    color = '#22c55e'; // green
  } else if (score >= 40) {
    color = '#eab308'; // yellow
  }

  return (
    <div className="flex flex-col md:flex-row max-w-4xl mx-auto mt-12 bg-white rounded-2xl shadow-xl overflow-hidden border border-slate-100">
      <div className="flex flex-col items-center justify-center bg-slate-50 p-8 border-b md:border-b-0 md:border-r border-slate-100 w-full md:w-1/3">
        <h3 className="text-xl font-bold text-slate-700 mb-6 uppercase tracking-wider text-center">Sentiment Score</h3>
        <div className="w-48 h-48">
          <CircularProgressbar
            value={score}
            text={`${score}`}
            styles={buildStyles({
              pathColor: color,
              textColor: color,
              trailColor: '#f8fafc',
              pathTransitionDuration: 1.5,
              textSize: '24px',
            })}
          />
        </div>
      </div>
      <div className="flex flex-col justify-center p-8 w-full md:w-2/3">
        <h3 className="text-xl font-bold text-slate-800 mb-4">Analysis Summary</h3>
        <p className="text-slate-600 leading-relaxed text-lg">
          {summary}
        </p>
      </div>
    </div>
  );
};
