-- Apple Sales Project - 1M rows sales dataset


Here is the fully formatted SQL script rewritten according to best practices. Each query ends with a semicolon (;), is properly indented, and formatted to enhance readability.

Dataset Queries
sql
Copy code
-- Apple Sales Project - 1M rows sales dataset

SELECT * 
FROM category;

SELECT * 
FROM products;

SELECT * 
FROM stores;

SELECT * 
FROM sales;


-- EDA

-- Distinct values in repair_status
SELECT DISTINCT index, repair_status 
FROM warranty;

-- Count total sales
SELECT COUNT(*) 
FROM sales;

--Improving Query Performance

-- et - 68ms
-- pt - 0.15ms
-- et after index 5-10ms

EXPLAIN ANALYZE
SELECT * 
FROM sales
WHERE product_id = 'p-44';

CREATE INDEX sales_product_id 
ON sales(product_id);


-- Business Problems
-- Medium Problems

-- Q.1 Find the number of stores in each country.

SELECT
    country,
    COUNT(store_id) AS total_stores
FROM stores
GROUP BY country
ORDER BY total_stores DESC;

-- Q.2 Calculate the total number of units sold by each store.

SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st
    ON st.store_id = s.store_id
GROUP BY s.store_id, st.store_name
ORDER BY total_units_sold DESC;

-- Q.3 Identify how many sales occurred in December 2023

/*  SELECT 
        *,
        TO_CHAR(sale_date, 'MM-YYYY') 
    FROM sales
    WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023'
*/

SELECT
    COUNT(sale_id) AS total_sales
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023';

-- Q.4 Determine how many stores have never had a warranty claim filed.

SELECT COUNT(*)
FROM stores
WHERE store_id NOT IN (
    SELECT DISTINCT store_id
    FROM sales AS s
    RIGHT JOIN warranty AS w
        ON s.sale_id = w.sale_id
);

-- Q.5 Calculate the percentage of warranty claims marked as "Warranty Void"
-- Number of claims as wv / total claim * 100

SELECT
    ROUND(
        COUNT(claim_id) * 100.0 / (SELECT COUNT(*) FROM warranty),
        0
    ) AS warranty_void_percentage
FROM warranty
WHERE repair_status = 'Warranty Void';

-- Q.6 Identify which store had the highest total units sold in the past year.

SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st
    ON s.store_id = st.store_id
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY s.store_id, st.store_name
ORDER BY total_units_sold DESC
LIMIT 1;

-- Q.7 Count the number of unique products sold in the last year.

SELECT
    COUNT(DISTINCT product_id) AS unique_products_sold
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year';

-- Answer: 50 Unique products

-- Q.8 Find the average price of products in each category.

SELECT
    p.category_id,
    c.category_name,
    ROUND(AVG(p.price)::numeric, 2) AS avg_price
FROM products AS p
JOIN category AS c
    ON p.category_id = c.category_id
GROUP BY p.category_id, c.category_name
ORDER BY avg_price DESC;

-- Q.9 How many warranty claims were filed in 2020?

SELECT
    COUNT(*) AS warranty_claims
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2020;

-- Q.10 For each store, identify the best-selling day based on highest quantity sold.
-- store_id, day_name, sum(qty)
-- window dense rank

SELECT *
FROM (
    SELECT
        store_id,
        TO_CHAR(sale_date, 'Day') AS day_name,
        SUM(quantity) AS total_units_sold,
        RANK() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rank
    FROM sales
    GROUP BY store_id, day_name
) AS t1
WHERE rank = 1;


--Medium to Hard Questions

-- Q.11  Identify the least selling product in each country for each year based on total units sold.

WITH product_rank AS (
    SELECT
        st.country,
        p.product_name,
        SUM(s.quantity) AS total_qty_sold,
        RANK() OVER (PARTITION BY st.country ORDER BY SUM(s.quantity)) AS rank
    FROM sales AS s
    JOIN stores AS st
        ON s.store_id = st.store_id
    JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY st.country, p.product_name
)
SELECT *
FROM product_rank
WHERE rank = 1;

-- Q.12 Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT
    COUNT(*) AS claims_within_180_days
FROM warranty AS w
LEFT JOIN sales AS s
    ON w.sale_id = s.sale_id
WHERE w.claim_date - s.sale_date <= 180;


-- Q.13 Determine how many warranty claims were filed for products launched in the last two years.
-- each product
-- number of claims
-- numnber of sales
-- each product must have been launched within the last 2 years

SELECT
    p.product_name,
    COUNT(w.claim_id) AS number_claims,
    COUNT(s.sale_id) AS total_sales
FROM warranty AS w
RIGHT JOIN sales AS s
    ON s.sale_id = w.sale_id
JOIN products AS p
    ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY p.product_name
HAVING COUNT(w.claim_id) > 0;



-- Q.14 List the months in the last three years where sales exceeded 5,000 units in the USA.

SELECT 
    TO_CHAR(s.sale_date, 'MM-YYYY') AS month,
    SUM(s.quantity) AS total_units_sold
FROM 
    sales AS s
JOIN 
    stores AS st
    ON s.store_id = st.store_id
WHERE 
    st.country = 'USA'
    AND s.sale_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY 
    TO_CHAR(s.sale_date, 'MM-YYYY')
HAVING 
    SUM(s.quantity) > 5000;

-- Q.15 Identify the product category with the most warranty claims filed in the last two years.

SELECT 
    c.category_name,
    COUNT(w.claim_id) AS total_claims
FROM 
    warranty AS w
LEFT JOIN 
    sales AS s
    ON w.sale_id = s.sale_id
JOIN 
    products AS p
    ON p.product_id = s.product_id
JOIN 
    category AS c
    ON c.category_id = p.category_id
WHERE 
    w.claim_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 
    c.category_name
ORDER BY 
    total_claims DESC;

-- Complex Problems
-- Q.16 Determine the percentage chance of receiving warranty claims after each purchase for each country.

SELECT 
    country,
    total_unit_sold,
    total_claim,
    ROUND(COALESCE(total_claim::NUMERIC / total_unit_sold::NUMERIC * 100, 0), 0) AS risk_percentage
FROM (
    SELECT 
        st.country,
        SUM(s.quantity) AS total_unit_sold,
        COUNT(w.claim_id) AS total_claim
    FROM sales AS s
    JOIN stores AS st
        ON s.store_id = st.store_id
    LEFT JOIN warranty AS w
        ON w.sale_id = s.sale_id
    GROUP BY st.country
) country_claims_summary
ORDER BY risk_percentage DESC;

-- Q.17 Analyze the year-by-year growth ratio for each store.
-- find each store and yearly sales.

WITH yearly_sales AS (
    SELECT
        s.store_id,
        st.store_name,
        EXTRACT(YEAR FROM sale_date) AS year,
        SUM(s.quantity * p.price) AS total_sale
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN stores AS st
        ON st.store_id = s.store_id
    GROUP BY s.store_id, st.store_name, year
    ORDER BY st.store_name, year
),
growth_ratio AS (
    SELECT
        store_name,
        year,
        LAG(total_sale, 1) OVER (PARTITION BY store_name ORDER BY year) AS last_year_sale,
        total_sale AS current_year_sale
    FROM yearly_sales
)

SELECT
    store_name,
    year,
    last_year_sale,
    current_year_sale,
    ROUND(
        (current_year_sale - last_year_sale)::NUMERIC /
        last_year_sale::NUMERIC * 100, 2
    ) AS growth_ratio
FROM growth_ratio
WHERE
    last_year_sale IS NOT NULL
    AND year <> EXTRACT(YEAR FROM CURRENT_DATE);

-- Q.18 Calculate the correlation between product price and warranty claims for 
-- products sold in the last five years, segmented by price range.

SELECT 
    CASE
        WHEN p.price < 500 THEN 'Less Expensive Product'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid-Range Product'
        ELSE 'Expensive Product'
    END AS price_segment,
    COUNT(w.claim_id) AS total_claims
FROM 
    warranty AS w
LEFT JOIN 
    sales AS s
    ON w.sale_id = s.sale_id
JOIN 
    products AS p
    ON p.product_id = s.product_id
WHERE 
    w.claim_date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY 
    price_segment;

-- Q.19 Identify the store with the highest percentage of 'Paid Repaired' claims 
-- relative to total claims to total claims filed.

WITH paid_repair AS (
    SELECT 
        s.store_id,
        COUNT(w.claim_id) AS paid_repaired
    FROM 
        sales AS s
    RIGHT JOIN 
        warranty AS w
        ON w.sale_id = s.sale_id
    WHERE 
        w.repair_status = 'Paid Repaired'
    GROUP BY 
        s.store_id
),
total_repair AS (
    SELECT 
        s.store_id,
        COUNT(w.claim_id) AS total_repaired
    FROM 
        sales AS s
    RIGHT JOIN 
        warranty AS w
        ON w.sale_id = s.sale_id
    GROUP BY 
        s.store_id
)
SELECT 
    tr.store_id,
    st.store_name,
    pr.paid_repaired,
    tr.total_repaired,
    ROUND(
        (pr.paid_repaired::NUMERIC / tr.total_repaired::NUMERIC) * 100, 
        2
    ) AS percentage_paid_repaired
FROM 
    paid_repair AS pr
JOIN 
    total_repair AS tr
    ON pr.store_id = tr.store_id
JOIN 
    stores AS st
    ON tr.store_id = st.store_id


-- Q.20 Calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

WITH monthly_sales AS (
    SELECT 
        s.store_id,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        SUM(p.price * s.quantity) AS total_revenue
    FROM 
        sales AS s
    JOIN 
        products AS p
        ON s.product_id = p.product_id
    WHERE 
        s.sale_date >= CURRENT_DATE - INTERVAL '4 years'
    GROUP BY 
        s.store_id, year, month
    ORDER BY 
        s.store_id, year, month
),
monthly_trends AS (
    SELECT 
        store_id,
        year,
        month,
        total_revenue,
        SUM(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month) AS running_total,
        LAG(total_revenue) OVER (PARTITION BY store_id ORDER BY year, month) AS previous_month_revenue
    FROM 
        monthly_sales
)
SELECT 
    store_id,
    year,
    month,
    total_revenue,
    running_total,
    previous_month_revenue,
    ROUND(
        CASE 
            WHEN previous_month_revenue IS NOT NULL AND previous_month_revenue > 0 THEN
                (total_revenue::numeric - previous_month_revenue::numeric) / previous_month_revenue::numeric * 100
            ELSE 
                NULL
        END, 
    2) AS month_over_month_change
FROM 
    monthly_trends
ORDER BY 
    store_id, year, month;


-- Q.21 Analyze product sales trends over time, segmented into key periods: from launch date to 6 months, 6 to 12 months and from 12 to 18 months, and beyond 18 months.

SELECT 
    p.product_name,
    CASE
        WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 months' THEN '0-6 months'
        WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 months' AND p.launch_date + INTERVAL '12 months' THEN '6-12 months'
        WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 months' AND p.launch_date + INTERVAL '18 months' THEN '12-18 months'
        ELSE '18 months+'
    END AS product_life_cycle,
    SUM(s.quantity) AS total_quantity_sold
FROM 
    sales AS s
JOIN 
    products AS p
    ON s.product_id = p.product_id
GROUP BY 
    p.product_name, product_life_cycle
ORDER BY 
    p.product_name, total_quantity_sold DESC;