-- Which states have the highest late delivery rate?

SELECT 
c.customer_state AS state,
COUNT(o.order_id) AS total_orders,
COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS late_orders,
ROUND(COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) * 100.0 / COUNT(o.order_id), 2) AS pct_late
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL 
AND o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY pct_late DESC;

-- What percentage of orders arrive late?
WITH total_delivered_orders AS (
SELECT order_id,
CASE
WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
ELSE 'On time'
END AS status_delivered
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
)

SELECT 
status_delivered, 
COUNT(*) AS num_orders,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS pct_orders
FROM total_delivered_orders
GROUP BY status_delivered;

-- Are delays concentrated on specific sellers?
WITH seller_stats AS (
SELECT
s.seller_id,
COUNT(DISTINCT o.order_id) AS total_orders,
COUNT(DISTINCT CASE 
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
THEN o.order_id 
END) AS late_orders
FROM sellers s
LEFT JOIN order_items oi ON oi.seller_id = s.seller_id
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_id
)
SELECT
seller_id,
total_orders,
late_orders,
ROUND(late_orders * 100.0 / total_orders, 2) AS pct_late,
RANK() OVER (ORDER BY late_orders * 1.0 / total_orders DESC) AS late_rank
FROM seller_stats
WHERE total_orders >= 10
ORDER BY pct_late DESC;

-- Do late orders get significantly lower review scores?
WITH order_status AS 
(SELECT o.order_id,
CASE
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
ELSE 'On Time'
END AS delivery_status
FROM orders o 
WHERE order_status='delivered' AND o.order_delivered_customer_date IS NOT NULL),

last_order_review AS (
SELECT DISTINCT ON (order_id) order_id, review_score
FROM order_reviews
ORDER BY order_id, review_answer_timestamp DESC
)

SELECT os.delivery_status, COUNT(DISTINCT os.order_id) as num_order, ROUND(AVG(lo.review_score),2) as avg_score,
COUNT(*) FILTER (WHERE lo.review_score =5) AS score_5,
COUNT(*) FILTER (WHERE lo.review_score =4) AS score_4, 
COUNT(*) FILTER (WHERE lo.review_score <=3) AS score_1_to_3, 
ROUND(COUNT(*) FILTER (WHERE lo.review_score <= 3) *100.0 / COUNT(*),2) as pct_bad_reviews
FROM order_status os
LEFT JOIN last_order_review lo ON lo.order_id = os.order_id
GROUP BY os.delivery_status
ORDER BY avg_score DESC;



