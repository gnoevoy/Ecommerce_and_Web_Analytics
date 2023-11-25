# Customers and Products Analysis

### Context
The recently appointed manager has requested an overview with key metrics of the company's products and customers for the previous and current years. As a Data Analyst, I was tasked with conducting research and presenting the insights in the form of a mini-report.

### My responsibilities.
1. Extracting the necessary data from the database and conducting exploratory data analysis.
2. Creating a visually informative report using data visualization tools.

### Objective
The goal is to provide information that will assist the new manager in gaining a better understanding of the company's operations and making informed decisions.

</br>

## Customers Analysis

### Comprehensive Customer Insights
Gain a deep understanding of customer types, including their impact on sessions, orders, conversion rates, revenue, by devices and traffic sources during a specific time period.

![source_page-0001](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/2ddda8e9-8e89-44c4-b3de-29817cc4cb07)

```sql
# Customers Analysis

# Overall information and Key Metrics: customer types breakdown of sessions, orders, conversion rates,
# revenue, costs for different sessions, devices, and traffic sources over a specified date period

WITH source_table AS (
    SELECT s.website_session_id, s.created_at,
        order_id, price_usd,
        cogs_usd, device_type, s.user_id,
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

SELECT YEAR(created_at) AS year,
    QUARTER(created_at) AS quarter,
    MONTHNAME(created_at) AS month_name,
    MONTH(created_at) AS month,
    type_of_session, device_type, traffic_source,
    COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(DISTINCT user_id) AS customers,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rate,
    COALESCE(SUM(price_usd - cogs_usd), 0) AS profit,
    COALESCE(ROUND(SUM(price_usd) / COUNT(website_session_id), 2), 0) AS revenue_per_session
FROM source_table
GROUP BY 1, 2, 3, 4, 5, 6, 7;
```

</br>

### Orders and Sessions Patterns by Day and Time
Explore into the data to reveal the patterns in the number of orders and sessions across the days of the week and various times of the day.

![source_page-0002](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/12ba5834-11ba-466a-a9d8-c65bb352db0f)

```sql
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

SELECT DAYOFWEEK(created_at) AS day_of_week,
    time_of_day, repeated_session,
    COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rate
FROM source_table
GROUP BY 1, 2, 3
ORDER BY 1 ASC;
```

</br>

### Average Time to the Next Order
Calculate the average time it takes for users in repeated sessions to place their next order.

![source_page-0003](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/a5fd2058-20f0-4438-8540-b1b4ed0c3a4e)

```sql
# Average time of the next order by the user (repeated_sessions)

WITH source_table AS (
    SELECT *, DATEDIFF(created_at, previous_session_time) AS date_diff
    FROM (
        SELECT website_session_id, created_at,
            user_id, is_repeat_session,
            LAG(created_at) OVER (PARTITION BY user_id ORDER BY created_at ASC) AS previous_session_time
        FROM website_sessions
        WHERE created_at BETWEEN '2013-01-01' AND '2014-06-01'
            AND user_id IN (SELECT user_id FROM website_sessions GROUP BY user_id HAVING COUNT(website_session_id) > 1)
    ) AS t1
    WHERE previous_session_time IS NOT NULL
)

SELECT YEAR(created_at) AS year,
    QUARTER(created_at) AS quarter,
    MONTHNAME(created_at) AS month_name,
    MONTH(created_at) AS month,
    AVG(date_diff) AS avg_return_time
FROM source_table
GROUP BY 1, 2, 3, 4;
```

</br>

## Products Analysis

### Essential Product Stats
Provide an overview of key product metrics, including quantity, profit, and refunds, within a specific date range.

![source_page-0004](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/568e8fda-4f1e-4699-a574-d8cb2dcd5edb)

```sql
# Products

# Overall information and Key Metrics: products breakdown of quantity, prodit, refunds over a specified date period

WITH source_table AS (
    SELECT o.order_id, o.created_at,
        o.items_purchased, o.price_usd - o.cogs_usd AS profit_order,
        product_name, oi.order_item_id,
        oi.price_usd - oi.cogs_usd AS profit_product,
        oif.order_item_refund_id, refund_amount_usd
    FROM orders AS o
    LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
    LEFT JOIN products AS p
    ON oi.product_id = p.product_id
    LEFT JOIN order_item_refunds AS oif 
    ON oi.order_item_id = oif.order_item_id
    WHERE o.created_at BETWEEN '2013-01-01' AND '2014-06-01'
)

SELECT YEAR(created_at) AS year,
    QUARTER(created_at) AS quarter,
    MONTHNAME(created_at) AS month_name,
    MONTH(created_at) AS month, product_name,
    COUNT(order_item_id) AS quantity,
    SUM(profit_product) AS profit,
    SUM(refund_amount_usd) AS refund_amount
FROM source_table
GROUP BY 1, 2, 3, 4, 5;
```

</br>

### Single Items vs Multiple
Examine the trends in single-product orders versus orders with multiple items over time.

![source_page-0005](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/d2fdc409-1ec6-4b1c-a18c-8d887ca87f8c)

```sql
# Analysis of single vs. multiple product orders over time

SELECT YEAR(created_at) AS year,
    QUARTER(created_at) AS quarter,
    MONTHNAME(created_at) AS month_name,
    MONTH(created_at) AS month, items_purchased,
    COUNT(order_id) AS orders,
    SUM(price_usd - cogs_usd) AS profit
FROM orders
WHERE created_at BETWEEN '2013-01-01' AND '2014-06-01'
GROUP BY 1, 2, 3, 4, 5;
```

</br>

### Products That Go Hand in Hand
Discover which items are commonly bought together during a specific time period.

![source_page-0006](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/64f2a992-0da9-4b2c-9ec9-8241d6054556)

```sql
# Cross-sell Analysis: Identify which products are often sell together over a specified date period

WITH source_table AS (
    SELECT o.order_id, o.created_at,
        primary_product_id, items_purchased,
        o.price_usd - o.cogs_usd AS order_profit,
        product_id, is_primary_item,
        CASE WHEN primary_product_id = product_id THEN NULL ELSE product_id END AS cross_sell_product
    FROM orders AS o
    LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
    WHERE o.created_at BETWEEN '2013-01-01' AND '2014-06-01'
)

SELECT primary_product_id, p1.product_name,
    cross_sell_product, p2.product_name,
    COUNT(DISTINCT order_id) AS orders,
    SUM(order_profit) AS order_profit
FROM source_table AS s
LEFT JOIN products AS p1
ON primary_product_id = p1.product_id
LEFT JOIN products AS p2
ON cross_sell_product = p2.product_id
GROUP BY 1, 2, 3, 4
ORDER BY primary_product_id ASC, order_profit DESC;
```

</br>

### Navigation links
- [Website Performance and Traffic Sources Analysis](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/blob/main/Assignments%20/Web_performance_and_traffic.md)
- [README.md](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/blob/main/README.md)

