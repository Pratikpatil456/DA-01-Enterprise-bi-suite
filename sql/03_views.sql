-- 03_views.sql : flat reporting views consumed by Power BI
CREATE OR ALTER VIEW dw.vw_Sales AS
SELECT s.SalesOrderNumber, d.FullDate, d.CalendarYear, d.CalendarQuarter, d.MonthName,
       r.RegionName, r.TerritoryName, p.Category, p.Subcategory, p.ProductName,
       s.Channel, s.OrderQuantity, s.SalesAmount, s.TotalProductCost, s.GrossProfit, s.RegionKey
FROM dw.FactSales s
JOIN dw.DimDate d    ON s.OrderDateKey = d.DateKey
JOIN dw.DimProduct p ON s.ProductKey = p.ProductKey
JOIN dw.DimRegion r  ON s.RegionKey = r.RegionKey;
GO

CREATE OR ALTER VIEW dw.vw_Quota AS
SELECT q.CalendarYear, q.CalendarQuarter, r.RegionName, q.RegionKey, q.SalesQuota
FROM dw.FactSalesQuota q
JOIN dw.DimRegion r ON q.RegionKey = r.RegionKey;
GO

CREATE OR ALTER VIEW dw.vw_Employees AS
SELECT e.EmployeeKey, e.FullName, e.Title, e.DepartmentName, e.HireDate, e.IsActive,
       r.RegionName, e.RegionKey
FROM dw.DimEmployee e
LEFT JOIN dw.DimRegion r ON e.RegionKey = r.RegionKey;
GO

CREATE OR ALTER VIEW dw.vw_Inventory AS
SELECT d.FullDate, d.CalendarYear, p.Category, p.ProductName, i.UnitsBalance
FROM dw.FactInventory i
JOIN dw.DimDate d    ON i.DateKey = d.DateKey
JOIN dw.DimProduct p ON i.ProductKey = p.ProductKey;
GO

CREATE OR ALTER VIEW dw.vw_Regions AS
SELECT RegionKey, RegionName, TerritoryName, CountryName
FROM dw.DimRegion;
GO
