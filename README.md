<div align="center">

# 🛒 Zepto SQL Data Analysis

### End-to-end SQL analysis of Zepto's grocery product catalog —  
### uncovering pricing strategy, inventory health, discount patterns & revenue opportunities

<br>

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-Advanced-FF6B35?style=for-the-badge&logo=databricks&logoColor=white)](https://github.com/Yashchaudhary872/Zepto-SQL-Analysis-project)
[![Domain](https://img.shields.io/badge/Domain-Quick%20Commerce-00C853?style=for-the-badge)](https://github.com/Yashchaudhary872/Zepto-SQL-Analysis-project)
[![Questions](https://img.shields.io/badge/Business%20Questions-15-blueviolet?style=for-the-badge)](https://github.com/Yashchaudhary872/Zepto-SQL-Analysis-project)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)](https://github.com/Yashchaudhary872/Zepto-SQL-Analysis-project)

<br>

[📋 Problem Statement](#-problem-statement) •
[🗃️ Dataset](#️-dataset) •
[🔍 Analysis](#-analysis--queries) •
[💡 Key Insights](#-key-insights) •
[⚙️ SQL Concepts](#️-sql-concepts-demonstrated) •
[🚀 Setup](#️-setup--usage) •
[👤 About Me](#-about-me)

</div>

---

## 📌 Project Overview

**Zepto** is India's pioneering **10-minute grocery delivery** startup operating on a hyperlocal quick-commerce model. This project performs a complete **SQL-based analysis** on Zepto's product catalog — from raw data cleaning to advanced business intelligence queries — answering 15 real-world business questions across pricing, inventory, revenue, and margin health.

| 🎯 What This Project Covers | Details |
|---|---|
| **Data Cleaning** | Handled paise→rupee conversion, zero-price records, NULL checks, duplicate SKUs |
| **Pricing Analysis** | Discount strategy, price-per-gram value, price tier vs discount correlation |
| **Inventory Intelligence** | In-stock rate per category, out-of-stock revenue leakage, weight segmentation |
| **Revenue Analytics** | Category GMV estimation, Pareto 80-20 analysis, running revenue totals |
| **Advanced SQL** | Window functions (RANK, SUM OVER), chained CTEs, PERCENTILE_CONT, health scoring |

---

## ❓ Problem Statement

> *"How can Zepto optimize its product pricing, discount strategy, and inventory management to maximize revenue while ensuring product availability across high-demand categories?"*

This analysis answers that question across **4 business dimensions**:

```
Pricing Strategy  →  Which products are over/under-discounted?
Inventory Health  →  Which categories have stock availability issues?
Revenue Analysis  →  Which categories drive 80% of GMV?
Margin Protection →  Which SKUs are margin outliers vs their category?
```

---

## 🗃️ Dataset

**Source:** Zepto product catalog snapshot (`zepto_v2.csv`)  
**Scope:** Grocery SKUs across multiple categories — Dairy, Snacks, Beverages, Fresh Produce, and more

### Schema

```sql
CREATE TABLE zepto (
    sku_id                 SERIAL PRIMARY KEY,      -- Unique product identifier
    category               VARCHAR(120),            -- Product category
    name                   VARCHAR(150) NOT NULL,   -- Product name
    mrp                    NUMERIC(8,2),            -- Maximum Retail Price (₹)
    discountPercent        NUMERIC(5,2),            -- Discount offered (%)
    availableQuantity      INTEGER,                 -- Units currently in stock
    discountedSellingPrice NUMERIC(8,2),            -- Final price after discount (₹)
    weightInGms            INTEGER,                 -- Product weight in grams
    outOfStock             BOOLEAN,                 -- TRUE = out of stock
    quantity               INTEGER                  -- Pack size
);
```

### Data Quality Issues Found & Fixed

| Issue | How It Was Fixed |
|---|---|
| Prices stored in **paise** instead of rupees | `UPDATE` — divided all price columns by 100 |
| **Zero-MRP records** (invalid entries) | `DELETE` — removed before analysis |
| **NULL values** across key columns | Identified via exploration; excluded from aggregations |
| **Duplicate product names** (multi-SKU variants) | Detected with `HAVING COUNT > 1`; handled with `DISTINCT` |

---

## 🔍 Analysis & Queries

### 🟢 Basic Questions (Q1 – Q4)

---

**Q1 · Top 10 Best-Value Products by Discount Percentage**

```sql
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;
```
> 💡 **Business Insight:** These are your "deal anchor" products. Zepto can feature them in push notifications or homepage banners to drive app opens and session depth.

---

**Q2 · High-MRP Products That Are Out of Stock**

```sql
SELECT DISTINCT name, mrp
FROM zepto
WHERE outOfStock = TRUE AND mrp > 300
ORDER BY mrp DESC;
```
> 💡 **Business Insight:** Every day a premium product is out of stock is direct revenue leakage. These SKUs should be first priority for restocking — they have the highest margin impact.

---

**Q3 · Estimated Revenue Potential per Category**

```sql
SELECT category,
       SUM(discountedSellingPrice * availableQuantity) AS estimated_revenue
FROM zepto
WHERE outOfStock = FALSE
GROUP BY category
ORDER BY estimated_revenue DESC;
```
> 💡 **Business Insight:** Reveals which categories drive the most GMV from available inventory. Redirect procurement budget toward the top-revenue categories to compound gains.

---

**Q4 · Premium Products with Suspiciously Low Discounts**

```sql
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC;
```
> 💡 **Business Insight:** High-value products with minimal discounts may be losing to competitors on price comparison apps. A targeted 5–10% flash discount on these could meaningfully lift conversion.

---

### 🟡 Medium Questions (Q5 – Q11)

---

**Q5 · Top 5 Categories by Average Discount Offered**

```sql
SELECT category,
       ROUND(AVG(discountPercent), 2) AS avg_discount_pct
FROM zepto
GROUP BY category
ORDER BY avg_discount_pct DESC
LIMIT 5;
```
> 💡 **Business Insight:** Categories averaging 25%+ discount may be eroding margins. Cross-reference with Q3 revenue — if they're not top revenue drivers either, the discount strategy needs recalibration.

---

**Q6 · Price-per-Gram Analysis — Best Value Products**

```sql
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
       ROUND(discountedSellingPrice / NULLIF(weightInGms, 0), 4) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram ASC;
```
> 💡 **Business Insight:** Price-per-gram is a powerful consumer metric in grocery. The lowest-cost-per-gram products can be surfaced as a "Value Picks" section to win price-sensitive shoppers.

---

**Q7 · Product Weight Segmentation (Low / Medium / Bulk)**

```sql
SELECT DISTINCT name, weightInGms,
       CASE
           WHEN weightInGms < 1000 THEN 'Low'
           WHEN weightInGms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_segment
FROM zepto
ORDER BY weightInGms DESC;
```
> 💡 **Business Insight:** Bulk items (>5kg) need different delivery logistics. Knowing the weight mix per order helps Zepto plan bike vs vehicle dispatch and set appropriate delivery fee tiers.

---

**Q8 · Total Inventory Weight per Category (Supply Chain View)**

```sql
SELECT category,
       SUM(weightInGms * availableQuantity) / 1000.0 AS total_weight_kg
FROM zepto
GROUP BY category
ORDER BY total_weight_kg DESC;
```
> 💡 **Business Insight:** Total inventory weight by category directly impacts warehouse floor space allocation and carrier cost per delivery. This is a key input for dark store capacity planning.

---

**Q9 · In-Stock Rate per Category (Availability Health)**

```sql
SELECT category,
       COUNT(*) AS total_skus,
       SUM(CASE WHEN outOfStock = FALSE THEN 1 ELSE 0 END) AS in_stock_count,
       ROUND(
           100.0 * SUM(CASE WHEN outOfStock = FALSE THEN 1 ELSE 0 END) / COUNT(*),
           2
       ) AS in_stock_rate_pct
FROM zepto
GROUP BY category
ORDER BY in_stock_rate_pct ASC;
```
> 💡 **Business Insight:** Categories below 70% in-stock rate signal supply chain failures. This metric belongs in a daily operations dashboard to trigger automated restock alerts before customers notice.

---

**Q10 · Discount Behavior Across Price Tiers**

```sql
SELECT
    CASE
        WHEN mrp < 100  THEN 'Budget (< ₹100)'
        WHEN mrp < 300  THEN 'Mid-Range (₹100–₹300)'
        WHEN mrp < 500  THEN 'Premium (₹300–₹500)'
        ELSE                 'Luxury (> ₹500)'
    END AS price_tier,
    COUNT(*)                              AS sku_count,
    ROUND(AVG(discountPercent), 2)        AS avg_discount_pct,
    ROUND(AVG(discountedSellingPrice), 2) AS avg_selling_price
FROM zepto
GROUP BY price_tier
ORDER BY avg_selling_price;
```
> 💡 **Business Insight:** If the luxury tier shows the lowest discounts, Zepto may be leaving conversion on the table for high-value products. If the budget tier carries the highest discounts, the category may be margin-negative and needs repricing.

---

**Q11 · Categories Running Deals on Nearly-Out-of-Stock Items**

```sql
SELECT category,
       ROUND(AVG(discountPercent), 2)   AS avg_discount_pct,
       ROUND(AVG(availableQuantity), 0) AS avg_available_qty,
       COUNT(*)                         AS total_skus
FROM zepto
WHERE outOfStock = FALSE
GROUP BY category
HAVING AVG(discountPercent) > 20
   AND AVG(availableQuantity) < 50
ORDER BY avg_discount_pct DESC;
```
> 💡 **Business Insight:** High discount + low stock is a dangerous combo — customers see attractive deals but can't place orders. This creates frustration and app uninstalls. Always fix stock before running promotions in a category.

---

### 🔴 Advanced Questions (Q12 – Q15)

---

**Q12 · Top 3 Deals per Category — In-Stock Leaderboard** *(Window Function)*

```sql
WITH ranked_products AS (
    SELECT name, category, mrp, discountPercent, discountedSellingPrice,
           RANK() OVER (
               PARTITION BY category
               ORDER BY discountPercent DESC
           ) AS discount_rank
    FROM zepto
    WHERE outOfStock = FALSE
)
SELECT * FROM ranked_products
WHERE discount_rank <= 3
ORDER BY category, discount_rank;
```
> 💡 **Business Insight:** The top-3 discounted in-stock products per category are the "category heroes." Zepto's merchandising team can use this query output to auto-populate deal sections in the app — no manual curation needed.

---

**Q13 · Pareto Analysis — Which Categories Drive 80% of GMV?** *(Running Total + Revenue Share)*

```sql
WITH category_revenue AS (
    SELECT category,
           SUM(discountedSellingPrice * availableQuantity) AS revenue
    FROM zepto
    WHERE outOfStock = FALSE
    GROUP BY category
),
totals AS (
    SELECT *,
           SUM(revenue) OVER ()                       AS grand_total,
           SUM(revenue) OVER (ORDER BY revenue DESC)  AS running_total
    FROM category_revenue
)
SELECT
    category,
    ROUND(revenue, 2)                             AS category_revenue,
    ROUND(100.0 * revenue / grand_total, 2)       AS revenue_share_pct,
    ROUND(100.0 * running_total / grand_total, 2) AS cumulative_pct
FROM totals
ORDER BY revenue DESC;
```
> 💡 **Business Insight:** The `cumulative_pct` column pinpoints exactly which categories collectively cross the 80% GMV threshold. These categories receive maximum inventory priority, promotional budget, and supply chain attention — the rest get optimized for efficiency.

---

**Q14 · Over-Discounting Detection — SKU-Level Margin Outliers** *(Windowed AVG)*

```sql
WITH category_avg AS (
    SELECT *,
           ROUND(AVG(discountPercent) OVER (PARTITION BY category), 2) AS cat_avg_discount
    FROM zepto
)
SELECT name, category, discountPercent, cat_avg_discount,
       ROUND(discountPercent - cat_avg_discount, 2) AS excess_discount_pct
FROM category_avg
WHERE discountPercent > cat_avg_discount + 15
ORDER BY excess_discount_pct DESC;
```
> 💡 **Business Insight:** Products discounted 15%+ above their category average are margin outliers — either intentional clearance items or pricing errors. A category manager should review this list weekly to protect margins from silent leakage.

---

**Q15 · Category Health Score — Executive Dashboard in SQL** *(Multi-CTE + Percentile Scoring)*

```sql
WITH base AS (
    SELECT category,
           COUNT(*)                                                    AS total_skus,
           SUM(CASE WHEN outOfStock = FALSE THEN 1 ELSE 0 END)        AS in_stock_skus,
           ROUND(AVG(discountPercent), 2)                              AS avg_discount,
           ROUND(SUM(discountedSellingPrice * availableQuantity), 2)   AS est_revenue
    FROM zepto
    GROUP BY category
),
scored AS (
    SELECT *,
        ROUND(40.0 * in_stock_skus / NULLIF(total_skus, 0), 1)        AS availability_score,
        CASE
            WHEN avg_discount < 10 THEN 30
            WHEN avg_discount < 20 THEN 20
            WHEN avg_discount < 30 THEN 10
            ELSE 5
        END                                                            AS margin_score,
        CASE
            WHEN est_revenue >= PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY est_revenue) OVER () THEN 30
            WHEN est_revenue >= PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY est_revenue) OVER () THEN 20
            WHEN est_revenue >= PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY est_revenue) OVER () THEN 10
            ELSE 5
        END                                                            AS revenue_score
    FROM base
)
SELECT category, total_skus, in_stock_skus, avg_discount AS avg_discount_pct,
       est_revenue, availability_score, margin_score, revenue_score,
       (availability_score + margin_score + revenue_score) AS health_score,
       CASE
           WHEN (availability_score + margin_score + revenue_score) >= 80 THEN '🟢 Healthy'
           WHEN (availability_score + margin_score + revenue_score) >= 55 THEN '🟡 Needs Attention'
           ELSE '🔴 At Risk'
       END AS category_status
FROM scored
ORDER BY health_score DESC;
```
> 💡 **Business Insight:** A single 0–100 score per category across 3 dimensions: stock availability (40pts), margin health (30pts), and revenue contribution (30pts). Red categories need immediate operational intervention. This is an executive KPI dashboard — built entirely in SQL.

---

## 💡 Key Insights

| # | Finding | Business Impact |
|---|---|---|
| 📉 | Some categories run **avg discounts above 25%** with below-average revenue | Margin erosion without volume payoff — reprice or reduce promos |
| 🚨 | Premium products (MRP > ₹300) going **out of stock** represent direct revenue leakage | Prioritize restocking high-MRP SKUs first |
| ⚖️ | **Price-per-gram** analysis reveals value packs consistently beat small units | Promote value packs to price-sensitive segments |
| 🛑 | Several categories simultaneously carry **high discounts + low stock** | Stop running promos until inventory is replenished |
| 📊 | A small set of categories drives the **majority of estimated GMV** (Pareto effect) | Focus supply chain resources on top-revenue categories |
| 🔍 | SKUs discounted **15%+ above their category average** are likely margin outliers | Weekly category manager review needed |
| 🏥 | Category Health Scoring reveals which categories are **🟢 scaling-ready vs 🔴 at risk** | Data-driven intervention prioritization for ops team |

---

## ⚙️ SQL Concepts Demonstrated

| Concept | Questions | Purpose |
|---|---|---|
| `SELECT DISTINCT` | Q1, Q2, Q4, Q6, Q7 | Eliminate duplicate product name rows |
| `WHERE` (compound) | Q2, Q4, Q6, Q11 | Multi-condition filtering |
| `GROUP BY` + Aggregates | Q3, Q5, Q8, Q9, Q10 | Category-level summaries |
| `HAVING` | Q11, Exploration | Post-aggregation filtering |
| `CASE WHEN` | Q7, Q9, Q10, Q14, Q15 | Conditional segmentation and scoring |
| `ROUND()`, `NULLIF()` | Q6, Q9, Q14, Q15 | Safe arithmetic and clean output |
| **Conditional Aggregation** | Q9, Q15 | `SUM(CASE WHEN ...)` pattern |
| **CTE** (`WITH`) | Q12, Q13, Q14, Q15 | Readable multi-step logic |
| **`RANK() OVER (PARTITION BY)`** | Q12 | Per-category product rankings |
| **`SUM() OVER (ORDER BY)`** | Q13 | Running total (Pareto analysis) |
| **`AVG() OVER (PARTITION BY)`** | Q14 | Compare each row to its group average |
| **`PERCENTILE_CONT() OVER()`** | Q15 | Revenue quartile scoring |
| `UPDATE` / `DELETE` | Data Cleaning | Real-world data pipeline skills |

---

## 🔄 Project Workflow

```
Raw CSV Data
     │
     ▼
Data Exploration ──→ Row counts · NULL checks · Duplicate detection · Category inventory
     │
     ▼
Data Cleaning ──→ Remove zero-MRP · Convert paise to ₹ · Validate schema
     │
     ▼
Basic Analysis (Q1–Q4) ──→ Discounts · Out-of-stock · Revenue · Pricing gaps
     │
     ▼
Medium Analysis (Q5–Q11) ──→ Avg discounts · Price-per-gram · Stock rates · Price tiers
     │
     ▼
Advanced Analysis (Q12–Q15) ──→ Window functions · Pareto GMV · Outlier detection · Health scoring
     │
     ▼
Business Recommendations ──→ Restock priorities · Promo timing · Category investment
```

---

## 🛠️ Setup & Usage

### Prerequisites
- PostgreSQL 13+ (or MySQL 8+)
- pgAdmin / DBeaver / any SQL client

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Yashchaudhary872/Zepto-SQL-Analysis-project.git
cd Zepto-SQL-Analysis-project
```

```sql
-- 2. Create database
CREATE DATABASE zepto_analysis;
\c zepto_analysis

-- 3. Run the SQL file (creates table, cleans data, runs all 15 queries)
\i Zepto_SQL_data_analysis.sql

-- 4. Import the dataset
COPY zepto FROM '/your/path/zepto_v2.csv' DELIMITER ',' CSV HEADER;

-- 5. Run cleaning steps (inside the SQL file, sections clearly marked)
-- 6. Run any of the 15 business queries
```

---

## 📁 Repository Structure

```
Zepto-SQL-Analysis-project/
├── README.md                      ← You are here
├── Zepto_SQL_data_analysis.sql    ← All queries: exploration + cleaning + 15 business Qs
└── zepto_v2.csv                   ← Raw product catalog dataset
```

---

## 🚀 What's Next

- [ ] Power BI dashboard — Revenue by category, in-stock rates, discount heatmap
- [ ] Python (Pandas + Matplotlib) — Visual EDA on top of SQL findings
- [ ] Multi-table extension — Orders + Customers table for cohort and retention analysis
- [ ] Scheduled pipeline — Automate with Apache Airflow for live catalog monitoring

---

## 👤 About Me

**Yash Chaudhary** — B.Tech IT Student | Data Analytics Enthusiast

Passionate about turning raw data into business decisions. This project reflects my approach to SQL: not just writing queries, but asking the right business questions first.

<div align="center">

[![Portfolio](https://img.shields.io/badge/Portfolio-Visit-FF6B35?style=for-the-badge&logo=firefox&logoColor=white)](https://yashchaudharyportfolio.netlify.app/)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/yash--chaudhary--/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Yashchaudhary872)
[![Email](https://img.shields.io/badge/Email-Contact-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:chaudharyyash872@gmail.com)

</div>

---

<div align="center">

*If this project helped you, a ⭐ on GitHub goes a long way!*

**Made with SQL · PostgreSQL · Business Thinking**

</div>
