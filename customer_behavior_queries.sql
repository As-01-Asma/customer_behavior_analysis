-- ============================================================
-- Customer Shopping Behavior Analysis - Business Insight Queries
-- Database: PostgreSQL | Table: customer
-- ============================================================

-- Q1. Revenue by gender
SELECT gender, SUM(purchase_amount) AS revenue
FROM customer
GROUP BY gender;

-- Q2. Customers who used a discount but spent more than the average purchase amount
SELECT customer_id, purchase_amount
FROM customer
WHERE discount_applied = 'Yes'
  AND purchase_amount > (SELECT AVG(purchase_amount) FROM customer);

-- Q3. Top 5 products with the highest average review rating
SELECT item_purchased,
       ROUND(AVG(review_rating)::numeric, 2) AS "Average Product Rating"
FROM customer
GROUP BY item_purchased
ORDER BY AVG(review_rating) DESC
LIMIT 5;

-- Q4. Average purchase amount: Standard vs Express shipping
SELECT shipping_type,
       ROUND(AVG(purchase_amount), 2) AS avg_purchase_amount
FROM customer
WHERE shipping_type IN ('Standard', 'Express')
GROUP BY shipping_type;

-- Q5. Subscribers vs non-subscribers: customers, average spend, total revenue
SELECT subscription_status,
       COUNT(customer_id)             AS total_customers,
       ROUND(AVG(purchase_amount), 2) AS avg_spend,
       ROUND(SUM(purchase_amount), 2) AS total_revenue
FROM customer
GROUP BY subscription_status
ORDER BY total_revenue, avg_spend DESC;

-- Q6. Top 5 products with the highest percentage of discounted purchases
SELECT item_purchased,
       ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS discount_rate
FROM customer
GROUP BY item_purchased
ORDER BY discount_rate DESC
LIMIT 5;

-- Q7. Customer segmentation: New (1 purchase), Returning (2-10), Loyal (more than 10)
WITH customer_type AS (
    SELECT customer_id,
           previous_purchases,
           CASE
               WHEN previous_purchases = 1 THEN 'New'
               WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
               ELSE 'Loyal'
           END AS customer_segment
    FROM customer
)
SELECT customer_segment, COUNT(*) AS "Number of Customers"
FROM customer_type
GROUP BY customer_segment;

-- Q8. Top 3 most purchased products within each category (ties kept)
WITH item_counts AS (
    SELECT category,
           item_purchased,
           COUNT(customer_id) AS total_orders,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY COUNT(customer_id) DESC) AS item_rank
    FROM customer
    GROUP BY category, item_purchased
)
SELECT item_rank, category, item_purchased, total_orders
FROM item_counts
WHERE item_rank <= 3;

-- Q9. Repeat buyers (more than 5 previous purchases) by subscription status
SELECT subscription_status,
       COUNT(customer_id) AS repeat_buyers
FROM customer
WHERE previous_purchases > 5
GROUP BY subscription_status;

-- Q9 (extended). Same, with the share of each group
SELECT subscription_status,
       COUNT(*) FILTER (WHERE previous_purchases > 5) AS repeat_buyers,
       COUNT(*) AS total_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE previous_purchases > 5) / COUNT(*), 2) AS pct_repeat
FROM customer
GROUP BY subscription_status;

-- Q10. Revenue by age group (bins match the Power BI dashboard: 40 / 55 / 65)
SELECT CASE
           WHEN age_group <= 40 THEN 'Young Adult'
           WHEN age_group BETWEEN 41 AND 55 THEN 'Middle-aged'
           WHEN age_group BETWEEN 56 AND 65 THEN 'Adult'
           ELSE 'Senior'
       END AS age_category,
       SUM(purchase_amount) AS total_revenue
FROM customer
GROUP BY age_category
ORDER BY total_revenue DESC;
