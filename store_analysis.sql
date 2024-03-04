-- Store Analysis Insight:
-- Which are the top 10 stores in terms of Incremental Revenue (IR) generated from the promotions?

with store_cte as(SELECT 
    store_id,
    round(SUM(base_price * quantity_sold_before_promo)/1000000,2) AS total_revenue_before_promo_in_millions,
    round(SUM(
        CASE 
            WHEN promo_type = 'BOGOF' THEN (base_price - (base_price * 0.5)) * quantity_sold_after_promo
            WHEN promo_type = '33% OFF' THEN (base_price - (base_price * 0.33)) * quantity_sold_after_promo
            WHEN promo_type = '25% OFF' THEN (base_price - (base_price * 0.25)) * quantity_sold_after_promo
            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
            WHEN promo_type = '50% OFF' THEN (base_price - (base_price * 0.5)) * quantity_sold_after_promo
            ELSE 0
        END/1000000
		),2) AS total_revenue_after_promo_in_millions
FROM  
    fact_events
GROUP BY 
    store_id),
store_rankings as (select store_id, round(100*(total_revenue_after_promo_in_millions-total_revenue_before_promo_in_millions)/total_revenue_before_promo_in_millions,2)
	as IR_percentage,
    rank() over(order by round(100*(total_revenue_after_promo_in_millions-total_revenue_before_promo_in_millions)/total_revenue_before_promo_in_millions,2)) as store_rank
from store_cte)
select store_id,IR_percentage
from store_rankings
where store_rank<=10;

-- Which are the bottom 10 stores when it comes to Incremental Sold Units (ISU) during the promotional period?
with bottom_10_store as(select store_id,	
	round(100*(sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))/ sum(quantity_sold_before_promo),2)  as "Diwali_ISU",
    rank() over( order by 100*(sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))/ sum(quantity_sold_before_promo) asc) as rnk
from fact_events
where campaign_id = "CAMP_DIW_01"
group by store_id)
select store_id,Diwali_ISU
from bottom_10_store
where rnk<=10;




with bottom_10_store as(select store_id,	
	round(100*(sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))/ sum(quantity_sold_before_promo),2)  as "Diwali_ISU",
    rank() over(order by 100*(sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))/ sum(quantity_sold_before_promo) asc) as rnk
from fact_events
where campaign_id = "CAMP_SAN_01"
group by store_id)
select store_id,Diwali_ISU
from bottom_10_store
where rnk<=10;
