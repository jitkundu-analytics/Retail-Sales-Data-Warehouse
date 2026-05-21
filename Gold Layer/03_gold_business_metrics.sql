/*
------------------------------------
Gold Layer Business Metrics

Script Purpose:
Create Business-Ready Analytical Views 
For Reporting And Dashboard Consumption.

Business Metrics:
-- Total Sales
-- Total Profit
-- Profit Margin
-- Customer Count
-- Product Performance 
-- Regional Analysis

Source Data:
1.silver.dim_customers
2.silver.dim_products
3.silver.dim_orders
4.silver.fact_orderitems

Target Data:
1.gold.dim_customers
2.gold.dim_products
3.gold.fact_orders
------------------------------------
*/

-- Create Gold Layer (gold.dim_cusomters)
CREATE VIEW gold.dim_customers AS
SELECT 
	customer_id,
	customer_name,
	age,
	gender,
	city
FROM silver.dim_customers;

-- Create Gold Layer (gold.dim_products)
CREATE VIEW gold.dim_products AS
SELECT 
	product_id,
	product_name,
	category,
	cost,
	price
FROM silver.dim_products;

-- Create Gold Layer (gold.fact_orders)
CREATE VIEW gold.fact_orders AS
SELECT 
	fo.order_item_id,
	fo.order_id,
	o.customer_id,
	fo.product_id,
	o.order_date,
	fo.quantity,
	p.price,
	(p.cost * fo.quantity) AS cost,
	fo.discount,
	CAST((p.price*fo.quantity)*(1-fo.discount) AS decimal(10,2)) AS sales
FROM silver.fact_orderitems AS fo
LEFT JOIN silver.dim_orders AS o
ON fo.order_id = o.order_id
INNER JOIN silver.dim_products AS p
ON fo.product_id = p.product_id;
--------------------------------
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_orders;
--------------------------------
-- Measure Metrics
SELECT 'Total Sales' AS Measure_Name, ROUND(SUM(sales),0) AS Measure_Value FROM gold.fact_orders
UNION ALL
SELECT 'Total Cost', SUM(cost) FROM gold.fact_orders
UNION ALL
SELECT 'Profit', ROUND(SUM(Sales)-SUM(cost),0) FROM gold.fact_orders
UNION ALL
SELECT 'Profit Margin%',ROUND(CAST(SUM(Sales)-SUM(cost) AS float)/SUM(Sales)*100,0) FROM gold.fact_orders
UNION ALL
SELECT 'Total Customer', COUNT(DISTINCT customer_id) FROM gold.fact_orders
UNION ALL 
SELECT 'Total Product', COUNT(DISTINCT product_id) FROM gold.fact_orders
UNION ALL 
SELECT 'Total Order', COUNT(DISTINCT order_id) FROM gold.fact_orders
UNION ALL
SELECT 'Total Order Items', COUNT(*) FROM gold.fact_orders
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_orders
UNION ALL
SELECT 'Average Price', ROUND(AVG(Price),0) FROM gold.fact_orders;
--------------------------------
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_orders;
--------------------------------
-- Total Sales By Category
SELECT 
	dp.category,
	ROUND(CONVERT(FLOAT,SUM(fo.Sales)),0) AS Total_Sales
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id
GROUP BY dp.category
ORDER BY Total_Sales DESC;
---------------------------------
-- Total Sales By City
SELECT 
	dc.city,
	ROUND(CONVERT(FLOAT,SUM(fo.Sales)),0) AS Total_Sales
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_customers AS dc
ON fo.customer_id = dc.customer_id
GROUP BY dc.city
ORDER BY Total_Sales DESC;
----------------------------------
-- Total Sales By Gender
SELECT
	dc.gender,
	ROUND(CONVERT(FLOAT,SUM(fo.Sales)),0) AS Total_Sales
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_customers AS dc
ON fo.customer_id = dc.customer_id
GROUP BY dc.gender
ORDER BY Total_Sales DESC;
----------------------------------
-- Total Customer By City
SELECT
	dc.city,
	COUNT(fo.customer_id) AS Total_Customer
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_customers AS dc
ON fo.customer_id = dc.customer_id
GROUP BY dc.city
ORDER BY Total_Customer DESC;
----------------------------------
-- Total Customer By Gender
SELECT 
	dc.gender,
	COUNT(fo.customer_id) AS Total_Customer
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_customers AS dc
ON fo.customer_id = dc.customer_id
GROUP BY dc.gender
ORDER BY Total_Customer DESC;
----------------------------------
-- Total Product By Category
SELECT
	dp.category,
	COUNT(fo.product_id) AS Total_Product
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id
GROUP BY dp.category
ORDER BY Total_Product DESC;
-----------------------------------
-- Top 5 Products By Sales & Quantity
SELECT 
*
FROM(
SELECT 
	dp.product_name,
	SUM(fo.Sales) AS Total_Sales,
	SUM(fo.quantity) AS Total_Quantity,
	DENSE_RANK() OVER (ORDER BY SUM(fo.Sales) DESC, SUM(fo.Quantity)) AS Rank
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id
GROUP BY dp.product_name)t
WHERE Rank <= 5
----------------------------------
-- Top 5 Worst Products By Sales & Quantity
SELECT 
* 
FROM(
SELECT 
	dp.product_name,
	SUM(fo.Sales) AS Total_Sales,
	SUM(fo.quantity) AS Total_Quantity,
	DENSE_RANK() OVER (ORDER BY SUM(fo.Sales) ASC, SUM(fo.Quantity)) AS Rank
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id
GROUP BY dp.product_name)t
WHERE Rank <= 5;
-----------------------------------
-- Top 5 Customer By Sales
SELECT
*
FROM(
SELECT
	dc.customer_name,
	SUM(fo.Sales) AS Total_Sales,
	DENSE_RANK() OVER (ORDER BY SUM(fo.Sales) DESC) AS Rank
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_customers AS dc
ON fo.customer_id = dc.customer_id
GROUP BY dc.customer_name)t
WHERE Rank <= 5;
-------------------------------------
-- Top 5 Category By Sales & Quantity
SELECT 
* 
FROM
(
	SELECT 
		dp.category,
		SUM(fo.Sales) AS Total_Sales,
		SUM(fo.quantity) AS Total_Quantity,
		DENSE_RANK() OVER (ORDER BY SUM(fo.Sales) DESC,SUM(fo.quantity)) AS Rank
	FROM gold.fact_orders AS fo
	INNER JOIN gold.dim_products AS dp
	ON fo.product_id = dp.product_id
	GROUP BY dp.category)t
	WHERE Rank <= 5;
-------------------------------------
-- Top 5 City By Sales & Quantity
SELECT 
* 
FROM 
(
	SELECT 
		dc.city,
		SUM(fo.Sales) AS Total_Sales,
		SUM(fo.quantity) AS Total_Quantity,
		DENSE_RANK() OVER (ORDER BY SUM(fo.Sales) DESC,SUM(fo.quantity)) AS Rank
	FROM gold.fact_orders AS fo
	INNER JOIN gold.dim_customers AS dc
	ON fo.customer_id = dc.customer_id
	GROUP BY dc.city)t
	WHERE Rank <=5;
----------------------------------
-- Running Total & Moving Average
SELECT 
	YEAR(order_date) AS Year,
	FORMAT(order_date,'MMMM') AS Month,
	SUM(Sales) AS Sales,
	SUM(SUM(Sales)) OVER (PARTITION BY YEAR(order_date) ORDER BY MONTH(order_date) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Total,
	AVG(price) AS Average,
	AVG(AVG(price)) OVER (PARTITION BY YEAR(order_date) ORDER BY MONTH(order_date) ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Moving_Average_Price
FROM gold.fact_orders
GROUP BY YEAR(order_date),MONTH(order_date),
FORMAT(order_date,'MMMM');
---------------------------------
-- Month Over Month Growth Rate%
WITH CTE1 AS(
SELECT 
	YEAR(order_date) AS Year,
	FORMAT(order_date,'MMMM') AS Month,
	SUM(Sales) AS Total_Sales,
	LAG(SUM(Sales)) OVER (PARTITION BY YEAR(order_date) ORDER BY MONTH(order_date) ASC) AS Py_Sales
FROM gold.fact_orders
GROUP BY 
YEAR(order_date),MONTH(order_date),
FORMAT(order_date,'MMMM'))

SELECT
	Year,
	Month,
	Total_Sales,
	Py_Sales,
	CASE
		WHEN ROUND((CONVERT(float,(Total_Sales-Py_Sales))/NULLIF(Py_Sales,0))*100,0) IS NOT NULL 
		THEN CONCAT(ROUND((CONVERT(float,(Total_Sales-Py_Sales))/NULLIF(Py_Sales,0))*100,0),'%') 
	END AS Growth_Rate
FROM CTE1;

------------------------------
-- /* Analysis the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year's sales.*/
WITH CTE1 AS(
SELECT 
	Year(fo.order_date) AS Year,
	dp.product_name,
	SUM(fo.Sales) AS Total_Sales
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id
GROUP BY 
	Year(fo.order_date),
	dp.product_name)

SELECT 
	Year,
	product_name,
	Total_Sales,
	AVG(Total_Sales) OVER (PARTITION BY product_name) AS Average,
	Total_Sales - AVG(Total_Sales) OVER (PARTITION BY product_name) AS Diff_Avg,
CASE 
	WHEN Total_Sales - AVG(Total_Sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	WHEN Total_Sales - AVG(Total_Sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	ELSE 'Avg'
END AS Avg_Change,
LAG(Total_Sales) OVER (PARTITION BY product_name ORDER BY Year ASC) AS Py_Sales,
Total_Sales - LAG(Total_Sales) OVER (PARTITION BY product_name ORDER BY Year ASC) AS Diff_Py,
CASE
	WHEN Total_Sales - LAG(Total_Sales) OVER (PARTITION BY product_name ORDER BY Year ASC) > 0 THEN 'Increase'
	WHEN Total_Sales - LAG(Total_Sales) OVER (PARTITION BY product_name ORDER BY Year ASC) < 0 THEN 'Decrease'
	ELSE 'No Change'
END AS Py_Change
FROM CTE1
ORDER BY product_name,Year;
-----------------------------------
-- Category Contribute To Whole Analysis
WITH CTE1 AS(
SELECT
	dp.category,
	SUM(fo.Sales) Total_Sales
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id
GROUP BY dp.category)

SELECT
	category,
	Total_Sales,
	SUM(Total_Sales) OVER () AS Overall_Sales,
	CONCAT(ROUND((CAST(Total_Sales AS FLOAT)/SUM(Total_Sales) OVER ())*100,0),'%') AS Percentage
FROM CTE1;
--------------------------------
-- Product Analysis Table

-- Create View For Products Report

ALTER VIEW gold.report_products AS
WITH CTE1 AS(
SELECT
	fo.order_item_id,
	fo.order_id,
	fo.customer_id,
	dp.category,
	fo.product_id,
	dp.product_name,
	fo.order_date,
	dp.cost,
	dp.price,
	fo.quantity,
	fo.Sales
FROM gold.fact_orders AS fo
INNER JOIN gold.dim_products AS dp
ON fo.product_id = dp.product_id),

CTE2 AS (
SELECT 
	category,
	product_name,
	product_id,
	SUM(Sales) AS Total_Sales,
	SUM(cost) AS Total_Cost,
	COUNT(DISTINCT order_id) AS Total_Order,
	COUNT(DISTINCT customer_id) AS Total_Customer,
	SUM(quantity) AS Total_Quantity,
	MIN(order_date) AS First_Order,
	MAX(order_date) AS Last_Order,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS Life_Span
FROM CTE1
GROUP BY category,
product_name,
product_id)

SELECT
	product_name,
	category,
	product_id,
	Total_Sales,
	CASE
		WHEN NTILE(3) OVER (ORDER BY Total_Sales DESC) = 1 THEN 'High Performance'
		WHEN NTILE(3) OVER (ORDER BY Total_Sales DESC) = 2 THEN 'Mid Performance'
		WHEN NTILE(3) OVER (ORDER BY Total_Sales DESC) = 3 THEN 'Low Performance'
	END AS Segmentation,
	Total_Cost,
	Total_Order,
	Total_Customer,
	Total_Quantity,
	First_Order,
	Last_Order,
	Life_Span,
	CASE 
		WHEN Total_Sales = 0 THEN 0
		ELSE ROUND(CONVERT(float,Total_Sales)/Total_Order,0)
	END AS Avg_Order_Value,
	CASE
		WHEN Total_Sales = 0 THEN 0 
		ELSE ROUND(CONVERT(float,Total_Sales)/NULLIF(Life_Span,0),0)
	END AS Avg_Monthly_Spend
FROM CTE2;
----------------------------------------------------------
-- Customer Analysis Table

-- Create View For Products Report

CREATE VIEW gold.report_customers AS
WITH CTE1 AS (
SELECT 
	order_item_id,
	customer_name,
	gender,
	city,
	order_id,
	product_id,
	order_date,
	quantity,
	cost,
	Sales
FROM gold.fact_orders AS fo
LEFT JOIN gold.dim_customers AS dc
ON fo.customer_id = dc.customer_id),
CTE2 AS(
SELECT
	customer_name,
	gender,
	city,
	ROUND(CONVERT(float,SUM(Sales)),0) AS Total_Sales,
	ROUND(CONVERT(float,SUM(cost)),0) AS Total_Cost,
	COUNT(DISTINCT product_id) AS Total_Product,
	COUNT(DISTINCT order_id) AS Total_Order,
	SUM(quantity) AS Total_Quantity,
	MIN(order_date) AS First_Order,
	MAX(order_date) AS Last_Order,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS Life_Span
FROM CTE1
GROUP BY 
customer_name,
gender,
city)

SELECT
customer_name,
gender,
city,
Total_Sales,
CASE
	WHEN NTILE(3) OVER (ORDER BY Total_Sales DESC) = 1 THEN 'High Performance'
	WHEN NTILE(3) OVER (ORDER BY Total_Sales DESC) = 2 THEN 'Mid Performance'
	WHEN NTILE(3) OVER (ORDER BY Total_Sales DESC) = 3 THEN 'Low Performance'
END AS Segmentation,
Total_Cost,
Total_Product,
Total_Order,
CASE
	WHEN Total_Sales = 0 THEN 0
	ELSE ROUND((CONVERT(float,Total_Sales)/Total_Order),0)
END AS Avg_Order_Value,
Total_Quantity,
Last_Order,
First_Order,
Life_Span,
CASE
	WHEN Total_Sales = 0 THEN 0
	ELSE ROUND((CONVERT(float,Total_Sales)/NULLIF(Life_Span,0)),0) 
END AS Avg_Monthly_Spend
FROM CTE2;
-----------------------------------------------
SELECT * FROM gold.report_customers;
SELECT * FROM gold.report_products;