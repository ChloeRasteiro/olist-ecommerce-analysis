--Total Revenue
WITH order_revenue AS (
SELECT order_id, 
SUM(payment_value) AS total_pay
FROM order_payments
GROUP BY order_id)
SELECT ROUND(SUM(r.total_pay), 2) AS total_revenue
FROM orders o
LEFT JOIN order_revenue r ON r.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable');

--Average Review Score
SELECT ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_reviews
WHERE review_score IS NOT NULL;

-- Monthly revenue trend
SELECT 
TO_CHAR(o.order_purchase_timestamp, 'MM-YYYY') AS year_month,
COUNT(DISTINCT o.order_id) as num_orders,
SUM(op.payment_value) AS total_revenu
FROM orders o
LEFT JOIN order_payments op ON op.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY TO_CHAR(o.order_purchase_timestamp, 'MM-YYYY')
ORDER BY MIN(o.order_purchase_timestamp) ASC;

-- Which product categories generate the most revenue?
SELECT 
COALESCE(t.product_category_name_english, p.product_category_name) AS category,
COUNT(distinct oi.order_id) AS num_orders,
SUM(oi.price+oi.freight_value) AS total_revenue
FROM products p 
LEFT JOIN order_items oi ON oi.product_id=p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN product_category_name_translation t ON t.product_category_name = p.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
AND p.product_category_name IS NOT NULL
GROUP BY t.product_category_name_english, p.product_category_name
ORDER BY total_revenue DESC LIMIT 12;


-- Is there a seasonal pattern in orders?

SELECT 
EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month_num,
TO_CHAR(o.order_purchase_timestamp, 'Month') AS month_name,
COUNT(DISTINCT o.order_id) AS num_orders,
ROUND(AVG(op.payment_value), 2) AS avg_order_value
FROM orders o
LEFT JOIN order_payments op ON op.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY month_num, month_name
ORDER BY month_num;





