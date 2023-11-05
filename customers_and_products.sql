USE mavenfuzzyfactory;

# Used tables in this assignment
SELECT * FROM order_item_refunds;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM website_sessions;

# Customers Analysis

# Overall information and Key Metrics: customer types breakdown of sessions, orders, conversion rates,
# revenue, costs for different sessions, devices, and traffic sources over a specified date period

WITH source_table AS (
	SELECT s.website_session_id, s.created_at, order_id, price_usd, cogs_usd, device_type, s.user_id,
		CASE WHEN is_repeat_session = 1 THEN 'repeated_session' ELSE 'single_session'END AS type_of_session,
        CASE WHEN utm_source IS NOT NULL THEN 'paid'
		WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct type in'
		WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic search'
        END AS traffic_source
	FROM website_sessions AS s
	LEFT JOIN orders AS o
	ON o.website_session_id = s.website_session_id
	WHERE s.created_at BETWEEN '2013-01-01' AND '2014-06-01'
)

SELECT YEAR(created_at) AS year, QUARTER(created_at) AS quarter, MONTHNAME(created_at) AS month_name,
	MONTH(created_at) AS month, type_of_session, device_type, traffic_source,
	COUNT(website_session_id) AS sessions, COUNT(order_id) AS orders, COUNT(DISTINCT user_id) AS customers,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rate, COALESCE(SUM(price_usd - cogs_usd), 0) AS profit,
    COALESCE(ROUND(SUM(price_usd) / COUNT(website_session_id), 2), 0) AS revenue_per_session
FROM source_table
GROUP BY 1, 2, 3, 4, 5, 6, 7;


# Analyzing seasonality and patterns: amount of orders and sessions throughout the week and at different times of the day.

WITH source_table AS (
	SELECT s.website_session_id, s.created_at, order_id,
		CASE WHEN TIME(s.created_at) >= '00:00:00' AND TIME(s.created_at) < '06:00:00' THEN 'Night'
			WHEN TIME(s.created_at) >= '06:00:00' AND TIME(s.created_at) < '12:00:00' THEN 'Morning'
			WHEN TIME(s.created_at) >= '12:00:00' AND TIME(s.created_at) < '18:00:00' THEN 'Afternoon'
			WHEN TIME(s.created_at) >= '18:00:00' THEN 'Evening'
			END AS time_of_day,
		CASE WHEN is_repeat_session = 1 THEN 'repeated_session' ELSE 'single_session'END AS repeated_session
	FROM website_sessions AS s
	LEFT JOIN orders AS o
	ON o.website_session_id = s.website_session_id
	WHERE s.created_at BETWEEN '2013-01-01' AND '2014-06-01'
)

SELECT DAYOFWEEK(created_at) AS day_of_week, time_of_day, repeated_session,
	COUNT(website_session_id) AS sessions, COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rate
FROM source_table
GROUP BY 1, 2, 3
ORDER BY 1 ASC;


# Average time of the second order by the user (repeated_sessions)

WITH source_table AS (
	SELECT *, DATEDIFF(created_at, previous_session_time) AS date_diff
	FROM (
		SELECT website_session_id, created_at, user_id, is_repeat_session,
			LAG(created_at) OVER (PARTITION BY user_id ORDER BY created_at ASC) AS previous_session_time
		FROM website_sessions
		WHERE created_at BETWEEN '2013-01-01' AND '2014-06-01'
			AND user_id IN (SELECT user_id FROM website_sessions GROUP BY user_id HAVING COUNT(website_session_id) > 1)
	) AS t1
	WHERE previous_session_time IS NOT NULL
)

SELECT YEAR(created_at) AS year, QUARTER(created_at) AS quarter,
	MONTHNAME(created_at) AS month_name, MONTH(created_at) AS month,
    AVG(date_diff) AS avg_return_time
FROM source_table
GROUP BY 1, 2, 3, 4;


# Products

# Overall information and Key Metrics: products breakdown of quantity, prodit, refunds over a specified date period

WITH source_table AS (
	SELECT o.order_id, o.created_at, o.items_purchased, o.price_usd - o.cogs_usd AS profit_order,
		product_name, oi.order_item_id, oi.price_usd - oi.cogs_usd AS profit_product, oif.order_item_refund_id, refund_amount_usd
	FROM orders AS o
	LEFT JOIN order_items AS oi
	ON o.order_id = oi.order_id
	LEFT JOIN products AS p
	ON oi.product_id = p.product_id
	LEFT JOIN order_item_refunds AS oif 
	ON oi.order_item_id = oif.order_item_id
	WHERE o.created_at BETWEEN '2013-01-01' AND '2014-06-01'
)

SELECT YEAR(created_at) AS year, QUARTER(created_at) AS quarter,
	MONTHNAME(created_at) AS month_name, MONTH(created_at) AS month, product_name,
	COUNT(order_item_id) AS quantity, SUM(profit_product) AS profit,
    SUM(refund_amount_usd) AS refund_amount
FROM source_table
GROUP BY 1, 2, 3, 4, 5;


# Analysis of single vs. multiple product orders over time

SELECT YEAR(created_at) AS year, QUARTER(created_at) AS quarter,
	MONTHNAME(created_at) AS month_name, MONTH(created_at) AS month, items_purchased,
	COUNT(order_id) AS orders, SUM(price_usd - cogs_usd) AS profit
FROM orders
WHERE created_at BETWEEN '2013-01-01' AND '2014-06-01'
GROUP BY 1, 2, 3, 4, 5;


# Cross-sell Analysis: Identify which products are often sell together over a specified date period

WITH source_table AS (
	SELECT o.order_id, o.created_at, primary_product_id, items_purchased, o.price_usd - o.cogs_usd AS order_profit,
		product_id, is_primary_item,
		CASE WHEN primary_product_id = product_id THEN NULL ELSE product_id END AS cross_sell_product
	FROM orders AS o
	LEFT JOIN order_items AS oi
	ON o.order_id = oi.order_id
	WHERE o.created_at BETWEEN '2013-01-01' AND '2014-06-01'
)

SELECT primary_product_id, p1.product_name, cross_sell_product, p2.product_name,
	COUNT(DISTINCT order_id) AS orders, SUM(order_profit) AS order_profit
FROM source_table AS s
LEFT JOIN products AS p1
ON primary_product_id = p1.product_id
LEFT JOIN products AS p2
ON cross_sell_product = p2.product_id
GROUP BY 1, 2, 3, 4
ORDER BY primary_product_id ASC, order_profit DESC;


