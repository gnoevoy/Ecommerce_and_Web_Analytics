## Website Performance
For simplicity, there was created a view table to reduce repetitive code.

<br>

```sql
-- source tables with all parameters
CREATE VIEW website_performance AS (

    WITH user_type AS (
        SELECT *, CASE WHEN created_at = first_entry THEN "new" ELSE "returning" END AS user_type
        FROM (
            SELECT created_at, website_session_id, MIN(created_at) OVER (PARTITION BY user_id ORDER BY user_id, created_at ASC) AS first_entry
            FROM website_sessions
        ) AS t1
    ),

    sessions AS (
        SELECT t1.website_session_id, t1.created_at, COALESCE(utm_source, "organic") AS utm_source, device_type, user_type
        FROM website_sessions_2014 AS t1
        LEFT JOIN user_type AS t2
            ON t1.website_session_id = t2.website_session_id AND t1.created_at = t2.created_at
        LEFT JOIN orders_2014 AS t3
            ON t1.website_session_id = t3.website_session_id
    ),

    merged_tables AS (
        SELECT t1.*, MONTH(t1.created_at) AS month, utm_source, device_type, user_type
        FROM website_pageviews_2014 AS t1
        LEFT JOIN sessions AS t2
            ON t1.website_session_id = t2.website_session_id
        WHERE utm_source IS NOT NULL
        ORDER BY website_session_id, website_pageview_id
    ),
	
    -- created id column for a better data model in power bi
    id_column AS (
        SELECT *, ROW_NUMBER() OVER () AS id
        FROM (
            SELECT DISTINCT MONTH(created_at) AS month, utm_source, device_type, user_type
            FROM merged_tables
        ) AS t1
    )

    SELECT id, t1.*
    FROM merged_tables AS t1
    LEFT JOIN id_column AS t2
        ON t1.month = t2.month AND t1.utm_source = t2.utm_source AND t1.device_type = t2.device_type
        AND t1.user_type = t2.user_type
);
```

![5](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/e80d23dc-57dc-47e2-9e11-b564903db2e7)

```sql
-- bounce rate and conversion rate for each entry page
WITH first_page AS (
    SELECT website_session_id, website_pageview_id, pageview_url
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY website_session_id ORDER BY website_pageview_id ASC) AS rnk
        FROM website_performance
    ) AS t1
    WHERE rnk = 1
),

n_pages AS (
    SELECT website_session_id, COUNT(DISTINCT website_pageview_id) AS n_pages
    FROM website_performance
    GROUP BY 1
)

SELECT id, MONTH(s.created_at) AS month, f.pageview_url, utm_source, device_type, user_type,
    COUNT(CASE WHEN n_pages = 1 THEN 1 ELSE NULL END) / COUNT(n.website_session_id) AS bounce_rate,
    COUNT(order_id) / COUNT(n.website_session_id) AS CVR
FROM first_page AS f 
LEFT JOIN n_pages AS n
    ON f.website_session_id = n.website_session_id
INNER JOIN website_performance AS s
    ON f.website_pageview_id = s.website_pageview_id AND f.website_session_id = s.website_session_id
LEFT JOIN orders_2014 AS o
    ON o.website_session_id = s.website_session_id
GROUP BY 1, 2, 3, 4, 5, 6;
```

![1](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/c28b2420-055e-4a1b-bfc1-da53693e989b)

```sql
-- conversion funnel
WITH funnel AS (
    SELECT id, DATE(created_at) AS date, website_session_id, utm_source, device_type, user_type,
        MAX(CASE WHEN pageview_url LIKE "/lander%" OR pageview_url = "/home" THEN 1 ELSE NULL END) AS entry_page,
        MAX(CASE WHEN pageview_url = "/products" THEN 1 ELSE NULL END) AS products_catalog,
        MAX(CASE WHEN pageview_url LIKE "/the-%" THEN 1 ELSE NULL END) AS product_page,
        MAX(CASE WHEN pageview_url = "/cart" THEN 1 ELSE NULL END) AS shopping_cart,
        MAX(CASE WHEN pageview_url = "/shipping" THEN 1 ELSE NULL END) AS shipping_page,
        MAX(CASE WHEN pageview_url LIKE "/billing%" THEN 1 ELSE NULL END) AS billing_page,
        MAX(CASE WHEN pageview_url = "/thank-you-for-your-order" THEN 1 ELSE NULL END) AS order_completion_page
    FROM website_performance
    GROUP BY 1, 2, 3, 4, 5, 6
)

SELECT id, MONTH(date) AS month, utm_source, device_type, user_type,
    COUNT(entry_page) AS entry_page_sessions,
    COUNT(products_catalog) AS products_catalog_sessions,
    COUNT(product_page) AS product_page_sessions,
    COUNT(shopping_cart) AS shopping_cart_sessions,
    COUNT(shipping_page) AS shipping_page_sessions,
    COUNT(billing_page) AS billing_page_sessions,
    COUNT(order_completion_page) AS order_completion_page_sessions
FROM funnel
GROUP BY 1, 2, 3, 4, 5;
```

![2](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/001ab01f-0f47-4bee-889c-4823f60a6d3b)

```sql
-- abandonment rate for product pages
WITH last_product_page AS (
    SELECT website_session_id AS last_product_page_session, pageview_url
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY website_session_id ORDER BY website_pageview_id DESC) AS rnk
        FROM website_performance
    ) AS t1
    WHERE rnk = 1 AND pageview_url LIKE "/the-%"
)

SELECT id, MONTH(created_at) AS month, s.pageview_url, utm_source, device_type, user_type,
    COUNT(DISTINCT last_product_page_session) / COUNT(DISTINCT website_session_id) AS abandonment_rate
FROM website_performance AS s
LEFT JOIN last_product_page AS l
    ON s.website_session_id = l.last_product_page_session
WHERE website_session_id IN (SELECT website_session_id FROM website_performance WHERE pageview_url LIKE "/the-%")
    AND s.pageview_url LIKE "/the-%"
GROUP BY 1, 2, 3, 4, 5, 6;
```

![3](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/45ddb916-a51f-4e9d-ae93-01e234f501e3)

```sql
-- average time to checkout (fill in user info, delivery and payment methods)
WITH time_to_checkout AS (
    SELECT *, MIN(created_at) OVER (PARTITION BY website_session_id) AS start_time 
    FROM (
        SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.website_session_id ORDER BY website_pageview_id DESC) AS rnk
        FROM website_performance AS p
    INNER JOIN orders_2014 AS o
        ON p.website_session_id = o.website_session_id
    ) AS t1
    WHERE rnk <= 3
)

SELECT id, MONTH(created_at) AS month, utm_source, device_type, user_type,
    AVG( TIMESTAMPDIFF(MINUTE, start_time, created_at) ) AS avg_time_to_checkout
FROM time_to_checkout
WHERE rnk = 1
GROUP BY 1, 2, 3, 4, 5;
```

![4](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/bc15e60d-6379-4de9-9a1e-481e5fa715a5)
