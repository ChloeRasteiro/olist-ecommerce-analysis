-- Geographic distribution of customers across Brazil
SELECT 
COUNT(customer_id) AS num_customers,
customer_state AS state
FROM customers
GROUP BY customer_state
ORDER BY num_customers DESC;

-- What percentage of customers are one-time buyers vs returning? 
WITH orders_per_customer AS (
SELECT 
c.customer_unique_id, 
COUNT( DISTINCT o.order_id) AS num_orders
FROM customers c 
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status ='delivered'
GROUP BY c.customer_unique_id
), 

customers_segment AS (
SELECT customer_unique_id, num_orders,
CASE
WHEN num_orders = 0 THEN 'No orders'
WHEN num_orders = 1 THEN 'One-time buyer'
ELSE 'Repeat buyer'
END AS customer_type
FROM orders_per_customer
)

SELECT 
customer_type,
COUNT(*) as total_customers,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS pct_customers
FROM customers_segment
GROUP BY customer_type
ORDER BY total_customers DESC;


-- Average basket size by state 
WITH payment_per_order AS 
(SELECT DISTINCT p.order_id, 
SUM(p.payment_value) AS total_pay ,
o.customer_id
FROM order_payments p
LEFT JOIN orders o ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.order_id, o.customer_id
)

SELECT c.customer_state, ROUND(AVG(po.total_pay),2) AS avg_basket 
FROM payment_per_order po
LEFT JOIN customers c ON c.customer_id = po.customer_id
GROUP BY c.customer_state
ORDER BY avg_basket DESC;










