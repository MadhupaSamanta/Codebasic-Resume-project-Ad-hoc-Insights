
USE `gdb023`;

----------------------------------------------------------------------------------------------------------------------
# Req 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

CREATE VIEW req_1 AS
    (SELECT DISTINCT
        (market)
    FROM
        dim_customer
    WHERE
        customer = 'Atliq Exclusive'
            AND region = 'APAC');
        
SELECT 
    *
FROM
    req_1;
   
-----------------------------------------------------------------------------------------------------------------------   

# Req 2. What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields, 
--                 unique_products_2020    unique_products_2021     percentage_chg

CREATE VIEW req_2 AS
(
WITH cte_unique_product_2020 AS
                         (SELECT 
    COUNT(DISTINCT (product_code)) AS unique_products_2020
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020),
cte_unique_product_2021 AS
                        (SELECT 
    COUNT(DISTINCT (product_code)) AS unique_products_2021
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2021)
SELECT 
    unique_products_2020,
    unique_products_2021,
    ROUND(((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100,
            2) AS percentage_chg
FROM
    cte_unique_product_2020,
    cte_unique_product_2021
);

SELECT 
    *
FROM
    req_2;
-----------------------------------------------------------------------------------------------------------------------------------

# Req 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields,
 --                      segment     product_count


CREATE VIEW req_3 AS
(
SELECT 
    segment, COUNT(DISTINCT (product_code)) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY 2 DESC
   ) ;

SELECT 
    *
FROM
    req_3;
----------------------------------------------------------------------------------------------------------------------------------------

# Req 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, 
--                    segment    product_count_2020     product_count_2021     difference


create view req_4 as
(
with cte_2020 as
				(select p.segment, count(distinct(s.product_code)) as product_count_2020
                     from dim_product p 
                      join fact_sales_monthly s
                           on p.product_code = s.product_code
                              where s.fiscal_year = 2020
                                    group by segment) ,
cte_2021 as
              (select p.segment , count(distinct(s.product_code)) as product_count_2021 
                from dim_product p 
                  join fact_sales_monthly s
                    on p.product_code = s.product_code
                      where s.fiscal_year = 2021
                         group by segment)

SELECT 
    cte_2020.segment,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 AS difference
FROM
    cte_2020
        JOIN
    cte_2021 ON cte_2020.segment = cte_2021.segment
ORDER BY difference DESC
);

SELECT 
    *
FROM
    req_4;
-----------------------------------------------------------------------------------------------------------------------------------------

# Req.5 Get the products that have the highest and lowest manufacturing costs.
 -- The final output should contain these fields,
 --                 product_code      product       manufacturing_cost          

CREATE VIEW req_5 AS
(
(SELECT 
    p.product_code,
    p.product,
    m.manufacturing_cost AS product_manufacturing_cost
FROM
    dim_product p
        JOIN
    fact_manufacturing_cost m ON p.product_code = m.product_code
GROUP BY product_code
ORDER BY manufacturing_cost DESC
LIMIT 1) 
union all
(SELECT 
    p.product_code,
    p.product,
    m.manufacturing_cost AS product_manufacturing_cost
FROM
    dim_product p
        JOIN
    fact_manufacturing_cost m ON p.product_code = m.product_code
GROUP BY product_code
ORDER BY manufacturing_cost
LIMIT 1)
);

SELECT 
    *
FROM
    req_5;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Req 6. Generate a report which contains the top 5 customers 
-- who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
 -- The final output contains these fields,
   --                         customer_code      customer       average_discount_percentage


CREATE VIEW req_6 AS
(
SELECT 
    c.customer_code,
    c.customer,
    ROUND(AVG(i.pre_invoice_discount_pct),4) AS average_discount_percentage
FROM
    dim_customer c
        JOIN
    fact_pre_invoice_deductions i ON c.customer_code = i.customer_code
WHERE
    fiscal_year = 2021 AND market = 'India'
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5
);

SELECT 
    *
FROM
    req_6;
-----------------------------------------------------------------------------------------------------------------------------------------



# REQ.7  Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
--                     (The final report contains these columns: Month, Year, Gross sales Amount )

CREATE VIEW req_7 AS
    (SELECT 
        DATE_FORMAT(date, '%M') AS month,
        YEAR(date) AS `year`,
        ROUND(SUM(gross_price * sold_quantity), 2) AS gross_sales_amount
    FROM
        (SELECT 
            c.customer, s.date, s.product_code, s.sold_quantity
        FROM
            dim_customer c
        INNER JOIN fact_sales_monthly s ON c.customer_code = s.customer_code) j
            INNER JOIN
        fact_gross_price g ON j.product_code = g.product_code
    WHERE
        j.customer = 'Atliq Exclusive'
    GROUP BY month , year
    ORDER BY year);

SELECT 
    *
FROM
    req_7;

-------------------------------------------------------------------------------------------------------------------------------------------

# Req 8. In which quarter of 2020, got the maximum total_sold_quantity?
--   The final output contains these fields sorted by the total_sold_quantity : Quarter, total_sold_quantity


CREATE VIEW req_8 AS
(
WITH cte_monthly_sales as (SELECT date, MONTH(date) as month, sold_quantity 
							FROM fact_sales_monthly
								WHERE fiscal_year=2020)
					 SELECT CASE
							WHEN MONTH(date) in (9,10,11) THEN 'Q1'
							WHEN MONTH(date) in (12,1,2) THEN 'Q2'
							WHEN MONTH(date) in (3,4,5) THEN 'Q3'
							WHEN MONTH(date) in (6,7,8) THEN 'Q4' END AS Quarter, SUM(sold_quantity) AS total_sold_quantity
								FROM cte_monthly_sales
									GROUP BY Quarter
									ORDER BY total_sold_quantity DESC 
                                    );
	
    SELECT 
    *
FROM
    req_8;

-------------------------------------------------------------------------------------------------------------------------------------------

# Req 9.  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
--          The final output contains these fields: channel, gross_sales_mln, percentage

CREATE VIEW req_9 AS
(
WITH cte AS
(
SELECT 
    c.channel,
    SUM(s.sold_quantity * g.gross_price) AS total_sales
FROM
    dim_customer c
        INNER JOIN
    fact_sales_monthly s ON c.customer_code = s.customer_code
        INNER JOIN
    fact_gross_price g ON s.product_code = g.product_code
WHERE
    s.fiscal_year = 2021 and g.fiscal_year = 2021
GROUP BY c.channel
ORDER BY total_sales DESC
)
SELECT
   channel,
    round(total_sales/1000000,2) AS gross_sales_in_mln,
     round(total_sales/(sum(total_sales) OVER())*100,2) AS percentage 
FROM cte
) ;

SELECT 
    *
FROM
    req_9;

---------------------------------------------------------------------------------------------------------------------------------


# Req 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
--          (The final output contains these fields: division, product_code,product, total_sold_quantity, rank_order)

create view req_10 as
( 
with cte1 as
(
select p.division, p.product_code, concat(p.product,"(",p.variant,")") AS product, sum(s.sold_quantity) as total_sold_quantity
from dim_product p
inner join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.product_code
),
cte2 as 
(
select *, dense_rank() over (partition by division order by total_sold_quantity desc) as rank_order 
from cte1
)
select *
from cte2
where rank_order <= 3
);

SELECT 
    *
FROM
    req_10;
----------------------------------------------------------------------------------------------------------------------------------------


# ADDITIONAL QUERY .
-- Month wise Gross Sales of AtliQ in FY 2020 to FY 2021

CREATE VIEW q11 AS
(
SELECT 
        DATE_FORMAT(date, '%M') AS month,
        YEAR(date) AS `year`, date,
        ROUND(SUM(gross_price * sold_quantity), 2) AS gross_sales_amount
    FROM
        (SELECT 
            c.customer, s.date, s.product_code, s.sold_quantity
        FROM
            dim_customer c
        INNER JOIN fact_sales_monthly s ON c.customer_code = s.customer_code) j
            INNER JOIN
        fact_gross_price g ON j.product_code = g.product_code
    
    GROUP BY month , year
    ORDER BY year

);

SELECT 
    *
FROM
    q11;
------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------



-- 




















