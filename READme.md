# 📊 AI Market Sentiment Monitor

A professional-grade financial analysis tool that leverages GenAI to provide real-time sentiment scores and deep market insights for global equities.

**🌐 Live Demo:** [http://35.238.123.229](http://35.238.123.229)

---

## 🚀 Key Features

- **Real-Time Analysis**: Fetches live market data (Price, Volume, Range) for any stock ticker via Yahoo Finance.
- **AI-Powered Insights**: Utilizes **Google Gemini 1.5 Pro** to analyze financial news and provide a "Sentiment Score" (1-100).
- **Global Market Support**: Optimized for both US (e.g., AAPL) and Indian markets (e.g., RELIANCE.NS).
- **Deep Web Search**: Integrates **Tavily AI Search** to crawl the web for the absolute latest financial catalysts.
- **Cloud Native**: Fully containerized and deployed on Google Cloud Platform with automated infrastructure provisioning.

---

## 🛠 Technology Stack

### **Frontend**
- **React 18 & TypeScript**: Robust, type-safe UI logic.
- **Vite 5**: Blazing fast build tool and development server.
- **Tailwind CSS 4**: Modern, atomic CSS for responsive and premium design.
- **Lucide React**: For sleek, consistent iconography.

### **Backend**
- **FastAPI (Python 3.11)**: High-performance, asynchronous REST API.
- **Pydantic**: Strict data validation and transformation.
- **Gemini Pro**: Advanced LLM for financial reasoning and sentiment quantification.
- **Tavily AI**: Optimized search for RAG (Retrieval-Augmented Generation).

### **Data & Infrastructure**
- **PostgreSQL 15**: Secure storage for analysis history and ticker metadata.
- **Terraform**: Infrastructure-as-Code (IaC) for reproducible GCP provisioning.
- **Docker & Docker Compose**: Multi-container orchestration for seamless environment parity.
- **Nginx**: High-performance reverse proxy and API gateway.
- **Google Cloud Platform (GCP)**: Hosting on Compute Engine with static IP configurations.

---

## 🏗 System Architecture & Techniques

### **1. Zero-SSH Automated Deployment**
The project uses a specialized **"Pull-based" automation** to ensure the server remains self-healing. Code is distributed via GCS buckets and managed by custom VM startup scripts, eliminating manual configuration errors.

### **2. Virtual Memory Optimization**
To handle high-intensity builds on cost-effective cloud hardware (`e2-micro`), the system implements **4GB of automated swap space**, ensuring smooth compilation of heavy data science libraries.

### **3. Nginx API Gateway**
All traffic is routed through a single entry point (Port 80) using Nginx, which handles the secure proxying of requests to the backend while serving optimized frontend assets.

---

## 💻 Local Development

### **Prerequisites**
- Docker & Docker Compose
- API Keys: Google Gemini (AI Studio), Tavily AI.

### **Setup**
1. Clone the repository.
2. Create a `.env` file in the root with:
   ```env
   GEMINI_API_KEY=your_key
   TAVILY_API_KEY=your_key
   POSTGRES_PASSWORD=your_secure_password
   ```
3. Run the application:
   ```bash
   docker-compose up --build
   ```
4. Access the UI at `http://localhost:80`.

---
