-- 01_schema.sql : creates schemas and warehouse tables (SQL Server)
IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
IF SCHEMA_ID('dw') IS NULL EXEC('CREATE SCHEMA dw');
GO

DROP TABLE IF EXISTS dw.FactSales;
DROP TABLE IF EXISTS dw.FactSalesQuota;
DROP TABLE IF EXISTS dw.FactInventory;
DROP TABLE IF EXISTS dw.UserRegionAccess;
DROP TABLE IF EXISTS dw.DimEmployee;
DROP TABLE IF EXISTS dw.DimCustomer;
DROP TABLE IF EXISTS dw.DimProduct;
DROP TABLE IF EXISTS dw.DimDate;
DROP TABLE IF EXISTS dw.DimRegion;
GO

CREATE TABLE dw.DimRegion (
    RegionKey      INT           NOT NULL PRIMARY KEY,
    RegionName     NVARCHAR(50)  NOT NULL,   -- North America, Europe, Pacific
    TerritoryName  NVARCHAR(50)  NOT NULL,
    CountryName    NVARCHAR(50)  NULL
);

CREATE TABLE dw.DimDate (
    DateKey         INT          NOT NULL PRIMARY KEY,  -- yyyymmdd
    FullDate        DATE         NOT NULL,
    CalendarYear    SMALLINT     NOT NULL,
    CalendarQuarter TINYINT      NOT NULL,
    MonthNumber     TINYINT      NOT NULL,
    MonthName       NVARCHAR(20) NOT NULL,
    DayOfMonth      TINYINT      NOT NULL
);

CREATE TABLE dw.DimProduct (
    ProductKey   INT           NOT NULL PRIMARY KEY,
    ProductName  NVARCHAR(100) NOT NULL,
    Category     NVARCHAR(50)  NULL,
    Subcategory  NVARCHAR(50)  NULL,
    StandardCost DECIMAL(19,4) NULL,
    ListPrice    DECIMAL(19,4) NULL
);

CREATE TABLE dw.DimCustomer (
    CustomerKey INT           NOT NULL PRIMARY KEY,
    FullName    NVARCHAR(150) NULL,
    RegionKey   INT           NULL REFERENCES dw.DimRegion(RegionKey)
);

CREATE TABLE dw.DimEmployee (
    EmployeeKey    INT           NOT NULL PRIMARY KEY,
    FullName       NVARCHAR(150) NOT NULL,
    Title          NVARCHAR(100) NULL,
    DepartmentName NVARCHAR(50)  NULL,
    HireDate       DATE          NULL,
    IsActive       BIT           NOT NULL,
    RegionKey      INT           NULL REFERENCES dw.DimRegion(RegionKey)
);

CREATE TABLE dw.FactSales (
    SalesKey         BIGINT        NOT NULL IDENTITY(1,1) PRIMARY KEY,
    OrderDateKey     INT           NOT NULL REFERENCES dw.DimDate(DateKey),
    ProductKey       INT           NOT NULL REFERENCES dw.DimProduct(ProductKey),
    CustomerKey      INT           NULL REFERENCES dw.DimCustomer(CustomerKey),
    RegionKey        INT           NOT NULL REFERENCES dw.DimRegion(RegionKey),
    Channel          NVARCHAR(20)  NOT NULL,   -- Internet / Reseller
    SalesOrderNumber NVARCHAR(25)  NOT NULL,
    OrderQuantity    INT           NOT NULL,
    SalesAmount      DECIMAL(19,4) NOT NULL,
    TotalProductCost DECIMAL(19,4) NOT NULL,
    GrossProfit AS (SalesAmount - TotalProductCost) PERSISTED
);

CREATE TABLE dw.FactSalesQuota (
    QuotaKey        INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    CalendarYear    SMALLINT      NOT NULL,
    CalendarQuarter TINYINT       NOT NULL,
    RegionKey       INT           NOT NULL REFERENCES dw.DimRegion(RegionKey),
    EmployeeKey     INT           NULL REFERENCES dw.DimEmployee(EmployeeKey),
    SalesQuota      DECIMAL(19,4) NOT NULL
);

CREATE TABLE dw.FactInventory (
    InventoryKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey      INT    NOT NULL REFERENCES dw.DimDate(DateKey),
    ProductKey   INT    NOT NULL REFERENCES dw.DimProduct(ProductKey),
    UnitsBalance INT    NOT NULL
);

CREATE TABLE dw.UserRegionAccess (
    UserEmail NVARCHAR(256) NOT NULL,
    RegionKey INT           NOT NULL REFERENCES dw.DimRegion(RegionKey),
    PRIMARY KEY (UserEmail, RegionKey)
);
GO
