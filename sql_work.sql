-- task 1
-- /Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region/
SELECT distinct market  FROM gdb023.dim_customer where region = "apac";
select product_code from fact_gross_price;

 /* task 2
 What is the percentage of unique product increase in 2021 vs. 2020?
  The final output contains these fields,
   unique_products_2020
   unique_products_2021
   percentage_chg*/

SELECT 
    COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN product_code END) AS unique_products_2021,
    ROUND(((COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN product_code  END) 
        - COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN product_code END)) 
        / COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN product_code END)) * 100.0, 2) AS percentage_chg
FROM fact_gross_price;

-- task 3
/* Provide a report with all the unique product counts for each segment and
   sort them in descending order of product counts. The final output contains
   2 fields,
   segment
   product_count */
   
select segment, count(distinct product) as product_count from dim_product
 group by segment order by product_count desc;
 
 -- task 4
 /* Follow-up: Which segment had the most increase in unique products in
    2021 vs 2020? The final output contains these fields,
	segment
    product_count_2020
	product_count_2021
    difference */
    
 select 
 segment,
 count( distinct case when fiscal_year= "2020" then dim_product.product_code end) as product_count_2020, 
 count( distinct case when fiscal_year = "2021" then dim_product.product_code end) as product_count_2021,
 count(distinct case when fiscal_year= "2021" then dim_product.product_code end)-
        count(case when fiscal_year = "2020" then dim_product.product_code end) as diffrence
 from fact_gross_price
 left join dim_product using(product_code)
 group by segment
 order  by segment desc;
 
-- task 5
/* Get the products that have the highest and lowest manufacturing costs.
   The final output should contain these fields,
   product_code
   product
   manufacturing_cost*/ 
   
select dim_product.product_code,  product,  manufacturing_cost 
from dim_product left join fact_manufacturing_cost using (product_code)
where manufacturing_cost in ( select max(manufacturing_cost) from fact_manufacturing_cost) or 
	 manufacturing_cost in (select min(manufacturing_cost) from fact_manufacturing_cost)
     order by 3 desc;
     
-- task 6
/* Generate a report which contains the top 5 customers who received an
   average high pre_invoice_discount_pct for the fiscal year 2021 and in the
   Indian market. The final output contains these fields,
    customer_code
    customer
    average_discount_percentage*/
    
select dim_customer.customer_code,dim_customer.customer,avg(pre_invoice_discount_pct) *100 as average_discount_percentage
from dim_customer left join fact_pre_invoice_deductions using(customer_code)
where fiscal_year= "2021"
group by dim_customer.customer_code,dim_customer.customer,pre_invoice_discount_pct
order by pre_invoice_discount_pct desc
limit 5 ;

-- task 7
/* Get the complete report of the Gross sales amount for the customer “Atliq
   Exclusive” for each month. This analysis helps to get an idea of low and
   high-performing months and take strategic decisions.
   The final report contains these columns:
     Month
     Year
     Gross sales Amount
*/

select
date_format(date,'%m') as month,
fact_sales_monthly.fiscal_year as year,
sum(sold_quantity*gross_price) as gross_sales_amount
from fact_sales_monthly left join fact_gross_price using (product_code) left join dim_customer using (customer_code)
where customer= 'Atliq Exclusive'
group by date_format(date,'%m'),fact_sales_monthly.fiscal_year,extract(month from date )
 order by  fact_sales_monthly.fiscal_year,extract(month from date );
 
-- task 8
/* In which quarter of 2020, got the maximum total_sold_quantity? The final
   output contains these fields sorted by the total_sold_quantity,
    Quarter
    total_sold_quantity*/
    
WITH sales_data AS (
    SELECT
        *,
        CASE
            WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
            WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
            WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
            ELSE 'Q4'
        END AS quarter
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
)
select
    quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM sales_data
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

-- task 9
/*  Which channel helped to bring more gross sales in the fiscal year 2021
    and the percentage of contribution? The final output contains these fields,
    channel
	gross_sales_mln
    percentage*/
    
with sales_data AS (
    SELECT
        dim_customer.channel,
        SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price) AS gross_sales_mln
    FROM
        fact_sales_monthly
        JOIN fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
        JOIN dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
    WHERE
        fact_sales_monthly.fiscal_year = 2021
    GROUP BY
        dim_customer.channel
), total_sales AS (
    SELECT
        SUM(gross_sales_mln) AS total_gross_sales_mln
    FROM
        sales_data
)
SELECT
    sales_data.channel,
    ROUND(sales_data.gross_sales_mln, 2) AS gross_sales_mln,
    ROUND(sales_data.gross_sales_mln / total_sales.total_gross_sales_mln * 100, 2) AS percentage
FROM
    sales_data
    CROSS JOIN total_sales
ORDER BY
    gross_sales_mln DESC
limit 1;

-- task 10
/*  Get the Top 3 products in each division that have a high
    total_sold_quantity in the fiscal_year 2021? The final output contains these
	fields,
    division
	product_code
	codebasics.io
	product
    total_sold_quantity
rank_order*/
WITH sales_data AS (
  SELECT 
    dim_product.division,
    fact_sales_monthly.product_code,
    dim_product.product,
    SUM(fact_sales_monthly.sold_quantity) AS total_sold_quantity,
    RANK() OVER (PARTITION BY dim_product.division 
   ORDER BY SUM(fact_sales_monthly.sold_quantity) DESC) AS rank_order
  FROM fact_sales_monthly
  JOIN dim_product ON fact_sales_monthly.product_code = dim_product.product_code
  WHERE fact_sales_monthly.fiscal_year = '2021'
  GROUP BY dim_product.division, fact_sales_monthly.product_code, dim_product.product
)
SELECT 
  division,
  product_code,
  product,
  total_sold_quantity,
  rank_order
FROM sales_data
WHERE rank_order <= 3
ORDER BY division, rank_order;



