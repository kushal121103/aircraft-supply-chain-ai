# ✈️ Aviation Supply Chain Analytics & AI Assistant

An end-to-end **Aircraft Maintenance Supply Chain Analytics** project combining **SQL, Python, Power BI, RAG, FAISS, Llama 3.1, LangChain, and Streamlit** to analyze supply-chain performance and provide AI-powered insights.

## 📌 Project Overview

Aircraft maintenance operations depend on the timely availability of critical parts, reliable suppliers, healthy inventory levels, and effective quality management.

This project analyzes aircraft maintenance supply-chain data to identify:

- Supplier performance and risk
- Inventory and backorder risks
- Procurement performance
- Quality incidents
- Site-level supply-chain issues
- Operational priorities and recommendations

The project also includes a **RAG-based AI Supply Chain Assistant** that allows users to ask natural-language questions about the supply-chain data.

---

## 🏗️ Project Architecture

```text
                    Supply Chain Data
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
     Parts Master     Purchase Orders   Quality Incidents
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                  Supply Chain History
                           │
                           ▼
                 Python + Pandas
                 Data Processing
                           │
                           ▼
                Business-Level Documents
                           │
                    Text Splitting
                           │
                           ▼
                     Embeddings
                           │
                           ▼
                        FAISS
                  Vector Database
                           │
                           ▼
                      Retriever
                           │
                           ▼
                        Prompt
                           │
                           ▼
                    Llama 3.1 8B
                           │
                           ▼
                  AI Supply Chain
                     Assistant


Power BI
   │
   ├── Procurement KPIs
   ├── Inventory Analysis
   ├── Backorder Analysis
   ├── Supplier Performance
   └── Quality Analysis
