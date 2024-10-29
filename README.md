# Analyzing Bike Store Revenue: Insights from 2016 to 2018

![Bike Store Logo](https://github.com/Aimee-Le/BikeStoreAnalysis/blob/main/logomain.png)

__Problem Statement__:
In the competitive world of retail, data-driven decisions can make all the difference. This blog explores an analysis of a bicycle store's performance from 2016 to 2018, focusing on key business questions to drive future growth.

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

## Business Questions
1. **Total orders, quantity sold, and revenue by year.**
2. **Monthly revenue accumulation.**
3. **Monthly sales figures and growth rates.**
4. **Highest revenue contributions by state.**
5. **Top 3 best-selling months by state.**
6. **Top 3 performance months by state.**
7. **Sales patterns by weekday.**
8. **Top 10 performing product categories.**
9. **Top 3 bikes by category.**
10. **Impact of customer segmentation on sales.**

## Key Findings

### Sales Trends

- **Performance Peaks**: The store's performance peaked in 2017, followed by a notable decline in 2018, suggesting an overall downward trend.
  
### Market Insights

- **Dominance of New York**: New York contributed approximately 65% of total revenue each year.
  
### Revenue Fluctuations

- Revenue saw drastic changes, dropping from $537,192 in April 2018 to $188.99 in June due to a closure in May, before rebounding to $9,484 in July.
  
### Sales Patterns

- No consistent best-selling months across states indicate that sales are not heavily seasonally dependent.
  
### Ordering Trends

- New York saw peak orders on Sundays, Tuesdays, and Thursdays, while Texas's highest orders were on Sundays and Mondays.

### Product Insights

- **Top-Selling Category**: Cruisers comprised 29% of total sales, with Electra being the most popular brand.

### Customer Breakdown

- The customer base consisted of 44% regulars, 20% new customers, with high-paying and regular customers accounting for 11% and 12%, respectively.

## Recommendations for Future Growth

To reverse the downward trend and capitalize on market potential, consider the following strategies:

- **Targeted Marketing**: Investigate the reasons for the sales decline post-2017 and implement focused marketing campaigns, especially in New York.
- **Inventory Management**: Utilize data analytics to optimize inventory levels based on peak ordering times.
- **Customer Engagement**: Develop loyalty programs, introduce seasonal promotions, and enhance the online shopping experience.
- **Staff Training**: Invest in employee training and establish a feedback loop to ensure excellent customer service.

## Sample SQL Queries Used in the Analysis

Here are a few SQL queries that were instrumental in deriving the insights:

### Total Orders, Quantity, and Revenue by Year
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

### Monthly Revenue Accumulation
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

### Impact of Customer Segmentation on Sales
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
