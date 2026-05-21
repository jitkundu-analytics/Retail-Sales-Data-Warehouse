/*
---------------------------------------
-- Silver Layer Transformation 

Script Purpose: Clean & Standardize Raw Data

Target Transformation: 
-- Trim Spaces 
-- Remove Duplicates 
-- Handle Null Values 
-- Standardize Gender Values 
-- Validate Customer Records 

Source Data:
1.bronze.dim_customers
2.bronze.dim_products
3.bronze.dim_orders
4.bronze.fact_orderitems

Target Data:
1.silver.dim_customers
2.silver.dim_products
3.silver.dim_orders
4.silver.dim_orderitems
---------------------------------------
*/

USE Sales_Project_DB;
-- Create Silver Layer
CREATE TABLE silver.dim_customers(
		customer_id INT PRIMARY KEY,
		customer_name VARCHAR(50) NOT NULL,
		city VARCHAR(30) NOT NULL,
		age INT NOT NULL CHECK (age > 0),
		gender VARCHAR(20),
		create_date DATE DEFAULT GETDATE());

CREATE TABLE silver.dim_products(
		product_id INT PRIMARY KEY,
		category VARCHAR(20) NOT NULL,
		product_name VARCHAR(50) NOT NULL,
		price DECIMAL(10,2) NOT NULL,
		cost DECIMAL (10,2) NOT NULL,
		create_date DATE DEFAULT GETDATE());

CREATE TABLE silver.dim_orders(
		order_id INT PRIMARY KEY,
		customer_id INT,
		order_date DATE ,
		create_date DATE DEFAULT GETDATE(),
		CONSTRAINT fk_dim_customers FOREIGN KEY (customer_id) REFERENCES silver.dim_customers(customer_id));

CREATE TABLE silver.fact_orderitems(
		order_item_id INT PRIMARY KEY,
		order_id INT,
		product_id INT,
		quantity INT,
		discount DECIMAL(10,2),
		create_date DATE DEFAULT GETDATE(),
		CONSTRAINT fk_dim_orders FOREIGN KEY(order_id) REFERENCES silver.dim_orders(order_id),
		CONSTRAINT fk_dim_products FOREIGN KEY(product_id) REFERENCES silver.dim_products(product_id));
-------------------------------------------------------------------------------------------------------

-- Step 1 Check (customer_id)
SELECT 
	customer_id,
	COUNT(*) AS Duplicate
FROM bronze.dim_customers AS c
GROUP BY customer_id
HAVING COUNT(*)>1 OR customer_id IS NULL OR NOT EXISTS (SELECT 1 FROM bronze.dim_orders AS o WHERE c.customer_id = o.customer_id);
-- Step 2 Check (customer_name)
SELECT
	customer_name
FROM bronze.dim_customers
WHERE LEN(customer_name) != LEN(TRIM(customer_name));
-- Step 3 Check (city)
SELECT
	DISTINCT city
FROM bronze.dim_customers;
-- Step 4 Check (age)
SELECT 
	age
FROM bronze.dim_customers
WHERE age < 0 OR age IS NULL;
-- Step 5 Check (gender)
SELECT
	DISTINCT gender
FROM bronze.dim_customers;
----------------------------

-- Step 1 Check (Product Id)
SELECT
	product_id,
	COUNT(*) AS Duplicate
FROM bronze.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;
-- Step 2 Check (category)
SELECT
	DISTINCT category
FROM bronze.dim_products;
-- Step 3 Check (product_name)
SELECT 
	product_name
FROM bronze.dim_products
WHERE product_name IS NULL OR LEN(product_name) != LEN(TRIM(product_name));
-- Step 4 Check (Price & cost)
SELECT
	price,
	cost
FROM bronze.dim_products
WHERE price IS NULL OR cost IS NULL OR price < 0 OR cost < 0;
-------------------------------------

-- Step 1 Check (order_id)
SELECT
	order_id,
	COUNT(*) AS duplicate
FROM bronze.dim_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
-- Step 2 Check (customer_id)
SELECT
	customer_id
FROM bronze.dim_orders AS o
WHERE NOT EXISTS (SELECT 1 FROM bronze.dim_customers AS c WHERE o.customer_id = c.customer_id);
-- Step 3 Check (order_date)
SELECT
*
FROM bronze.dim_orders
WHERE order_date =(SELECT MIN(order_date) FROM bronze.dim_orders);
-------------------------------------------

-- Step 1 Check (order_item_id)
SELECT
	order_item_id,
	COUNT(*) AS Duplicate
FROM bronze.fact_orderitems
GROUP BY order_item_id
HAVING COUNT(*) >1;
-- Step 2 Check (order_id)
SELECT
	order_id
FROM bronze.fact_orderitems AS fo
WHERE NOT EXISTS (SELECT 1 FROM bronze.dim_orders AS o WHERE o.order_id = fo.order_id) OR order_id IS NULL;
-- Step 3 Check (product_id)
SELECT 
	product_id
FROM bronze.fact_orderitems
WHERE NOT EXISTS (SELECT 1 FROM bronze.fact_orderitems) OR product_id IS NULL;
-- Step 4 Check (quantity)
SELECT 
	quantity
FROM bronze.fact_orderitems
WHERE quantity >= 0 OR quantity IS NULL;
-- Step 5 Check(discount)
SELECT
	discount
FROM bronze.fact_orderitems
WHERE discount < 0;


--===============================================
-- Insert Into silver.dim_customers;
INSERT INTO silver.dim_customers(customer_id,customer_name,city,age,gender)
SELECT 
	customer_id,
	customer_name,
	city,
	age,
	gender
FROM bronze.dim_customers;
-------------------------------
-- Insert Into silver.dim_products;
INSERT INTO silver.dim_products(product_id,category,product_name,price,cost)
SELECT
	product_id,
	category,
	product_name,
	price,
	cost
FROM bronze.dim_products;
--------------------------------
-- Insert Into silver.dim_orders;
INSERT INTO silver.dim_orders(order_id,customer_id,order_date)
SELECT 
	order_id,
	customer_id,
	order_date
FROM bronze.dim_orders;
--------------------------------
-- Insert Into silver.fact_orderitems;
INSERT INTO silver.fact_orderitems(order_item_id,order_id,product_id,quantity,discount)
SELECT 
	order_item_id,
	order_id,
	product_id,
	quantity,
	discount
FROM bronze.fact_orderitems;
--===============================================