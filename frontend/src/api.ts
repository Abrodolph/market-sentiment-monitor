import axios from 'axios';

export interface SentimentResponse {
  score: number;
  summary: string;
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';

export async function analyzeTicker(ticker: string): Promise<SentimentResponse> {
  try {
    const response = await axios.get<SentimentResponse>(`${API_BASE_URL}/analyze/${ticker}`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const message = error.response?.data?.detail || error.message;
      throw new Error(`Failed to analyze ticker: ${message}`);
    }
    throw new Error('An unexpected error occurred while analyzing the ticker.');
  }
}
