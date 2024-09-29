
![image.png](https://github.com/Aimee-Le/BikeStoreAnalysis/blob/main/logomain.png)

## Overview
This project analyzes the performance of a bicycle store from 2016 to 2018. It addresses 10 key business questions, and the findings will assist the business in making informed decisions for future development.

## Objectives
- Analyze annual and monthly sales, monthly cumulative sales, together with the growth rate.
- Identify revenue contributions and patterns such as state revenue contributions, peak sales months, and weekday sales patterns.
- Evaluate product performance by category, brand, product itself.
- Segment customers using RFM analysis.

## Tasks:
- Set up workspace: download CSV files and import to database that was created using Azure Data Studio.
- Read, explore to understand business problems, define objectives and key questions.
- Data cleaning include correct the data types, handle Null values/ duplicate values, delete unvaluable columns to ensure it's accurate and free of errors
- Data analysis: answer given business questions, optimize the codes to reduce the running time.
- Documentation: wrap up the project's objetives, observations and upload to Github's repository.

## Dataset

The data for this project is the sample data from SQL Server Tutorial
- **Dataset Link:** [bike-dataset](http://www.sqlservertutorial.net/load-sample-database/)

## Business Questions

- [Q1: Total orders, quantity, and revenue by year](#q1-total-orders-quantity-and-revenue-by-year)
- [Q2: Monthly revenue accumulation](#q2-monthly-revenue-accumulation)
- [Q3: Monthly sales figures and growth rate](#q3-monthly-sales-figures-and-growth-rate)
- [Q4: Highest revenue contribution by year](#q4-highest-revenue-contribution-by-year)
- [Q5: Top 3 best selling month by state](#q5-top-3-months-with-highest-sales-by-state)
- [Q6: Top 3 performance months by state](#q6-top-3-performance-months-by-state)
- [Q7: Sales patterns by weekday](#q7-sales-patterns-by-weekday)
- [Q8: Top 10 performing categories](#q8-top-10-performing-categories)
- [Q9: Top 3 bikes by category](#q9-top-3-bikes-by-category)
- [Q10: Impact of customer segmentation on sales](#q10-impact-of-customer-segmentation-on-sales)


## Findings and Conclusion
- Sales Trends: Performance peaked in 2017, followed by a significant decline in 2018—indicating an overall downward trend.
- Market Leadership: New York accounted for about 65% of total revenue each year.
- Revenue Fluctuations: Revenue fell from $537,192 in April 2018 to $188.99 in June (due to closure in May) but rebounded to $9,484 in the next month.
- Sales Patterns: No consistent monthly bestsellers across states suggest sales are not seasonally dependent.
- Ordering Trends: In New York, orders peak on Sundays, Tuesdays, and Thursdays. Texas sees orders on Sundays, Mondays, and Thursdays. California shows no clear pattern.
- Product Categories: Cruisers are the top-selling bikes, making up 29% of total sales, with Electra as the most popular brand.
- Customer Breakdown: 44% of customers were regular, 20% were new, high-paying and regular customers comprised 11% and 12%, respectively, while the best customers contributed only 1% of sales.

### Recommendations:
- Analyze the factors behind the sales decline post-2017 and implement targeted marketing campaigns, especially in the lucrative New York market. 
- Improving inventory management and utilizing data analytics will help optimize stock levels and capitalize on peak ordering times.
- Developing customer loyalty programs, introducing seasonal promotions, diversifying the product range, and enhancing the online shopping experience can attract and retain customers. 
- Establishing a feedback loop and investing in staff training will further ensure a high-quality customer experience, for sustained growth and profitability.

## Business questions
### Q1: Total orders, quantity, and revenue by year
```sql
SELECT 
    Year,
    COUNT(order_id) NumberOrders,
    SUM(quantity) Quantity,
    CAST(SUM(final_price) AS NUMERIC(10,2)) TotalRevenue
FROM tbl_combine
GROUP BY Year
ORDER BY Year;
```

### Q2: Monthly revenue accumulation
```sql
WITH monthly_sales AS (
    SELECT
        year,
        month,
        CAST(SUM(final_price) AS NUMERIC (10,2)) total_sales
    FROM tbl_combine
    GROUP BY year, month
)
SELECT 
    year, 
    month, 
    total_sales,
    CAST(SUM(total_sales) OVER (ORDER BY year, month) AS NUMERIC(10,2)) AS accumulative
FROM monthly_sales;
```
### Q3: Monthly sales figures and growth rate
```sql
SELECT
    Month,
    Year,
    CAST(SUM(final_price)AS DECIMAL(10,2)) recent_sale,
    CAST(SUM(final_price) - LAG(SUM(final_price)) OVER (ORDER BY year, Month) AS DECIMAL(10,2)) sale_growth,
    CAST(100 *(SUM(final_price) - LAG(SUM(final_price)) OVER (ORDER BY year, month)) / (SUM(final_price) + LAG(SUM(final_price)) OVER (ORDER BY year, month)) AS DECIMAL(5,2)) growth_rate
FROM tbl_combine
GROUP BY Month, Year
ORDER BY year, growth_rate, month;
```
### Q4: Highest revenue contribution by year
```sql
WITH group_tbl AS (
    SELECT 
        Year,
        state,
        count(distinct order_id) NumberOrders,
        sum(quantity) Quantity,
        round(sum(final_price), 2) TotalRevenue
    FROM tbl_combine
    GROUP BY state, Year
)
SELECT *,
    ROUND(TotalRevenue / SUM(TotalRevenue) OVER (PARTITION BY year), 2) AS Ratio
FROM group_tbl
ORDER BY year, TotalRevenue desc
```
### Q5: Top 3 best selling month by state
```sql
WITH group_tbl AS (
    SELECT 
        Month,
        Year,
        State,
        COUNT(distinct order_id) NumberOrders,
        SUM(quantity) Quantity,
        CAST(SUM(final_price) AS NUMERIC (10,2)) TotalRevenue
    FROM tbl_combine
    GROUP BY state, Year, Month
)
, tbl_rank AS (
    SELECT * ,
        CAST(TotalRevenue / SUM(TotalRevenue) OVER (PARTITION BY year) AS NUMERIC (2,2)) AS Ratio,
        RANK() OVER (PARTITION BY year ORDER BY TotalRevenue desc) rank
    FROM group_tbl
)
SELECT *
FROM tbl_rank
WHERE rank <=3
```

### Q6: Top 3 performance months by state
```sql
WITH ranked_orders AS (
    SELECT state, Month, Year,
           COUNT(DISTINCT order_id) AS NumberOrders,
           SUM(quantity) AS Quantity,
           ROUND(SUM(final_price), 2) AS TotalRevenue,
           ROW_NUMBER() OVER (PARTITION BY year, state ORDER BY SUM(final_price) DESC) AS row_number
    FROM tbl_combine
    GROUP BY state, Year, Month
)
SELECT state, Month, Year, NumberOrders, Quantity, TotalRevenue
FROM ranked_orders
WHERE row_number < 4
ORDER BY state, year;
```
### Q7: Sales patterns by weekday
```sql
WITH tbl_row AS (
SELECT year,
    State,
    DATENAME(weekday, order_date) AS Date,
    COUNT(DISTINCT order_id) AS num_orders,
    ROUND(CAST(SUM(final_price) AS FLOAT), 2) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY year, state ORDER BY SUM(final_price) desc) row_number
FROM tbl_combine
GROUP BY DATENAME(weekday, order_date), year, State
)
SELECT YEAR, state, Date, num_orders, total_sales
FROM tbl_row 
WHERE row_number < 4
order by state, year;
```
### Q8: Top 10 performing categories
```sql
with tbl as (
    SELECT category_name, 
        SUM(total_quantity) total_quantity
    FROM product_sales_details
    GROUP BY category_name
)
select *,
cast(total_quantity as float) / sum(total_quantity) over ()
from tbl
```
### Q9: Top 3 bikes by category
```sql
-- Q9: Top 3 bikes by category
WITH quantity_ratio_per_category AS (
    SELECT 
        product_name,
        category_name,
        brand_name,
        total_quantity,
        CAST(100 * CAST(total_quantity AS FLOAT) / SUM(total_quantity) OVER (PARTITION BY category_name) as numeric(5,2)) ratio
    FROM dbo.product_sales_details
)
,ranked_quantity AS (
    SELECT 
        category_name, 
        product_name, 
        brand_name,
        total_quantity,
        ratio,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY ratio DESC) AS rank
    FROM quantity_ratio_per_category
)
SELECT category_name, product_name, brand_name, brand_name, total_quantity, concat(ratio, '%')
FROM ranked_quantity
WHERE rank <= 3;
```
### Q10: Impact of customer segmentation on sales
```sql

WITH tbl_rfm AS (
    SELECT 
        customer_id,
        DATEDIFF(day, MAX(order_date), '2018-12-28') AS recency,
        COUNT(order_id) AS frequency,
        ROUND(SUM(CAST(final_price AS FLOAT)), 2) AS monetary
    FROM tbl_combine
    GROUP BY customer_id
)
/* Calculate the percentile rank for each RFM metric */
, tbl_rank AS (
    SELECT *,
        PERCENT_RANK() OVER (ORDER BY recency) AS r_rank,
        PERCENT_RANK() OVER (ORDER BY frequency) AS f_rank,
        PERCENT_RANK() OVER (ORDER BY monetary) AS m_rank
    FROM tbl_rfm
)
/*  Categorize customers into tiers based on RFM scores */
, tbl_tier AS (
    SELECT *,
        CASE 
            WHEN r_rank <= 0.25 THEN 1
            WHEN r_rank <= 0.5 THEN 2
            WHEN r_rank <= 0.75 THEN 3
            ELSE 4 
        END AS r_tier,
        CASE 
            WHEN f_rank <= 0.25 THEN 1
            WHEN f_rank <= 0.5 THEN 2
            WHEN f_rank <= 0.75 THEN 3
            ELSE 4 
        END AS f_tier,
        CASE 
            WHEN m_rank <= 0.25 THEN 1
            WHEN m_rank <= 0.5 THEN 2
            WHEN m_rank <= 0.75 THEN 3
            ELSE 4 
        END AS m_tier
    FROM tbl_rank
)
/*Combine tiers to create an RFM score and segment customers*/
, tbl_score AS (
    SELECT *, 
        CONCAT(r_tier, f_tier, m_tier) AS rfm_score
    FROM tbl_tier
)
/* Segment customers based on their RFM score*/
, tbl_seg AS (
    SELECT 
        customer_id,
        CASE 
            WHEN rfm_score = '444' THEN 'Best customers'
            WHEN rfm_score LIKE '4[1-3][1-3]' THEN 'New customers'
            WHEN rfm_score LIKE '[1-3]4[1-3]' THEN 'Loyal customers'
            WHEN rfm_score LIKE '[1-3][1-3]4' THEN 'High paying customers'
            WHEN rfm_score LIKE '44[1-3]' THEN 'New and regular customers'
            WHEN rfm_score LIKE '[1-3]44' THEN 'Regular high paying customers'
            WHEN rfm_score LIKE '4[1-3]4' THEN 'New high paying customers'
            WHEN rfm_score = '111' THEN 'Low-value customers'
            ELSE 'Normal customers' 
        END AS cus_segment 
    FROM tbl_score
)
/* Aggregate and calculate the proportion of each customer segment*/
, tbl_segment AS (
    SELECT 
        cus_segment,
        COUNT(customer_id) AS NumberOfCustomer
    FROM tbl_seg
    GROUP BY cus_segment
)
/* Display the customer segments along with their ratio */
SELECT *,
    ROUND(CAST(NumberOfCustomer AS FLOAT) / SUM(NumberOfCustomer) OVER (), 2) AS Percentage
FROM tbl_segment;
```
