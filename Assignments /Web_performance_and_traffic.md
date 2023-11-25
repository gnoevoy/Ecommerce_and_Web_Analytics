# Website Performance and Traffic Sources Analysis

### Context
Fuzzy Factory has been living for about 8 months, and my CEO have to present company performance and growth to the board next week. As a Data Analyst, I was tasked with preparing relevant metrics and graphs for presentation.

### My responsibilities.
1. Based on CEO request and wishes, extract and analyse website traffic and performance data from database.
2. Provide extracted insight to visual graphs as accessible as possible to stakeholders.

### Objective
Analyse website data and transform it into visually accessible metrics and graphs that enable the CEO to showcase the company's performance and growth to the board.

</br>

### Task 1
Showcase the key metrics for the year, such as the total number of sessions and orders, conversion rate, and profit. It's also important to analyse the monthly trends in our growth and demonstrate tendency.

Furthermore, it would be better to highlight the top traffic source from which we receive the most profit.

> **Note**
> **Time period for analysis** - since March 19 to November 11 (2012 year)

![website_performance_and_traffic_sources_page-0001](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/e0d9da39-66d6-4ada-8f48-f174fc54a84e)

> **Note**
> **Conversion rate** – a measure that shows of how many people make an order, compared to the total number of visitors.
> </br>
> **Conversion Rate** = (Total Orders / Total Sessions) * 100

```sql
# Task 1
# Calculate the following metrics for each traffic source: total number of sessions, total number of orders, conversion rate, profit.
# Perform a monthly analysis to identify growth trends based on the previous metrics.

# Key metrics

SELECT COALESCE(utm_source, 'direct') AS utm_source,
    COUNT(s.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(s.website_session_id) AS conversion_rate,
    SUM(price_usd - cogs_usd) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
GROUP BY 1;

# Trend Analysis

SELECT QUARTER(s.created_at) AS quarter,
    MONTHNAME(s.created_at) AS month_name,
    MONTH(s.created_at) AS month_num,
    COUNT(s.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(s.website_session_id) AS conversion_rate,
    SUM(price_usd - cogs_usd) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
GROUP BY 1, 2, 3;
```

</br>

### Task 2
Display months trends for “gsearch” traffic source sessions, orders and profit, so that showcase the growth here.

![website_performance_and_traffic_sources_page-0002](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/7621e57a-6338-4880-8390-e32df8b39c17)

```sql
# Task 2
# Calculate and present the monthly trends for sessions, orders, and profit from the "gsearch" traffic source to demonstrate its growth.

SELECT QUARTER(s.created_at) AS quarter,
    MONTHNAME(s.created_at) AS month_name,
    MONTH(s.created_at) AS month_num,
    COUNT(s.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    SUM(price_usd - cogs_usd) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27' AND utm_source = 'gsearch'
GROUP BY 1, 2, 3;
```

</br>

### Task 3
Provide a similar monthly trend for 'gserach', but this time splitting out nonbrand and brand campaigns separately.

![website_performance_and_traffic_sources_page-0003](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/6accc932-ae17-40c5-bb2c-9b86f9b44265)

```sql
# Task 3
# Calculate a monthly trend analysis for 'gsearch,' and ensure it's separated into non-brand and brand campaigns.

SELECT QUARTER(s.created_at) AS quarter,
    MONTHNAME(s.created_at) AS month_name,
    MONTH(s.created_at) AS month, utm_campaign,
    COUNT(s.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COALESCE(SUM(price_usd - cogs_usd), 0) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign IN ('nonbrand', 'brand')
GROUP BY 1, 2, 3, 4;
```

</br>

### Task 4
Explore the 'nonbrand' category and extract monthly trends categorized by device type.

![website_performance_and_traffic_sources_page-0004](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/a9952a4c-2914-412c-b9ce-27c92c1fb8af)

```sql
# Task 4
# Calculate monthly trends for the 'nonbrand' category, segmented by device type.

SELECT QUARTER(s.created_at) AS quarter,
    MONTHNAME(s.created_at) AS month_name,
    MONTH(s.created_at) AS month, device_type,
    COUNT(s.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    SUM(price_usd - cogs_usd) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1, 2, 3, 4;
```

</br>

### Task 5
Present monthly trends with conversion rate for “gsearch” alongside monthly trends for each of other channels.

![website_performance_and_traffic_sources_page-0005](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/84b68847-90f7-43bd-85cf-dc322e4c2c64)

```sql
# Task 5
# Calculate monthly conversion rate trends for 'gsearch' and also generate monthly trends for each of our other channels.

SELECT QUARTER(s.created_at) AS quarter,
    MONTHNAME(s.created_at) AS month_name,
    MONTH(s.created_at) AS month,
    COALESCE(utm_source, 'direct') AS utm_source,
    COUNT(s.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(s.website_session_id) AS conversion_rate
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
GROUP BY 1, 2, 3, 4;
```

</br>

### Task 6
This summer (June 19 - July 28), It was conducted an A/B test for our homepage. Display the test results for “gsearch nonbrand”, showing how much money was earned in comparison to the original main homepage.

![website_performance_and_traffic_sources_page-0006](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/2472b2bf-3d0c-43d0-a45e-9a7d863c23b0)

```sql
# Task 6
# Calculate the A/B test results for our homepage conducted between June 19 and July 28.
# Determine profit generated for 'gsearch nonbrand' and compare it to profit from the original main homepage.

WITH homepage_test AS (
    SELECT s.website_session_id, s.created_at,
        order_id, (price_usd - cogs_usd) AS profit,
        p.created_at AS pageview_date, pageview_url
    FROM website_sessions AS s
    LEFT JOIN orders AS o 
    ON s.website_session_id = o.website_session_id
    INNER JOIN website_pageviews AS p
    ON s.website_session_id = p.website_session_id
    WHERE s.created_at BETWEEN '2012-06-19' AND '2012-07-28'
        AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
        AND pageview_url IN ('/home', '/lander-1')
)

# In our case, each distinct session has only one entry page.
# SELECT website_session_id FROM homepage_test GROUP BY 1 HAVING COUNT(DISTINCT pageview_url) > 1;

SELECT pageview_url,
    COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rate,
    SUM(profit) AS profit
FROM homepage_test
GROUP BY 1;
```

</br>

### Task 7
For the landing page test you analyse previously, show a full conversation funnel from each of the two pages to orders. Hint: use the same time period as in task 6.

![website_performance_and_traffic_sources_page-0007](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/a94a3011-ae17-4eda-9b71-3087f83237f6)

> **Note**
> **Conversion funnel** – a series of steps that a user takes to complete a purchase on a website or app. The goal is to guide users through the funnel and maximize the number of successful conversions.
> </br>
> **Conversion Funnel Rate** = (Current page sessions / Previous page sessions) * 100

```sql
# Task 7
# Calculate a comprehensive conversion funnel from each of the two pages to orders (home and lander-1).
# Utilize the same time period you examined in our A/B test and the same utm_source and campaign.

# Step-1. Create a source table with the necessary parameters.

WITH source_table AS (
    SELECT website_pageview_id, p.created_at,
        p.website_session_id, pageview_url
    FROM website_sessions AS s
    INNER JOIN website_pageviews AS p
    ON s.website_session_id = p.website_session_id
    WHERE s.created_at BETWEEN '2012-06-19' AND '2012-07-28'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
),

# Step-2. Identify sessions with an entry page = 'home' and with entry page = 'lander-1' separately.

lander_1 AS (
    SELECT website_session_id AS lander_sessions
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY website_session_id ORDER BY created_at ASC) AS rnk
	FROM source_table
    ) AS t1
    WHERE pageview_url = '/lander-1' AND rnk = 1
),

home AS (
    SELECT website_session_id AS home_sessions
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY website_session_id ORDER BY created_at ASC) AS rnk
	FROM source_table
    ) AS t1
    WHERE pageview_url = '/home' AND rnk = 1
),

# Step-3. Merge 3 tables and calculate the number of sessions for each page.
# Determine the number of sessions from the previous page.

conversion_funnel AS (
    SELECT CASE WHEN pageview_url IN ('/home', '/lander-1') THEN 'entry_page' ELSE pageview_url END AS pageview_url, 
        COUNT(lander_sessions) AS lander_sessions,
        LAG(COUNT(lander_sessions)) OVER () AS previous_page_lander,
        COUNT(home_sessions) AS home_sessions,
        LAG(COUNT(home_sessions)) OVER () AS previous_page_home
    FROM source_table AS s
    LEFT JOIN lander_1 AS l ON s.website_session_id = l.lander_sessions
    LEFT JOIN home AS h ON s.website_session_id = h.home_sessions
    GROUP BY 1
)

# Step-4. Determine the click rate percentage.

SELECT pageview_url,
    lander_sessions,
    COALESCE(lander_sessions / previous_page_lander, 1) AS lander_clikrate,
    home_sessions,
    COALESCE(home_sessions / previous_page_home, 1) AS home_clikrate
FROM conversion_funnel;
```

</br>

### Task 8
Show a comparison of the bounce rates for the main homepage and the bounce rate for 'lander-1'.

![website_performance_and_traffic_sources_page-0008](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/db04e9b0-2883-47a9-81ce-9a01d2d58151)

> **Note**
> **Bounce rate** – a metric that measures the percentage of visitors who land on a website or a specific page and then leave the site without interacting with it further.
> </br>
> **Bounce Rate** = (Number of single-page sessions) / (Total sessions) * 100

```sql
# Task 8
# Calculate the comparison of bounce rates for the main homepage and 'lander-1' test
# Use 'gsearch nonbrand' traffic source and campaign again.

# Step-1. Create a source table with the necessary parameters.

WITH souce_table AS (
    SELECT p.website_pageview_id, p.created_at,
        p.website_session_id, pageview_url
    FROM website_sessions AS s
    INNER JOIN website_pageviews AS p
    ON s.website_session_id = p.website_session_id
    WHERE s.created_at < '2012-11-27'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
),

# Step-2. Identify bounce sessions for both entry pages.

bounce_sessions AS (
    SELECT website_session_id
    FROM souce_table
    GROUP BY website_session_id
    HAVING COUNT(DISTINCT pageview_url) = 1
)

# Step-3. Determine the bounce rate percentage.

SELECT pageview_url,
    COUNT(s.website_session_id) AS total_sessions,
    COUNT(b.website_session_id) AS bounce_sessions,
    COUNT(b.website_session_id) / COUNT(s.website_session_id) AS bounce_rate
FROM souce_table AS s
LEFT JOIN bounce_sessions AS b 
ON s.website_session_id = b.website_session_id
WHERE pageview_url IN ('/home', '/lander-1')
GROUP BY 1;
```

</br>

### Task 9
Provide the results of the A/B test for the billing page, conducted from September 10 - November 10. The "Revenue per click" metric for 'gsearch nonbrand' is especially interesting.

![website_performance_and_traffic_sources_page-0009](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/assets/43414592/c0a251d5-412a-4b1c-8476-2d063abe25fc)

```sql
# Task 9
# Calculate the outcomes of the A/B test on the billing page that was carried out between September 10 and November 10.
# Specifically, focus on determining the 'Revenue per click' metric for the 'gsearch nonbrand'.

WITH billing_test AS (
    SELECT s.website_session_id, order_id,
        price_usd AS revenue, p.created_at AS pageview_date,
        pageview_url
    FROM website_sessions AS s
    LEFT JOIN orders AS o 
    ON s.website_session_id = o.website_session_id
    INNER JOIN website_pageviews AS p
    ON s.website_session_id = p.website_session_id
    WHERE s.created_at BETWEEN '2012-09-10' AND '2012-11-10'
        AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
        AND pageview_url IN ('/billing', '/billing-2')
)

# Like in task 6, there are no any sessions who visited both billing pages.
# SELECT website_session_id FROM billing_test GROUP BY 1 HAVING COUNT(DISTINCT pageview_url) > 1;

SELECT pageview_url,
    COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rate,
    SUM(revenue) AS revenue,
    SUM(revenue) / COUNT(website_session_id) AS revenue_per_click
FROM billing_test
GROUP BY 1;
```

</br>

### Navigation links
- [Customers and Products Analysis](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/blob/main/Assignments%20/Customers_and_products.md)
- [README.md](https://github.com/gnoevoy/Ecommerce_and_Web_Analytics/blob/main/README.md)

















