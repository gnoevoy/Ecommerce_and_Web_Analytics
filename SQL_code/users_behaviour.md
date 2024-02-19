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

```


```sql

```


```sql

```

```sql

```

```sql

```

```sql

```
