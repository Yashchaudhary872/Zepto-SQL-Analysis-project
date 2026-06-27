-- ============================================================
-- ZEPTO SQL DATA ANALYSIS PROJECT
-- 15 Business Questions | Basic → Medium → Advanced
-- Dataset: Zepto Product Catalog | Tool: PostgreSQL
-- ============================================================

-- ─────────────────────────────────────────────
-- TABLE CREATION
-- ─────────────────────────────────────────────

DROP TABLE IF EXISTS zepto;

CREATE TABLE zepto (
    sku_id                 SERIAL PRIMARY KEY,
    category               VARCHAR(120),
    name                   VARCHAR(150) NOT NULL,
    mrp                    NUMERIC(8,2),
    discountPercent        NUMERIC(5,2),
    availableQuantity      INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms            INTEGER,
    outOfStock             BOOLEAN,
    quantity               INTEGER
);

-- ─────────────────────────────────────────────
-- DATA EXPLORATION
-- ─────────────────────────────────────────────

-- Total row count
SELECT COUNT(*) FROM zepto;

-- Sample data
SELECT * FROM zepto LIMIT 10;

-- Check for NULL values
SELECT * FROM zepto
WHERE name IS NULL
   OR category IS NULL
   OR mrp IS NULL
   OR discountPercent IS NULL
   OR discountedSellingPrice IS NULL
   OR weightInGms IS NULL
   OR availableQuantity IS NULL
   OR outOfStock IS NULL
   OR quantity IS NULL;

-- Distinct product categories
SELECT DISTINCT category FROM zepto ORDER BY category;

-- In-stock vs Out-of-stock count
SELECT outOfStock, COUNT(sku_id) AS product_count
FROM zepto
GROUP BY outOfStock;

-- Products listed more than once (multi-SKU detection)
SELECT name, COUNT(sku_id) AS sku_count
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) > 1
ORDER BY COUNT(sku_id) DESC;

-- ─────────────────────────────────────────────
-- DATA CLEANING
-- ─────────────────────────────────────────────

-- Identify zero-priced records
SELECT * FROM zepto WHERE mrp = 0 OR discountedSellingPrice = 0;

-- Remove zero-MRP records
DELETE FROM zepto WHERE mrp = 0;

-- Convert paise → rupees
UPDATE zepto
SET mrp                    = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

-- Verify conversion
SELECT mrp, discountedSellingPrice FROM zepto LIMIT 5;


-- ============================================================
-- 🟢 BASIC QUESTIONS (Q1 – Q4)
-- ============================================================

-- Q1. Top 10 Best-Value Products by Discount Percentage
-- Business use: Identify hero deals for marketing campaigns
-- SQL: ORDER BY, LIMIT, DISTINCT

SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

/*
Insight: These are your "deal anchor" products. Zepto can feature
them in push notifications or homepage banners to drive app opens.
*/


-- Q2. High-MRP Products That Are Out of Stock
-- Business use: Revenue leakage detection — premium SKUs losing sales
-- SQL: WHERE with multiple conditions, ORDER BY

SELECT DISTINCT name, mrp
FROM zepto
WHERE outOfStock = TRUE AND mrp > 300
ORDER BY mrp DESC;

/*
Insight: Every day these are out of stock is lost revenue on
high-margin items. These should be first-priority restocks.
*/


-- Q3. Estimated Revenue Potential per Category
-- Business use: Category-level investment prioritization
-- SQL: GROUP BY, SUM, aggregate functions

SELECT category,
       SUM(discountedSellingPrice * availableQuantity) AS estimated_revenue
FROM zepto
WHERE outOfStock = FALSE
GROUP BY category
ORDER BY estimated_revenue DESC;

/*
Insight: Understand which categories drive the most GMV.
Redirect procurement budget toward top-revenue categories.
*/


-- Q4. Premium Products with Suspiciously Low Discounts
-- Business use: Find conversion opportunities — price-sensitive customers
-- SQL: WHERE with compound filter, ORDER BY

SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC;

/*
Insight: High-priced, low-discount products may lose to competitors.
A targeted 5–10% flash discount could improve conversion significantly.
*/


-- ============================================================
-- 🟡 MEDIUM QUESTIONS (Q5 – Q11)
-- ============================================================

-- Q5. Top 5 Categories by Average Discount Offered
-- Business use: Identify margin-eroding categories
-- SQL: AVG, GROUP BY, ROUND, LIMIT

SELECT category,
       ROUND(AVG(discountPercent), 2) AS avg_discount_pct
FROM zepto
GROUP BY category
ORDER BY avg_discount_pct DESC
LIMIT 5;

/*
Insight: Categories with avg discount > 25% may be sacrificing margin
for volume. Cross-check with Q3 revenue to see if the trade-off is worth it.
*/


-- Q6. Price-per-Gram Analysis — Best Value Products Above 100g
-- Business use: Help price-conscious customers find value packs
-- SQL: Derived column (arithmetic), WHERE, ORDER BY

SELECT DISTINCT name,
       weightInGms,
       discountedSellingPrice,
       ROUND(discountedSellingPrice / NULLIF(weightInGms, 0), 4) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram ASC;

/*
Insight: "Best value per gram" is a powerful consumer metric in
grocery. Zepto can surface these in a "Value Picks" section.
*/


-- Q7. Product Weight Segmentation (Low / Medium / Bulk)
-- Business use: Delivery slot optimization and packaging cost planning
-- SQL: CASE WHEN, DISTINCT

SELECT DISTINCT name,
       weightInGms,
       CASE
           WHEN weightInGms < 1000 THEN 'Low'
           WHEN weightInGms < 5000 THEN 'Medium'
           ELSE 'Bulk'
       END AS weight_segment
FROM zepto
ORDER BY weightInGms DESC;

/*
Insight: Bulk items (> 5kg) need different delivery handling.
Knowing the split helps logistics plan bike vs vehicle allocation per order.
*/


-- Q8. Total Inventory Weight per Category (Supply Chain View)
-- Business use: Warehouse space planning and carrier cost allocation
-- SQL: SUM, GROUP BY, ORDER BY

SELECT category,
       SUM(weightInGms * availableQuantity) / 1000.0 AS total_weight_kg
FROM zepto
GROUP BY category
ORDER BY total_weight_kg DESC;

/*
Insight: Categories with heavy inventory need more warehouse floor space
and affect last-mile delivery cost per order.
*/


-- Q9. Stock Health Check — In-Stock Rate per Category
-- Business use: Operations monitoring — which categories have availability issues
-- SQL: CASE WHEN inside SUM (conditional aggregation), ROUND, GROUP BY

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

/*
Insight: Categories with < 70% in-stock rate signal supply chain issues.
This metric belongs in a daily ops dashboard to trigger restock alerts.
*/


-- Q10. Discount vs MRP Correlation Buckets
-- Business use: Understand pricing strategy across price tiers
-- SQL: CASE WHEN for multi-column bucketing, GROUP BY, AVG

SELECT
    CASE
        WHEN mrp < 100  THEN 'Budget (< ₹100)'
        WHEN mrp < 300  THEN 'Mid-Range (₹100–₹300)'
        WHEN mrp < 500  THEN 'Premium (₹300–₹500)'
        ELSE                 'Luxury (> ₹500)'
    END AS price_tier,
    COUNT(*)                         AS sku_count,
    ROUND(AVG(discountPercent), 2)   AS avg_discount_pct,
    ROUND(AVG(discountedSellingPrice), 2) AS avg_selling_price
FROM zepto
GROUP BY price_tier
ORDER BY avg_selling_price;

/*
Insight: If the luxury tier has lowest discounts, Zepto may be
leaving conversion on the table. If budget tier has highest discounts,
it may be margin-negative. Either finding drives a pricing discussion.
*/


-- Q11. Categories with Both High Discount AND Low Availability
-- Business use: Detects the dangerous combo — heavy deals on items running out
-- SQL: GROUP BY, HAVING with multiple aggregate conditions

SELECT category,
       ROUND(AVG(discountPercent), 2)     AS avg_discount_pct,
       ROUND(AVG(availableQuantity), 0)   AS avg_available_qty,
       COUNT(*)                           AS total_skus
FROM zepto
WHERE outOfStock = FALSE
GROUP BY category
HAVING AVG(discountPercent) > 20
   AND AVG(availableQuantity) < 50
ORDER BY avg_discount_pct DESC;

/*
Insight: Running a sale on items nearly out of stock creates bad UX —
customers see deals but can't order. Fix stock before running promotions.
*/


-- ============================================================
-- 🔴 ADVANCED QUESTIONS (Q12 – Q15)
-- ============================================================

-- Q12. Rank Products Within Each Category by Discount (Window Function)
-- Business use: Category-level deal leaderboard for merchandising teams
-- SQL: RANK() OVER (PARTITION BY ... ORDER BY ...), CTE

WITH ranked_products AS (
    SELECT
        name,
        category,
        mrp,
        discountPercent,
        discountedSellingPrice,
        RANK() OVER (
            PARTITION BY category
            ORDER BY discountPercent DESC
        ) AS discount_rank
    FROM zepto
    WHERE outOfStock = FALSE
)
SELECT *
FROM ranked_products
WHERE discount_rank <= 3
ORDER BY category, discount_rank;

/*
Insight: The top-3 discounted in-stock products per category are your
"category heroes." Zepto's merchandising team can use this to auto-populate
deal sections in the app without manual curation.
*/


-- Q13. Revenue Contribution % per Category (Running Total + Share)
-- Business use: Pareto / 80-20 analysis — find which categories drive 80% of GMV
-- SQL: SUM() OVER(), ROUND, derived percentage, CTE chain

WITH category_revenue AS (
    SELECT
        category,
        SUM(discountedSellingPrice * availableQuantity) AS revenue
    FROM zepto
    WHERE outOfStock = FALSE
    GROUP BY category
),
totals AS (
    SELECT *,
           SUM(revenue) OVER ()                         AS grand_total,
           SUM(revenue) OVER (ORDER BY revenue DESC)    AS running_total
    FROM category_revenue
)
SELECT
    category,
    ROUND(revenue, 2)                                       AS category_revenue,
    ROUND(100.0 * revenue / grand_total, 2)                 AS revenue_share_pct,
    ROUND(100.0 * running_total / grand_total, 2)           AS cumulative_pct
FROM totals
ORDER BY revenue DESC;

/*
Insight: Cumulative % column shows exactly when you've crossed 80% GMV.
The categories before that threshold get maximum inventory and promo budget.
This is the classic Pareto / ABC analysis every business analyst does.
*/


-- Q14. Detect Over-Discounting: Products Where Discount Exceeds Category Average
-- Business use: Margin protection — flag SKUs with outlier discounts
-- SQL: AVG() OVER (PARTITION BY), CTE, self-comparison

WITH category_avg AS (
    SELECT *,
           ROUND(AVG(discountPercent) OVER (PARTITION BY category), 2) AS cat_avg_discount
    FROM zepto
)
SELECT
    name,
    category,
    discountPercent,
    cat_avg_discount,
    ROUND(discountPercent - cat_avg_discount, 2) AS excess_discount_pct
FROM category_avg
WHERE discountPercent > cat_avg_discount + 15   -- 15% above category average
ORDER BY excess_discount_pct DESC;

/*
Insight: SKUs discounted 15%+ above their category average are outliers.
Either it's intentional clearance, or a pricing error. Either way, a
category manager should review these flagged products weekly.
*/


-- Q15. Comprehensive Product Health Score per Category
-- Business use: Single-number executive KPI combining revenue, availability & discount
-- SQL: Multiple CTEs, window functions, CASE WHEN scoring, ROUND

WITH base AS (
    SELECT
        category,
        COUNT(*)                                               AS total_skus,
        SUM(CASE WHEN outOfStock = FALSE THEN 1 ELSE 0 END)   AS in_stock_skus,
        ROUND(AVG(discountPercent), 2)                         AS avg_discount,
        ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS est_revenue
    FROM zepto
    GROUP BY category
),
scored AS (
    SELECT *,
        -- Availability Score (0–40 points)
        ROUND(40.0 * in_stock_skus / NULLIF(total_skus, 0), 1) AS availability_score,
        -- Discount Health Score (0–30 points: lower avg discount = healthier margin)
        CASE
            WHEN avg_discount < 10 THEN 30
            WHEN avg_discount < 20 THEN 20
            WHEN avg_discount < 30 THEN 10
            ELSE 5
        END AS margin_score,
        -- Revenue Score (0–30 points: top quartile gets full marks)
        CASE
            WHEN est_revenue >= PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY est_revenue) OVER () THEN 30
            WHEN est_revenue >= PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY est_revenue) OVER () THEN 20
            WHEN est_revenue >= PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY est_revenue) OVER () THEN 10
            ELSE 5
        END AS revenue_score
    FROM base
)
SELECT
    category,
    total_skus,
    in_stock_skus,
    avg_discount         AS avg_discount_pct,
    est_revenue,
    availability_score,
    margin_score,
    revenue_score,
    (availability_score + margin_score + revenue_score) AS health_score,
    CASE
        WHEN (availability_score + margin_score + revenue_score) >= 80 THEN '🟢 Healthy'
        WHEN (availability_score + margin_score + revenue_score) >= 55 THEN '🟡 Needs Attention'
        ELSE '🔴 At Risk'
    END AS category_status
FROM scored
ORDER BY health_score DESC;

/*
Insight: This is a single-page executive dashboard in SQL form.
Each category gets a 0–100 health score across three dimensions:
availability, margin health, and revenue contribution. Red categories
need immediate action; green ones can be scaled.

This query alone shows you can think like a business analyst,
not just a SQL developer.
*/
