use fmcg;
select * from dim_campaigns;
select * from dim_stores;
select * from dim_products;
select * from fact_events;

-- PROBLEM STATMENT-1
-- Provide a list of products with a base price greater than 500 and 
-- that are featured in promo type of 'BOGOF' (Buy One Get One Free). This information will help us identify 
-- high-value products that 
-- are currently being heavily discounted, 
-- which can be useful for evaluating our pricing and promotion strategies.

select dp.product_name,fe.*
from fact_events fe
left join dim_products dp
on fe.product_id = dp.product_id
where fe.base_price>500 and fe.promo_type = 'BOGOF';	

-- PROBLEM STATMENT-2
-- find the number of stores in each city so that we can analyse the operations?
select city,count(distinct store_id) as total_stores,
	rank() over(order by count(distinct store_id) desc) as maximum_amount_of_stores
from dim_stores
group by city;
-- insight : bangluru and chennai has highest amount of retail stores so the maximum sales are coming from that state;

-- Problem statment-3
-- 3:Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
-- The report includes three key fields: campaign _name, total revenue(before_promotion), total revenue(after_promotion). 
-- This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)

select dc.campaign_name,
	round(sum(fe.base_price*fe.quantity_sold_before_promo)/1000000,2) as total_revenue_before_promo_in_Millions,
    round(sum(case 
            when fe.promo_type = "BOGOF" then ((fe.base_price-(fe.base_price*0.5))*fe.quantity_sold_after_promo)/1000000
			when fe.promo_type = "33% OFF" then ((fe.base_price-(fe.base_price*0.33))*fe.quantity_sold_after_promo)/1000000
            when fe.promo_type = "25% OFF" then ((fe.base_price-(fe.base_price*0.25)) * fe.quantity_sold_after_promo)/1000000
            when fe.promo_type = "500 Cashback" then ((fe.base_price-500) * fe.quantity_sold_after_promo)/1000000
			when fe.promo_type = " 50% OFF" then ((fe.base_price-(fe.base_price*0.5)) * fe.quantity_sold_after_promo)/1000000
            else 0 end ),2) as total_revenue_after_promo_in_Millions
	from fact_events fe
join dim_campaigns dc on fe.campaign_id = dc.campaign_id
group by dc.campaign_name;
-- growth_pecentage after campaign
	-- sakranti- 141.5%
    -- diwali - 151.2%
-- Problem statment-4
-- 4.	Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
-- Additionally, provide rankings for the categories based on their ISU%. 
-- The report will include three key fields: category, isu%, and rank order. 
-- This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.

-- incremntal sold quantity % = quantity sold before the action and the quantity sold after the action and there %
with promotion_table as
	(select dp.product_category,sum(quantity_sold_before_promo) as before_period,
						   sum(quantity_sold_after_promo) as after_period,
                           round(100*(sum(quantity_sold_after_promo)- sum(quantity_sold_before_promo))
                           /sum(quantity_sold_before_promo),2) as isu_percentage
from fact_events fe
left join  dim_products dp
on fe.product_id = dp.product_id
where fe.campaign_id="CAMP_DIW_01"
group by dp.product_category)
select  product_category,isu_percentage,
		rank() over(order by isu_percentage desc) as "isu%_rank"
from promotion_table;

-- Problem stat_5

-- Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
-- The report will provide essential information including product name, category, and ir%. This analysis 
-- helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.


with promo_calulation as
(select de.product_name ,
		de.product_category,
		sum(
			case 
            when fe.promo_type = "BOGOF" then (fe.base_price-(fe.base_price*0.5))*fe.quantity_sold_after_promo
			when fe.promo_type = "33% OFF" then (fe.base_price-(fe.base_price*0.33))*fe.quantity_sold_after_promo
            when fe.promo_type = "25% OFF" then (fe.base_price-(fe.base_price*0.25)) * fe.quantity_sold_after_promo
            when fe.promo_type = "500 Cashback" then (fe.base_price-500) * fe.quantity_sold_after_promo
			when fe.promo_type = " 50% OFF" then (fe.base_price-(fe.base_price*0.5)) * fe.quantity_sold_after_promo
            else 0 end/1000000) as total_revenue_after_promo,
		sum(fe.base_price*fe.quantity_sold_before_promo)/1000000   as total_revenue_before_promo
from dim_products de
left join fact_events  fe
on de.product_id = fe.product_id
group by de.product_name,de.product_category),


product_rank as (select product_name,
	 product_category,
		round(100*(total_revenue_after_promo-total_revenue_before_promo)/ total_revenue_before_promo,2)
		as  IR_precentage,
		rank() over(partition by product_category order by round(100*(total_revenue_after_promo-total_revenue_before_promo)/ total_revenue_before_promo,2) desc)
        as "Ir_rank"
from promo_calulation
order by IR_precentage desc,
		product_category asc
)
select product_name,product_category,IR_precentage
from product_rank
where Ir_rank<2
order by product_category ;



