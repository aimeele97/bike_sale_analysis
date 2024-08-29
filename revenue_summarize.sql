-- SALES TREND ANALYSIS

-- Combine data from orders, order items, and stores into a single table for analysis
WITH tbl_combine AS (
    SELECT 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        MONTH(order_date) AS month,
        YEAR(order_date) AS year,
        quantity,
        list_price,
        discount,
        final_price
    FROM sales.orders ord
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    JOIN sales.stores sto 
        ON sto.store_id = ord.store_id 
)
-- Calculate annual revenue per state
, tbl_state AS (
    SELECT state,
        year,
        SUM(final_price) AS revenue_per_year
    FROM tbl_combine 
    GROUP BY state, year
)
-- Calculate the revenue ratio for each state and sort by the highest ratio
SELECT *,
    CAST(revenue_per_year AS FLOAT) / SUM(revenue_per_year) OVER () AS ratio
FROM tbl_state
ORDER BY CAST(revenue_per_year AS FLOAT) / SUM(revenue_per_year) OVER () DESC;

/* 
- New York City is the main market, accounting for over 68% of total sales from 2016 to 2018, followed by California at 21% and Texas at around 11%.
- The most profitable year was 2017, followed by 2016, with 2018 being the least profitable year.
*/

-- SALES TREND ANALYSIS WITH MONTHLY DETAILS

-- Combine data from orders, order items, and stores into a single table for detailed analysis
WITH tbl_combine AS (
    SELECT 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        MONTH(order_date) AS month,
        YEAR(order_date) AS year,
        quantity,
        list_price,
        discount,
        final_price
    FROM sales.orders ord
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    JOIN sales.stores sto 
        ON sto.store_id = ord.store_id
)
-- Calculate total sales per city, state, month, and year
, tbl_details AS (
    SELECT state, city, month, year,
        SUM(final_price) AS total_sales
    FROM tbl_combine
    GROUP BY state, city, month, year
)
-- Calculate the sales ratio per year
, tbl_ratio AS (
    SELECT *,
        CAST(total_sales AS FLOAT) / SUM(total_sales) OVER (PARTITION BY year) AS ratio
    FROM tbl_details
)
-- Aggregate the sales ratio by month and year
, tbl_ym AS (
    SELECT month, year,
        SUM(ratio) AS sum_ratio
    FROM tbl_ratio
    GROUP BY month, year
)
-- Rank the sales ratio by year for each month
SELECT *,
    RANK() OVER (PARTITION BY month ORDER BY year) AS ranking
FROM tbl_ym;

-- CUSTOMER, CITY, AND STATE ANALYSIS

-- Determine the number of distinct orders, customers, cities, and states
SELECT 
    COUNT(DISTINCT order_id) AS num_ord,
    COUNT(DISTINCT customer_id) AS num_cus,
    COUNT(DISTINCT city) AS num_city,
    COUNT(DISTINCT state) AS num_state
FROM (
      SELECT 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        ord.order_id,
        MONTH(order_date) AS month,
        YEAR(order_date) AS year,
        quantity,
        list_price,
        discount,
        final_price
    FROM sales.orders ord
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    JOIN sales.stores sto 
        ON sto.store_id = ord.store_id 
) AS subquery;

/* Based on the result, there were 1,615 orders and 1,445 customers from 3 different cities and 3 states between January 2016 and December 2018. */

-- SALES ANALYSIS BY DAY OF THE WEEK

-- Determine the number of orders and total sales for each day of the week
SELECT 
    DATENAME(weekday, ord.order_date) AS day_order,
    COUNT(DISTINCT ord.order_id) AS num_orders,
    ROUND(CAST(SUM(final_price) AS FLOAT), 2) AS total_sales
FROM sales.orders ord
JOIN sales.order_items ite
    ON ite.order_id = ord.order_id
JOIN sales.stores sto 
    ON sto.store_id = ord.store_id 
GROUP BY DATENAME(weekday, ord.order_date)
ORDER BY ROUND(SUM(final_price), 2) DESC;

/* Based on the result, the company sold the most on Sundays, and the quietest day for sales was Wednesday. */

-- MONTHLY PROFITABILITY AND QUANTITY ANALYSIS

-- Combine data from orders, order items, and stores for monthly profitability analysis
WITH tbl_combine AS (
    SELECT 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        quantity,
        list_price,
        discount,
        final_price
    FROM sales.orders ord
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    JOIN sales.stores sto 
        ON sto.store_id = ord.store_id 
)
-- Calculate total sales and quantity sold per month and year
SELECT 
    year,
    month,
    SUM(final_price) AS sales_by_month,
    SUM(quantity) AS quan_per_month
FROM tbl_combine
GROUP BY year, month
ORDER BY year, sales_by_month DESC;

/* The best-selling months in 2016 were September, August, and October. In 2017, June, March, and February led sales. In 2018, the top months were April, January, and March.
   --> No consistent pattern was identified for the best-selling months. */

-- SALES PERFORMANCE ANALYSIS FOR SALESPEOPLE BY CATEGORY

-- Combine data from orders, order items, stores, and products for sales performance analysis
WITH tbl_combine AS (
    SELECT 
        sta.staff_id,
        state,
        city,
        ord.store_id,
        ord.customer_id,
        cat.category_id,
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        quantity,
        ite.list_price,
        discount,
        final_price
    FROM sales.orders ord
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    JOIN sales.stores sto 
        ON sto.store_id = ord.store_id 
    JOIN sales.staffs sta
        ON ord.staff_id = sta.staff_id
    JOIN production.products pro 
        ON pro.product_id = ite.product_id
    JOIN production.categories cat 
        ON cat.category_id = pro.category_id
)
-- Calculate total sales and quantity sold for each category by month and year
, tbl_sort AS (
    SELECT year, month, staff_id, state, store_id, 
        SUM(quantity) AS total_quantity,
        SUM(final_price) AS total_sales
    FROM tbl_combine
    GROUP BY year, month, staff_id, category_id, state, store_id
)
-- Rank the top 3 salespeople each year based on total sales
, tbl_rank AS (
    SELECT year, month, staff_id, state, total_sales,
        RANK() OVER(PARTITION BY year ORDER BY total_sales DESC) AS rank
    FROM tbl_sort
)
-- Select only the top 3 salespeople
SELECT *
FROM tbl_rank
WHERE rank <= 3;
