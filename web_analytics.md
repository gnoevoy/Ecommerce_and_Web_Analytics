## Website Performance and Traffic Sources

### Context
Maven Fuzzy Factory has been living for about 8 months, and my CEO have to present company performance and growth to the board next week. As a Data Analyst, I was tasked with preparing relevant metrics and graphs for presentation.

### My responsibilities.
1. Based on CEO request and wishes, extract and analyse website traffic and performance data from database.
2. Provide extracted insight to visual graphs as accessible as possible to stakeholders.
   
<p>&nbsp;</p>

**Task 1.** Showcase the key metrics for the year, such as the total number of sessions and orders, conversion rate, and profit. It's also important to analyse the monthly trends in our growth and demonstrate tendency.

```sql
# Task 1
# Calculate the following metrics for each traffic source: total number of sessions, total number of orders, conversion rate, profit.
# Perform a monthly analysis to identify growth trends based on the previous metrics.

# Key metrics

SELECT COALESCE(utm_source, 'direct') AS utm_source,
	COUNT(s.website_session_id) AS sessions, COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(s.website_session_id) AS conversion_rate,
    SUM(price_usd - cogs_usd) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
GROUP BY 1;

# Trend Analysis

SELECT QUARTER(s.created_at) AS quarter, MONTHNAME(s.created_at) AS month_name, MONTH(s.created_at) AS month_num,
	COUNT(s.website_session_id) AS sessions, COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(s.website_session_id) AS conversion_rate,
    SUM(price_usd - cogs_usd) AS profit
FROM website_sessions AS s
LEFT JOIN orders AS o 
ON s.website_session_id = o.website_session_id
WHERE s.created_at < '2012-11-27'
GROUP BY 1, 2, 3;
```
