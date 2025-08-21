-- change over time analysis

SELECT 
			YEAR(order_date) AS order_year,
            MONTH(order_date) AS order_year,
			SUM(sales_amount) AS total_sales,
			COUNT(DISTINCT customer_key) AS total_customer,
			SUM(quantity) AS total_quantity
FROM 
			fact_sales
WHERE 
			order_date is not null
GROUP BY 
			YEAR(order_date),MONTH(order_date)
ORDER BY  
			YEAR(order_date),MONTH(order_date);
            
-- Calculate the total_sales per month and 
-- the running total of sales over time  

SELECT   
            order_year,
            month_year,
            total_sales,
            sum(total_sales) OVER(PARTITION BY order_year ORDER BY order_year, month_year) AS running_total_sales
FROM            
(
SELECT 
            YEAR(order_date) AS order_year,
            MONTH(order_date) AS month_year,
			SUM(sales_amount) AS total_sales
 FROM 
			fact_sales
WHERE 
			order_date is not null
GROUP BY 
			YEAR(order_date),MONTH(order_date)
ORDER BY  
			YEAR(order_date),MONTH(order_date)
            ) as alias;

-- Analyze the yearly performance of products
-- by comparing each product's sales to both
-- its average sales performance and the previous year's sales

WITH yearly_product_sales AS (
			 SELECT
						YEAR(f.order_date) AS order_year,
						p.product_name,
						SUM(f.sales_amount) AS current_sales
			 FROM
						fact_sales f
			 LEFT JOIN 
						products p 
						on f.product_key= p.product_key
			 WHERE 
						f.order_date is not null
			 GROUP BY 
						YEAR(f.order_date),
						p.product_name
                        )
  SELECT
			order_year,
            product_name,
            current_sales,
            ROUND(AVG(current_sales) OVER(PARTITION BY product_name) )AS avg_sales,
            current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name)) AS diff_avg,
CASE 
			WHEN current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name)) > 0 THEN 'above_Avg'
            WHEN current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name)) < 0 THEN 'below_Avg'
            ELSE  'Avg'
 END avg_change,
			LAG(current_sales)  OVER(PARTITION BY product_name 
            ORDER BY order_year) py_sales,
            current_sales - LAG(current_sales)  OVER(PARTITION BY product_name 
            ORDER BY order_year) AS py_diff,
            CASE 
			WHEN current_sales - LAG(current_sales)  OVER(PARTITION BY product_name 
            ORDER BY order_year)  > 0 THEN 'Increase'
            WHEN current_sales - LAG(current_sales)  OVER(PARTITION BY product_name 
            ORDER BY order_year) < 0 THEN 'Decrease'
            ELSE  'No Change'
            END py_change
 FROM
			yearly_product_sales
 ORDER BY
			  product_name,
            order_year;
			
-- Which category contribute the most to overall sales

WITH category_sales AS (
			SELECT 
						category,
						SUM(sales_amount) AS total_sales
			FROM 
						fact_sales f
			LEFT JOIN 
					products p
					on p.product_key = f.product_key
			GROUP BY 
						category )
 SELECT 
			category,
            total_sales,
            SUM(total_sales) OVER() AS overall_sales,
           CONCAT(ROUND(( total_sales / SUM(total_sales) OVER() ) * 100,2),'%') AS percentage_of_total 
FROM 
			category_sales
ORDER BY 
			total_sales DESC;
            
-- Segement products into cost ranges and
-- count how many products fall into each segment 

WITH product_segment AS (
			SELECT 
						product_key,
						product_name,
						cost,
						CASE WHEN  cost < 100 THEN 'Below 100'
								  WHEN  cost BETWEEN 100 AND 500 THEN '100-500'
								  WHEN   cost BETWEEN 500 AND 1000 THEN '500-1000'
								  ELSE 'Above 1000'
						END cost_range
			FROM 
						products )
SELECT 
			cost_range,
            COUNT(product_key) AS total_product
FROM 
			product_segment
GROUP BY 
				cost_range
ORDER BY 
				total_product DESC ;
                
-- Group customers into three segments based on their spending behavior
-- VIP : at least 12 months of history and spending more than 5,000.
-- REGULAR : at least 12 months of history but spending 5,000 or less.
-- NEW : lifespan less than 12 months.
-- And find the total number of customers by each group.                
            
WITH customer_spending AS (            
			SELECT
						c.customer_key,
						SUM(f.sales_amount) AS total_spending,
						MIN(order_date) AS first_order,
						MAX(order_date) AS last_order,
						TIMESTAMPDIFF( month , MIN(order_date), MAX(order_date)) AS lifespan
			FROM 
					fact_sales f
			LEFT JOIN 
							customers c
							on f.customer_key = c.customer_key            
			GROUP BY 
						customer_key )
SELECT
			customer_segment,
            COUNT(customer_key) AS total_customer
FROM (            
		SELECT
					customer_key,
					CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
								WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'REGULAR'
								ELSE 'NEW'
					END customer_segment 
		FROM
					customer_spending ) t 
GROUP BY 
			customer_segment
ORDER BY 
				total_customer DESC ;
                
/* Customer Report
Purpose:
- This report consolidates key customer metrics and behaviors

Highlights:
1.  Gathers essential fields such as names, ages, and transaction details.
2.  Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
    - total orders
    - total sales
    - total quantity purchased
    - total products
    -lifespan (in months)
4.  Calculates valuable KPIs:
    - recency (months since last order)
    - average order value
    - average monthly spend    */
           
     
CREATE VIEW report_customers AS           
WITH base_query AS (
 -- Base Query: Retrieves core columns from tables     
			   SELECT 
							f.order_number,
							f.product_key,
							f.order_date,
							f.sales_amount,
							f.quantity,
							c.customer_key,
							c.customer_number,
							c.birthdate,
							CONCAT(c.first_name, ' ',c.last_name) AS customer_name,
							TIMESTAMPDIFF(year, c.birthdate, now()) AS age
			FROM
						fact_sales f 
			LEFT JOIN
							customers c
							on c.customer_key = f.customer_key
			WHERE order_date is not null )
            
, customer_aggregation AS (
-- Customer Aggregations: Surmarizes key metrics at the customer level
			SELECT 
						 customer_key,
						 customer_number,
						 customer_name,
						 age,
						 COUNT(DISTINCT order_number) AS total_order,
						 SUM(sales_amount) AS total_sales,
						 SUM(quantity) AS total_quantity,
						 COUNT(DISTINCT product_key) AS total_product,
						 MAX(order_date) AS last_order_date,
						TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
						 
			FROM 
						base_query
			GROUP BY            
						 customer_key,
						 customer_number,
						 customer_name,
						 age  )
 SELECT 
				customer_key,
				customer_number,
				customer_name,
				age,
                CASE 
                           WHEN age < 20 THEN 'Under 20'
						   WHEN age BETWEEN 20 AND 29 THEN '20-29'
                           WHEN age BETWEEN 30 AND 39 THEN '30-39'
                           WHEN age BETWEEN 40 AND 49 THEN '40-49'
                           ELSE '50 and Above'
                 END age_group ,         
                CASE 
                            WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
							WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'REGULAR'
							ELSE 'NEW'
				END customer_segment ,
                last_order_date,
                TIMESTAMPDIFF(month,last_order_date,now()) AS recency,
				total_order,
				total_sales,
				total_quantity,
			    total_product,
				lifespan,
                -- compuate avg order value
                CASE WHEN total_order = 0  THEN 0
                           ELSE ROUND(total_sales / total_order,2) 
                END AS avg_order_value,
                -- compuate avg monthly spend  
                CASE WHEN lifespan = 0 THEN total_sales
                            ELSE total_sales / lifespan 
                END AS  avg_monthly_spend           
                
FROM                         
          customer_aggregation