use projecdb;
-- Explore All Objects in Database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Explore All Countries our customers come from.
SELECT DISTINCT country FROM customers;

-- Explore All Categories "The Major Division"
SELECT DISTINCT category , subcategory ,product_name from products;

-- Find the date of the first and last order 
-- How many years of sales are available
SELECT 
			MIN(order_date) AS first_order_date , 
            MAX(order_date) AS last_order_date, 
            TIMESTAMPDIFF(month,MIN(order_date),MAX(order_date) ) 
            AS order_range_months
from fact_sales;

-- Find the youngest and oldest customer
SELECT 
			MIN(birthdate) AS oldest_customer, 
            MAX(birthdate) AS youngest_customer,
            TIMESTAMPDIFF(year,MIN(birthdate),NOW()) AS oldest_age,
            TIMESTAMPDIFF(year,MAX(birthdate),NOW()) AS youngest_age
FROM 
			customers
WHERE 
			birthdate;

-- Find the Total Sales
SELECT 
			SUM(sales_amount) AS total_sales
FROM 
			fact_sales;
            
-- Find how many items are sold  
SELECT 
			SUM(quantity) AS total_quantity
FROM 
			fact_sales;
            
-- Find the average selling price
SELECT 
			AVG(price) AS avg_selling_price
FROM 
			fact_sales;
            
-- Find the Total number of Orders
SELECT 
			COUNT(DISTINCT order_number) AS total_orders
FROM 
			fact_sales;
            
-- Find the total number of products
SELECT 
			COUNT(DISTINCT product_key) AS total_products
FROM 
			products;
            
-- Find the total number of customers
SELECT 
			COUNT(DISTINCT customer_key) AS total_customer
FROM 
			customers;
            
-- Find the total number of customers that has placed an order
SELECT 
			COUNT(DISTINCT customer_key) AS total_sales
FROM 
			fact_sales;

-- Generate a Report that shows all key metrics of the business
SELECT  'Total Sales' as measure_name, SUM(sales_amount) AS measure_value FROM fact_sales
UNION ALL
SELECT  'Total Quantity' as measure_name, SUM(quantity) AS measure_value FROM fact_sales
UNION ALL
SELECT  'Average Price' as measure_name, AVG(price) AS measure_value FROM fact_sales
UNION ALL
SELECT  'Total No. Orders' as measure_name, COUNT(DISTINCT order_number) AS measure_value FROM fact_sales
UNION ALL
SELECT  'Total No. Product' as measure_name, COUNT(product_name) AS measure_value FROM products
UNION ALL
SELECT  'Total No. Customer' as measure_name, COUNT(customer_key) AS measure_value FROM customers

