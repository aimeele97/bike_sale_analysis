-- CUSTOMER SEGMENTATION - RFM ANALYSIS 

-- Step 1: Calculate RFM (Recency, Frequency, Monetary) for each customer

/* 
ALTER TABLE sales.order_items
ADD final_price AS (list_price * (1 - discount)) PERSISTED;
*/

-- Create a view for customer segmentation using RFM analysis
WITH tbl_rfm AS (
    SELECT 
        cus.customer_id,
        -- Calculate recency as the number of days since the last purchase
        DATEDIFF(day, MAX(order_date), '2018-12-28') AS recency,
        -- Calculate frequency as the total number of items purchased
        COUNT(ite.item_id) AS frequency,
        -- Calculate monetary value as the total spending of the customer
        ROUND(SUM(CAST(final_price AS FLOAT)), 2) AS monetary
    FROM sales.customers cus 
    JOIN sales.orders ord 
        ON cus.customer_id = ord.customer_id 
    JOIN sales.order_items ite
        ON ite.order_id = ord.order_id
    GROUP BY cus.customer_id
)

-- Step 2: Calculate the percentile rank for each RFM metric
, tbl_rank AS (
    SELECT *,
        -- Rank customers based on recency, frequency, and monetary value
        PERCENT_RANK() OVER (ORDER BY recency) AS r_rank,
        PERCENT_RANK() OVER (ORDER BY frequency) AS f_rank,
        PERCENT_RANK() OVER (ORDER BY monetary) AS m_rank
    FROM tbl_rfm
)

-- Step 3: Categorize customers into tiers based on RFM scores
, tbl_tier AS (
    SELECT *,
        -- Assign tiers based on percentile rank
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

-- Step 4: Combine tiers to create an RFM score and segment customers
, tbl_score AS (
    SELECT *, 
        -- Concatenate the RFM tiers to create a unique RFM score for each customer
        CONCAT(r_tier, f_tier, m_tier) AS rfm_score
    FROM tbl_tier
)

-- Step 5: Segment customers based on their RFM score
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

-- Step 6: Aggregate and calculate the proportion of each customer segment
, tbl_segment AS (
    SELECT 
        cus_segment,
        COUNT(customer_id) AS num_cus
    FROM tbl_seg
    GROUP BY cus_segment
)

-- Step 7: Display the customer segments along with their ratio
SELECT *,
    ROUND(CAST(num_cus AS FLOAT) / SUM(num_cus) OVER (), 2) AS ratio
FROM tbl_segment;

-- Retrieve and display customer segmentation results, sorted by ratio
SELECT *
FROM dbo.customer_segmentation
ORDER BY ratio DESC;

/*
Best Customers: These are the top performers, making recent, frequent, and high-value purchases. Retaining them is critical.

New Customers: Recently acquired but not yet loyal. Personalized offers can convert them into repeat buyers.

Loyal Customers: Frequent buyers who may not spend the most but are consistent. Loyalty programs can keep them engaged.

High Paying Customers: High spenders per transaction but infrequent shoppers. Premium offers could increase their frequency.

Low-Value Customers: Infrequent buyers with low spending. Targeted promotions may boost their engagement.

Normal Customers: Represent the average, with potential to be nurtured into higher-value segments.
*/




