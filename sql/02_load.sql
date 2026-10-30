-- 02_load_FIXED.sql : full refresh of dw from AdventureWorksDW2022 (same SQL Server instance).
-- Replace sql/02_load.sql with this file. Do NOT use older saved query tabs.
CREATE OR ALTER PROCEDURE dw.usp_load_all
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DELETE FROM dw.UserRegionAccess;
        DELETE FROM dw.FactInventory;
        DELETE FROM dw.FactSalesQuota;
        DELETE FROM dw.FactSales;
        DELETE FROM dw.DimEmployee;
        DELETE FROM dw.DimCustomer;
        DELETE FROM dw.DimProduct;
        DELETE FROM dw.DimDate;
        DELETE FROM dw.DimRegion;

        -- Territories in the three business regions
        INSERT INTO dw.DimRegion (RegionKey, RegionName, TerritoryName, CountryName)
        SELECT t.SalesTerritoryKey,
               t.SalesTerritoryGroup,
               t.SalesTerritoryRegion,
               t.SalesTerritoryCountry
        FROM AdventureWorksDW2022.dbo.DimSalesTerritory t
        WHERE t.SalesTerritoryGroup IN ('North America', 'Europe', 'Pacific');

        INSERT INTO dw.DimDate (DateKey, FullDate, CalendarYear, CalendarQuarter, MonthNumber, MonthName, DayOfMonth)
        SELECT DateKey, FullDateAlternateKey, CalendarYear, CalendarQuarter,
               MonthNumberOfYear, EnglishMonthName, DayNumberOfMonth
        FROM AdventureWorksDW2022.dbo.DimDate
        WHERE CalendarYear BETWEEN 2011 AND 2014;

        INSERT INTO dw.DimProduct (ProductKey, ProductName, Category, Subcategory, StandardCost, ListPrice)
        SELECT p.ProductKey, p.EnglishProductName, c.EnglishProductCategoryName,
               s.EnglishProductSubcategoryName, p.StandardCost, p.ListPrice
        FROM AdventureWorksDW2022.dbo.DimProduct p
        LEFT JOIN AdventureWorksDW2022.dbo.DimProductSubcategory s ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
        LEFT JOIN AdventureWorksDW2022.dbo.DimProductCategory c ON s.ProductCategoryKey = c.ProductCategoryKey;

        INSERT INTO dw.DimCustomer (CustomerKey, FullName, RegionKey)
        SELECT c.CustomerKey, CONCAT(c.FirstName, ' ', c.LastName), g.SalesTerritoryKey
        FROM AdventureWorksDW2022.dbo.DimCustomer c
        LEFT JOIN AdventureWorksDW2022.dbo.DimGeography g ON c.GeographyKey = g.GeographyKey
        WHERE g.SalesTerritoryKey IN (SELECT RegionKey FROM dw.DimRegion)
           OR g.SalesTerritoryKey IS NULL;

        -- Each employee's region = the territory where they make most reseller sales
        SELECT e.EmployeeKey, x.SalesTerritoryKey AS RegionKey
        INTO #EmployeeRegion
        FROM AdventureWorksDW2022.dbo.DimEmployee e
        CROSS APPLY (
            SELECT TOP 1 f.SalesTerritoryKey
            FROM AdventureWorksDW2022.dbo.FactResellerSales f
            WHERE f.EmployeeKey = e.EmployeeKey
            GROUP BY f.SalesTerritoryKey
            ORDER BY COUNT(*) DESC
        ) x;

        INSERT INTO dw.DimEmployee (EmployeeKey, FullName, Title, DepartmentName, HireDate, IsActive, RegionKey)
        SELECT e.EmployeeKey, CONCAT(e.FirstName, ' ', e.LastName), e.Title, e.DepartmentName,
               e.HireDate,
               CASE WHEN e.Status = 'Current' THEN 1 ELSE 0 END,
               er.RegionKey
        FROM AdventureWorksDW2022.dbo.DimEmployee e
        LEFT JOIN #EmployeeRegion er ON er.EmployeeKey = e.EmployeeKey
        WHERE er.RegionKey IN (SELECT RegionKey FROM dw.DimRegion)
           OR er.RegionKey IS NULL;

        -- Sales: internet and reseller channels combined, in-region territories only
        INSERT INTO dw.FactSales (OrderDateKey, ProductKey, CustomerKey, RegionKey, Channel,
                                  SalesOrderNumber, OrderQuantity, SalesAmount, TotalProductCost)
        SELECT f.OrderDateKey, f.ProductKey, f.CustomerKey, f.SalesTerritoryKey, 'Internet',
               f.SalesOrderNumber, f.OrderQuantity, f.SalesAmount, f.TotalProductCost
        FROM AdventureWorksDW2022.dbo.FactInternetSales f
        WHERE f.OrderDateKey IN (SELECT DateKey FROM dw.DimDate)
          AND f.SalesTerritoryKey IN (SELECT RegionKey FROM dw.DimRegion)
        UNION ALL
        SELECT f.OrderDateKey, f.ProductKey, NULL, f.SalesTerritoryKey, 'Reseller',
               f.SalesOrderNumber, f.OrderQuantity, f.SalesAmount, f.TotalProductCost
        FROM AdventureWorksDW2022.dbo.FactResellerSales f
        WHERE f.OrderDateKey IN (SELECT DateKey FROM dw.DimDate)
          AND f.SalesTerritoryKey IN (SELECT RegionKey FROM dw.DimRegion);

        -- Quota: yearly quota per employee, assigned to the employee's region
        INSERT INTO dw.FactSalesQuota (CalendarYear, CalendarQuarter, RegionKey, EmployeeKey, SalesQuota)
        SELECT q.CalendarYear, q.CalendarQuarter, er.RegionKey, q.EmployeeKey, SUM(q.SalesAmountQuota)
        FROM AdventureWorksDW2022.dbo.FactSalesQuota q
        JOIN #EmployeeRegion er ON er.EmployeeKey = q.EmployeeKey
        JOIN dw.DimEmployee e ON e.EmployeeKey = q.EmployeeKey
        GROUP BY q.CalendarYear, q.CalendarQuarter, er.RegionKey, q.EmployeeKey;

        -- Inventory balance by product and date
        INSERT INTO dw.FactInventory (DateKey, ProductKey, UnitsBalance)
        SELECT i.DateKey, i.ProductKey, i.UnitsBalance
        FROM AdventureWorksDW2022.dbo.FactProductInventory i
        WHERE i.DateKey IN (SELECT DateKey FROM dw.DimDate);

        DROP TABLE #EmployeeRegion;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

EXEC dw.usp_load_all;
GO

-- Row-level security mapping: each test account gets every territory in its region
INSERT INTO dw.UserRegionAccess (UserEmail, RegionKey)
SELECT v.Email, r.RegionKey
FROM (VALUES
    ('na.manager@contoso-demo.com', 'North America'),
    ('eu.manager@contoso-demo.com', 'Europe'),
    ('apac.manager@contoso-demo.com', 'Pacific')
) AS v(Email, Region)
JOIN dw.DimRegion r ON r.RegionName = v.Region;
GO
GO