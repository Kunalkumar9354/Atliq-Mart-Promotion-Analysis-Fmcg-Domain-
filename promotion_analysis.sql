-- Promotional Type 
-- What are the top 2 promotion types that resulted in the highest Incremental Revenue?
with promo_cte as(SELECT 
    promo_type,
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
    promo_type),
promo_rankings as (select promo_type, round(100*(total_revenue_after_promo_in_millions-total_revenue_before_promo_in_millions)/total_revenue_before_promo_in_millions,2)
	as IR_percentage,
    rank() over(order by round(100*(total_revenue_after_promo_in_millions-total_revenue_before_promo_in_millions)/total_revenue_before_promo_in_millions,2) desc) as store_rank
from promo_cte)

select promo_type,IR_percentage
from promo_rankings
where store_rank<=2;
	
--  	What are the bottom 2 promotion types in terms of their impact on Incremental Sold Units?
with bottom_2 as 
(select promo_type,sum(quantity_sold_before_promo) as before_period,
						   sum(quantity_sold_after_promo) as after_period,
                           round(100*(sum(quantity_sold_after_promo)- sum(quantity_sold_before_promo))
                           /sum(quantity_sold_before_promo),2) as isu_percentage,
                           rank() over(order by round(100*(sum(quantity_sold_after_promo)- sum(quantity_sold_before_promo))
                           /sum(quantity_sold_before_promo),2) asc)  as  promo_rank
from fact_events
group by promo_type)
select promo_type,
	isu_percentage
from bottom_2
where promo_rank<=2;
	
--  	Is there a significant difference in the performance of discount-based promotions versus BOGOF (Buy One Get One Free) or cashback promotions?
select sum(base_price* quantity_sold_after_promo) as total_revenue
from fact_events
where promo_type = "BOGOF";
select sum(base_price* quantity_sold_after_promo) as total_revenue
from fact_events
where promo_type = "500 cashback";