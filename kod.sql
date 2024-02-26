-- view všech dat s výpočtem tržby (použití slide: 3, 8, 9, 25)
CREATE VIEW RetailRevenues AS	
SELECT "Index", "InvoiceNo", "StockCode", "Description", "Quantity", 
"InvoiceDate", "UnitPrice", ("Quantity" * "UnitPrice") as "Revenue", "CustomerID", "Country"
FROM public."Retail2"

-------------------

-- celkové tržby po měsících (použití slide: 3)
select extract(year from "InvoiceDate") as "Year", 
extract(month from "InvoiceDate") as "Month", 
round(sum("Revenue"), 2) as "Revenue"
from "retailrevenues"
group by "Year", "Month"

-------------------

-- celkové tržby seskupené na Goods a ostatní speciální položky (použití slide: 4)
select case
	when upper("StockCode") in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
	then upper("StockCode")
	else 'Goods'
	end as "Group",
max(case
	when upper("StockCode") in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
	then (upper("Description"))
	else 'Goods'
	end) as "GroupDescription",
round(sum("Revenue"), 2) as "TotalRevenue"
from "retailrevenues"
group by "Group"
order by "TotalRevenue" desc

-------------------

-- tržby podle zemí, UK + prvních 20 (použití slide: 5, 7)
select "Country", round(sum("Revenue"), 2) as "Revenue"
from "retailrevenues"
group by "Country"
order by "Revenue" desc
limit 21

-------------------

-- tržby po měsích jen UK (použití slide: 6)
select extract(month from "InvoiceDate") as "Month", round(sum("Revenue"), 2) as "Revenue"
from "retailrevenues"
where "Country" = 'United Kingdom' and "InvoiceDate" <= '2011-11-30'
group by extract(month from "InvoiceDate")

select extract(month from "InvoiceDate") as "Month", round(sum("Revenue"), 2) as "Revenue"
from "retailrevenues"
where "Country" = 'United Kingdom' and "InvoiceDate" > '2011-11-30'
group by extract(month from "InvoiceDate")

-------------------

-- nejvýznamnější odběratelé (20) - tržby a ks (použití slide: 9)
select "CustomerID", round(sum("Revenue"), 2) as "Revenue", sum("Quantity") as "Quantity"
from "retailrevenues"
group by "CustomerID"
having "CustomerID" is not null
order by "Revenue" desc
limit 20

-------------------

-- nejvýznamnější odběratelé podle tržeb prvních 20 + others (použití slide: 10)
SELECT "CustomerID", round(SUM("Revenue"), 2) AS "TotalRevenuePerCustomer",
    CASE
        WHEN RANK() OVER (ORDER BY SUM("Revenue") DESC) <= 21 and "CustomerID" IS NOT NULL 
		THEN 'Best'
        ELSE 'Others'
    END AS "Category"
FROM "retailrevenues"
GROUP BY "CustomerID"
ORDER BY "TotalRevenuePerCustomer" DESC;

-------------------

-- rozdělení odběratelů do 3 kategorií o stejném počtu podle počtu nákupů a průměrné tržby 
-- (použití slide: 11, 12)
WITH CustomerCategory AS (
    SELECT "CustomerID",
        COUNT(DISTINCT "InvoiceNo") AS "CountPurchase",
        SUM("Revenue") AS "TotalRevenue",
        sum("Revenue")/COUNT(DISTINCT "InvoiceNo") AS "RevenueAVG",
        NTILE(3) OVER (ORDER BY COUNT(DISTINCT "InvoiceNo") DESC) AS "PurchaseNTile",
        NTILE(3) OVER (ORDER BY sum("Revenue")/COUNT(DISTINCT "InvoiceNo") DESC) AS "RevenueNTile"
    FROM (
        SELECT *
        FROM "retailrevenues"
        WHERE
            LOWER("InvoiceNo") NOT LIKE 'c%' and
			UPPER("StockCode") NOT IN ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
            and "CustomerID" IS NOT NULL
    )
    GROUP BY "CustomerID"
)
SELECT "CustomerID", "CountPurchase",
    CASE
        WHEN "PurchaseNTile" = 1 THEN 'Frequent'
        WHEN "PurchaseNTile" = 2 THEN 'Occasional'
        ELSE 'Infrequent'
    END AS "CategoryPurchase",
    ROUND("RevenueAVG", 2) AS "RevenueAVG",
    CASE
        WHEN "RevenueNTile" = 1 THEN 'High'
        WHEN "RevenueNTile" = 2 THEN 'Medium'
        ELSE 'Low'
    END AS "CategoryRevenue",
    ROUND("TotalRevenue", 2) AS "TotalRevenue"
FROM CustomerCategory
ORDER BY "TotalRevenue" DESC;

-------------------

-- chování zákazníků - četnost nákupů, průměrná tržba na jeden nákup, celkové tržby 
-- (použití slide: 13, 14)
select "CustomerID", count(distinct "InvoiceNo") as "CountPurchase", 
round(sum("Revenue")/count(distinct "InvoiceNo"), 2) as "RevenueAVG",
round(sum("Revenue"), 2) as "TotalRevenuePerCustomer"
from (
	select * from "retailrevenues" 
	where lower("InvoiceNo") not like 'c%' and
		  upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
)
group by "CustomerID"
having "CustomerID" is not null
order by sum("Revenue") desc
limit 20

-------------------

-- view "retailrevenues" upravený o speciální položky (použití slide: 15)
SELECT *
FROM "retailrevenues"
where upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')

-------------------

-- produkty podle tržeb od nejvyšších (použití slide: 15)
select "Description", round(sum("Revenue"), 2) as "TotalRevenuePerProduct"
from "retailrevenues"
where upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
group by "Description"
order by "TotalRevenuePerProduct" desc
limit 20

-------------------

-- view "retailrevenues" bez Revenue 0, null a speciálních položek - jen produkty
-- (použití slide: 16 - 20)
select * 
from "retailrevenues"
where "Revenue" != 0 and "Revenue" is not null and 
upper("StockCode") not in 
('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES', 'PADS')

-------------------

-- produkty podle tržeb od nejnižších (použití slide: 21)
select "StockCode", "Description", round(sum("Revenue"), 2) as "TotalRevenuePerProduct"
from "retailrevenues"
group by "StockCode", "Description"
having upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES', 'PADS')
and sum("Revenue") > 0 and sum("Revenue") < 2
order by "TotalRevenuePerProduct"

-------------------

-- produkty podle objemu stornovaných tržeb (použití slide: 22)
select "StockCode", "Description", round(SUM("Revenue"), 2) as "TotalCancelledRevenue"
from "retailrevenues"
where lower("InvoiceNo") like 'c%' and 
upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
group by "StockCode", "Description"
order by "TotalCancelledRevenue"
limit 20

-------------------

-- tržby bez speciálních položek a storno tržby (použití slide: 22)
SELECT sum("Revenue"),
case
	when lower("InvoiceNo") like 'c%' then 'Cancelled'
	else 'Revenue'
	end as "Category"
FROM "retailrevenues"
where upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
group by "Category"

-------------------

-- basket analysis - nejčastější kombinace dvou produktů (použití slide: 23, 24)
WITH "Basket" AS (
    SELECT "InvoiceNo", "StockCode", "Description", "Revenue"
    FROM "retailrevenues"
	where upper("StockCode") not in ('POST', 'DOT', 'AMAZONFEE', 'M', 'S', 'D', 'CRUK', 'B', 'BANK CHARGES')
	and "Revenue" > 0
)
SELECT A."StockCode" as "Product1Code", A."Description" as "Product1Desc",
B."StockCode" as "Product2Code", B."Description" as "Product2Desc", 
COUNT(*) AS "Occurrences"
FROM "Basket" A
JOIN "Basket" B 
ON A."InvoiceNo" = B."InvoiceNo" AND A."StockCode" < B."StockCode"
GROUP BY A."StockCode", A."Description", B."StockCode", B."Description"
ORDER BY "Occurrences" DESC
limit 20

-------------------







