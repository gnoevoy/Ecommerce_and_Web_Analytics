
![1](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/824251bc-29f4-40d5-8d2f-3f6661697bc1)

```sql
-- define new and returning visitors
WITH new_vs_returning AS (
	SELECT *, CASE WHEN created_at = first_entry THEN 1 ELSE 0 END AS is_new_visit
	FROM (
		SELECT created_at, user_id, MIN(created_at) OVER (PARTITION BY user_id ORDER BY user_id, created_at ASC) AS first_entry
		FROM website_sessions_2014
	) AS t1
),

-- merge tables together
source_table AS (
	SELECT s.*, order_id, o.user_id AS user_with_order, primary_product_id, items_purchased, price_usd, cogs_usd, is_new_visit
	FROM website_sessions_2014 AS s 
	LEFT JOIN orders_2014 AS o 
		ON s.website_session_id = o.website_session_id AND s.user_id = o.user_id
	LEFT JOIN new_vs_returning AS n
		ON s.user_id = n.user_id AND s.created_at = n.created_at
)

-- final output
SELECT MONTH(created_at) AS month,
	CASE WHEN is_new_visit = 1 THEN "new" ELSE "returning" END AS user_type,
	COALESCE(utm_source, "organic") AS traffic_source, utm_campaign, utm_content, device_type,
	COUNT(website_session_id) AS n_sessions,
    COUNT(order_id) AS n_orders,
	COUNT(order_id) / COUNT(website_session_id) AS CVR,
    COUNT(CASE WHEN is_new_visit = 1 THEN "new" ELSE "returning" END) AS n_visits,
    SUM(price_usd) AS revenue
FROM source_table
GROUP BY 1, 2, 3, 4, 5, 6;
```
1
321312
