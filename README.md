# Analyzing Bike Store Revenue: Insights from 2016 to 2018

![Bike Store Logo](https://github.com/Aimee-Le/BikeStoreAnalysis/blob/main/logomain.png)

__Problem Statement__:
In the competitive world of retail, data-driven decisions can make all the difference. This analysis explores a bicycle store's performance from 2016 to 2018, focusing on key business questions to drive future growth.

## Objectives of the Analysis

This project aims to achieve several critical objectives:

- **Sales Analysis**: Examine annual and monthly sales figures, including cumulative sales and growth rates.
- **Revenue Insights**: Identify patterns and contributions from different states, peak sales months, and ordering trends throughout the week.
- **Product Performance**: Evaluate how different categories, brands, and individual products performed.
- **Customer Segmentation**: Implement RFM (Recency, Frequency, Monetary) analysis to better understand customer behavior.

## Key Tasks Undertaken

1. **Workspace Setup**: Downloading and importing relevant CSV files into a database using Azure Data Studio.
2. **Data Understanding**: Grasping the data structure, defining business problems, and formulating key analytical questions.
3. **Data Cleaning**: Ensuring accuracy by correcting data types, handling null values, and removing irrelevant columns.
4. **Data Analysis**: Answering business questions while optimizing SQL queries for performance.
5. **Documentation**: Summarizing findings and methodologies for clear presentation in the GitHub repository.

## Dataset Information

The data used for this analysis comes from a sample provided in the [SQL Server Tutorial](http://www.sqlservertutorial.net/load-sample-database/).

## Business Questions Explored

The analysis focused on ten key business questions, including:

### Key metrics
1. What were the total orders, quantity sold, and revenue generated each year?
2. How did the monthly revenue accumulate over the analysis period?
3. What were the monthly sales figures, and how did the growth rate fluctuate month-over-month?

### State Performance
4. Which states contributed the highest revenue each year?
5. What were the top three best-selling months for each state?
6. Which three months had the highest performance (in terms of revenue) for each state?

### Sales Patterns
7. What are the sales patterns observed across different weekdays?

### Product Performance
8. Which product categories performed the best in terms of sales?
9. What are the top three bikes sold in each product category?

### Customer Insights
10. How does customer segmentation (based on RFM analysis) impact overall sales performance?

## Key Findings
- 2017 was the best-selling year, but there has been a decline since then, with a notable drop in sales starting in June 2018.
- New York contributed about 65% of total revenue. Targeted marketing efforts should focus on this state.
- Cruisers accounted for 29% of total sales, with Electra being the top brand.
- 44% of customers were regulars, highlighting opportunities for enhanced loyalty programs.

## Recommendations for Future Growth

- Since New York is the largest market and a major revenue contributor, it’s crucial to enhance our presence there. Strategies should include targeted marketing campaigns, improving customer engagement, and forming partnerships with local businesses to boost sales.
- Consider promotional campaigns specifically for cruisers to capitalize on this strong market segment.
- Strengthen customer retention through enhanced loyalty programs that reward frequent purchases and engagement.
- 
## Sample SQL Queries Used in the Analysis

Here are a few SQL queries that were instrumental in deriving the insights:

### What were the total orders, quantity sold, and revenue generated each year?
```sql
SELECT 
    Year,
    COUNT(order_id) AS NumberOrders,
    SUM(quantity) AS Quantity,
    CAST(SUM(final_price) AS NUMERIC(10,2)) AS TotalRevenue
FROM tbl_combine
GROUP BY Year
ORDER BY Year;
```

### How did the monthly revenue accumulate over the analysis period?
```sql
WITH monthly_sales AS (
    SELECT
        year,
        month,
        CAST(SUM(final_price) AS NUMERIC(10,2)) AS total_sales
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

### How does customer segmentation (based on RFM analysis) impact overall sales performance?
```sql
WITH tbl_rfm AS (
    SELECT 
        customer_id,
        DATEDIFF(day, MAX(order_date), '2018-12-28') AS recency,
        COUNT(order_id) AS frequency,
        ROUND(SUM(CAST(final_price AS FLOAT)), 2) AS monetary
    FROM tbl_combine
    GROUP BY customer_id
),
tbl_rank AS (
    SELECT *,
        PERCENT_RANK() OVER (ORDER BY recency) AS r_rank,
        PERCENT_RANK() OVER (ORDER BY frequency) AS f_rank,
        PERCENT_RANK() OVER (ORDER BY monetary) AS m_rank
    FROM tbl_rfm
),
tbl_tier AS (
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
SELECT 
    CONCAT(r_tier, f_tier, m_tier) AS rfm_score,
    COUNT(customer_id) AS NumberOfCustomer
FROM tbl_tier
GROUP BY rfm_score;
```

## Conclusion

The analysis of the bike store's performance provides valuable insights into sales trends, customer behavior, and product performance. By leveraging these findings, the business can implement targeted strategies for growth and sustainability in a competitive market. As always, continuous analysis and adaptation will be key to long-term success.
