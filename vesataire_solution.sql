--1: top 10 brands by sale
SELECT brand,
       ROUND(SUM(revenue::numeric), 2) AS total_sales
FROM 
	public.datasets_sales
GROUP BY brand
ORDER BY total_sales DESC
LIMIT 10;

--2: Calculate the contribution (in percentage) of each country to the total by both sales and nb of items sold.
SELECT
  c.country,
  ROUND(CAST(SUM(s.revenue) / SUM(SUM(s.revenue)) OVER () AS numeric) * 100, 2) AS revenue_percentage,
  ROUND((count(*) / SUM(count(*)) OVER ()) * 100, 2) AS items_sold_percentage
FROM 
	public.datasets_sales s
LEFT JOIN 
	public.datasets_country c 
	ON s.id_seller_country = c.id_country
GROUP BY c.country;


-- 3: Which two countries had the best relationship in terms of sales? Include the sales in both direction
WITH ranked_sales AS (
    SELECT 
        LEAST(id_seller_country, id_buyer_country) AS country1, 
        GREATEST(id_seller_country, id_buyer_country) AS country2, 
        COUNT(*) AS order_count,
        SUM(revenue) AS total_sales
    FROM 
        public.datasets_sales ds
    WHERE 
        id_seller_country <> id_buyer_country  
    GROUP BY 
        1, 2
    ORDER BY 
        total_sales DESC
    LIMIT 2
)
SELECT 
    dc1.country AS country1, 
    dc2.country AS country2, 
    rs.order_count, 
    rs.total_sales
FROM 
    ranked_sales rs
JOIN 
    public.datasets_country dc1 ON rs.country1 = dc1.id_country
JOIN 
    public.datasets_country dc2 ON rs.country2 = dc2.id_country;


-- 4: When and why should you create a table or a view?
   
  /* Tables -->
   * Why Tables?:  Can be directly updated, hence they're faster for basic operations eg: add, update, or delete. They support ACID properties
   * (Atomicity, Consistency, Isolation, Durability) which means they support reliable transactions.
   * 
   * 
   * When Tables? : When we want to store actual data. Also when there are frequent modifications then we use tables.
   * They're also used when we want to impose data integrity eg: defining relationships, foreign, primary keys or unique constraints 
   * between different fields, other tables. Useful for data modeling purposes. Used when we have to query large amounts of data, for performance, can
   * use indexes

   * 
   * 
   * 
   * Views --> 
   * They don't store data themselves, but act as a predefined query that fetchess and organizes data.
   * 
   * Why Views? : Efficient in terms of data storage, doesn't store data, just a virtual representation. 
   * In this case,we can save sending the many bytes again and again. Moreover, when we want to enforce data consistency
   * 
   * 
   * When Views?: When we want to handle complex joins easily, alongside aggregations, or calculations into a single view.
   * Helps to add/remove field without changing the schema. Plus, the GRANT commands
   * which controls data access better. Also, its more use-case specific, eg: when we want to have filtered, calcultaed, and formatted data. Overall 
   * giving a focussed result-set for the users. Furthermore, they support reusability, the same complex queries across multiple places in application 
   *
   * */
   



-- 5: What percentage of all buyers are repeat buyers represented in the second week by number of customers? 
-- (you may assume week 1 as the 1/1/2021 to 7/1/2021 and the second week as 8/1/2021 to 15/1/2021)
   
   WITH week1_buyers AS (
    SELECT DISTINCT id_buyer
    FROM 
    	public.datasets_sales
    WHERE date_payment BETWEEN '2021-01-01' AND '2021-01-07'
),
week2_buyers AS (
    SELECT DISTINCT id_buyer
    FROM 
    	public.datasets_sales
    WHERE date_payment BETWEEN '2021-01-08' AND '2021-01-15'
),
repeat_buyers AS (
    SELECT w2.id_buyer
    FROM 
    	week2_buyers w2
    JOIN 
    	week1_buyers w1 
    	ON w2.id_buyer = w1.id_buyer
)

SELECT 
    (COUNT(rb.id_buyer) * 100.0 / (SELECT COUNT(*) FROM week2_buyers)) AS repeat_buyer_percentage
FROM 
    repeat_buyers rb;
  

 -- 6: What was the total sales of repeat buyers in the first week compared to the second week? 
 --(answer in % increase or decrease). Note that you must first find the repeat buyers in week 2, and then use this list to calculate the sales in both weeks.

   
WITH week1_buyers AS (
    SELECT DISTINCT id_buyer
    FROM 
    	public.datasets_sales
    WHERE date_payment BETWEEN '2021-01-01' AND '2021-01-07'
),
week2_buyers AS (
    SELECT DISTINCT id_buyer
    FROM 
    	public.datasets_sales
    WHERE date_payment BETWEEN '2021-01-08' AND '2021-01-15'
),
repeat_buyers AS (
    SELECT w2.id_buyer
    FROM 
    	week2_buyers w2
    JOIN week1_buyers w1 ON w2.id_buyer = w1.id_buyer
),
first_week AS (
    SELECT 
        SUM(ds.revenue) AS first_week_rev
    FROM 
        repeat_buyers rb 
    JOIN 
        public.datasets_sales ds 
    ON 
        ds.id_buyer = rb.id_buyer  
    WHERE 
        ds.date_payment BETWEEN '2021-01-01' AND '2021-01-07'
),
second_week AS (
    SELECT 
        SUM(ds.revenue) AS second_week_rev
    FROM 
        repeat_buyers rb 
    JOIN 
        public.datasets_sales ds 
    ON 
        ds.id_buyer = rb.id_buyer  
    WHERE 
        ds.date_payment BETWEEN '2021-01-08' AND '2021-01-15'
)
SELECT 
    first_week.first_week_rev,
    second_week.second_week_rev,
    first_week.first_week_rev / second_week.second_week_rev AS revenue_ratio,
    CASE
        WHEN first_week.first_week_rev > second_week.second_week_rev THEN 'Decrease in 2nd week'
        WHEN first_week.first_week_rev < second_week.second_week_rev THEN 'Increased in 2nd week'
        ELSE 'No Change'
    END AS revenue_status
FROM 
    first_week,
    second_week;


-- 7: implement a new tool that is able to combine data from several sources easily and provide basic visualisation capabilities. 
-- What would you consider in your decision making process and why?
   
   /* Detailed document is attached
    * 
    * */
   
-- 8: singe statement, 3 tasks: 

MERGE INTO public.datasets_country AS target
USING (
    SELECT 
        0 AS id_country, 'DELETE' AS operation, NULL AS region, NULL AS country
    UNION ALL
    SELECT 
        target.id_country, 'UPDATE' AS operation, 'OCEA' AS region, NULL AS country
    FROM 
        public.datasets_country AS target
    WHERE 
        target.country IN ('Australia', 'New Zealand')
    UNION ALL
    SELECT 
        246 AS id_country, 'INSERT' AS operation, 'SPACE' AS region, 'Mars' AS country
) AS source
ON target.id_country = source.id_country
WHEN MATCHED AND source.operation = 'DELETE' THEN 
    DELETE
WHEN MATCHED AND source.operation = 'UPDATE' THEN 
    UPDATE SET region = source.region
WHEN NOT MATCHED AND source.operation = 'INSERT' THEN 
    INSERT (id_country, region, country) 
    VALUES (source.id_country, source.region, source.country);


   
-- 9 :id_buyers split into odd and even groups. 
-- (I did not use the hint link of snowflake, because those functions are not available in postgres.)
   
WITH id_buyers AS (
    SELECT DISTINCT id_buyer
    FROM 
    	public.datasets_sales
),

even_buyers AS (
    SELECT array_agg(id_buyer ORDER BY id_buyer) AS id_buyers
    FROM 
    	id_buyers
    WHERE id_buyer % 2 = 0
),

odd_buyers AS (
    SELECT array_agg(id_buyer ORDER BY id_buyer) AS id_buyers
    FROM id_buyers
    WHERE id_buyer % 2 <> 0
)

SELECT json_build_object(
           'Id_buyers', even_buyers.id_buyers,
           'Is_even', true
       ) AS buyers_group
FROM even_buyers

UNION ALL

SELECT json_build_object(
           'Id_buyers', odd_buyers.id_buyers,
           'Is_even', false
       ) AS buyers_group
FROM odd_buyers;

   
   

-- 10: Problems with Query; debugging


/*Improvements for the Provided Query:
1. Simplification in subquery :
The subquery for CATEGORY can be joined to DWH_PRD.DIM_VC_PRD_PRODUCT table directly instead of using a subquery.
Moreover,  can remove redundant GROUP BY 1, 2 from the sellers CTE as DISTINCT already ensures uniqueness.
2. Consistency in alias :
There’re no consistent aliases for tables throughout the query. For example, use o instead of O for DWH_SLS.FCT_VC_SLS_ORDER_PRODUCT. 
Can be made better by  having a lowercase and descriptive approach. Also, for the CTE name sellers could have been use , instead of us sellers to improve clarity.
3. Uselesss "where" clause:
The WHERE Us.ID_SELLER_COUNTRY = 223 clause is already applied in the first WITH clause. We can remove from the second WHERE clause.
4. "Join" optimization:
Can use an inner join instead of a left join on us_sellers and DWH_SLS.FCT_VC_SLS_ORDER_PRODUCT tables if we only want data where a 
seller exists and has placed an order.
5. Window functions:
Can create a window function to calculate CURRENT_DATE once per query execution.
6. Cleaning of code:
There is no fixed spacing around commas, parentheses, and operators for consistency. (especially in the select clauses) 
7. Column naming selection:
Must only select necessary columns to optimize performance, especially in column-store databases as hinted.
Moreover, if we filter at early steps that will reduce the dataset size before joins and aggregations. eg: I think date filter should have been up in CTE
**/







   