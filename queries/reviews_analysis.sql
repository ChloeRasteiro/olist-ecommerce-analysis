
-- Distribution of review scores (1 to 5) in percentage
SELECT review_score,
COUNT(*) AS num_reviews,
ROUND( COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- Are negative reviews (1, 2) linked to late deliveries?
WITH reviews_with_delivery AS
(SELECT o.order_id, ore.review_score, 
CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
ELSE 'On time'
END AS order_state
FROM orders o 
LEFT JOIN order_reviews ore ON o.order_id = ore.order_id
WHERE order_status='delivered' AND o.order_delivered_customer_date IS NOT NULL AND ore.review_score IS NOT NULL)

SELECT 
review_score,
COUNT(*) FILTER (WHERE order_state='On time') AS num_on_time,
COUNT(*) FILTER (WHERE order_state = 'Late') AS num_late,
ROUND(COUNT(*) FILTER (WHERE order_state = 'Late') * 100.0 / COUNT(*), 2) AS pct_late
FROM reviews_with_delivery
GROUP BY review_score

-- Which product categories have the best and worst ratings?

WITH category_scores AS (
SELECT 
p.product_category_name,
ROUND(AVG(ore.review_score), 2) AS avg_score,
COUNT(ore.review_id) AS num_reviews
FROM products p
LEFT JOIN order_items oi    ON p.product_id = oi.product_id
LEFT JOIN order_reviews ore ON oi.order_id  = ore.order_id
WHERE ore.review_score IS NOT NULL 
AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING COUNT(ore.review_id) >= 30  
)

SELECT * FROM (
SELECT *, 'best' AS rank_type 
FROM category_scores 
ORDER BY avg_score DESC 
LIMIT 10 ) AS best_categories

UNION ALL 

SELECT * FROM (
SELECT *, 'worst' AS rank_type 
FROM category_scores 
ORDER BY avg_score ASC 
LIMIT 10) AS worst_categories

ORDER BY rank_type, avg_score DESC;

-- Does Olist respond faster to negative reviews?

WITH review_response_time AS(
SELECT 
review_score,
EXTRACT(EPOCH FROM (review_answer_timestamp - review_creation_date)) /3600 AS response_hours
FROM order_reviews
WHERE review_answer_timestamp IS NOT NULL AND review_creation_date IS NOT NULL)

SELECT review_score, 
ROUND(AVG(response_hours),1) AS avg_response_hours,
ROUND(AVG(response_hours)/24,1) AS avg_response_days
FROM review_response_time 
GROUP BY review_score
ORDER BY review_score;













