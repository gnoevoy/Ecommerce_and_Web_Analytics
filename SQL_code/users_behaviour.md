## Users Behaviour
For better readability, I used temporary tables to calculate metrics and then merge tables together in a final output.

```sql
-- Calculate average order value | purchase frequency | customer lifespan months | customer lifetime_value
CREATE TEMPORARY TABLE AOV_PG_CLF (

    WITH customer_lifespan AS (
        SELECT ROUND(AVG(customer_lifespan_months), 2) AS avg_customer_lifespan_months
        FROM (
            SELECT user_id, DATEDIFF( MAX(DATE(created_at)), MIN(DATE(created_at)) ) / 12 AS customer_lifespan_months
            FROM orders
            WHERE YEAR(created_at) <= 2014
            AND user_id IN (SELECT user_id FROM orders WHERE YEAR(created_at) <= 2014 GROUP BY 1 HAVING COUNT(order_id) > 1)
            GROUP BY 1
            ORDER BY user_id
        ) AS t1
    ),

    other_metrics AS (
        SELECT MONTH(created_at) AS month,
        ROUND(SUM(price_usd) / COUNT(order_id), 2) AS average_order_value,
        ROUND(COUNT(order_id) / COUNT(DISTINCT user_id), 2) AS purchase_frequency
        FROM orders_2014
        GROUP BY 1
    )

    SELECT *, ROUND(average_order_value * purchase_frequency * avg_customer_lifespan_months, 2) AS customer_lifetime_value
    FROM other_metrics
    CROSS JOIN customer_lifespan
    
);
```

![1](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/871c0520-6101-45ed-b750-11edb69aa77d)

```sql
-- Cart abandonment rate
CREATE TEMPORARY TABLE cart_abandonment_rate ( 

    WITH cart_abandonment_rate AS (
        SELECT p.*, order_id, CASE WHEN order_id IS NOT NULL THEN 1 ELSE 0 END AS is_completed
        FROM website_pageviews_2014 AS p
        LEFT JOIN orders_2014 AS o
            ON p.website_session_id = o.website_session_id
        WHERE pageview_url = "/cart"
    )

    SELECT MONTH(created_at) AS month,
        ROUND(1 - ( COUNT(CASE WHEN is_completed = 1 THEN 1 ELSE NULL END) / COUNT(is_completed) ), 2) AS cart_abandonment_rate
    FROM cart_abandonment_rate
    GROUP BY 1
    
);
```

![2](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/7ae0a4ca-0190-4f13-81ed-29906992e838)

```sql
-- Bounce rate 
CREATE TEMPORARY TABLE bounce_rate (

    SELECT month, ROUND(COUNT(CASE WHEN n_pages = 1 THEN 1 ELSE NULL END) / COUNT(website_session_id), 2) AS bounce_rate
    FROM (
        SELECT MONTH(created_at) AS month, website_session_id, COUNT(website_pageview_id) AS n_pages
        FROM website_pageviews_2014
        GROUP BY 1, 2
    ) AS t1
    GROUP BY 1
    
);
```

![3](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/4bb09ba1-a453-44bd-83e7-9a3f9bf77904)

```sql
-- returning users rate 
CREATE TEMPORARY TABLE returning_users_rate (

    WITH returning_users AS (
        SELECT *, CASE WHEN created_at = first_entry THEN 1 ELSE 0 END AS is_new_visit
        FROM (
            SELECT created_at, user_id, MIN(created_at) OVER (PARTITION BY user_id ORDER BY user_id, created_at ASC) AS first_entry
            FROM website_sessions
        ) AS t1
    )

    SELECT MONTH(created_at) AS month,
        ROUND( COUNT(CASE WHEN is_new_visit = 0 THEN 1 ELSE NULL END) / COUNT(is_new_visit), 2) AS returning_users_rate
    FROM returning_users
    WHERE YEAR(created_at) = 2014
    GROUP BY 1

);
```

![4](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/b7358520-8d62-49a4-bae5-e6e32caf0f6d)

```sql
-- new vs returning customers
CREATE TEMPORARY TABLE new_vs_returning_customers (

    WITH new_and_returning_customers AS (
        SELECT *, CASE WHEN created_at = first_entry THEN 1 ELSE 0 END AS is_new_customer
        FROM (
            SELECT created_at, user_id, MIN(created_at) OVER (PARTITION BY user_id ORDER BY created_at ASC) AS first_entry
            FROM orders
        ) AS t1
    )

    SELECT MONTH(created_at) AS month,
        COUNT(CASE WHEN is_new_customer = 1 THEN 1 ELSE NULL END) AS n_new_customers,
        COUNT(CASE WHEN is_new_customer = 0 THEN 1 ELSE NULL END) AS n_returning_customers,
        ROUND( COUNT(CASE WHEN is_new_customer = 0 THEN 1 ELSE NULL END) / COUNT(is_new_customer), 2) AS returning_customers_rate
    FROM new_and_returning_customers
    WHERE YEAR(created_at) = 2014
    GROUP BY 1

);
```

![5](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/8d58f896-6b50-4a28-babd-1d4b8cfdcfdf)

```sql
-- customer retention rate
CREATE TEMPORARY TABLE customers_retention_rate (

    WITH retained_customers_rate AS (
        SELECT *, CASE WHEN month - previous_month = 1 THEN "retained" ELSE NULL END AS customer_type
        FROM (
            SELECT user_id, month, LAG(month) OVER (PARTITION BY user_id ORDER BY user_id, month) AS previous_month
            FROM (SELECT DISTINCT user_id, MONTH(created_at) AS month FROM orders_2014) AS t1
        ) AS t1
    )

    SELECT month, COUNT(CASE WHEN customer_type IS NOT NULL THEN 1 ELSE NULL END) / COUNT(user_id) AS customers_retention_rate
    FROM retained_customers_rate
    GROUP BY 1

);
```

![6](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/cbbbdf12-1bd2-474d-a429-ed425d152f54)

```sql
-- customers churn rate
CREATE TEMPORARY TABLE churn_rate (

    WITH churn_rate AS (
        SELECT *, CASE WHEN month - previos_month != 1 OR previos_month IS NULL THEN "churned" ELSE NULL END AS customer_type
        FROM (
            SELECT user_id, month, LAG(month) OVER (PARTITION BY user_id ORDER BY user_id, month) AS previos_month
            FROM (SELECT DISTINCT user_id, MONTH(created_at) AS month FROM orders_2014) AS t1
        ) AS t1
    )

    SELECT month, COUNT(CASE WHEN customer_type IS NOT NULL THEN 1 ELSE NULL END) / COUNT(user_id) AS churn_rate
    FROM churn_rate
    GROUP BY 1

);
```

![7](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/531ccaef-c90f-4729-891b-cc3b31f10948)

```sql
-- Repeat purchase rate (RPR)
CREATE TEMPORARY TABLE repeat_purchase_rate (

    SELECT month, COUNT(CASE WHEN is_repeat = 1 THEN 1 ELSE NULL END) / COUNT(DISTINCT user_id) AS repeat_purchase_rate
    FROM (
        SELECT MONTH(created_at) AS month, user_id, COUNT(order_id) AS n_orders,
            CASE WHEN COUNT(order_id) > 1 THEN 1 ELSE 0 END AS is_repeat
        FROM orders_2014
        GROUP BY 1, 2
    ) AS t1
    GROUP BY 1

);
```

![1](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/ac51ecb0-b81b-4eb7-9be9-6ae116fcbad8)

```sql
-- Time between purchases (in days)
CREATE TEMPORARY TABLE time_between_purchases (

    SELECT MONTH(created_at) AS month, ROUND( AVG(DATEDIFF(created_at, previos_purchase_date)), 2) AS time_between_purchases_days
    FROM (
        SELECT created_at, user_id, LAG(created_at) OVER (PARTITION BY user_id ORDER BY created_at ASC) AS previos_purchase_date
        FROM orders_2014
        WHERE user_id IN (SELECT user_id FROM orders_2014 GROUP BY 1 HAVING COUNT(order_id) > 1)
    ) AS t1
    GROUP BY 1
    ORDER BY 1

);
```

![2](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/f6ea3315-56af-49d7-81b4-78c056391ba7)

```sql
-- average time to first purchase (in days) and average number of sessions
CREATE TEMPORARY TABLE time_to_first_purchase (

    WITH first_orders AS (
        SELECT *
        FROM (
            SELECT website_session_id, user_id, created_at, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) AS rnk
            FROM orders_2014
        ) AS t1
        WHERE rnk = 1
    ),

    all_user_sessions AS (
        SELECT s.website_session_id AS all_sessions, s.created_at AS session_time,
            o.website_session_id AS order_session, o.created_at AS order_time, o.user_id
        FROM website_sessions_2014 AS s
        INNER JOIN first_orders AS o 
            ON s.user_id = o.user_id
        WHERE o.website_session_id >= s.website_session_id
    ),

    combined_table AS (
        SELECT MONTH(order_time) AS month, user_id, COUNT(all_sessions) AS n_sessions, MAX(time_diff_days) AS time_between_purchase_days
        FROM (
            SELECT *, DATEDIFF( MAX(order_time) OVER (PARTITION BY user_id), MIN(session_time) OVER (PARTITION BY user_id) ) AS time_diff_days
            FROM all_user_sessions
            WHERE user_id IN (SELECT user_id FROM all_user_sessions GROUP BY 1 HAVING COUNT(DISTINCT all_sessions) > 1)
        ) AS t1
        GROUP BY 1, 2
    )

    SELECT month, ROUND( AVG(n_sessions), 2) AS avg_n_sessions, ROUND( AVG(time_between_purchase_days), 2) AS avg_days_to_purchase
    FROM combined_table
    GROUP BY 1

);
```

![3](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/0a93234f-dcc4-43b3-8dad-ee7b3e40968d)

```sql
-- final result (merge tables together)
SELECT t1.*, t2.cart_abandonment_rate, t3.bounce_rate, t4.returning_users_rate,
    t5.n_new_customers, t5.n_returning_customers, t5.returning_customers_rate,
    t6.customers_retention_rate, t7.churn_rate, t8.repeat_purchase_rate,
    t9.time_between_purchases_days,
    t10.avg_n_sessions AS avg_sessions_to_first_purchase, t10.avg_days_to_purchase AS avg_days_to_first_purchase
FROM AOV_PG_CLF AS t1
LEFT JOIN cart_abandonment_rate AS t2 ON t1.month = t2.month
LEFT JOIN bounce_rate AS t3 ON t1.month = t3.month
LEFT JOIN returning_users_rate AS t4 ON t1.month = t4.month
LEFT JOIN new_vs_returning_customers AS t5 ON t1.month = t5.month
LEFT JOIN customers_retention_rate AS t6 ON t1.month = t6.month
LEFT JOIN churn_rate AS t7 ON t1.month = t7.month
LEFT JOIN repeat_purchase_rate AS t8 ON t1.month = t8.month
LEFT JOIN time_between_purchases AS t9 ON t1.month = t9.month
LEFT JOIN time_to_first_purchase AS t10ON t1.month = t10.month;
```

![4](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/79cfbab9-5696-42f5-81f8-141bcd0c8445)

