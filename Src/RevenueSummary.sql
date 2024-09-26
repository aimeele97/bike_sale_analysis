-- REVENUE SUMMARY

-- Question 1: What are the total orders, quantity, and revenue generated each year?

/* Create VIEW for table combine */
DROP VIEW tbl_combine
CREATE VIEW tbl_combine AS 
    SELECT ord.order_id, ord.customer_id, ord.order_date, Month(ord.order_date) as Month, Year(ord.order_date) as Year, product_id, staff_id, quantity, list_price, discount, final_price, sto.store_id, store_name, city, [state], zip_code
    FROM sales.orders ord
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    JOIN sales.stores sto 
        ON sto.store_id = ord.store_id 

SELECT 
    Year,
    count(order_id) NumberOrders,
    sum(quantity) Quantity,
    round(sum(final_price), 2) TotalRevenue
FROM tbl_combine
GROUP BY Year
ORDER BY Year;
-- Question 2: What is the revenue accumulative each month ?

WITH monthly_sales AS (
    SELECT
        year,
        month,
        SUM(final_price) AS total_sales
    FROM tbl_combine
    GROUP BY year, month
)
SELECT 
    year, 
    month, 
    total_sales,
    CAST(SUM(total_sales) OVER (ORDER BY year, month) AS NUMERIC(10,2)) AS accumulative
FROM monthly_sales;

-- Question 3: What are the monthly sales figures, growth-rate per month to predict for next month’s sales?
SELECT 
    Month,
    Year,
    SUM(final_price) recent_sale,
    LAG(SUM(final_price)) over (order by year desc, month) previous_sale,
    SUM(final_price) - LAG(SUM(final_price)) OVER (ORDER BY year DESC, Month) sale_growth,
    ROUND(100 *(SUM(final_price) - LAG(SUM(final_price)) OVER (ORDER BY year DESC, month)) / (SUM(final_price) + LAG(SUM(final_price)) OVER (ORDER BY year DESC, month)), 2) growth_rate
FROM tbl_combine
GROUP BY Month, Year 

SELECT
    year,
    month,
    SUM(final_price) total_sales
FROM tbl_combine
GROUP BY ROLLUP(year,month)
ORDER BY year , month;

-- Question 4: What are the monthly sales figures, growth-rate per month to predict for next month’s sales?
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

-- Question 5: What are the monthly sales figures, growth-rate per month to predict for next month’s sales?
WITH group_tbl AS (
    SELECT 
        Month,
        Year,
        state,
        count(distinct order_id) NumberOrders,
        sum(quantity) Quantity,
        round(sum(final_price), 2) TotalRevenue
    FROM tbl_combine
    GROUP BY state, Year, Month
)
, tbl_rank AS (
    SELECT * ,
        ROUND(TotalRevenue / SUM(TotalRevenue) OVER (PARTITION BY year), 2) AS Ratio,
        RANK() OVER (PARTITION BY year ORDER BY TotalRevenue desc) rank
    FROM group_tbl
)
SELECT *
FROM tbl_rank
WHERE rank <=3

-- Question 6: What are the monthly sales figures, growth-rate per month to predict for next month’s sales?
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

-- Question 7: What are the monthly sales figures, growth-rate per month to predict for next month’s sales?
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

