-- SALES TREND ANALYSIS

with tbl_combine as (
    select 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        month(order_date) month,
        year(order_date) year,
        quantity,
        list_price,
        discount,
        final_price
    from sales.orders ord
    join sales.order_items ite
        on ite.order_id = ord.order_id
    join sales.stores sto 
        on sto.store_id = ord.store_id 
)
, tbl_state as (
    select state,
        year,
        sum(final_price) revenue_per_year
    from tbl_combine 
    group by state, year
)
select *,
    cast(revenue_per_year as float) / sum(revenue_per_year) over () ratio
from tbl_state
order by cast(revenue_per_year as float) / sum(revenue_per_year) over () desc

/* 
- Main market is in Newyork city, occupied over 68% total_sales from 2016 to 2018, respectively California for 21% and Texas for around 11%.
- The most profitable year is in 2017, 2016 is the second and the worst year is in 2018.
*/

-- 
with tbl_combine as (
    select 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        month(order_date) month,
        year(order_date) year,
        quantity,
        list_price,
        discount,
        final_price
    from sales.orders ord
    join sales.order_items ite
        on ite.order_id = ord.order_id
    join sales.stores sto 
        on sto.store_id = ord.store_id
)
, tbl_details as (
    select state, city, month, year,
        sum(final_price) total_sales
    from tbl_combine
    group by state, city, month, year
)
, tbl_ratio as (
    select *,
        cast(total_sales as float) / sum(total_sales) over (partition by year) ratio
    from tbl_details
)
, tbl_ym as (
    select month, year,
        sum(ratio) sum_ratio
    from tbl_ratio
    group by month, year
)
select *,
    rank() over (partition by month order by year) ranking
from tbl_ym

--- find customer, city and state

select 
    count(distinct order_id) as num_ord,
    count(distinct customer_id) as num_cus,
    count(distinct city) as num_city,
    count(distinct state) as num_state
from (
      select 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        ord.order_id,
        month(order_date) month,
        year(order_date) year,
        quantity,
        list_price,
        discount,
        final_price
    from sales.orders ord
    join sales.order_items ite
        on ite.order_id = ord.order_id
    join sales.stores sto 
        on sto.store_id = ord.store_id 
) as subquery

/* Based on the result, there are 1615 orders and 1445 customers from 3 different cities and 3 states from JAN 2016 to DEC 2018.*/

-- Determine the number of orders and sales for different days of the week.

select 
    DATENAME(weekday, ord.order_date) as day_order,
    count(distinct ord.order_id) num_orders,
    round(cast(sum(final_price) as float), 2) total_sales
from sales.orders ord
join sales.order_items ite
    on ite.order_id = ord.order_id
join sales.stores sto 
    on sto.store_id = ord.store_id 
group by DATENAME(weekday, ord.order_date)
order by round(sum(final_price), 2) desc

/* Base on the result, the company sold the most on Sunday and the mist quiet day is on wednesday*/

-- Check the monthly profitability and monthly quantity sold to see if there are patterns in the dataset.

with tbl_combine as (
    select 
        state,
        city,
        ord.store_id,
        ord.customer_id,
        ite.product_id,
        year(order_date) year,
        month(order_date) month,
        quantity,
        list_price,
        discount,
        final_price
    from sales.orders ord
    join sales.order_items ite
        on ite.order_id = ord.order_id
    join sales.stores sto 
        on sto.store_id = ord.store_id 
)
select 
    year,
    month,
    sum(final_price) sales_by_month,
    sum(quantity) quan_per_month
from tbl_combine
group by year, month
order by year,sales_by_month desc

/* From the result, the best selling month in 2016 is Sep, Aug, Oct. In 2017, the best selling month is in Jun, Mar, Feb. In 2018, the best selling month is Apr, Jan, Mar* 

--> No partern relaed for selling month.*/

-- Determine the number of times that salespeople hit or failed to hit the sales target for each category

with tbl_combine as (
    select 
        sta.staff_id,
        state,
        city,
        ord.store_id,
        ord.customer_id,
        cat.category_id,
        year(order_date) year,
        month(order_date) month,
        quantity,
        ite.list_price,
        discount,
        final_price
    from sales.orders ord
    join sales.order_items ite
        on ite.order_id = ord.order_id
    join sales.stores sto 
        on sto.store_id = ord.store_id 
    join sales.staffs sta
        on ord.staff_id = sta.staff_id
    join production.products pro 
        on pro.product_id = ite.product_id
    join production.categories cat 
        on cat.category_id = pro.category_id
)
-- find out the sale for each categories each month
, tbl_sort as (
    select year, month, staff_id, state, store_id, 
        sum(quantity) total_quantity,
        sum(final_price) total_sales
    from tbl_combine
    group by year, month, staff_id, category_id, state, store_id
)
-- find the top 3 sale person each year
, tbl_rank as (
    select year, month, staff_id, state, total_sales,
        rank() over( partition by year order by total_sales desc ) rank
    from tbl_sort
)
select *
from tbl_rank
where rank <= '3'