## Products Analysis

```sql
-- products info
SELECT MONTH(i.created_at) AS month, product_id,
    COUNT(DISTINCT i.order_id) AS n_orders,
    SUM(price_usd) - SUM(cogs_usd) AS profit,
    ROUND((SUM(price_usd) - SUM(cogs_usd)) / SUM(price_usd), 2) AS profit_margin_rate,
    COUNT(order_item_refund_id) AS n_refund_items,
    ROUND(COUNT(order_item_refund_id) / COUNT(DISTINCT i.order_id), 2) AS refund_rate,
    ROUND(AVG(DATEDIFF(f.created_at, i.created_at)), 2) AS days_to_refund,
    SUM(refund_amount_usd) AS refund_amount
FROM order_items_2014 AS i
LEFT JOIN order_item_refunds_2014 AS f 
    ON i.order_item_id = f.order_item_id
GROUP BY 1, 2;
```

![1](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/13ad71f7-17d5-4d89-a458-6c84f103acee)

```sql
-- seasonality patterns
SELECT DAYOFWEEK(created_at) AS day_number,
    DAYNAME(created_at) AS day_of_week, 
    CASE WHEN HOUR(created_at) BETWEEN 5 AND 11 THEN "morning"
        WHEN HOUR(created_at) BETWEEN 12 AND 17 THEN "afternoon"
        WHEN HOUR(created_at) BETWEEN 18 AND 24 THEN "evening"
        WHEN HOUR(created_at) BETWEEN 0 AND 4 THEN "night"
    END AS time_of_day,
    COUNT(order_id) / (SELECT COUNT(order_id) FROM orders_2014) AS orders_pct
FROM orders_2014
GROUP BY 1, 2, 3;
```

![2](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/5f06707a-078f-45ad-9b7b-a6d0929b6a42)

```sql
-- cross selling items
WITH cross_cell_products AS (
    SELECT primary_product_id, product_id AS cross_sell_product,
    COUNT(DISTINCT t1.order_id) AS n_orders
    FROM orders_2014 AS t1
    LEFT JOIN order_items_2014 AS t2
        ON t1.order_id = t2.order_id
    WHERE is_primary_item = 0
    GROUP BY 1, 2
),

cte AS (
    SELECT LEAST(primary_product_id, cross_sell_product) AS primary_product,
        GREATEST(cross_sell_product, primary_product_id) AS cross_sell_product,
        SUM(n_orders) AS n_orders
    FROM cross_cell_products
    GROUP BY 1, 2
    ORDER BY 3 DESC
)

SELECT primary_product, t2.product_name AS primary_product_name, cross_sell_product,
    t3.product_name AS cross_sell_product_name, n_orders
FROM cte AS t1
LEFT JOIN products AS t2
    ON t1.primary_product = t2.product_id
LEFT JOIN products AS t3
    ON t1.cross_sell_product = t3.product_id;
```

![3](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/2366631e-fb2c-485a-a3a3-29cc7c73be2a)
