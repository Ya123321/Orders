select * from dbo.market$
select * from dbo.orders$
select * from dbo.prod$
select * from dbo.shipping$

--1 What is the number of orders and profit each month?
select count(o.Order_ID) as number_of_orders, cast(sum(m.profit) as varchar)+'$'as total_profit 
,month(o.Order_Date) as month from dbo.orders$ o
join dbo.market$ m on o.Ord_id=m.Ord_id
group by month(o.Order_Date)
order by sum(m.profit) desc

--2 For each product,what are the sales from  the category and the sub-category?
select distinct(p.prod_id), p.Product_Category, 
sum(m.Order_Quantity) over (partition by p.Product_Category) Number_Of_Quantity_of_Category,
p.product_sub_category,
sum(m.Order_Quantity) over (partition by p.product_sub_category) Number_Of_Quantity_of_sub_Category
from dbo.prod$ p 
join dbo.market$ m on p.Prod_id=m.Prod_id
order by 3 desc

--3 How long on average does it take for a booking to arrive if it urgency?
select o.Order_Priority, avg(datediff(day,o.order_date,s.ship_date)) as days
from dbo.shipping$ s join dbo.orders$ o on s.order_id=o.order_id
group by o.Order_Priority

--4 how much money each customer spent each month?
select distinct m.Cust_id,month(o.order_date) as month,
sum(m.sales) over (partition by m.Cust_id order by month(o.order_date)) sales_per_customer
from dbo.market$ m join dbo.orders$ o on m.Ord_id=o.ord_id
--sum(m.sales) over (partition by m.Cust_id) number_of_customers
group by month(o.order_date),Cust_id,m.sales

--5 What is the cumulative amount of sales by order and date? 
select  o.order_id as Order_id , format(o.order_date,'dd/MM/yyyy') as Date ,sum(m.sales) as Order_Sales,
sum(m.sales) over (order by format(o.order_date,'dd/MM/yyyy') 
ROWS between unbounded preceding and current row) as Accumulate_Sales
from dbo.market$ m join dbo.orders$ o on m.Ord_id=o.ord_id
--sum(m.sales) over (partition by m.Cust_id) number_of_customers
group by format(o.order_date,'dd/MM/yyyy'), o.order_id,m.sales

--6 What is the most profitable day of the week?
select top 1 datename(dw,o.Order_Date) as Day_Of_The_Week,cast(count(order_id)as varchar)+' orders' as Total_Number_Of_Orders
from dbo.orders$ o
group by datename(dw,o.Order_Date)
order by count(order_id) desc

--7 What is the total cost of delivery each month and how many orders were shipped?
select distinct month(s.ship_date) as month,sum(m.Order_Quantity) as Quantity_Orderd 
,round(sum(m.Shipping_Cost),2) as Cost_Of_Shipping
from dbo.market$ m
join dbo.shipping$ s on m.Ship_id=s.Ship_id
group by month(s.ship_date)
order by 3 desc

--8 How many customers from all the customers have set up their priority order at least once as high?
with "A" as (select count(distinct m.Cust_id) as number_of_high_priority from
dbo.market$ m join dbo.orders$ o on m.ord_id=o.ord_id
where o.order_priority='HIGH')
select cast(cast (number_of_high_priority as float) /cast(count(distinct m.Cust_id) as float)*100 as varchar)+'%'
from A, dbo.market$ m  
group by number_of_high_priority



--9 median of Product_Base_Margin
--
SELECT
(
 (SELECT MAX(Product_Base_Margin) FROM
   (SELECT TOP 50 PERCENT Product_Base_Margin FROM dbo.market$ ORDER BY Product_Base_Margin) AS BottomHalf)
 +
 (SELECT MIN(Product_Base_Margin) FROM
   (SELECT TOP 50 PERCENT Product_Base_Margin FROM dbo.market$ ORDER BY Product_Base_Margin DESC) AS TopHalf)
) / 2 AS Median

--9 For each parent product it is profitable according to "Product_Base_Margin" measure?
with avg_Margin as(select avg(m.Product_Base_Margin) as avarge_Margin
from dbo.market$ m)
select m.Prod_id, p.Product_Sub_Category, case
when m.Product_Base_Margin<avarge_Margin then 'Low-Margin'
else 'High-Margin' end as Kind_Margin from  avg_Margin, dbo.market$ m
join dbo.prod$ p on m.prod_id=p.prod_id
order by 3

--11 Ranking of products by quantity of products sold in each category
select p.prod_id, p.Product_Category,count(p.prod_id) as amount_of_sales, rank ()over (partition by p.Product_Category order by count(p.prod_id) desc) ranking
from dbo.market$ m join dbo.prod$ p on m.prod_id=p.prod_id
group by p.prod_id,p.Product_Category
