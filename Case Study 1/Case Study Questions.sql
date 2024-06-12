/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT a.customer_id, 
	   sum(b.price) as "total Spent"
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id 
GROUP BY a.customer_id;


-- 2. How many days has each customer visited the restaurant?
-- Distinct to count unique days 

SELECT  a.customer_id,
		COUNT(DISTINCT a.order_date) as "days"
FROM dannys_diner.sales a
GROUP BY a.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
-- The question is a bit ambiguous, we could either using the ranking or
-- Make an assumption that the row order determines time purchased or order of purchase

SELECT Rank_table.customer_id, Rank_table.product_name
FROM
(SELECT a.customer_id,
		b.product_name,a.order_date, 
		RANK() OVER (PARTITION BY a.customer_id ORDER BY a.order_date  ASC) as order_rank,
		ROW_NUMBER() OVER (PARTITION BY a.customer_id ORDER BY a.order_date  ASC) as order_row
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id) as Rank_table
WHERE Rank_table.order_rank = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- LIMIT 1
-- OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY

SELECT TOP 1 
	   b.product_name,
	   COUNT(a.product_id) as count_per_product
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
GROUP BY b.product_name
ORDER BY COUNT(a.product_id) DESC




-- 5. Which item was the most popular for each customer?
-- The question is a bit ambiguous, we could either using the ranking or
-- Make an assumption that the row order determines time purchased or order of purchase

SELECT fte.customer_id,
	   fte.product_name
FROM 
(SELECT 
	cte.customer_id, 
	cte.product_name,
	cte.count_per_product,
	RANK() OVER (PARTITION BY cte.customer_id ORDER BY cte.count_per_product  DESC) as order_rank
	ROW_NUMBER() OVER (PARTITION BY cte.customer_id ORDER BY cte.count_per_product  ASC) as order_row
FROM 
(SELECT a.customer_id,b.product_name,COUNT(a.product_id) as count_per_product
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
GROUP BY a.customer_id,b.product_name) as cte) as fte
WHERE fte.order_rank = 1


-- 6. Which item was purchased first by the customer after they became a member?
-- A: Ramen (01/10)  B: Sushi (01/11) 

SELECT bte.customer_id,
	   bte.product_name
FROM 
(SELECT a.customer_id,
	   a.order_date,
	   b.product_name,
	   c.join_date,
	   RANK() OVER (PARTITION BY a.customer_id ORDER BY a.order_date  ASC) as order_rank
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
INNER JOIN dannys_diner.members c on  a.customer_id = c.customer_id
WHERE a.order_date >= c.join_date) bte
WHERE bte.order_rank = 1



-- 7. Which item was purchased just before the customer became a member?

SELECT bte.customer_id,
	   bte.product_name
FROM 
(SELECT a.customer_id,
	   a.order_date,
	   b.product_name,
	   c.join_date,
	   RANK() OVER (PARTITION BY a.customer_id ORDER BY a.order_date  DESC) as order_rank
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
INNER JOIN dannys_diner.members c on  a.customer_id = c.customer_id
WHERE a.order_date < c.join_date) bte
WHERE bte.order_rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT a.customer_id,
	   count(b.product_name) as total_items,
	   sum(b.price) as amount_spent
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
INNER JOIN dannys_diner.members c on  a.customer_id = c.customer_id
WHERE a.order_date < c.join_date
GROUP BY a.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT a.customer_id,
	   SUM(CASE 
			WHEN b.product_name = 'sushi' THEN 2*10*b.price
			ELSE 10*b.price 
		   END) as total_points
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
GROUP BY a.customer_id


-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

SELECT a.customer_id,
	   SUM(CASE 
			WHEN (a.order_date BETWEEN c.join_date AND  DATEADD(DAY,6,c.join_date)) 
			or b.product_name = 'sushi' THEN 2*10*b.price
			ELSE 10*b.price 
		   END) as total_points
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
INNER JOIN dannys_diner.members c on  a.customer_id = c.customer_id
WHERE MONTH(a.order_date) = 1
GROUP BY a.customer_id


-- Bonus Questions

-- Join All The Things
SELECT a.customer_id,
       a.order_date,
       b.product_name,
	   b.price,
	   CASE WHEN a.order_date >= c.join_date THEN 'Y'
	   ELSE 'N' END as "member"
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
LEFT JOIN dannys_diner.members c on  a.customer_id = c.customer_id


-- Rank All Things

SELECT hte.*,
        CASE 
            WHEN hte.member = 'N' THEN NULL
            ELSE RANK() OVER (PARTITION BY hte.customer_id,hte.member ORDER BY hte.order_date)
        END AS ranking
FROM
(SELECT a.customer_id,
       a.order_date,
       b.product_name,
	   b.price,
	   CASE WHEN a.order_date >= c.join_date THEN 'Y'
	   ELSE 'N' END as "member"
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
LEFT JOIN dannys_diner.members c on  a.customer_id = c.customer_id) as hte
ORDER BY
    hte.customer_id,
    hte.order_date; 


WITH ranked_orders AS (
    SELECT
        customer_id,
        order_date,
        product_name,
        price,
        member,
        CASE 
            WHEN member = 'N' THEN NULL
            ELSE RANK() OVER (PARTITION BY customer_id,member ORDER BY order_date)
        END AS ranking
    FROM
        (SELECT a.customer_id,
       a.order_date,
       b.product_name,
	   b.price,
	   CASE WHEN a.order_date >= c.join_date THEN 'Y'
	   ELSE 'N' END as "member"
	FROM dannys_diner.sales a
	INNER JOIN dannys_diner.menu b on a.product_id = b.product_id
	LEFT JOIN dannys_diner.members c on  a.customer_id = c.customer_id) as orders
)
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,
    rank
FROM
    ranked_orders
ORDER BY
    customer_id,
    order_date;



