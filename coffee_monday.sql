-- SET TABLE ID TO NOT NULL 
ALTER TABLE city
ALTER COLUMN city_id float NOT NULL;

ALTER TABLE customers
ALTER COLUMN customer_id float NOT NULL;

ALTER TABLE products
ALTER COLUMN product_id float NOT NULL;

ALTER TABLE sales
ALTER COLUMN sale_id float NOT NULL;

--change sale_date datatype from DATETIME to DATE
ALTER TABLE sales
ALTER COLUMN sale_date DATE;

-- ADD PRIMARY KEYS
ALTER TABLE city
ADD CONSTRAINT pk_city PRIMARY KEY (city_id);

ALTER TABLE customers
ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);

ALTER TABLE products
ADD CONSTRAINT pk_products PRIMARY KEY (product_id);

ALTER TABLE sales
ADD CONSTRAINT pk_sales PRIMARY KEY (sale_id);

--ADD FOREIGN KEYS
ALTER TABLE customers
ADD CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id);

ALTER TABLE sales
ADD CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE sales
ADD CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id);


--MONDAY COFFEE DATA ANALYSIS

SELECT * FROM city
SELECT * FROM customers
SELECT * FROM products
SELECT * FROM sales

-- REPORTS & DATA ANALYSIS
--1. **Coffee Consumers Count**  
--   How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_name,
	population,
	population*0.25 AS estimated_coffee_drinker
FROM CITY
ORDER BY 3 DESC

--2. **Total Revenue from Coffee Sales**  
--   What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	cit.city_name,
	SUM(total) AS total_revenue
FROM sales s 
JOIN customers cust
ON s.customer_id = cust.customer_id
JOIN city cit
ON cust.city_id = cit.city_id
WHERE 
	YEAR(sale_date) = 2023 
	AND 
	DATEPART(QUARTER, sale_date) = 4
GROUP BY cit.city_name
ORDER BY 2 DESC

--3. **Sales Count for Each Product**  
--   How many units of each coffee product have been sold?
SELECT
	p.product_name,
	COUNT(*) AS total_units_sold
FROM sales s
JOIN products p
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY 2 DESC

--4. **Average Sales Amount per City**  
--   What is the average sales amount per customer in each city?
SELECT
	cit.city_name,
	SUM(s.total) AS total_sales,
	COUNT(DISTINCT s.customer_id) AS num_of_customers,
	ROUND(
			SUM(s.total) / COUNT(DISTINCT s.customer_id), 
	2) AS avg_sales
FROM city cit
JOIN customers cust
ON cit.city_id = cust.city_id
JOIN sales s
ON cust.customer_id = s.customer_id
GROUP BY cit.city_name
ORDER BY 2 DESC


--5. **City Population and Coffee Consumers**  
--   Provide a list of cities along with their populations and estimated coffee consumers.
-- return city name, total current customers, estimated coffee consumers (25%)
SELECT 
	cit.city_name,
	COUNT(Distinct s.customer_id) unique_current_customers,
	ROUND((cit.population * 0.25) / 1000000, 2) AS est_coffee_consumers_in_millions
FROM city cit
JOIN customers cust
ON cit.city_id = cust.city_id
JOIN sales s
ON s.customer_id = cust.customer_id
GROUP BY cit.city_name, cit.population
ORDER BY 2 DESC

--6. **Top Selling Products by City**  
--   What are the top 3 selling products in each city based on sales volume?

SELECT 
	city_name,
	product_name,
	total_sales,
	rank
FROM
(
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY total_sales DESC) AS rank
FROM 
(
SELECT
	cit.city_name,
	p.product_id,
	p.product_name,
	COUNT(*) total_sales
FROM sales s
JOIN customers cust
ON s.customer_id = cust.customer_id
JOIN city cit
ON cust.city_id = cit.city_id
JOIN products p
ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name, cit.city_name
--ORDER BY 1, 4 desc
) AS t1
) AS t2
WHERE rank <= 3


--7. **Customer Segmentation by City**  
--   How many unique customers are there in each city who have purchased coffee products?
SELECT 
	c.city_name,
	COUNT(DISTINCT s.customer_id) AS total_customers
FROM customers cust
LEFT JOIN sales s
ON cust.customer_id = s.customer_id
JOIN city c
ON c.city_id = cust.city_id
GROUP BY c.city_name
ORDER BY 2 DESC

--8. **Average Sale vs Rent**  
--   Find each city and their average sale per customer and avg rent per customer
SELECT SUM(total) FROM sales
WHERE customer_id = 117
SELECT * FROM customers
SELECT * FROM products
SELECT * FROM city

SELECT 
	city_name,
	total_customer,
	avg_rent_per_customer,
	ROUND(total_sales / total_customer, 2) AS avg_sale_per_customer
FROM
(
SELECT 
	cit.city_name,
	cit.city_id,
	ROUND(cit.estimated_rent / COUNT(DISTINCT cust.customer_id), 2) AS avg_rent_per_customer,
	COUNT(DISTINCT cust.customer_id) total_customer
FROM city cit
JOIN customers cust
ON cit.city_id = cust.city_id
GROUP BY cit.city_name, cit.city_id, cit.estimated_rent
) AS t1 
JOIN (
SELECT 
	c.city_id,
	SUM(s.total) AS total_sales
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
GROUP BY c.city_id
) AS t2
ON t1.city_id = t2.city_id
ORDER BY 3 DESC

--9. **Monthly Sales Growth**  
--   Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
SELECT * FROM sales
SELECT * FROM customers
SELECT * FROM products
SELECT * FROM city

WITH t1 AS  
(
	SELECT 
		cit.city_name,
		YEAR(s.sale_date) AS sales_year,
		MONTH(s.sale_date) sales_month,
		SUM(s.total) total_sales
	FROM sales s
	JOIN customers cust
	ON s.customer_id = cust.customer_id
	JOIN city cit
	ON cust.city_id = cit.city_id
	GROUP BY YEAR(sale_date), MONTH(sale_date), cit.city_name
	--ORDER BY 1,2,3
), 
t2 AS
(
	SELECT 
		city_name, 
		sales_year,
		sales_month, 
		total_sales AS current_month_sales,
		LAG(total_sales, 1) OVER (PARTITION BY city_name ORDER BY sales_year, sales_month) AS prev_month_sales
	FROM t1
)
SELECT 
	*,
	ROUND(((current_month_sales - prev_month_sales) / prev_month_sales) * 100, 2)  AS growth_percentage
FROM t2
ORDER BY 1,2,3


--10. **Market Potential Analysis**  
--    Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated  coffee consumer
SELECT * FROM sales
SELECT * FROM customers
SELECT * FROM products
SELECT * FROM city

SELECT
	city_name,
	total_sales_per_city,
	estimated_rent,
	total_customers,
	est_coffee_consumer
FROM 
(
SELECT 
	 cust.city_id,
	 SUM(s.total) total_sales_per_city
FROM sales s
JOIN customers cust
ON s.customer_id = cust.customer_id
GROUP BY cust.city_id
) AS t1
JOIN 
(
SELECT 
	COUNT(DISTINCT s.customer_id) total_customers,
	cit.city_id,
	cit.city_name,
	cit.estimated_rent,
	ROUND((cit.population * 0.25) / 1000000, 2) AS est_coffee_consumer
FROM sales s
JOIN customers c
ON s.customer_id=c.customer_id
JOIN city cit
ON c.city_id = cit.city_id
GROUP BY cit.city_id, cit.city_name, cit.estimated_rent, cit.population
) AS t2 
ON t1.city_id = t2.city_id
ORDER BY 2 DESC


