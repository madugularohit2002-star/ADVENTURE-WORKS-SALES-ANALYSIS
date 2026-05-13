-- Creating a database
create database AW_P1;

-- Utilizing the database
use AW_P1;

-- Displaying the databases 
show databases;

-- Displaying the tables
show tables;
select * from customers;
select * from D_dates;
select * from product;
select * from category;
select * from sub_category;
select * from sales_territory;
select * from old_sales;
select * from new_sales;



-- 0. Union of Fact Internet sales and Fact internet sales new
create table sales_combined as
select * from old_sales
union all
select * from new_sales;

select * from sales_combined;




-- 1.Lookup the productname from the Product sheet to Sales sheet.
select
    s.SalesOrderNumber,
    s.ProductKey,
    p.EnglishProductName as ProductName,
    s.OrderQuantity,
    s.SalesAmount
from sales_combined s
inner join Product p
    on s.ProductKey = p.ProductKey;




-- 2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.
select
    s.SalesOrderNumber,
    s.ProductKey,
    p.EnglishProductName as ProductName,
    s.UnitPrice,
    s.CustomerKey,
    TRIM(
        CONCAT(
            c.FirstName, ' ',
            if(c.MiddleName = 'N/A' or c.MiddleName is null, '', c.MiddleName),
            ' ',
            c.LastName
        )
    ) as CustomerFullName,
    s.OrderQuantity,
    s.SalesAmount
from sales_combined s
join Product p 
    on s.ProductKey = p.ProductKey
join Customers c 
    on s.CustomerKey = c.CustomerKey;





/*  3.calcuate the following fields from the Orderdatekey field ( First Create a Date Field from Orderdatekey)
A.Year
B. Monthno
C. Monthfullname
D. Quarter(Q1,Q2,Q3,Q4)
E. YearMonth (YYYY-MMM)
F. Weekdayno
G. Weekdayname
H. FinancialMOnth
I. FinancialQuarter  */

-- Orderdatekey to OrderDate CALCULATION
select
    OrderDateKey,
    STR_TO_DATE(OrderDateKey, '%Y%m%d') as OrderDate
from sales_combined;

-- all conditions Set in one table
select
    s.OrderDateKey,
    
    STR_TO_DATE(s.OrderDateKey, '%Y%m%d') as OrderDate,
    
    Year(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) as Year,
    
    Month(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) as MonthNo,
    
    MONTHNAME(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) as MonthFullName,
    
    CONCAT('Q', Quarter(STR_TO_DATE(s.OrderDateKey, '%Y%m%d'))) as Quarter,
    
    DATE_FORMAT(STR_TO_DATE(s.OrderDateKey, '%Y%m%d'), '%Y-%b') as YearMonth,
    
    DAYOFWEEK(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) as WeekdayNo,
    
    DAYNAME(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) as WeekdayName,
    
    case
        WHEN MONTH(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) >= 4 
        THEN MONTH(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) - 3
        ELSE MONTH(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) + 9
    end as FinancialMonth,
    
    case 
        WHEN MONTH(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) BETWEEN 4 AND 6 THEN 'Q1'
        WHEN MONTH(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) BETWEEN 7 AND 9 THEN 'Q2'
        WHEN MONTH(STR_TO_DATE(s.OrderDateKey, '%Y%m%d')) BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    end as FinancialQuarter

from sales_combined s;





-- 4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
select
    UnitPrice,
    OrderQuantity,
    DiscountAmount,
    (UnitPrice * OrderQuantity * (1 - DiscountAmount)) as Total_SalesAmount
from sales_combined;




-- 5.Calculate the Productioncost uning the columns(unit cost ,order quantity)
select
    UnitPrice,
    OrderQuantity,
    (UnitPrice * OrderQuantity) as ProductionCost
from sales_combined;





-- 6.Calculate the profit.
select 
    UnitPrice,
    UnitPrice,
    OrderQuantity,
    DiscountAmount,
    
    -- sales
    (UnitPrice * OrderQuantity * (1 - DiscountAmount)) as SalesAmount,
    
    -- Cost
    (UnitPrice * OrderQuantity) as ProductionCost,
    
    -- Profit
    (UnitPrice * OrderQuantity * (1 - DiscountAmount)) 
    - (UnitPrice * OrderQuantity) as Profit

from sales_combined;



-- 12) KPI perfromances
-- i)KPI's on produce perfromance
select
p.EnglishProductName,
SUM(s.salesamount) as total_sales,
SUM(s.orderquantity) as total_quantity
from new_sales s
join product p 
on s.productkey = p.productkey
group by p.EnglishProductName
order by total_sales desc;


-- ii) KPI on customer performance
select
TRIM(
    CONCAT(
        c.FirstName,' ',
        if(c.MiddleName is null or c.MiddleName='N/A','',CONCAT(c.MiddleName,' ')),
        c.LastName
    )
) as CustomerFullName,
SUM(s.SalesAmount) as TotalSales
from sales_combined s
join Customers c
on s.CustomerKey = c.CustomerKey
group by CustomerFullName
order by TotalSales desc;


-- iii) KPI Region performance
select
t.SalesTerritoryRegion as Region,
SUM(s.SalesAmount) as TotalSales,
SUM(s.OrderQuantity) as TotalQuantity,
COUNT(distinct s.SalesOrderNumber) as TotalOrders
from sales_combined s
join Customers c
on s.CustomerKey = c.CustomerKey
join sales_territory t
on s.salesTerritoryKey = t.SalesTerritoryKey
group by t.SalesTerritoryRegion
order by TotalSales desc;