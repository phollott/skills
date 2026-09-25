# BIP to SSRS Conversion

There is no Microsoft-provided one-click conversion from Oracle BI Publisher (BIP) to SSRS/Power BI Paginated Reports, but there are well-established migration patterns that many organizations follow. Templates are likely Excel-based, not necessarily RTF., so we should focus on XDO inspection and Excel-template handling.

## Typical Conversion Mapping

| BI Publisher | SSRS / Power BI Paginated | ✅ |
|--------------|---------------------------|-----|
| Data Model | Dataset | ✅ |
| SQL Query | Dataset Query | ✅ |
| Parameters | Report Parameters | ❌ |
| RTF Template | Report Layout (RDL) | |
| XML Data Source | Dataset Results | ✅ |
| Bursting | SSRS Subscriptions / Custom Distribution | |
| Conditional Formatting | Expressions | ✅ |
| Groups and Repeating Sections | Tablix Groups | ✅ |
| Charts | SSRS Charts | ❌ |

## Typical Migration Process

1. Inventory Reports

For each report, document: Report name, Business owner, Data sources, Parameters, Scheduling requirements, Bursting/distribution rules, Usage frequency

Most migration projects discover that 20-40% of reports are obsolete and don't need converting.

2. Extract the BI Publisher SQL

The most important asset is usually the SQL.

In BI Publisher:

Report
 └── Data Model
      └── SQL Query

Retrieve: SQL, Stored procedure calls, Parameters, LOV (List of Values) definitions

3. Create SSRS Data Sources

Map:

Oracle Database
    ↓
SSRS Shared Data Source

Typically via: Oracle ODP.NET, OLE DB, ODBC

4. Rebuild Datasets

Create SSRS datasets using the extracted SQL:

```sql
SELECT *
FROM EMPLOYEE
WHERE DEPARTMENT = :P_DEPT
```

becomes

```sql
SELECT *
FROM EMPLOYEE
WHERE DEPARTMENT = @P_DEPT
```

The largest query change is usually: Oracle parameter syntax (:param) to SSRS parameter syntax (@param)

5. Rebuild Layout

This is the labor-intensive step.

BI Publisher RTF templates: for-each, if, choose, group

must be recreated in: Tablix controls, Groups, Expressions, Headers/footers

There is generally no reliable automated conversion of RTF templates into RDL layouts (although we may be able to reverse engineer this out of the XSL:FO).

6. Convert Parameters

With default values and available values recreated.

7. Validate Output

Compare: Row counts, Totals, Pagination, PDF output, Parameter behavior

Most conversion effort is testing rather than development.

## Common Challenges

### Multiple Template Types

Inspect .xdo file and extract: template name, template type, locale, parameter definitions, data model references. For example:

```xml
<template name="Default"
          location="pli010_en.xls"
          type="xls"/>
```

or

```xml
<layout templateFile="pli010_en.xls"/>
```

For .xls templates, Apache POI might be useful, as a way of converting Excel into a JSON or XML representation. SSRS generation needs to understand the report layout, and POI already exposes the workbook as rows, cells, styles, merged regions, and formulas. That's almost exactly the abstraction level you want. A low-level .xls parser would force you to rebuild that model yourself before you could even start converting the report.

Converting .xls to .xslx is also an option, although Excel XML can be messy to work with. Apache POI Is one way to do this. LibreOffice may help, and opening in Excel and saving as XLSX is also an option. Using Tika to convert .xls into .xhtml may also be a useful approach, for really simple reports.

Excel Template to Report Model (XHTML?); Report Model to SSRS.

### Oracle-Specific SQL

BI Publisher reports often contain:

DECODE(...)
NVL(...)
CONNECT BY

These work fine if the SSRS report still queries Oracle.

If you're moving to SQL Server, they must be rewritten:

| Oracle | SQL Server |
|--------|------------|
| NVL(x,y) | ISNULL(x,y) or COALESCE(x,y) |

### Bursting

BI Publisher bursting:

One report
→ Many recipients
→ Different parameter values

is often replaced by: SSRS subscriptions, Data-driven subscriptions, Power Automate flows, Custom scheduling

### Complex Templates

Very sophisticated RTF documents with nested loops, dynamic sections, repeating tables can require significant redesign in SSRS.

## Are There Conversion Tools?

Some consultancies and organizations have built proprietary tools, and there are occasional open-source attempts, but in practice:

The industry standard approach is: Extract metadata, Reuse SQL, Rebuild the RDL layout, Test and validate.

Most successful migrations are semi-automated analysis + manual report redevelopment, not full automated conversion.

Realistic automation targets are:

✅ Extract report parameters
✅ Extract SQL/data models
✅ Generate SSRS datasets
✅ Generate basic RDL structure

The part that usually still needs manual work is:

❌ RTF layout fidelity
❌ Complex conditional formatting
❌ Bursting logic
❌ Advanced pagination behavior

In real-world projects, about 60-80% of the effort is recreating and validating the report layout, while the data layer conversion is often much more straightforward.
