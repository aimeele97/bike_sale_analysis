-- PRODUCT PERFORMANCE ANALYSIS

-- Create a view to aggregate product sales details

CREATE VIEW product_sales_details AS 
SELECT 
    pro.product_id,
    pro.product_name,
    cat.category_id,
    cat.category_name,
    bra.brand_id,
    bra.brand_name,
    pro.model_year,
    ite.list_price,
    SUM(ite.quantity) AS total_quantity,
    ROUND(CAST(SUM(final_price) AS FLOAT), 2) AS total_sales
FROM sales.order_items ite
JOIN production.products pro
    ON ite.product_id = pro.product_id
JOIN production.categories cat 
    ON cat.category_id = pro.category_id
JOIN production.brands bra 
    ON bra.brand_id = pro.brand_id
GROUP BY 
    pro.product_id,
    pro.product_name,
    cat.category_id,
    cat.category_name,
    bra.brand_id,
    bra.brand_name,
    pro.model_year,
    ite.list_price;


-- Calculate the ratio of quantity and sales by category
WITH category_performance AS (
    SELECT 
        category_id, 
        category_name, 
        CAST(total_quantity AS FLOAT) / SUM(total_quantity) OVER () AS quantity_ratio, 
        CAST(total_sales AS FLOAT) / SUM(total_sales) OVER () AS sales_ratio
    FROM dbo.product_sales_details
)
SELECT 
    category_id, 
    category_name,
    ROUND(SUM(quantity_ratio), 2) AS total_quantity_ratio, 
    ROUND(SUM(sales_ratio), 2) AS total_sales_ratio
FROM category_performance
GROUP BY category_id, category_name
ORDER BY total_quantity_ratio DESC, total_sales_ratio DESC;

-- Analysis of top 10 performing bikes by category (High Sales Volumes)
WITH item_performance AS (
    SELECT *,
        CAST(total_sales AS FLOAT) / total_quantity AS sales_per_item
    FROM dbo.product_sales_details
),
sales_ratio_per_category AS (
    SELECT 
        category_name, 
        product_name,
        CAST(sales_per_item AS FLOAT) / SUM(sales_per_item) OVER (PARTITION BY category_name) AS ratio
    FROM item_performance
),
ranked_sales AS (
    SELECT 
        category_name, 
        product_name, 
        ratio,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY ratio DESC) AS rank
    FROM sales_ratio_per_category
)
SELECT 
    category_name,
    product_name,
    ROUND(ratio, 2) AS sales_ratio
FROM ranked_sales
WHERE rank <= 10;

-- Top 10 most selling bikes by category
WITH quantity_ratio_per_category AS (
    SELECT 
        *,
        CAST(total_quantity AS FLOAT) / SUM(total_quantity) OVER (PARTITION BY category_name) AS ratio
    FROM dbo.product_sales_details
),
ranked_quantity AS (
    SELECT 
        category_name, 
        product_name, 
        ratio,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY ratio DESC) AS rank
    FROM quantity_ratio_per_category
)
SELECT 
    category_name,
    product_name,
    ROUND(ratio, 2) AS quantity_ratio
FROM ranked_quantity
WHERE rank <= 10;

-- Top 10 worst performing bikes by category (High Sales Volumes)
WITH item_performance AS (
    SELECT *,
        CAST(total_sales AS FLOAT) / total_quantity AS sales_per_item
    FROM dbo.product_sales_details
),
sales_ratio_per_category AS (
    SELECT 
        category_name, 
        product_name,
        CAST(sales_per_item AS FLOAT) / SUM(sales_per_item) OVER (PARTITION BY category_name) AS ratio
    FROM item_performance
),
ranked_sales AS (
    SELECT 
        category_name, 
        product_name, 
        ratio,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY ratio ASC) AS rank
    FROM sales_ratio_per_category
)
SELECT 
    category_name,
    product_name,
    ROUND(ratio, 2) AS sales_ratio
FROM ranked_sales
WHERE rank <= 10;

-- Top 10 least selling bikes by category
WITH quantity_ratio_per_category AS (
    SELECT 
        *,
        CAST(total_quantity AS FLOAT) / SUM(total_quantity) OVER (PARTITION BY category_name) AS ratio
    FROM dbo.product_sales_details
),
ranked_quantity AS (
    SELECT 
        category_name, 
        product_name, 
        ratio,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY ratio ASC) AS rank
    FROM quantity_ratio_per_category
)
SELECT 
    category_name,
    product_name,
    ROUND(ratio, 2) AS quantity_ratio
FROM ranked_quantity
WHERE rank <= 10;

-- Top 10 best selling bikes by quantity
SELECT TOP 10
    category_name,
    product_id,
    total_quantity,
    total_sales
FROM dbo.product_sales_details
ORDER BY total_quantity DESC, category_name;

-- Top 10 worst selling bikes by quantity
SELECT 
    category_name,
    product_id,
    total_quantity,
    total_sales
FROM dbo.product_sales_details
WHERE total_quantity = 1;
