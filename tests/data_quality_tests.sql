-- Each check returns PASS or FAIL. All should be PASS after a load.

-- 1. Sales amount reconciles to source (internet + reseller)
SELECT CASE WHEN ABS(
         (SELECT SUM(SalesAmount) FROM dw.FactSales)
       - (SELECT SUM(SalesAmount) FROM AdventureWorksDW2022.dbo.FactInternetSales f
           WHERE f.OrderDateKey IN (SELECT DateKey FROM dw.DimDate))
       - (SELECT SUM(SalesAmount) FROM AdventureWorksDW2022.dbo.FactResellerSales f
           WHERE f.OrderDateKey IN (SELECT DateKey FROM dw.DimDate))) < 0.01
       THEN 'PASS' ELSE 'FAIL' END AS Check_SalesReconciles;

-- 2. Row count matches the filtered source
SELECT CASE WHEN (SELECT COUNT(*) FROM dw.FactSales)
       = (SELECT COUNT(*) FROM AdventureWorksDW2022.dbo.FactInternetSales f
           WHERE f.OrderDateKey IN (SELECT DateKey FROM dw.DimDate))
       + (SELECT COUNT(*) FROM AdventureWorksDW2022.dbo.FactResellerSales f
           WHERE f.OrderDateKey IN (SELECT DateKey FROM dw.DimDate))
       THEN 'PASS' ELSE 'FAIL' END AS Check_RowCount;

-- 3. No sales rows without a matching product
SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Check_NoOrphanProducts
FROM dw.FactSales s LEFT JOIN dw.DimProduct p ON s.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL;

-- 4. Every sales row maps to a region
SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Check_AllRowsHaveRegion
FROM dw.FactSales s LEFT JOIN dw.DimRegion r ON s.RegionKey = r.RegionKey
WHERE r.RegionKey IS NULL;

-- 5. No negative gross profit in the sample data
SELECT CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Check_GrossProfitNonNegative
FROM dw.FactSales WHERE GrossProfit < 0;

-- 6. RLS mapping covers all three regions
SELECT CASE WHEN COUNT(DISTINCT r.RegionName) = 3 THEN 'PASS' ELSE 'FAIL' END AS Check_RLSCoverage
FROM dw.UserRegionAccess u JOIN dw.DimRegion r ON u.RegionKey = r.RegionKey;
