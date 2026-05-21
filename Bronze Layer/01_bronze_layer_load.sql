/*
----------------------------------
-- Bronze Layer Raw Data Load

Script Purpose: Load Raw Data Into Bronze Layer

Source: 
1. dim_customers
2. dim_orders
3. dim_products
4. fact_orders_items

Target:
1.bronze.dim_customers
2.bronze.dim_orders
3.bronze.dim_products
4.bronze.fact_ordersitems

Notes: 
- No Transformation Applied
- Raw Data Preserved
------------------------------------
*/

-- Database Create
CREATE DATABASE Sales_Project_DB;

-- Schema Create
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

-- Create Table bronze.dim_customers
IF OBJECT_ID('bronze.dim_customers','U') IS NOT NULL
DROP TABLE bronze.dim_customers;
CREATE TABLE bronze.dim_customers(
	customer_id INT,
	customer_name VARCHAR(50),
	city VARCHAR(50),
	age INT,
	gender VARCHAR(10));
 GO
 IF OBJECT_ID ('bronze.dim_products','U') IS NOT NULL 
 DROP TABLE bronze.dim_products;
 -- Create Table bronze.dim_products
 CREATE TABLE bronze.dim_products(
	product_id INT,
	category VARCHAR(50),
	product_name VARCHAR(50),
	price DECIMAL(10,2),
	cost DECIMAL(10,2));
	GO
	IF OBJECT_ID ('bronze.dim_orders','U') IS NOT NULL
	DROP TABLE bronze.dim_orders;
 -- Create Table bronze.dim_orders
CREATE TABLE bronze.dim_orders(
	order_id INT,
	customer_id INT,
	order_date DATE);
	GO
	IF OBJECT_ID('bronze.fact_orderitems','U') IS NOT NULL 
	DROP TABLE bronze.fact_orderitems;
 -- Create Table bronze.fact_orderitems
CREATE TABLE bronze.fact_orderitems(
	order_item_id INT,
	order_id INT,
	product_id INT,
	quantity INT,
	discount DECIMAL(5,2) DEFAULT 0);
----------------------------------------------------------------------
CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
	DECLARE @Start_time DATETIME2, @End_time DATETIME2, @Batch_start_time DATETIME2, @Batch_end_time DATETIME2;
	BEGIN TRY
		SET @Batch_start_time = GETDATE()
		-------------------------------------
		SET @Start_time = GETDATE();
		
		-- Truncate Table bronze.dim_customers
		TRUNCATE TABLE bronze.dim_customers;

		-- Insert Data bronze.dim_customers		
		BULK INSERT bronze.dim_customers
		FROM 'C:\Users\USER\Desktop\PRACTICE\SQL MAIN\Sql First Project\dim_customers.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK);

		SET @End_time = GETDATE();
		PRINT 'Loading Duration: '+CAST(DATEDIFF(SECOND,@Start_time,@End_time) AS VARCHAR) +'Seconds';
		-------------------------------------
		SET @Start_time = GETDATE();
		
		-- Truncate Table bronze.dim_products
		TRUNCATE TABLE bronze.dim_products;

		-- Insert Data bronze.dim_products		
		BULK INSERT bronze.dim_products
		FROM 'C:\Users\USER\Desktop\PRACTICE\SQL MAIN\Sql First Project\dim_products.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK);

		SET @End_time = GETDATE();
		PRINT 'Loading Duration: '+CAST(DATEDIFF(SECOND,@Start_time,@End_time) AS VARCHAR) +'Seconds';
		
		-------------------------------------
		SET @Start_time = GETDATE();

		-- Truncate Table bronze.dim_orders
		TRUNCATE TABLE bronze.dim_orders;

		-- Insert Data bronze.dim_orders		
		BULK INSERT bronze.dim_orders
		FROM 'C:\Users\USER\Desktop\PRACTICE\SQL MAIN\Sql First Project\dim_orders.csv'
		WITH(
			FIRSTROW =2,
			FIELDTERMINATOR =',',
			TABLOCK);
		
		SET @End_time = GETDATE();
		PRINT 'Loading Duration: '+CAST(DATEDIFF(SECOND,@Start_time,@End_time) AS VARCHAR) +'Seconds';
		-------------------------------------
		SET @Start_time = GETDATE();

		-- Truncate Table bronze.fact_orderitems
		TRUNCATE TABLE bronze.fact_orderitems;

		-- Insert Data bronze.fact_orderitems
		BULK INSERT bronze.fact_orderitems
		FROM 'C:\Users\USER\Desktop\PRACTICE\SQL MAIN\Sql First Project\fact_orders_items.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK);
		SET @End_time = GETDATE();
		PRINT 'Loading Duration: '+CAST(DATEDIFF(SECOND,@Start_time,@End_time) AS VARCHAR) +'Seconds';
		----------------------------------------
		PRINT '---------------------------------'
		SET @Batch_end_time = GETDATE();
		PRINT 'Total Load Duration: '+CAST(DATEDIFF(SECOND,@Batch_start_time,@Batch_end_time) AS VARCHAR)+'Seconds';
	END TRY 
	BEGIN CATCH
	PRINT '---------------------------------';
	PRINT 'Error Occured During Loading';
	PRINT '---------------------------------';
	PRINT 'Error Message'+Error_Message();
	PRINT 'Error Number'+CAST(Error_Number() AS VARCHAR);
	PRINT 'Error State'+CAST(Error_State() AS VARCHAR);
	PRINT '----------------------------------';
	END CATCH
END

-- Execute The Procedure To Refresh & Add New Data
EXECUTE bronze.load_bronze;

-- See The Data
SELECT * FROM bronze.dim_customers;
SELECT * FROM bronze.dim_orders;
SELECT * FROM bronze.dim_products;
SELECT * FROM bronze.fact_orderitems;


