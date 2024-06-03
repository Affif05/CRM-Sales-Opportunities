use sales_crm;

-- CLEANING DATA
-- 1. table accounts
select * from accounts
where sector like 'tech%';

update accounts
set sector = 'technology'
where sector like 'tech%';

select distinct * from accounts;

-- 2. table products
select * from products
order by series;

-- 3. table sales_teams
select distinct * from sales_teams
order by sales_agent asc;

-- 4. table sales_pipeline
select * from sales_pipeline
order by sales_agent, deal_stage asc
;

DELETE FROM sales_pipeline
WHERE account = '';

select sales_agent, product,  `account`, deal_stage, engage_date, close_date, count(*)
from sales_pipeline
group by sales_agent, product, `account`, deal_stage, engage_date, close_date
having count(*) > 1
order by sales_agent, deal_stage;

SELECT MIN(opportunity_id) AS min_id
FROM sales_pipeline
GROUP BY sales_agent, product, `account`, deal_stage, engage_date, close_date
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE keep_ids AS
SELECT MIN(opportunity_id) AS min_id
FROM sales_pipeline
GROUP BY sales_agent, product, `account`, deal_stage, engage_date, close_date
HAVING COUNT(*) > 1;

delete from sales_pipeline
where opportunity_id in
(
select min_id from keep_ids
);

DROP TEMPORARY TABLE keep_ids;

-- 5. Table sales_teams
select * from sales_teams;


-- STANDARDIZING DATA
select * from sales_pipeline;

alter table sales_pipeline
MODIFY COLUMN engage_date DATE;

-- REMOVEING NULL / BLANK VALUES
select * from sales_pipeline;

-- REMOVE ANY COLUMNS
select * from sales_pipeline;





-- Searching the best sales agents based on total closed order
select sales_agent,
count(case when deal_stage = 'Won' then 1 end) as total_won,
sum(close_value) as total_close_value
from sales_pipeline
group by sales_agent
order by total_won desc
limit 1;



-- FRAGE 1: How is each sales team performing compared to the rest?
-- searching total win & lost, total close value
select engage_date,
sales_agent,
count(case when deal_stage = 'Won' then 1 end) as total_won, 
count(case when deal_stage = 'Lost' then 1 end) as total_lost,
sum(close_value) as total_close_value
from sales_pipeline
group by engage_date,sales_agent
order by  sales_agent, total_close_value desc;

-- searching products that have the greatest sales value from each sales agents
SELECT t1.sales_agent,
       t1.product,
       t1.total_won,
       t1.total_lost,
       t1.total_close_value
FROM (
    SELECT sales_agent, 
           product,
           COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS total_won, 
           COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS total_lost,
           SUM(close_value) AS total_close_value,
           ROW_NUMBER() OVER (PARTITION BY sales_agent ORDER BY SUM(close_value) DESC) AS rn
    FROM sales_pipeline
    GROUP BY sales_agent, product
) t1
WHERE t1.rn = 1
ORDER BY t1.sales_agent;

-- searching most saled products from each sales agents
WITH sales_ranking AS (
    SELECT 
        sales_agent, 
        product,
        count(case when deal_stage = 'Won' then 1 end) as sales_count,
        ROW_NUMBER() OVER (PARTITION BY sales_agent ORDER BY COUNT(*) DESC) AS rn
    FROM sales_pipeline
    GROUP BY sales_agent, product
)
SELECT sales_agent, product, sales_count
FROM sales_ranking
WHERE rn = 1
ORDER BY sales_agent;

-- Sales agents performance based on regional office
SELECT st.regional_office,
COUNT(CASE WHEN sp.deal_stage = 'Won' THEN 1 END) AS total_won
FROM sales_pipeline sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
GROUP BY st.regional_office;


-- FRAGE 2: Are any sales agents lagging behind?
select * from sales_pipeline
where deal_stage = 'Engaging' or deal_stage = 'Prospecting';

-- FRAGE 3: Can you identify any quarter-over-quarter trends?
-- searching sales closing trends per quarter
select YEAR(close_date) as 	`Year`,
quarter(close_date) as `Quarter`,
SUM(CASE WHEN deal_stage = 'Won' THEN 1 END) AS total_winning_sales,
SUM(close_value) AS total_close_value
from sales_pipeline
where quarter(close_date) IS NOT NULL
group by `Year`, `Quarter`;

-- searching quarterly marketing and sales trends
select product,
engage_date,
SUM(CASE WHEN deal_stage = 'Won' THEN 1 else 0 END) AS total_winning_sales,
SUM(CASE WHEN deal_stage = 'Lost' THEN 1 else 0 END) AS total_losing_sales,
SUM(CASE WHEN deal_stage = 'Engaging' THEN 1 else 0 END) AS total_lagging_sales,
SUM(close_value) AS total_close_value
from sales_pipeline
where YEAR(engage_date) is not null
group by engage_date, product;

-- Frage 4: Do any products have better win rates?
-- Searching The most hard selling product
select pr.product as hard_selling_product, sum(sp.close_value) as total_value
from sales_pipeline sp
join products pr on sp.product = pr.product
where sp.deal_stage = 'Won'
group by pr.product, pr.sales_price
order by total_value desc
limit 1;

-- Searching The most saled product
select pr.product as most_saled_product, count(sp.product) as total_saled_product
from sales_pipeline sp
join products pr on sp.product = pr.product
where sp.deal_stage = 'Won'
group by pr.product, pr.sales_price
order by total_saled_product desc
limit 1;


-- searching total won for every products
select 
product,
SUM(CASE WHEN deal_stage = 'Won' THEN 1 else 0 END) AS total_winning_sales
from sales_pipeline
group by product
order by total_winning_sales desc;

-- searching total won based on product series
select 
pr.series,
SUM(CASE WHEN deal_stage = 'Won' THEN 1 else 0 END) AS total_winning_sales
from sales_pipeline sp
join products pr on sp.product = pr.product
group by pr.series;




select * from products;

select count(product) as total_saled_product, sum(close_value) from sales_pipeline
where product = 'MG Special' and deal_stage = 'Won';



