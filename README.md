# Enterprise Business Intelligence Suite (DA-01)

A multi-region business intelligence system. It combines sales, finance (sales quota), HR and supply (inventory) data into one Power BI model with row-level security, so each regional manager sees only their own region.

## Architecture

```
AdventureWorksDW2022 (SQL Server source)
        |
        |  ADF pipeline or SQL Server Agent job (runs dw.usp_load_all)
        v
dw schema: star schema (BIWarehouse)
        |
        |  Import
        v
Power BI model: DAX measures and row-level security
        |
        v
Report pages: Page 1 overview, Page 2 regional detail
```

### Star schema (`dw` schema)

| Type | Tables |
|---|---|
| Fact tables | `FactSales`, `FactSalesQuota`, `FactInventory` |
| Dimension tables | `DimDate`, `DimRegion`, `DimProduct`, `DimCustomer`, `DimEmployee` |
| Security | `dw.UserRegionAccess` maps user emails to region keys for row-level security |

### Regions

| Region | Territories |
|---|---|
| North America | Northwest, Northeast, Southwest, Central, Canada |
| Europe | France, Germany, United Kingdom |
| Pacific | Australia |

## Repository layout

| Path | Purpose |
|---|---|
| `sql/01_schema.sql` | Creates the `staging` and `dw` schemas and all tables |
| `sql/02_load.sql` | Creates `dw.usp_load_all`, which loads the warehouse from AdventureWorksDW2022 |
| `sql/03_views.sql` | Reporting views used by Power BI |
| `adf/pipeline_daily_load.json` | ADF pipeline that runs `dw.usp_load_all` (written, not yet run) |
| `powerbi/dax_measures.dax` | DAX measures for sales, quota, HR and supply |
| `powerbi/rls_roles.md` | Row-level security role and test accounts |
| `powerbi/USER_GUIDE.md` | One-page user guide |
| `tests/data_quality_tests.sql` | Six reconciliation and integrity checks |
| `docs/test_plan.md` | Test cases, results and notes |
| `docs/data_dictionary.md` | Table and column reference |
| `docs/demo_link.txt` | Location of the demo recording |

## Setup

1. Restore `AdventureWorksDW2022` on SQL Server, using Microsoft's sample databases page.
2. Create a database named `BIWarehouse`, then run these scripts against it, in order:
   1. `sql/01_schema.sql`
   2. `sql/02_load.sql`
   3. `sql/03_views.sql`
3. Run `tests/data_quality_tests.sql`. All checks should return PASS except `Check_GrossProfitNonNegative`, which is an expected FAIL (see the test plan, note A).
4. To load on a schedule, import `adf/pipeline_daily_load.json` into Azure Data Factory with a linked service to SQL Server. If Azure is not available, schedule `EXEC dw.usp_load_all` with SQL Server Agent instead.
5. In Power BI Desktop, connect to `localhost\SQLEXPRESS`, database `BIWarehouse`, and import the `dw` tables. Paste the measures from `powerbi/dax_measures.dax`, and create the role described in `powerbi/rls_roles.md`.
6. Publishing to Power BI Service and a scheduled refresh are next steps and have not been completed.

## Deliverables

| Item | Status |
|---|---|
| Working demo (screen recording) | Done: `enterprise-bi-suite 2026-10-30 02-08-54.mp4`, listed in `docs/demo_link.txt` |
| Repository structure, README and setup steps | Done (this file) |
| Architecture diagram and data documentation | Done (above and `docs/data_dictionary.md`) |
| Test results and performance notes | Done (`docs/test_plan.md`) |
| 10-minute final presentation | Done (`DA-01_presentation_draft.pptx`) |
| Individual reflection | Done (`Individual reflection.txt`) |
| Publish to Power BI Service | Not done (requires a work or school account) |
