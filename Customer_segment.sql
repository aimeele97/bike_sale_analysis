-- CUSTOMER SEGMENTATION - RFM ANALYSIS 
-- Step 1: RFM for each customer

/* 
ALTER TABLE sales.order_items
ADD final_price AS (list_price * (1 - discount)) PERSISTED;
*/

-- create view customer_segmentation as 
with tbl_rfm as (
select cus.customer_id,
    recency = datediff( day, max(order_date), '2018-12-28'),
    frequency = count(ite.item_id),
    monetary = round(sum(cast(final_price as float)), 2)
from sales.customers cus 
join sales.orders ord 
on cus.customer_id = ord.customer_id 
join sales.order_items ite
on ite.order_id = ord.order_id
group by cus.customer_id
)

-- Step 2: Percentile position
, tbl_rank as (
select *,
    PERCENT_RANK() over (order by recency) as r_rank,
    PERCENT_RANK() over (order by frequency) as f_rank,
    PERCENT_RANK() over (order by monetary) as m_rank
from tbl_rfm
)
-- Step3: Catergorize by 4 tiers
, tbl_tier as (
select *,
    case when r_rank <= 0.25 then 1
        when r_rank <= 0.5 then 2
        when r_rank <= 0.75 THEN 3
        else 4 end as r_tier,
    case when f_rank <= 0.25 then 1
        when f_rank <= 0.5 then 2
        when f_rank <= 0.75 THEN 3
        else 4 end as f_tier,
    case when m_rank <= 0.25 then 1
        when m_rank <= 0.5 then 2
        when m_rank <= 0.75 then 3
        else 4 end as m_tier
from tbl_rank
)
, tbl_score as(
    select *, 
        concat(r_tier, f_tier, m_tier) rfm_score
    from tbl_tier
)
-- Step 4: Segmentation by customer behaviours
, tbl_seg as (
    select customer_id,
        case when rfm_score = '444' then 'Best customers'
        when rfm_score like '4[1-3][1-3]' then 'New customers'
        when rfm_score like '[1-3]4[1-3]' then 'Loyal customers'
        when rfm_score like '[1-3][1-3]4' then 'High paying customers'
        when rfm_score like '44[1-3]' then 'New and regular customers'
        when rfm_score like '[1-3]44' then 'Regular high paying customers'
        when rfm_score like '4[1-3]4' then 'New high paying customers'
        when rfm_score = '111' then 'Low-value customers'
        else 'Nomal customers' end as cus_segment 
    from tbl_score
)
, tbl_segment as (
    select cus_segment,
        count(customer_id) as num_cus
    from tbl_seg
    group by cus_segment
)
select *
    , round(cast (num_cus as float) / sum(num_cus) over (),2) ratio
from tbl_segment;

select *
from dbo.customer_segmentation
order by ratio desc 
