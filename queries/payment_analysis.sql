SELECT DISTINCT payment_type from order_payments

-- Breakdown of payment methods (credit card, boleto, voucher…)
WITH order_totals AS (
SELECT
order_id,
payment_type,
SUM(payment_value) AS total_order_value
FROM order_payments
GROUP BY order_id, payment_type
)
SELECT
payment_type,
COUNT(order_id) AS num_orders,
ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER(), 2) AS pct_orders,
ROUND(AVG(total_order_value), 2) AS avg_order_value,
ROUND(SUM(total_order_value), 2) AS total_revenue
FROM order_totals
WHERE payment_type IN ('credit_card','voucher','debit_card','boleto')
GROUP BY payment_type
ORDER BY pct_orders DESC;

-- Do customers who pay in installments spend more?
WITH order_payment_summary AS (
SELECT order_id, 
MAX(payment_installments) AS installments, 
SUM(payment_value) AS sum_pay
FROM order_payments
GROUP BY order_id)

SELECT installments, 
COUNT(order_id) AS num_order, 
ROUND(AVG(sum_pay),2) AS avg_pay
FROM order_payment_summary
WHERE installments>0 
GROUP BY installments
ORDER BY installments;


