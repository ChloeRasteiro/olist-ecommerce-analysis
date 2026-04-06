-- Top 10 sellers by revenue generated
SELECT 
oi.seller_id,
COUNT(DISTINCT oi.order_id)             AS num_orders,
ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;


--Percentile Analysis
WITH seller_metrics AS (
SELECT 
oi.seller_id,
ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
COUNT(DISTINCT oi.order_id) AS num_orders,
ROUND(AVG(DISTINCT ore.review_score), 2) AS avg_review,
ROUND(
COUNT(DISTINCT CASE 
WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
THEN oi.order_id 
END) * 100.0 / COUNT(DISTINCT oi.order_id), 2
) AS on_time_rate
FROM order_items oi
LEFT JOIN order_reviews ore ON ore.order_id = oi.order_id
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
)
SELECT
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) AS p75_revenue,
PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_revenue) AS p90_revenue,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_review) AS median_review,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY on_time_rate) AS median_ontime
FROM seller_metrics;

-- Seller segmentation: High Value / At Risk / Low Performer
WITH seller_metrics AS (
SELECT 
oi.seller_id,
ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
COUNT(DISTINCT oi.order_id) AS num_orders,
ROUND(AVG(DISTINCT ore.review_score), 2) AS avg_review,
ROUND(
COUNT(DISTINCT CASE 
WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
THEN oi.order_id 
END) * 100.0 / COUNT(DISTINCT oi.order_id), 2
) AS on_time_rate
FROM order_items oi
LEFT JOIN order_reviews ore ON ore.order_id = oi.order_id
LEFT JOIN orders o ON o.order_id   = oi.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
)
SELECT 
seller_id,
total_revenue,
num_orders,
avg_review,
on_time_rate,
CASE 
WHEN total_revenue > 11578 
AND avg_review    >= 3.33
AND on_time_rate  >= 90   THEN 'High Value'
WHEN avg_review < 3.33
OR on_time_rate< 90  THEN 'At Risk'
ELSE 'Low Performer'
END AS segment
FROM seller_metrics
ORDER BY total_revenue DESC;








