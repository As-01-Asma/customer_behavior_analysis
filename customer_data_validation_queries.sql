-- ============================================================
-- Customer Shopping Behavior Analysis - Data Validation Queries
-- Database: PostgreSQL | Table: customer
-- Expected values come from the raw CSV (3,900 rows)
-- ============================================================

-- ---- Data fix applied once: fill the 37 missing review ratings with the category median
-- (matches the pandas imputation). Run only if V1 shows null_ratings = 37.
-- UPDATE customer c
-- SET review_rating = m.med
-- FROM (SELECT category,
--              PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY review_rating) AS med
--       FROM customer GROUP BY category) m
-- WHERE c.category = m.category AND c.review_rating IS NULL;

-- V1. Row count, duplicates, nulls, KPI values
-- Expect: 3900 | 3900 | 0 | 59.76 | 3.75 | 233081
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS unique_customers,
       COUNT(*) - COUNT(review_rating) AS null_ratings,
       ROUND(AVG(purchase_amount), 2) AS avg_purchase,
       ROUND(AVG(review_rating)::numeric, 2) AS avg_rating,
       SUM(purchase_amount) AS total_revenue
FROM customer;

-- V2. Subscription split (dashboard donut)
-- Expect: No 2847 (73.00) | Yes 1053 (27.00)
SELECT subscription_status, COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM customer
GROUP BY subscription_status;

-- V3. Revenue and orders by category (dashboard: Revenue by Category / Sales by Category)
-- Expect: Clothing 104264/1737 | Accessories 74200/1240 | Footwear 36093/599 | Outerwear 18524/324
SELECT category, SUM(purchase_amount) AS revenue, COUNT(*) AS orders
FROM customer
GROUP BY category
ORDER BY revenue DESC;

-- V4. Proof that the old "Sales by Category" measure summed Customer ID
-- Expect: Clothing 3402678 | Accessories 2412422 | Footwear 1173896 | Outerwear 617954
SELECT category, SUM(customer_id) AS sum_of_customer_id
FROM customer
GROUP BY category
ORDER BY 2 DESC;

-- V5. What the age_group column holds
SELECT age_group, MIN(age) AS min_age, MAX(age) AS max_age, COUNT(*) AS n
FROM customer
GROUP BY age_group
ORDER BY MIN(age);

-- V6. Revenue and orders by age category (dashboard bins 40 / 55 / 65)
-- Expect: Young Adult 100472/1674 | Middle-aged 67353/1121 | Adult 44352/750 | Senior 20904/355
SELECT CASE WHEN age <= 40 THEN 'Young Adult'
            WHEN age BETWEEN 41 AND 55 THEN 'Middle-aged'
            WHEN age BETWEEN 56 AND 65 THEN 'Adult'
            ELSE 'Senior' END AS age_category,
       SUM(purchase_amount) AS revenue, COUNT(*) AS orders
FROM customer
GROUP BY 1
ORDER BY revenue DESC;

-- V7. Repeat buyers with percentages
-- Expect: No 2518 of 2847 = 88.44 | Yes 958 of 1053 = 90.98
SELECT subscription_status,
       COUNT(*) FILTER (WHERE previous_purchases > 5) AS repeat_buyers,
       COUNT(*) AS total,
       ROUND(100.0 * COUNT(*) FILTER (WHERE previous_purchases > 5) / COUNT(*), 2) AS pct_repeat
FROM customer
GROUP BY subscription_status;

-- V8. Category / value checks (no typos or split groups)
-- Expect: 2 genders | 4 categories | 2 subscription values | 6 shipping types
SELECT COUNT(DISTINCT gender) AS genders,
       COUNT(DISTINCT category) AS categories,
       COUNT(DISTINCT subscription_status) AS sub_values,
       COUNT(DISTINCT shipping_type) AS shipping_types
FROM customer;

-- V9. Range checks (no out-of-range values)
-- Expect: min_age 18 | max_age 70 | min_amt 20 | max_amt 100 | min_rating 2.5 | max_rating 5.0
SELECT MIN(age) AS min_age, MAX(age) AS max_age,
       MIN(purchase_amount) AS min_amt, MAX(purchase_amount) AS max_amt,
       MIN(review_rating) AS min_rating, MAX(review_rating) AS max_rating
FROM customer;
