# 🏭 Patel Mart Supply Chain Intelligence
### AI-Powered Order & Inventory Analytics | End-to-End Data Pipeline

<div align="center">

![Supply Chain](https://img.shields.io/badge/Domain-Supply%20Chain%20Analytics-0f6e56?style=for-the-badge)
![n8n](https://img.shields.io/badge/Automation-n8n-ea4b71?style=for-the-badge&logo=n8n)
![Supabase](https://img.shields.io/badge/Database-Supabase%20%2F%20PostgreSQL-3ecf8e?style=for-the-badge&logo=supabase)
![Docker](https://img.shields.io/badge/Container-Docker-2496ed?style=for-the-badge&logo=docker)
![Quadratic](https://img.shields.io/badge/Analysis-Quadratic%20AI-7c3aed?style=for-the-badge)
![Python](https://img.shields.io/badge/Code-Python-3776ab?style=for-the-badge&logo=python)

**Built to demonstrate modern supply chain analytics for top FMCG companies in the Netherlands**

[View Report](#-project-report) · [KPI Results](#-kpi-results) · [Pipeline](#-data-pipeline) · [Setup Guide](#-local-setup)

</div>

---

## 📌 Project Overview

AtliQ Mart is a **Gujarat-based organic food manufacturer** that recently expanded to the United States. Rapid growth exposed a critical supply chain vulnerability: **immature order management** causing customer dissatisfaction.

| Stakeholder | Problem Identified |
|---|---|
| COO — Bruce Hurali | Supply chain immaturity causing poor order management |
| Head of Analytics — Tony Sharma | Root cause: failure to maintain optimum inventory levels |

**This project delivers an end-to-end AI-powered analytics system** that automatically ingests daily supply chain data, stores it in a cloud database, and generates real-time KPI insights — replacing hours of manual reporting with continuous intelligence.

---

## 🏗️ Architecture

```
📧 Gmail Inbox (Daily CSV Attachments)
         │
         ▼  every 15 minutes
┌─────────────────────────┐
│        n8n              │  ← Running in Docker on Windows
│  Gmail Trigger          │
│  Extract from CSV       │  ← Two attachments processed in parallel
│  Insert to Postgres     │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│        Supabase / PostgreSQL            │
│                                         │
│  dim_customers      dim_products        │
│  dim_targets_orders                     │
│  fact_order_line    fact_aggregate      │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│      Quadratic AI       │  ← Natural language → SQL → Analysis
│  KPI Calculations       │
│  Customer Rankings      │
│  Business Insights      │
└─────────────────────────┘
         │
         ▼
📊 COO-Ready Insights: OTIF%, Revenue Loss, Customer Performance
```

---

## 🗄️ Data Model — Star Schema

```
                    ┌─────────────────────┐
                    │   dim_customers     │
                    │  35 rows · 4 cols   │
                    │  customer_id (PK)   │
                    │  customer_name      │
                    │  city · currency    │
                    └──────────┬──────────┘
                               │
┌──────────────────┐           │           ┌──────────────────────┐
│   dim_products   │           │           │  dim_targets_orders  │
│  18 rows · 5 cols│           │           │  35 rows · 4 cols    │
│  product_id (PK) │           │           │  customer_id (PK)    │
│  product_name    │     ┌─────┴──────┐    │  ontime_target_pct   │
│  category        │─────┤FACT TABLES │────│  infull_target_pct   │
│  price_INR/USD   │     └─────┬──────┘    │  otif_target_pct     │
└──────────────────┘           │           └──────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
┌─────────────────────────┐    ┌─────────────────────────┐
│    fact_order_line      │    │     fact_aggregate      │
│  25,886 rows · 11 cols  │    │  14,931 rows · 6 cols   │
│  order_id + product_id  │    │  order_id (PK)          │
│  (composite PK)         │    │  customer_id            │
│  order_placement_date   │    │  order_placement_date   │
│  agreed_delivery_date   │    │  on_time                │
│  actual_delivery_date   │    │  in_full                │
│  order_qty              │    │  otif                   │
│  delivery_qty           │    └─────────────────────────┘
│  in_full · on_time      │
│  on_time_in_full        │
└─────────────────────────┘
```

---

## ⚙️ Data Pipeline (n8n)

The automated workflow runs inside **Docker on Windows** and processes daily supply chain emails:

```
Gmail Trigger (INBOX + Subject: "Daily Sales")
    │
    ├──► Extract from File: order_line  ──► Insert rows → fact_order_line
    │         (128 rows per day)
    │
    └──► Extract from File: Aggregate  ──► Insert rows → fact_aggregate
              (226 rows per day)
```

**Key configurations:**
| Setting | Value |
|---|---|
| Poll frequency | Every minute (production: every 15 min) |
| Gmail filter | `INBOX` + `Subject: Daily Sales` |
| Date transform | `DD-MM-YYYY` → `YYYY-MM-DD` (ISO 8601) |
| Live test | Day 17 (2025-05-17) — 354 rows auto-ingested ✅ |

---

## 📊 KPI Results

> Calculated by Quadratic AI via natural language prompts connected directly to Supabase

| # | KPI | Result | Benchmark | Status |
|---|---|---|---|---|
| 1 | Total Order Lines | **25,886** | — | — |
| 2 | Total Orders | **13,652** | — | — |
| 3 | Line Fill Rate | **65.99%** | 90%+ | 🟡 Below Target |
| 4 | Volume Fill Rate | **96.62%** | 95%+ | 🟢 On Target |
| 5 | On Time Delivery % | **59.18%** | 80%+ | 🔴 Critical |
| 6 | In Full Delivery % | **52.91%** | 80%+ | 🔴 Critical |
| 7 | **OTIF %** | **28.89%** | 70%+ | 🔴 Critical |

> 💡 **OTIF at 28.89%** means only 1 in 3.5 orders arrives both on time AND in full — the primary area requiring executive attention.

---

## 👥 Customer Performance

### Top 5 Global (by Order Value)

| # | Customer | Order Value | OT % | IF % | OTIF % |
|---|---|---|---|---|---|
| 1 | Foodtown (NJ, US) | $51.3M | 69.07% | 58.51% | 33.25% |
| 2 | Whole Foods Market (NJ, US) | $50.7M | 70.63% | 61.11% | 39.15% |
| 3 | Lidl (NJ, US) | $50.6M | 29.55% | 68.47% | 🔴 21.98% |
| 4 | Wegmans (NJ, US) | $49.9M | 71.16% | 57.94% | 37.04% |
| 5 | Price Rite (NJ, US) | $49.3M | 72.63% | 16.58% | 🔴 8.42% |

### Top 5 India (by Order Value)

| # | Customer | City | Order Value | OT % | IF % | OTIF % |
|---|---|---|---|---|---|---|
| 1 | Acclaimed Stores | Ahmedabad | INR 20.5M | 29.67% | 67.75% | 🔴 19.21% |
| 2 | Rel Fresh | Ahmedabad | INR 20.1M | 72.32% | 55.36% | 35.16% |
| 3 | Elite Mart | Ahmedabad | INR 20.1M | 73.38% | 56.72% | 37.06% |
| 4 | Propel Mart | Vadodara | INR 19.9M | 73.47% | 63.40% | 🟢 44.30% |
| 5 | Propel Mart | Ahmedabad | INR 19.9M | 74.48% | 57.22% | 39.69% |

---

## 🔍 Key Business Insights

### 💰 Revenue Loss from Undelivered Orders
```
Total Ordered Revenue  : INR 103.60 Crore
Total Delivered Revenue: INR  99.67 Crore
Revenue at Risk        : INR   3.93 Crore  (3.79%)
```

### ⚠️ Biggest OTIF Gaps vs SLA Target
| Customer | Actual OTIF | Target | Gap |
|---|---|---|---|
| Price Rite (US) | 8.42% | 62% | **-53.58 pts** |
| Vijay Stores (Vadodara) | 10.87% | 62% | **-51.13 pts** |
| Elite Mart (Vadodara) | 10.70% | 60% | **-49.30 pts** |

### 📦 Supply Chain Bottleneck Analysis
```
Category    In Full Rate   Volume Fill   Signal
──────────────────────────────────────────────
Beverages     65.88%         96.60%    ← Inventory allocation
Dairy         65.99%         96.62%    ← Inventory allocation  
Food          66.13%         96.60%    ← Inventory allocation

All categories show identical pattern → SYSTEMIC planning failure,
NOT category-specific. Root cause: inventory allocation, not production.
```

### ⏱️ Delivery Delay Analysis
- **Total late deliveries:** 7,444
- **Average delay:** 1.69 days
- **Maximum delay:** 3 days
- **Implication:** Short but frequent → last-mile logistics failure, not warehousing

---

## 📁 Repository Structure

```
atliq-supply-chain-intelligence/
│
│
├── 📁 pipeline/
│   └── n8n_workflow.json             # Exported n8n workflow
│
├── 📁 sql/
│   ├── schema.sql                    # Table creation scripts
│   └── kpi_queries.sql               # KPI calculation queries
│
├── 📁 analysis/
│   └── kpi_analysis.py               # Python KPI calculations
│
├── 📁 screenshots/
│   ├── n8n_workflow.png
│   ├── gmail_trigger.png
│   ├── postgres_node.png
│   ├── supabase_tables.png
│   ├── quadratic_kpi_results.png
│   └── quadratic_top_customers.png
│
├── 📁 report/
│   └── AtliQ_Mart_Supply_Chain_Intelligence_Report.pdf
│
└── README.md
```

---

## 🚀 Local Setup

### Prerequisites
- Docker Desktop installed and running
- Supabase account (free tier)
- Gmail account
- Google Cloud project with Gmail API enabled

### Step 1 — Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/atliq-supply-chain-intelligence.git
cd atliq-supply-chain-intelligence
```

### Step 2 — Start n8n with Docker
```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_HOST=localhost \
  -e WEBHOOK_URL=http://localhost:5678/ \
  docker.n8n.io/n8nio/n8n
```
Then open: `http://localhost:5678`

### Step 3 — Set Up Supabase
1. Create a new project at [supabase.com](https://supabase.com)
2. Run `sql/schema.sql` in the Supabase SQL Editor
3. Import cleaned CSV files from `data/cleaned/` via Table Editor

### Step 4 — Import n8n Workflow
1. In n8n, go to **Workflows** → **Import from file**
2. Select `pipeline/n8n_workflow.json`
3. Update Gmail credentials and Supabase connection details
4. Activate the workflow ✅

### Step 5 — Connect Quadratic AI
1. Sign up at [quadratichq.com](https://quadratichq.com)
2. Create new spreadsheet → **Connect data** → PostgreSQL
3. Use your Supabase pooler connection details
4. Use the prompts in `analysis/` to generate KPIs

---

## 🔑 Environment Variables

Create a `.env` file (never commit this):
```env
SUPABASE_HOST=aws-0-eu-west-1.pooler.supabase.com
SUPABASE_PORT=5432
SUPABASE_DB=postgres
SUPABASE_USER=postgres.YOUR_PROJECT_ID
SUPABASE_PASSWORD=your_password_here
```

---

## 📈 KPI Definitions

| KPI | Formula | Why It Matters |
|---|---|---|
| **OTIF %** | Orders delivered on-time AND in-full / Total orders | Most critical — directly tied to customer retention |
| **On Time %** | On-time deliveries / Total deliveries | Measures logistics reliability |
| **In Full %** | Full-quantity deliveries / Total deliveries | Measures inventory adequacy |
| **Line Fill Rate** | Fully completed order lines / Total order lines | Measures order fulfilment precision |
| **Volume Fill Rate** | Total delivered qty / Total ordered qty | Measures quantity fulfilment efficiency |

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|---|---|---|
| [n8n](https://n8n.io) | Latest | Workflow automation — Gmail → CSV → Postgres |
| [Supabase](https://supabase.com) | Cloud | PostgreSQL database + REST API |
| [Docker Desktop](https://docker.com) | 4.69+ | n8n container environment |
| [Quadratic AI](https://quadratichq.com) | Latest | AI-powered spreadsheet analysis |
| Python | 3.12 | Data cleaning + KPI validation |
| PostgreSQL | 15 | Relational database (via Supabase) |

---

## 👤 About

**Harshil Patel** — Supply Chain Data Analyst

Passionate about combining supply chain domain expertise with modern AI tools to deliver real business intelligence. This project demonstrates end-to-end analytical ownership: from raw data ingestion to C-suite insights.

📍 Based in the Netherlands | Targeting roles at Unilever, Philips, PostNL, Jumbo, Heineken

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077b5?style=flat-square&logo=linkedin)](https://linkedin.com/in/YOUR_PROFILE)

---

## 📄 License

This project is for portfolio and educational purposes.

---

<div align="center">
<sub>Built with n8n · Supabase · Quadratic AI · Python · Docker</sub>
</div>
