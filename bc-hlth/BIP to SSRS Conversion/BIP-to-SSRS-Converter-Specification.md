# Oracle BI Publisher to SSRS Conversion Utility

## Specification Document

**Version:** 1.18  
**Date:** March 5, 2026  
**Status:** Release Candidate

---

## Table of Contents

1. [Introduction](#introduction)
   - [Continuous Service Improvements](#continuous-service-improvements)
   - [Editorial Notes](#editorial-notes)
2. [Quick Start](#quick-start)
3. [Objectives](#objectives)
4. [Scope](#scope)
5. [Background](#background)
   - [XDM Data Model as the Source of Truth](#xdm-data-model-as-the-source-of-truth)
   - [BIP vs SSRS Data Model Architecture](#bip-vs-ssrs-data-model-architecture)
   - [Design Constraint: No Hardcoded Element Names](#design-constraint-no-hardcoded-element-names)
6. [System Requirements](#system-requirements)
7. [Architecture Overview](#architecture-overview)
8. [Technical Implementation Options](#technical-implementation-options)
9. [Preferred Solution: Unified eXist-db + SSRS Platform](#preferred-solution-unified-exist-db--ssrs-platform)
10. [Conversion Mapping](#conversion-mapping)
11. [Data Source Handling](#data-source-handling)
12. [Template Conversion](#template-conversion)
13. [Output Formats](#output-formats)
14. [Error Handling](#error-handling)
15. [Limitations](#limitations)
    - [Design Constraints](#design-constraints)
16. [Implementation Phases](#implementation-phases)
17. [Testing Strategy](#testing-strategy)
18. [SSRS Output Testing](#ssrs-output-testing)
19. [Appendix](#appendix)
   - [E. eXist-db Administration](#e-exist-db-administration)
   - [F. Project Maintenance](#f-project-maintenance)
   - [G. SQL Server Connectivity (JDBC Driver Setup)](#g-sql-server-connectivity-jdbc-driver-setup)
   - [H. XSLT Transformation Rules](#appendix-h-xslt-transformation-rules)
   - [I. Standalone XSLT Packaging Feasibility](#appendix-i-standalone-xslt-packaging-feasibility)
20. [Release Readiness Assessment](#release-readiness-assessment)
21. [Document History](#document-history)

---

## Introduction

This document specifies the requirements and design for a utility that converts Oracle Business Intelligence (BI) Publisher reports to SQL Server Reporting Services (SSRS) format. The utility aims to automate the migration process, reducing manual effort and ensuring consistency in report translation.

### Purpose

Organizations transitioning from Oracle BI Publisher to Microsoft SQL Server Reporting Services require a systematic approach to migrate existing reports. This utility provides an automated conversion pipeline that transforms BI Publisher report definitions, data models, and templates into equivalent SSRS Report Definition Language (RDL) files.

### Audience

- Solution Architects
- Report Developers
- Database Administrators
- Migration Project Teams

### Continuous Service Improvements

Tools like this BIP-to-SSRS conversion utility represent a strategic approach to **Continuous Service Improvement (CSI)**. Rather than treating every technology transition as a large-scale transformation initiative, organizations can achieve meaningful modernization through targeted, AI-assisted tooling.

**Why this matters:**

- **Preserving budget for larger changes** — By handling routine migrations cost-effectively, organizations retain financial capacity for genuinely transformational initiatives where full investment is warranted.
- **Keeping existing configurations moving forward** — Legacy systems and reports don't have to become technical debt. Incremental tooling keeps them viable while the organization evolves.
- **Smart, non-transformational ROI** — Many high-value changes will not produce sufficient return on investment if approached as enterprise transformation projects. A pragmatic, tool-assisted approach delivers value without the overhead.
- **AI-assisted development economics** — There is a crossover point where building a conversion tool by hand is more time-consuming than converting reports manually. However, building the tool *with* AI code generation support shifts that equation favorably, making automation viable for smaller portfolios.

**Other examples of CSI in practice:**

- **Well-planned configuration changes** — Instead of complete overhaul and replacement of key components, a well-architected and understood configuration change can achieve the same business outcome with far less risk and cost. This requires solid understanding of the existing system, but avoids the hidden costs of wholesale replacement.
- **Reducing integrated components** — Thoughtful improvements can consolidate or eliminate integration points. Fewer moving parts means fewer failure modes, simpler testing, and reduced cognitive load for operations teams.
- **Reducing operational overhead** — Configuration-level changes that improve manageability, observability, or automation reduce the ongoing cost of running a system—often more sustainably than replacing it with something new that introduces its own operational learning curve.

This project exemplifies that philosophy: a focused utility, developed with AI assistance, that enables modernization without requiring organizational transformation.

### Challenges and Observations

- **Backups** — Ask Claude to do a backup and Claude deletes all previous backups, not sure why.
- **Optional Features** — Claude routinely tells me that features that are not coming together smoothly are "optional", not sure why.
- **Architectural Insights** — I have contributed the overall architecture, Claude has done a lot of heavy lifting with DevOps, XSL wrangling, generating data. Using the official image of ExistDB was problematic because of the need to do JDBC, which is absent, so we switched to a development image, which worked and then it didn't so we ended up switching back, and the official image worked after some modification.
- **Roles** — Single role, single agent, no need to use extra prompt engineering, and using Copilot, so no /skills, no MCP, but still quite effective. Very low barrier to entry.
- **Declarative Coding** — This may be important? Really nice work with XSL and XQuery, which was surprising. Claude Opus does appear better.
- **ROI** — For a conversion tool, there may be a crossover point where building a tool by hand is more time consuming than converting reports by hand, but building the tool with CodeGen support is less time consuming.
- **Hard-Coding** — By default, Claude really wants to hard-code to find a solution.
- **Design pushes** — These have value because context is not guaranteed.

---

## Quick Start

### Prerequisites

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **VS Code** with recommended extensions (optional, for development)
- **PowerShell** 5.1+ or **bash**

### Startup Instructions

```powershell
# 1. Navigate to project directory
cd c:\workspace\pbcs-hibc\Sideswipe

# 2. Create environment file from template
Copy-Item .env.example .env

# 3. Start the containers
docker compose up -d

# 4. Verify containers are running
docker compose ps

# 5. Wait for services to be healthy (30-60 seconds)
docker compose logs -f existdb
# Press Ctrl+C when you see "Server has started"

# 6. Deploy application to eXist-db (first time only)
.\scripts\setup-existdb.ps1

# 7. Access eXist-db Dashboard
Start-Process "http://localhost:8088/exist/apps/dashboard/"
```

### Verify Installation

```powershell
# Check eXist-db REST API is responding
Invoke-RestMethod -Uri "http://localhost:8088/exist/rest/db" -Method GET

# Check application is deployed
Invoke-RestMethod -Uri "http://localhost:8088/exist/rest/db/apps/bip2ssrs/modules/config.xqm"

# Check SQL Server is running
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong!Passw0rd" -Q "SELECT @@VERSION" -C
```

### Service Endpoints

| Service | URL | Purpose |
|---------|-----|---------|
| eXist-db Dashboard | http://localhost:8088/exist/apps/dashboard/ | Admin UI |
| **BIP2SSRS Web UI** | http://localhost:8088/exist/apps/bip2ssrs/ | **Converter Web Interface** |
| REST API | http://localhost:8088/exist/rest/db/apps/bip2ssrs/ | REST interface |
| Upload API | http://localhost:8088/exist/apps/bip2ssrs/api/upload.xql | Upload BIP files |
| Convert API | http://localhost:8088/exist/apps/bip2ssrs/api/convert-stored.xql?report=NAME | Convert uploaded reports |
| List Reports | http://localhost:8088/exist/apps/bip2ssrs/api/list-reports.xql | List available reports |
| Clear All | http://localhost:8088/exist/apps/bip2ssrs/api/clear-all.xql | Clear input/output collections |
| SQL Server | localhost:1433 | SSRS database backend |

### eXist-db Authentication

eXist-db generates a random admin password on first startup. The setup scripts automatically detect this password from Docker logs.

**How it works:**
1. On first startup, eXist-db logs: `setting password to <random-password>`
2. The `setup-existdb.ps1` and `sync-to-existdb.ps1` scripts parse this from Docker logs
3. No manual password configuration is needed

**Manual password retrieval (if needed):**
```powershell
# Extract the auto-generated password from container logs
docker logs bip2ssrs-existdb 2>&1 | Select-String "setting password to"
```

**Using scripts with explicit password:**
```powershell
# Override auto-detection with explicit password
.\scripts\setup-existdb.ps1 -Password "your-password"
.\scripts\sync-to-existdb.ps1 -Password "your-password"
```

> **Note:** The web UI at `/exist/apps/bip2ssrs/` does not require authentication for most operations. The browser will prompt for credentials only when accessing protected paths like `/db/apps/`.

### Converting BIP Files to SSRS

#### Method 1: Web Interface (Recommended)

The easiest way to convert BIP files is via the web interface at:

**http://localhost:8088/exist/apps/bip2ssrs/**

**Features:**
- **Bulk Upload** - Drag & drop multiple files at once; files are automatically grouped by report name
- **Auto-grouping** - Files like `invoice.xsl-fo`, `invoice.xdm`, and `invoice-data.xml` are grouped as "invoice"
- **Convert All** - One-click conversion of all uploaded reports
- **Download** - Click any converted RDL filename to download it
- **Clear All** - Red button to reset all uploaded files and converted output
- **Re-upload Support** - Uploading new files automatically clears stale output

#### Method 2: PowerShell Script

```powershell
# Convert a single template
.\scripts\convert-bip.ps1 -InputFile input\your-template.xsl-fo

# Specify output location
.\scripts\convert-bip.ps1 -InputFile input\your-template.xsl-fo -OutputFile output\my-report.rdl

# Batch convert all templates
Get-ChildItem input -Filter "*.xsl-fo" | ForEach-Object {
    .\scripts\convert-bip.ps1 -InputFile $_.FullName
}
```

#### Method 3: REST API

```powershell
# Get the auto-generated password from Docker logs
$logOutput = docker logs bip2ssrs-existdb 2>&1 | Select-String "setting password to" | Select-Object -Last 1
$password = if ($logOutput -match "setting password to (\S+)") { $Matches[1] } else { "" }
$auth = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$password"))

# Convert a stored report (after uploading via web UI or upload.xql)
Invoke-WebRequest -Uri "http://localhost:8088/exist/apps/bip2ssrs/api/convert-stored.xql?report=invoice" `
    -Headers @{Authorization=$auth}

# Fetch stored RDL via REST
Invoke-WebRequest -Uri "http://localhost:8088/exist/rest/db/apps/bip2ssrs/output/invoice/invoice.rdl" `
    -Headers @{Authorization=$auth} -OutFile "my-report.rdl"

# List all available reports
Invoke-WebRequest -Uri "http://localhost:8088/exist/apps/bip2ssrs/api/list-reports.xql" `
    -Headers @{Authorization=$auth}
```

#### Method 4: Deploy Directly to SSRS

```powershell
# Deploy RDL from eXist-db to SSRS Report Server
.\scripts\deploy-to-ssrs.ps1 -ReportName sample-invoice -SsrsUrl "http://your-ssrs-server/ReportServer"
```

#### Method 5: Standalone Command-Line (No Docker)

For environments where Docker is unavailable, use the standalone XSLT converter with Saxon-HE.

**Prerequisites:**
- Java 11+ (JDK or JRE)
- Apache Ant 1.10+ (optional)

**Folder Structure:**
```
standalone/
├── build.xml           # Ant build script
├── convert-folder.ps1  # PowerShell batch script
├── convert-folder.sh   # Bash batch script
├── README.md           # Usage documentation
├── lib/
│   └── saxon-he-10.9.jar   # XSLT 2.0 processor (~5.5 MB)
└── xslt/
    └── bip-to-rdl.xsl      # Transformation stylesheet
```

**XSLT Parameters:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `xdm-uri` | Path to XDM data model file (extracts SQL query and parameters) | (none) |
| `connection-string` | SSRS connection string | Placeholder |
| `data-source-name` | DataSource name in RDL | DataSource1 |
| `data-provider` | Data provider type | SQL |
| `mode` | `preview` (SELECT * FROM table) or `production` (XDM SQL with param conversion) | preview |
| `preview-table-name` | Table name for preview mode | SampleData |

**Option A: Direct Java Command (No Ant Required)**

```powershell
# PREVIEW MODE (default): SELECT * FROM table - for testing with sample data
java -jar standalone\lib\saxon-he-10.9.jar `
    -s:input\invoice.xsl-fo `
    -xsl:standalone\xslt\bip-to-rdl.xsl `
    -o:output\invoice-preview.rdl `
    xdm-uri=input\invoice.xdm `
    mode=preview `
    preview-table-name=INVOICE_DATA

# PRODUCTION MODE: Use XDM SQL with :P_NAME → @P_NAME conversion
java -jar standalone\lib\saxon-he-10.9.jar `
    -s:input\invoice.xsl-fo `
    -xsl:standalone\xslt\bip-to-rdl.xsl `
    -o:output\invoice-production.rdl `
    xdm-uri=input\invoice.xdm `
    mode=production `
    connection-string="Data Source=sqlserver;Initial Catalog=ReportDB;Integrated Security=True"
```

**Option B: Folder Conversion Scripts**

```powershell
# PowerShell (Windows)
cd standalone
.\convert-folder.ps1 -InputFolder ..\input\tested -OutputFolder ..\output -ConnectionString "Data Source=server;Initial Catalog=DB;Integrated Security=True"
```

```bash
# Bash (Linux/macOS)
cd standalone
chmod +x convert-folder.sh
./convert-folder.sh ../input/tested ../output "Data Source=server;Initial Catalog=DB;Integrated Security=True"
```

**Option C: Using Ant Build Script**

```bash
cd standalone

# Download Saxon-HE (first time only)
ant download-saxon

# Convert all .xsl-fo files in input/
ant convert-all

# Convert a single file with connection string
ant convert -Dfile=invoice -Dconnection-string="Data Source=server;Initial Catalog=DB;Integrated Security=True"

# Convert with custom input/output folders
ant convert-all -Dinput.dir=C:/reports/bip -Doutput.dir=C:/reports/ssrs

# List available files
ant list

# Show help
ant help
```

**Notes:**
- Saxon-HE 10.9 is used because it's self-contained (11.x+ requires xmlresolver dependency)
- The XSLT uses pure XSLT 2.0 features — no XQuery or eXist-db extensions
- **SQL extraction:** When `xdm-uri` is provided, the XSLT extracts the SQL query from the XDM `<sql>` element
- **Single-file XSLT:** The `bip-to-rdl.xsl` is self-contained (~2400 lines) with no `xsl:import` or `xsl:include`
- Unlike the web app, standalone does **not** require test data files — connection string is passed via parameter

### Sample Reports (Synthetic)

These synthetic BIP templates were created for testing the converter. Real production reports may have different structures and complexity levels.

| Report | Description | Conversion Status | Notes |
|--------|-------------|-------------------|-------|
| `customer-dashboard` | Dashboard with KPIs, charts, percentage-width tables | ✅ Converts | Percentages auto-converted to inches |
| `employee-list` | Simple tabular list with alternating row colors | ✅ Converts | Basic table structure |
| `financial-statement` | Multi-section layout, hierarchical grouping, calculated totals | ✅ Converts | Complex nested structure; may need manual row/column adjustment |
| `inventory-report` | Grouped by warehouse/category, conditional stock status colors | ✅ Converts | SQL with `<=` operators properly escaped |
| `project-status` | Project tracking with Gantt-style bars, progress indicators | ✅ Converts | Visual elements may need SSRS equivalents |
| `purchase-order` | Form layout with line items, signatures | ✅ Converts | Form-based layout |
| `sales-report` | Grouped report with regional subtotals | ✅ Converts | Standard grouped structure |

**Known Limitations of Sample Reports:**
- These are **synthetic** reports created for testing, not extracted from a real BI Publisher instance
- Complex visual elements (charts, Gantt bars, images) are placeholders only
- Tablix row/column alignment may need manual adjustment in Report Builder
- Conditional formatting and calculated fields may require manual conversion
- They convert to RDL, but the generated reports are incomplete because they use features the converter does not currently map.

**Project Status**: relies heavily on _nested repeating structures_ and named templates for progress bars, badges, risks, milestones, and tasks. The converter only extracts simple field references and does not reproduce the nested layout or execute those templates fully. See project-status.xsl-fo:163.
**Inventory Report**: contains nested warehouse/category/product loops and fo:external-graphic images. The converter has _no image handler_, and nested loops inside the outer grouping are not preserved correctly. See inventory-report.xsl-fo:98-180.
**Customer Dashboard**: uses Oracle-specific _xdochart:* chart elements_. Those elements have no conversion template, so the charts disappear; the result is only a partial dashboard. See customer-dashboard.xsl-fo:265-294.
**Purchase Order**: uses fo:page-sequence-master, fo:marker, fo:retrieve-marker, and external graphics for the company logo. These header/page-continuation constructs are unsupported, so important portions of the document are omitted. See purchase-order.xsl-fo:76-123.

### After Conversion

1. Open the `.rdl` file in **Visual Studio** or **SSRS Report Builder**
2. Configure the data source connection to your database
3. Review field mappings (expressions like `=Fields!FIELD_NAME.Value`)
4. Preview and adjust layout as needed
5. Deploy to SSRS Report Server

### Stop Services

```powershell
# Stop containers (preserves data)
docker compose stop

# Stop and remove containers (preserves volumes)
docker compose down

# Stop and remove everything including data
docker compose down -v
```

### Troubleshooting

#### Permission Errors

If you encounter permission errors like "No write permissions" or "Permission denied to write collection":

```powershell
# Run the fix-permissions XQuery script via REST
$auth = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:"))
$script = Get-Content ".\scripts\fix-permissions.xql" -Raw
Invoke-RestMethod -Method POST -Uri "http://localhost:8088/exist/rest/db" -ContentType "application/xquery" -Headers @{Authorization = $auth} -Body $script
```

#### Clear All Collections

To reset all uploaded files and converted output:

```powershell
# Via app controller
Invoke-RestMethod -Method POST -Uri "http://localhost:8088/exist/apps/bip2ssrs/api/clear-all.xql"
```

#### Connection Issues

If eXist-db is not responding:

```powershell
# Check container status
docker compose ps

# View container logs
docker compose logs existdb

# Restart the container
docker compose restart existdb
```

#### Redeploy Application

If XQuery modules need to be updated:

```powershell
.\scripts\setup-existdb.ps1
```

---

## Objectives

| ID | Objective | Priority |
|----|-----------|----------|
| O1 | Automate conversion of BI Publisher XDO/RTF templates to SSRS RDL format | High |
| O2 | Preserve report layout and formatting during conversion | High |
| O3 | Map BI Publisher data models to SSRS datasets | High |
| O4 | Convert expressions and calculations to SSRS equivalents | Medium |
| O5 | Provide detailed conversion logs and error reports | Medium |
| O6 | Support batch processing of multiple reports | Medium |
| O7 | Generate migration assessment reports | Low |
| 08 | Determine template type from XDO | High |
---

## Scope

### In Scope

- **Report Templates**
  - RTF (Rich Text Format) templates
  - XPT (BI Publisher Template) files
  - PDF templates (layout extraction)
  - Excel templates (XLS/XLSX)

- **Data Models**
  - XML data model definitions (.xdm)
  - SQL query extraction and conversion
  - Parameter definitions
  - List of Values (LOV) conversion

- **Report Components**
  - Tables and cross-tabs
  - Charts and graphs
  - Images and logos
  - Subreports
  - Conditional formatting
  - Page headers and footers
  - Page numbering

- **Output**
  - SSRS RDL files (Report Definition Language)
  - Shared data sources (.rds)
  - Shared datasets (.rsd)
  - Conversion summary reports

### Out of Scope

- BI Publisher Bursting configurations (manual migration required)
- Integration with Oracle E-Business Suite specific APIs
- Real-time dashboard conversions
- BI Publisher Scheduler job migration
- Custom Java-based extensions
- Flash-based interactive components

---

## Background

### Oracle BI Publisher Overview

Oracle BI Publisher (formerly XML Publisher) is an enterprise reporting solution that:
- Uses XML as the data interchange format
- Supports multiple template formats (RTF, PDF, Excel, XPT)
- Provides pixel-perfect report output
- Integrates with Oracle Applications and external data sources

**Key Components:**
- Data Model (.xdm) - Defines data structure and queries
- Template (.rtf, .xpt) - Defines report layout
- Report Definition - Combines data model and template

#### Internal Architecture: XSL-FO

BI Publisher uses **XSL-FO (XSL Formatting Objects)** as its internal rendering format. This is a critical architectural detail:

```
┌─────────────────────────────────────────────────────────────────┐
│                 BI Publisher Rendering Pipeline                  │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  RTF     │    │  XSL-FO  │    │   FO     │    │  Output  │  │
│  │ Template │───▶│Generator │───▶│Processor │───▶│  (PDF,   │  │
│  │          │    │          │    │ (Apache  │    │  HTML)   │  │
│  └──────────┘    └──────────┘    │   FOP)   │    └──────────┘  │
│                                  └──────────┘                   │
│                                                                  │
│  Template tags like <?for-each:?> are converted to:             │
│  <xsl:for-each select="...">                                    │
│    <fo:table-row>...</fo:table-row>                             │
│  </xsl:for-each>                                                │
└─────────────────────────────────────────────────────────────────┘
```

**XSL-FO Characteristics:**
- XML-based formatting vocabulary (W3C standard)
- Contains both XSLT logic (`xsl:for-each`, `xsl:if`, `xsl:choose`) and formatting objects (`fo:block`, `fo:table`, `fo:inline`)
- RTF templates are converted to XSL-FO stylesheets internally
- XPT templates store XSL-FO directly or in a compressed format
- The `.xdo` files often contain the compiled XSL-FO representation

**Implication for Conversion:** Since BI Publisher's internal format is already XSLT/XSL-FO (pure XML), the conversion to SSRS RDL (also XML) becomes a **direct XML-to-XML transformation** — significantly improving feasibility of the XSLT-based approach.

### SQL Server Reporting Services Overview

SSRS is Microsoft's enterprise reporting platform that:
- Uses RDL (Report Definition Language) - an XML-based format
- Provides paginated and interactive reports
- Integrates with SQL Server and other data sources
- Supports expressions using Visual Basic syntax

**Key Components:**
- Report Definition (.rdl) - Complete report specification
- Shared Data Sources (.rds) - Reusable connection definitions
- Shared Datasets (.rsd) - Reusable query definitions

### XDM Data Model as the Source of Truth

The XDM (XML Data Model) file serves as the **authoritative definition** for both the XSL-FO template structure and the sample data files. Understanding this relationship is essential for creating consistent, functional reports.

#### XDM Structure Overview

An XDM file defines three critical aspects:

1. **SQL Query** - Determines what columns/data are retrieved from the database
2. **Output Structure** - Defines how flat SQL rows are restructured into hierarchical XML
3. **Parameters** - Input parameters that filter or control data retrieval

#### SQL Query → Output Structure Relationship

The SQL query produces a **flat result set** (denormalized rows), and the `<output>` section defines how to **reshape** that data into hierarchical XML:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SQL Query (flat rows)              →    Output Structure (hierarchical)    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SELECT i.invoice_number,                 <output name="INVOICE">           │
│         c.customer_name,          →         <element name="INVOICE_NUMBER"/>│
│         l.description,                      <element name="CUSTOMER">       │
│         l.quantity                            <element name="NAME"          │
│  FROM invoices i                                source="CUSTOMER_NAME"/>    │
│  JOIN customers c ...                       </element>                      │
│  JOIN invoice_lines l ...                   <element name="LINE_ITEMS"      │
│                                                 isRepeating="true">         │
│                                               <element name="LINE_ITEM">    │
│  Result: Flat rows like:                        <element name="DESCRIPTION"/>
│  ┌──────────┬───────────┬─────────┐            <element name="QUANTITY"/>  │
│  │INV-001   │ Acme Corp │Widget A │          </element>                     │
│  │INV-001   │ Acme Corp │Widget B │        </element>                       │
│  │INV-001   │ Acme Corp │Widget C │      </output>                          │
│  └──────────┴───────────┴─────────┘                                         │
│                                                                             │
│  The output structure groups repeated line items under a parent element     │
│  and maps SQL column names to XML element names via the "source" attribute  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key points:**
- The **SQL determines what data exists** (column names, joins, filters)
- The **output section determines XML structure** (hierarchy, element names, grouping)
- The `source` attribute maps SQL column names → XML element names (e.g., `CUSTOMER_NAME` → `NAME`)
- Elements with `isRepeating="true"` indicate where flat rows become repeated child elements

```xml
<dataModel xmlns="http://xmlns.oracle.com/oxp/xmlp" version="2.0">
    <dataSets>
        <dataSet name="InvoiceDS" type="complex">
            <sql><![CDATA[
                SELECT i.invoice_id, i.invoice_number, c.customer_name, l.description, l.quantity
                FROM invoices i
                JOIN customers c ON i.customer_id = c.customer_id
                JOIN invoice_lines l ON i.invoice_id = l.invoice_id
            ]]></sql>
            <output name="INVOICE">
                <element name="INVOICE_NUMBER" dataType="xsd:string"/>
                <element name="CUSTOMER" isComplex="true">
                    <element name="NAME" dataType="xsd:string" source="CUSTOMER_NAME"/>
                </element>
                <element name="LINE_ITEMS" isComplex="true" isRepeating="true">
                    <element name="LINE_ITEM" isComplex="true">
                        <element name="DESCRIPTION" dataType="xsd:string"/>
                        <element name="QUANTITY" dataType="xsd:decimal"/>
                    </element>
                </element>
            </output>
        </dataSet>
    </dataSets>
</dataModel>
```

#### How XDM Output Drives XSL-FO Template Structure

The `<output>` section of the XDM defines the **exact XPath expressions** that must be used in the XSL-FO template:

| XDM Output Definition | XSL-FO XPath Expression |
|----------------------|-------------------------|
| `<output name="INVOICE">` | Root element: `/INVOICE` |
| `<element name="INVOICE_NUMBER">` | `/INVOICE/INVOICE_NUMBER` |
| `<element name="CUSTOMER" isComplex="true">` | Parent container: `/INVOICE/CUSTOMER` |
| `<element name="NAME">` inside CUSTOMER | `/INVOICE/CUSTOMER/NAME` |
| `<element name="LINE_ITEMS" isRepeating="true">` | Loop target: `/INVOICE/LINE_ITEMS/LINE_ITEM` |

**Template XPath must match XDM output structure:**

```xml
<!-- XSL-FO template must use XPaths matching the XDM output schema -->
<xsl:value-of select="/INVOICE/INVOICE_NUMBER"/>
<xsl:value-of select="/INVOICE/CUSTOMER/NAME"/>
<xsl:for-each select="/INVOICE/LINE_ITEMS/LINE_ITEM">
    <fo:table-row>
        <fo:table-cell><fo:block><xsl:value-of select="DESCRIPTION"/></fo:block></fo:table-cell>
    </fo:table-row>
</xsl:for-each>
```

#### How XDM Drives Sample Data Structure

Sample data XML files (`*-data.xml`) must mirror the XDM output structure **exactly** for the template to render correctly:

**Option A: Hierarchical Structure (matches XDM output directly)**

When the XDM defines nested complex elements, the sample data should be hierarchical:

```xml
<INVOICE>
    <INVOICE_NUMBER>INV-2026-001</INVOICE_NUMBER>
    <CUSTOMER>
        <NAME>Acme Corp</NAME>
        <CITY>Seattle</CITY>
    </CUSTOMER>
    <LINE_ITEMS>
        <LINE_ITEM>
            <DESCRIPTION>Widget A</DESCRIPTION>
            <QUANTITY>10</QUANTITY>
        </LINE_ITEM>
        <LINE_ITEM>
            <DESCRIPTION>Widget B</DESCRIPTION>
            <QUANTITY>5</QUANTITY>
        </LINE_ITEM>
    </LINE_ITEMS>
</INVOICE>
```

**Option B: Flat Structure (matches SQL result set)**

When sample data represents raw SQL output (denormalized/flat rows), the template XPaths must adapt:

```xml
<INVOICE>
    <LINE_ITEM>
        <INVOICE_NUMBER>INV-2026-001</INVOICE_NUMBER>
        <CUSTOMER_NAME>Acme Corp</CUSTOMER_NAME>
        <DESCRIPTION>Widget A</DESCRIPTION>
        <QUANTITY>10</QUANTITY>
    </LINE_ITEM>
    <LINE_ITEM>
        <INVOICE_NUMBER>INV-2026-001</INVOICE_NUMBER>
        <CUSTOMER_NAME>Acme Corp</CUSTOMER_NAME>
        <DESCRIPTION>Widget B</DESCRIPTION>
        <QUANTITY>5</QUANTITY>
    </LINE_ITEM>
</INVOICE>
```

When using flat data, the template must reference the first row for header fields:
```xml
<xsl:value-of select="/INVOICE/LINE_ITEM[1]/INVOICE_NUMBER"/>
<xsl:value-of select="/INVOICE/LINE_ITEM[1]/CUSTOMER_NAME"/>
<xsl:for-each select="/INVOICE/LINE_ITEM">
    ...
</xsl:for-each>
```

#### Key XDM Attributes

| Attribute | Purpose | Impact on Template/Data |
|-----------|---------|------------------------|
| `name` | Element name in output XML | Defines the XPath node name |
| `dataType` | Data type (xsd:string, xsd:decimal, xsd:date) | Affects formatting functions |
| `source` | Maps to different SQL column name | Data uses `source` value; template uses `name` |
| `isComplex="true"` | Indicates nested structure | Creates parent element for grouping |
| `isRepeating="true"` | Indicates multiple occurrences | Requires `xsl:for-each` in template |
| `formula` | Calculated field expression | Value computed, not from SQL |

#### Consistency Rules

1. **XSL-FO XPaths must match XDM output structure** — If XDM defines `/INVOICE/CUSTOMER/NAME`, the template must use that exact path
2. **Sample data must match template expectations** — The data file structure must provide the elements the template XPaths reference
3. **Element names are case-sensitive** — `CUSTOMER_NAME` ≠ `Customer_Name`
4. **The `source` attribute remaps SQL columns** — SQL column `CUSTOMER_NAME` can become element `NAME` via `source="CUSTOMER_NAME"`

#### Troubleshooting Mismatches

| Error | Likely Cause | Solution |
|-------|-------------|----------|
| Empty table body | XPath finds no elements | Verify `xsl:for-each` path matches data structure |
| Missing values | Element name mismatch | Check XDM `source` vs `name` attributes |
| Template renders but blank | Data structure differs from XDM output | Align sample data with XDM output schema |

#### BIP vs SSRS Data Model Architecture

A fundamental difference exists between how BIP and SSRS handle data grouping. Understanding this is critical for the conversion process.

**BIP Architecture: Data Reshaping Before Template**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SQL (flat rows) → XDM Reshaping → Hierarchical XML → XSL-FO Template       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. SQL produces denormalized rows:                                         │
│     ┌──────────┬──────────┬─────────┬──────┐                               │
│     │ SEGMENT  │ CUSTOMER │ REVENUE │ ...  │                               │
│     ├──────────┼──────────┼─────────┼──────┤                               │
│     │ Enterprise│ Acme    │ 10000   │      │                               │
│     │ Enterprise│ Contoso │ 8000    │      │                               │
│     │ SMB      │ StartupX │ 2000    │      │                               │
│     └──────────┴──────────┴─────────┴──────┘                               │
│                                                                             │
│  2. XDM output section reshapes at runtime:                                 │
│     <REPORT>                                                                │
│       <SEGMENTS>                                                            │
│         <SEGMENT>  ← Grouped by SEGMENT field                               │
│           <NAME>Enterprise</NAME>                                           │
│           <CUSTOMERS>                                                       │
│             <CUSTOMER><NAME>Acme</NAME></CUSTOMER>                          │
│             <CUSTOMER><NAME>Contoso</NAME></CUSTOMER>                       │
│           </CUSTOMERS>                                                      │
│         </SEGMENT>                                                          │
│       </SEGMENTS>                                                           │
│     </REPORT>                                                               │
│                                                                             │
│  3. XSL-FO template traverses hierarchy:                                    │
│     <xsl:for-each select="/REPORT/SEGMENTS/SEGMENT">                        │
│       <fo:block><xsl:value-of select="NAME"/></fo:block>                   │
│       <xsl:for-each select="CUSTOMERS/CUSTOMER">                            │
│         ...                                                                 │
│       </xsl:for-each>                                                       │
│     </xsl:for-each>                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**SSRS Architecture: Flat Data with Report-Level Grouping**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SQL (flat rows) → DataSet (stays flat) → RDL Tablix Groups                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. SQL produces same denormalized rows (same query as BIP)                 │
│                                                                             │
│  2. DataSet keeps data FLAT - no reshaping:                                 │
│     <DataSet Name="MainDS">                                                 │
│       <Fields>                                                              │
│         <Field Name="SEGMENT"><DataField>SEGMENT</DataField></Field>        │
│         <Field Name="CUSTOMER"><DataField>CUSTOMER</DataField></Field>      │
│         <Field Name="REVENUE"><DataField>REVENUE</DataField></Field>        │
│       </Fields>                                                             │
│     </DataSet>                                                              │
│                                                                             │
│  3. Grouping is defined in the Tablix control via TablixRowHierarchy:       │
│     <TablixRowHierarchy>                                                    │
│       <TablixMembers>                                                       │
│         <TablixMember>  ← Outer group (Segment)                             │
│           <Group Name="SegmentGroup">                                       │
│             <GroupExpressions>                                              │
│               <GroupExpression>=Fields!SEGMENT.Value</GroupExpression>      │
│             </GroupExpressions>                                             │
│           </Group>                                                          │
│           <TablixMembers>                                                   │
│             <TablixMember>  ← Inner detail rows (Customers)                 │
│               <Group Name="CustomerDetail"/>                                │
│             </TablixMember>                                                 │
│           </TablixMembers>                                                  │
│         </TablixMember>                                                     │
│       </TablixMembers>                                                      │
│     </TablixRowHierarchy>                                                   │
│                                                                             │
│  4. Aggregates use scope parameter:                                         │
│     =Sum(Fields!REVENUE.Value, "SegmentGroup")                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Insight: Same SQL, Different Grouping Mechanism**

| Aspect | BIP | SSRS |
|--------|-----|------|
| Data transformation | Runtime reshaping via XDM | None - data stays flat |
| Grouping definition | XDM `isComplex` + `isRepeating` | RDL `Group` + `GroupExpressions` |
| Template iteration | `xsl:for-each` over hierarchical paths | Tablix detail rows with group context |
| Aggregation | XPath functions on grouped data | `=Sum(Field, "GroupName")` with scope |
| SQL query | Same | Same |

**Conversion Strategy**

The converter translates grouping from XSL-FO to RDL:

| XSL-FO Pattern | RDL Translation |
|----------------|-----------------|
| `<xsl:for-each select="/ROOT/ITEMS/ITEM">` | `<Group Name="ItemDetail"><GroupExpressions>` based on extracted field |
| Nested `xsl:for-each` | Nested `TablixMember` with parent group |
| `<xsl:value-of select="sum(...)">` | `=Sum(Fields!Field.Value, "GroupScope")` |
| `position()` | `=RowNumber("GroupScope")` |

This approach allows **both BIP and SSRS to use the same SQL query**, with grouping semantics translated during conversion.

#### Known Challenge: Sample Data Structure Mismatch

A fundamental architectural difference exists between BIP and SSRS that affects testing with sample data:

**The Problem:**

| Testing Scenario | Required Data Format | Reason |
|-----------------|---------------------|--------|
| BIP template preview | Hierarchical XML | XSL-FO templates use XPath like `/ROOT/SEGMENTS/SEGMENT` |
| SSRS report testing | Flat rows | DataSets expect `Fields!SEGMENT_NAME.Value` |

In **production**, both systems use the same flat SQL. BIP's XDM layer reshapes the data at runtime before the template processes it. SSRS never reshapes - it relies on Tablix grouping to organize flat data visually.

---

### CRITICAL: Same SQL, Different Data Representation

**This is essential to understand before working with real BIP reports:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRODUCTION WORKFLOW                                 │
│                                                                             │
│    SQL Query (identical)                                                    │
│         │                                                                   │
│         ├──────────────────────┬────────────────────────────┐              │
│         ▼                      ▼                            ▼              │
│    ┌─────────┐          ┌─────────────┐              ┌─────────────┐       │
│    │   BIP   │          │    SSRS     │              │  Test Data  │       │
│    │ Runtime │          │   Runtime   │              │  (Synthetic)│       │
│    └────┬────┘          └──────┬──────┘              └──────┬──────┘       │
│         │                      │                            │              │
│    XDM reshapes                Uses flat                    │              │
│    flat → hierarchical         data directly                │              │
│         │                      │                            │              │
│         ▼                      ▼                            ▼              │
│    ┌─────────────┐      ┌─────────────┐              ┌─────────────┐       │
│    │ Hierarchical│      │    Flat     │              │   -bip.xml  │       │
│    │    XML      │      │   Rows      │              │  -ssrs.xml  │       │
│    └──────┬──────┘      └──────┬──────┘              └─────────────┘       │
│           │                    │                                           │
│           ▼                    ▼                                           │
│    XSL-FO Template      RDL Tablix Groups                                  │
│    (uses XPath)         (uses =Fields!)                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key Points:**

1. **The SQL is identical** for BIP and SSRS in production
2. **BIP reshapes at runtime** via the XDM `<output>` section's `isComplex` and `isRepeating` attributes
3. **SSRS never reshapes** - it receives flat rows and uses Tablix Groups to create visual hierarchy
4. **Synthetic test data requires two files** because we don't have a running BIP/SSRS server to execute the SQL:
   - `-bip.xml`: Pre-reshaped hierarchical structure (simulates XDM output)
   - `-ssrs.xml`: Flat rows (simulates raw SQL output)

**When switching to real BIP reports:**
- The SQL from the XDM file will work for both systems unchanged
- SSRS will run the SQL and receive flat rows directly
- The `-ssrs.xml` test files are only needed for offline testing without database connectivity

---

**For synthetic test data**, this creates a mismatch:
- Creating hierarchical sample data makes BIP previews work but doesn't represent actual SQL output
- Creating flat sample data matches SQL reality but breaks BIP template XPath expectations

**Deferred Resolution:**

This challenge is best addressed when working with **actual BIP reports** rather than synthetic ones:

1. Real BIP reports include XDM files that explicitly define reshaping rules
2. The XDM `<output>` section shows exactly how flat SQL maps to hierarchical XML
3. This metadata can inform automated reshaping or help generate appropriate test data

**Current Approach:**

Each report maintains **two separate data files** with distinct purposes:

| File Pattern | Format | Purpose |
|--------------|--------|---------|
| `{report}-data-ssrs.xml` | Flat (SQL rows) | Uploaded to SQL Server, used by SSRS DataSet |
| `{report}-data-bip.xml` | Hierarchical (XDM output) | Pre-reshaped structure for BIP template testing |

**Naming rationale:** `-ssrs` indicates the format SSRS expects (flat rows), while `-bip` indicates the format BIP's XDM layer produces (hierarchical XML).

This approach:
- Avoids hard-coded flattening transforms per report type
- Allows both BIP preview testing and SSRS preview testing
- Keeps the flat/hierarchical relationship explicit and maintainable

The deprecated `hierarchical-to-flat.xsl` transform is retained in `src/xslt/` for reference but should not be extended.

**Future Enhancement:**

When real BIP reports are available, implement XDM-driven automatic reshaping that:
1. Parses the XDM `<output>` section to extract grouping rules
2. Generates XSLT transforms dynamically based on `isComplex` and `isRepeating` attributes
3. Applies reshaping at preview time for BIP, while SSRS uses flat data with Tablix groups

#### Design Constraint: No Hardcoded Element Names

**The converter must not rely on specific table, row, or field names.**

This constraint ensures the conversion process scales to arbitrary BIP reports without per-report customization.

| ❌ Avoid | ✅ Prefer |
|----------|----------|
| `if (elementName == "CUSTOMER_ROW")` | Pattern-based detection (e.g., elements ending in `_ROW`) |
| `select="/CUSTOMER_DASHBOARD/SEGMENTS/SEGMENT"` hardcoded | XPath extraction from `xsl:for-each/@select` dynamically |
| Mapping `SEGMENT_NAME` → specific RDL field | Deriving field names from XPath structure generically |
| Report-specific reshaping templates | XDM-driven transforms that read metadata |

**Rationale:**

1. **Scalability** - Hundreds of BIP reports exist; manual per-report coding is not feasible
2. **Maintainability** - Hardcoded names create brittle, hard-to-debug logic
3. **Correctness** - Real reports will have names we cannot predict from synthetic examples
4. **XDM as metadata** - The XDM file already contains the structural rules; the converter should read them, not duplicate them

**Implications:**

- The `hierarchical-to-flat.xsl` transform is **deprecated** - do not extend with additional report-specific templates
- Each synthetic report requires both `*-data-ssrs.xml` (flat) and `*-data-bip.xml` (hierarchical) files
- The `extract-group-field-from-xpath` helper uses **XDM-driven field resolution** exclusively (XDM is always required)
- Test sample data should be structured to match XDM output schemas, not created ad-hoc

#### XDM-Driven Field Resolution (v1.5.0)

The XSLT requires an `xdm-uri` parameter pointing to the XDM file. For grouping expressions:

1. For grouping expressions (e.g., `xsl:for-each select="/REGIONS/REGION"`), the converter:
   - Extracts the repeating element name (`REGION`)
   - Looks up `<element name="REGION" isRepeating="true">` in the XDM
   - Returns the first non-complex child element name (`REGION_NAME`)

2. **Fallback behavior:** If the element is not found in XDM, uses `ELEMENT_ID` as a generic default.

**Example:** For `SALES_REP` element:
- XDM lookup finds first child `REP_NAME`, returns `REP_NAME` ✓

---

## System Requirements

### Runtime Environment

| Component | Requirement |
|-----------|-------------|
| Operating System | Windows Server 2019+ / Windows 10/11 |
| .NET Runtime | .NET 8.0 or later |
| Memory | Minimum 8 GB RAM |
| Disk Space | 500 MB for installation + working space |

### Dependencies

| Dependency | Purpose |
|------------|---------|
| Microsoft.ReportingServices.RdlObjectModel | RDL generation and manipulation |
| DocumentFormat.OpenXml | RTF/Office document parsing |
| System.Xml.Linq | XML processing |
| Oracle.ManagedDataAccess | Oracle database connectivity (optional) |

### Input Requirements

| File Type | Extension | Description |
|-----------|-----------|-------------|
| BI Publisher Data Model | .xdm | XML-based data definition |
| RTF Template | .rtf | Rich Text Format template |
| XPT Template | .xpt | BI Publisher native template |
| Excel Template | .xlsx | Excel-based template |
| Report Archive | .xdoz | Packaged report bundle |

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    BIP-to-SSRS Converter                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Input      │    │  Conversion  │    │   Output     │      │
│  │   Parser     │───▶│   Engine     │───▶│   Generator  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Data Model   │    │  Expression  │    │    RDL       │      │
│  │ Extractor    │    │  Translator  │    │   Writer     │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Logging & Reporting                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Component Descriptions

#### Input Parser
- Reads and validates BI Publisher artifacts
- Extracts template content from RTF/XPT files
- Parses XDM data model definitions
- Creates intermediate object representation

#### Conversion Engine
- Maps BI Publisher constructs to SSRS equivalents
- Translates XPath expressions to SSRS expressions
- Handles layout transformation
- Manages conversion rules and mappings

#### Output Generator
- Produces valid RDL XML
- Creates shared data sources and datasets
- Generates conversion reports
- Validates output against RDL schema

---

## Technical Implementation Options

This section evaluates different technical approaches for implementing the conversion utility, with a focus on leveraging XML-native technologies given that both BI Publisher and SSRS are fundamentally XML-based.

### Option 1: eXist-db Container + XSLT Pipeline

**Overview:** Use eXist-db (an open-source XML database) running in a Docker container as the transformation engine, with XSLT stylesheets performing the actual conversion.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Docker Environment                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    eXist-db Container                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐    │  │
│  │  │   XQuery    │  │    XSLT     │  │  XML Storage    │    │  │
│  │  │   Engine    │  │  Processor  │  │  (Collections)  │    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘    │  │
│  │         │               │                   │              │  │
│  │         └───────────────┼───────────────────┘              │  │
│  │                         ▼                                  │  │
│  │              ┌─────────────────────┐                       │  │
│  │              │   REST API / XQuery │                       │  │
│  │              │   Endpoints          │                       │  │
│  │              └─────────────────────┘                       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Orchestration Container                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐    │  │
│  │  │    RTF      │  │  Pre/Post   │  │   Validation    │    │  │
│  │  │  Extractor  │  │  Processing │  │   & Reporting   │    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

#### XSLT Transformation Chain

Since BI Publisher internally uses XSL-FO, the source is already XSLT/XML:

```
BIP Source Files
       │
       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  1. Extract  │────▶│  2. Parse    │────▶│  3. Convert  │
│  XSL-FO from │     │  XSL-FO      │     │  FO→RDL      │
│  XPT/.xdo    │     │  Structure   │     │  Elements    │
└──────────────┘     └──────────────┘     └──────────────┘
                                                 │
       ┌─────────────────────────────────────────┘
       ▼
┌──────────────┐     ┌──────────────┐
│  4. Map      │────▶│  5. Validate │────▶ RDL Output
│  XSLT Logic  │     │  & Package   │
│  to VB Expr  │     │              │
└──────────────┘     └──────────────┘
```

#### Feasibility Assessment

| Factor | Rating | Analysis |
|--------|--------|----------|
| **XML-to-XML Transformation** | ★★★★★ | **XSL-FO is already XML/XSLT.** Source and target are both XML. Perfect fit for XSLT transformation. |
| **Expression Translation** | ★★★★☆ | **XSL-FO already uses XSLT syntax** (`xsl:for-each`, `xsl:if`). Mapping to VB.NET expressions is more direct than from RTF tags. |
| **RTF Handling** | ★★★★☆ | **Can bypass RTF entirely** by extracting the compiled XSL-FO from .xdo files. RTF is just authoring format. |
| **Layout Preservation** | ★★★★☆ | **FO formatting objects map well** to RDL: `fo:table`→Tablix, `fo:block`→Textbox, `fo:inline`→TextRun. |
| **Container Portability** | ★★★★★ | eXist-db has official Docker images. Easy to deploy and scale. |
| **Development Speed** | ★★★★★ | **XSLT-to-XSLT transformation** is XSLT's sweet spot. Much faster development. |
| **Debugging** | ★★★☆☆ | XSLT debugging is challenging. eXist-db IDE helps but not as mature as traditional IDEs. |

#### XSL-FO to RDL Mapping

| XSL-FO Element | RDL Equivalent | Notes |
|----------------|----------------|-------|
| `fo:root` | `Report` | Document root |
| `fo:page-sequence` | `Body` / `Page` | Page structure |
| `fo:static-content` | `PageHeader` / `PageFooter` | Static regions |
| `fo:flow` | `Body/ReportItems` | Main content |
| `fo:block` | `Textbox` | Block-level container |
| `fo:inline` | `TextRun` | Inline text |
| `fo:table` | `Tablix` | Table structure |
| `fo:table-row` | `TablixRow` | Table row |
| `fo:table-cell` | `TablixCell` | Table cell |
| `fo:external-graphic` | `Image` | Images |
| `fo:leader` | Line/Rectangle | Leaders and rules |
| `xsl:for-each` | Tablix RowGroup | Data iteration |
| `xsl:if` | Visibility expression | Conditional |
| `xsl:choose/when` | Switch expression | Multi-condition |

#### Sample XSLT: XSL-FO to RDL Transformation

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:rd="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition"
    exclude-result-prefixes="fo">

  <!-- Root template: fo:root → Report -->
  <xsl:template match="fo:root">
    <rd:Report xmlns:rd="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
      <xsl:apply-templates select="fo:layout-master-set"/>
      <xsl:apply-templates select="fo:page-sequence"/>
    </rd:Report>
  </xsl:template>

  <!-- Convert fo:table with xsl:for-each to SSRS Tablix -->
  <xsl:template match="fo:table[ancestor::xsl:for-each]">
    <rd:Tablix Name="{generate-id()}">
      <rd:DataSetName>
        <xsl:value-of select="ancestor::xsl:for-each[1]/@select"/>
      </rd:DataSetName>
      <rd:TablixBody>
        <rd:TablixColumns>
          <xsl:for-each select="fo:table-column">
            <rd:TablixColumn>
              <rd:Width><xsl:value-of select="@column-width"/></rd:Width>
            </rd:TablixColumn>
          </xsl:for-each>
        </rd:TablixColumns>
        <rd:TablixRows>
          <xsl:apply-templates select="fo:table-body/fo:table-row"/>
        </rd:TablixRows>
      </rd:TablixBody>
    </rd:Tablix>
  </xsl:template>

  <!-- Convert fo:block to Textbox -->
  <xsl:template match="fo:block">
    <rd:Textbox Name="{generate-id()}">
      <rd:Paragraphs>
        <rd:Paragraph>
          <rd:TextRuns>
            <rd:TextRun>
              <rd:Value>
                <xsl:call-template name="translate-expression">
                  <xsl:with-param name="expr" select="."/>
                </xsl:call-template>
              </rd:Value>
              <rd:Style>
                <rd:FontFamily><xsl:value-of select="@font-family"/></rd:FontFamily>
                <rd:FontSize><xsl:value-of select="@font-size"/></rd:FontSize>
              </rd:Style>
            </rd:TextRun>
          </rd:TextRuns>
        </rd:Paragraph>
      </rd:Paragraphs>
    </rd:Textbox>
  </xsl:template>

  <!-- Translate XPath/xsl:value-of to SSRS expression -->
  <xsl:template name="translate-expression">
    <xsl:param name="expr"/>
    <xsl:analyze-string select="string($expr)" regex="(\w+)">
      <xsl:matching-substring>
        <xsl:text>=Fields!</xsl:text>
        <xsl:value-of select="regex-group(1)"/>
        <xsl:text>.Value</xsl:text>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:template>

</xsl:stylesheet>
```

#### eXist-db Container Setup

```yaml
# docker-compose.yml
version: '3.8'
services:
  existdb:
    image: existdb/existdb:6.2.0
    ports:
      - "8080:8080"
    volumes:
      - ./xslt:/exist/xslt
      - ./data:/exist/data
    environment:
      - EXIST_ENV=production
      
  converter:
    build: ./converter
    depends_on:
      - existdb
    volumes:
      - ./input:/app/input
      - ./output:/app/output
```

#### Pros
- Native XML processing - no impedance mismatch
- XSLT 3.0 supports streaming for large documents
- XQuery allows complex querying during transformation
- Containerized deployment is portable and reproducible
- eXist-db provides built-in versioning and collections
- Can store conversion rules as queryable XML
- **XSL-FO source is already XSLT** — minimal impedance mismatch
- **FO elements map directly** to RDL report items

#### Cons
- RTF templates still need extraction (but can use compiled .xdo instead)
- XSLT debugging is challenging
- Learning curve for teams unfamiliar with XQuery/XSLT
- Less tooling support than mainstream languages

---

### Option 1 Detailed Design: Pure eXist-db Solution

This section provides implementation-level detail for the eXist-db + XSLT approach.

#### Project Structure

```
bip-to-ssrs/
├── docker-compose.yml              # Uses official existdb/existdb image
├── README.md
├── .env
├── .vscode/
│   └── settings.json               # eXist-db connection settings
│
├── src/
│   ├── collection.xconf                # Collection configuration
│   ├── expath-pkg.xml                  # Package descriptor
│   ├── repo.xml                        # Repository metadata
│   │
│   ├── modules/                        # XQuery modules
│   │   ├── config.xqm                  # Configuration settings
│   │   ├── extract.xqm                 # XSL-FO extraction from BIP files
│   │   ├── transform.xqm               # Transformation orchestration
│   │   ├── validate.xqm                # RDL schema validation
│   │   ├── expressions.xqm             # XPath→VB expression translation
│   │   └── utils.xqm                   # Utility functions
│   │
│   ├── xslt/                           # XSLT transformation modules
│   │   ├── main-transform.xsl          # Master transformation entry point
│   │   ├── fo-to-rdl/
│   │   │   ├── page-layout.xsl         # fo:page-sequence → Page
│   │   │   ├── tables.xsl              # fo:table → Tablix
│   │   │   ├── blocks.xsl              # fo:block → Textbox
│   │   │   ├── lists.xsl               # fo:list-block → List
│   │   │   ├── graphics.xsl            # fo:external-graphic → Image
│   │   │   └── styles.xsl              # FO properties → RDL styles
│   │   ├── xsl-logic/
│   │   │   ├── for-each.xsl            # xsl:for-each → RowGroup
│   │   │   ├── conditionals.xsl        # xsl:if, xsl:choose → Visibility
│   │   │   ├── variables.xsl           # xsl:variable → ReportVariable
│   │   │   └── expressions.xsl         # XPath → VB.NET expressions
│   │   └── data-model/
│   │       ├── datasources.xsl         # Connection conversion
│   │       ├── datasets.xsl            # Query/field mapping
│   │       └── parameters.xsl          # Parameter conversion
│   │
│   ├── schemas/                        # Validation schemas
│   │   ├── rdl-2016.xsd                # SSRS 2016+ RDL schema
│   │   └── fo.xsd                      # XSL-FO schema (validation)
│   │
│   └── api/                            # REST API endpoints
│       ├── controller.xql              # Main REST controller
│       ├── upload.xql                  # Upload BIP files
│       ├── convert-stored.xql          # Convert uploaded reports
│       ├── convert-json.xql            # Convert with JSON input
│       ├── list-reports.xql            # List available reports
│       └── clear-all.xql               # Clear input/output collections
│
├── test/
│   ├── xspec/                          # XSpec test specifications
│   │   ├── tables.xspec
│   │   ├── expressions.xspec
│   │   └── integration.xspec
│   └── samples/                        # Sample BIP files for testing
│       ├── simple-table.xdo
│       ├── grouped-report.xdo
│       └── complex-chart.xdo
│
└── scripts/
    ├── convert-bip.ps1                 # Convert BIP files to RDL
    ├── deploy-to-ssrs.ps1              # Deploy RDL to SSRS server
    ├── setup-existdb.ps1               # Deploy app to eXist-db
    ├── sync-to-existdb.ps1             # Sync src/ files to running eXist-db (dev)
    ├── view-rdl.ps1                    # Preview RDL output
    └── fix-permissions.xql             # XQuery to fix collection permissions
```

#### Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Official eXist-db container - no custom Dockerfile needed
  existdb:
    image: existdb/existdb:6.2.0
    container_name: bip2ssrs-existdb
    ports:
      - "8080:8080"      # eXist-db web interface & REST API
    volumes:
      # Mount source for live VS Code editing
      - ./src/modules:/exist/webapp/WEB-INF/data/fs/db/apps/bip2ssrs/modules
      - ./src/xslt:/exist/webapp/WEB-INF/data/fs/db/apps/bip2ssrs/xslt
      - ./src/api:/exist/webapp/WEB-INF/data/fs/db/apps/bip2ssrs/api
      # Persistent data storage
      - existdb-data:/exist/webapp/WEB-INF/data
    environment:
      - JAVA_OPTS=-Xms512m -Xmx2g
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/exist/status"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

volumes:
  existdb-data:
```

#### VS Code Development Workflow

The official eXist-db container (`existdb/existdb:6.2.0`) works out of the box — no custom Dockerfile needed. XQuery and XSLT files can be edited directly in VS Code with live updates.

##### Option A: Volume Mounts (Recommended)

Mount your local source folders directly into the container:

```yaml
# docker-compose.yml - Development configuration
services:
  existdb:
    image: existdb/existdb:6.2.0
    ports:
      - "8080:8080"
    volumes:
      # Mount source code for live editing
      - ./src/modules:/exist/webapp/WEB-INF/data/fs/db/apps/bip2ssrs/modules
      - ./src/xslt:/exist/webapp/WEB-INF/data/fs/db/apps/bip2ssrs/xslt
      - ./src/api:/exist/webapp/WEB-INF/data/fs/db/apps/bip2ssrs/api
      # Persistent data
      - existdb-data:/exist/webapp/WEB-INF/data
```

**Workflow:**
1. Run `docker compose up -d`
2. Edit `.xqm` and `.xsl` files in VS Code
3. Changes are immediately available — no rebuild or restart needed
4. Access eXist-db Dashboard at http://localhost:8080/exist/apps/dashboard/

##### Option B: eXist-db VS Code Extension

Install the **eXide** or **existdb-vscode** extension for full IDE integration:

1. **Install Extension:**
   - Search for "existdb" in VS Code Extensions
   - Install "eXist-db for VSCode" or similar

2. **Configure Connection:**
   ```json
   // .vscode/settings.json
   {
     "existdb.connection": {
       "server": "http://localhost:8080/exist",
       "user": "admin",
       "password": ""
     },
     "existdb.syncOnSave": true
   }
   ```

3. **Sync Files:**
   - Edit XQuery/XSLT locally
   - Extension syncs to eXist-db on save via REST API

##### Option C: REST API Upload

Upload files programmatically via eXist-db's REST API:

```powershell
# Upload a single XQuery module
$content = Get-Content -Path .\src\modules\transform.xqm -Raw
Invoke-RestMethod -Uri "http://localhost:8080/exist/rest/db/apps/bip2ssrs/modules/transform.xqm" `
    -Method PUT `
    -Body $content `
    -ContentType "application/xquery" `
    -Credential (Get-Credential)

# Or use curl
curl -X PUT "http://localhost:8080/exist/rest/db/apps/bip2ssrs/xslt/main-transform.xsl" `
    -H "Content-Type: application/xml" `
    --data-binary "@src/xslt/main-transform.xsl" `
    -u admin:
```

##### Recommended VS Code Extensions

| Extension | Purpose |
|-----------|---------|
| **XML** (Red Hat) | XML/XSLT syntax, validation, formatting |
| **XSLT/XPath for Visual Studio Code** | XSLT 3.0 syntax highlighting, snippets |
| **XQuery for VSCode** | XQuery syntax highlighting |
| **eXist-db for VSCode** | Direct sync with eXist-db |
| **REST Client** | Test REST API endpoints |

##### Development Commands

```powershell
# Start eXist-db container
docker compose up -d

# View logs
docker compose logs -f existdb

# Access eXist-db shell (for debugging)
docker compose exec existdb bash

# Restart after config changes
docker compose restart existdb

# Stop and remove
docker compose down
```

##### Hot Reload Verification

After editing a file, verify the change is active:

```powershell
# Test XQuery module loaded correctly
curl "http://localhost:8080/exist/rest/db/apps/bip2ssrs/modules/transform.xqm"

# Test transformation endpoint
curl -X POST "http://localhost:8080/exist/rest/db/apps/bip2ssrs/api/convert.xql" `
    -H "Content-Type: application/xml" `
    --data-binary "@test/samples/simple-table.xdo"
```

#### Core XQuery Modules

##### Configuration Module
```xquery
xquery version "3.1";

(:~ 
 : Configuration module for BIP-to-SSRS converter
 :)
module namespace config = "http://bip2ssrs.org/config";

declare variable $config:app-root := "/db/apps/bip2ssrs";
declare variable $config:xslt-root := $config:app-root || "/xslt";
declare variable $config:schema-root := $config:app-root || "/schemas";

(: Target SSRS version - affects RDL namespace :)
declare variable $config:ssrs-version := "2016";

(: RDL namespace based on version :)
declare variable $config:rdl-ns := 
    "http://schemas.microsoft.com/sqlserver/reporting/" || 
    $config:ssrs-version || "/01/reportdefinition";

(: Transformation options :)
declare variable $config:options := map {
    "preserve-formatting": true(),
    "convert-charts": true(),
    "embed-images": true(),
    "validate-output": true(),
    "expression-fallback": "placeholder"  (: or "error" :)
};
```

##### Extraction Module
```xquery
xquery version "3.1";

(:~
 : Extract XSL-FO content from BI Publisher files
 :)
module namespace extract = "http://bip2ssrs.org/extract";

import module namespace util = "http://exist-db.org/xquery/util";
import module namespace compression = "http://exist-db.org/xquery/compression";

(:~
 : Extract XSL-FO from .xdo file (often a ZIP containing XML)
 :)
declare function extract:from-xdo($xdo as xs:base64Binary) as element()* {
    let $entries := compression:unzip($xdo)
    return
        for $entry in $entries
        where ends-with($entry/@name, '.xsl') or ends-with($entry/@name, '.fo')
        return parse-xml(util:binary-to-string($entry))/*
};

(:~
 : Extract XSL-FO from .xpt file
 :)
declare function extract:from-xpt($xpt as xs:base64Binary) as element()* {
    let $content := util:binary-to-string($xpt)
    (: XPT files may have header; extract XML portion :)
    let $xml-start := substring-after($content, '<?xml')
    return 
        if ($xml-start) then
            parse-xml('<?xml' || $xml-start)/*
        else
            parse-xml($content)/*
};

(:~
 : Parse .xdm data model file (already XML)
 :)
declare function extract:data-model($xdm as node()) as element() {
    $xdm/dataModel
};
```

##### Transformation Orchestration
```xquery
xquery version "3.1";

(:~
 : Main transformation orchestration module
 :)
module namespace transform = "http://bip2ssrs.org/transform";

import module namespace config = "http://bip2ssrs.org/config";
import module namespace extract = "http://bip2ssrs.org/extract";
import module namespace validate = "http://bip2ssrs.org/validate";

declare namespace fo = "http://www.w3.org/1999/XSL/Format";
declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";

(:~
 : Convert a BI Publisher report to SSRS RDL
 : @param $source The XSL-FO source document
 : @param $data-model Optional data model for dataset generation
 : @param $options Conversion options (overrides defaults)
 : @return Map containing RDL and conversion report
 :)
declare function transform:convert(
    $source as element(),
    $data-model as element()?,
    $options as map(*)?
) as map(*) {
    
    let $opts := if ($options) then map:merge(($config:options, $options)) else $config:options
    
    (: Load the master XSLT stylesheet :)
    let $xslt := doc($config:xslt-root || "/main-transform.xsl")
    
    (: Set up XSLT parameters :)
    let $params := map {
        "rdl-namespace": $config:rdl-ns,
        "preserve-formatting": $opts?preserve-formatting,
        "convert-charts": $opts?convert-charts
    }
    
    (: Execute transformation :)
    let $result := transform:transform($source, $xslt, $params)
    
    (: Validate if requested :)
    let $validation := 
        if ($opts?validate-output) then
            validate:rdl($result)
        else
            map { "valid": true(), "errors": () }
    
    (: Build conversion report :)
    let $report := transform:build-report($source, $result, $validation)
    
    return map {
        "rdl": $result,
        "valid": $validation?valid,
        "errors": $validation?errors,
        "report": $report,
        "statistics": map {
            "source-elements": count($source//*),
            "rdl-elements": count($result//*),
            "warnings": count($report//warning)
        }
    }
};

(:~
 : Build conversion report with details
 :)
declare function transform:build-report($source as element(), $result as element(), $validation as map(*)) as element() {
    <conversionReport timestamp="{current-dateTime()}">
        <source>
            <rootElement>{local-name($source)}</rootElement>
            <elementCount>{count($source//*) }</elementCount>
            <hasDataLoops>{exists($source//xsl:for-each)}</hasDataLoops>
            <hasConditionals>{exists($source//xsl:if | $source//xsl:choose)}</hasConditionals>
            <hasTables>{exists($source//fo:table)}</hasTables>
            <hasCharts>{exists($source//*[contains(local-name(), 'chart')])}</hasCharts>
        </source>
        <output>
            <elementCount>{count($result//*) }</elementCount>
            <valid>{$validation?valid}</valid>
        </output>
        <validation>
            {for $err in $validation?errors return <error>{$err}</error>}
        </validation>
    </conversionReport>
};
```

##### Expression Translation Module
```xquery
xquery version "3.1";

(:~
 : Translate XPath/XSLT expressions to SSRS VB.NET expressions
 :)
module namespace expr = "http://bip2ssrs.org/expressions";

(:~
 : Expression translation rules
 : Pattern → Replacement (with capture groups)
 :)
declare variable $expr:rules := (
    (: Field references :)
    map { "pattern": "^\./(\w+)$", "replacement": "=Fields!$1.Value" },
    map { "pattern": "^current\(\)/(\w+)$", "replacement": "=Fields!$1.Value" },
    map { "pattern": "^(\w+)$", "replacement": "=Fields!$1.Value" },
    
    (: Aggregate functions :)
    map { "pattern": "^sum\(\.?/?(\w+)\)$", "replacement": "=Sum(Fields!$1.Value)" },
    map { "pattern": "^count\(\.?/?(\w+)\)$", "replacement": "=Count(Fields!$1.Value)" },
    map { "pattern": "^avg\(\.?/?(\w+)\)$", "replacement": "=Avg(Fields!$1.Value)" },
    map { "pattern": "^min\(\.?/?(\w+)\)$", "replacement": "=Min(Fields!$1.Value)" },
    map { "pattern": "^max\(\.?/?(\w+)\)$", "replacement": "=Max(Fields!$1.Value)" },
    
    (: String functions :)
    map { "pattern": "^concat\((.+)\)$", "replacement": "=$1", "post": expr:translate-concat#1 },
    map { "pattern": "^substring\((\w+),\s*(\d+),\s*(\d+)\)$", 
          "replacement": "=Mid(Fields!$1.Value, $2, $3)" },
    map { "pattern": "^string-length\((\w+)\)$", "replacement": "=Len(Fields!$1.Value)" },
    
    (: Numeric formatting :)
    map { "pattern": "^format-number\((\w+),\s*'([^']+)'\)$", 
          "replacement": "=Format(Fields!$1.Value, \"$2\")" },
    
    (: Date functions :)
    map { "pattern": "^format-date\((\w+),\s*'([^']+)'\)$",
          "replacement": "=Format(Fields!$1.Value, \"$2\")" },
    
    (: Position / row number :)
    map { "pattern": "^position\(\)$", "replacement": "=RowNumber(Nothing)" }
);

(:~
 : Translate an XPath expression to SSRS VB expression
 :)
declare function expr:translate($xpath as xs:string) as xs:string {
    let $normalized := normalize-space($xpath)
    let $matched := 
        for $rule in $expr:rules
        where matches($normalized, $rule?pattern)
        return $rule
    return
        if (exists($matched)) then
            let $rule := $matched[1]
            let $result := replace($normalized, $rule?pattern, $rule?replacement)
            return
                if (exists($rule?post)) then
                    $rule?post($result)
                else
                    $result
        else
            (: Fallback: wrap in placeholder for manual review :)
            concat("="""" &amp; ""[REVIEW: ", $normalized, "]"" &amp; """"")
};

(:~
 : Post-process concat translations
 :)
declare function expr:translate-concat($partial as xs:string) as xs:string {
    (: Convert XPath concat args to VB string concatenation :)
    let $inner := substring-after(substring-before($partial, ')'), '(')
    let $parts := tokenize($inner, ',\s*')
    let $vb-parts := 
        for $part in $parts
        return
            if (matches($part, "^'[^']*'$")) then
                (: String literal :)
                concat('"', replace($part, "^'|'$", ""), '"')
            else
                (: Field reference :)
                concat("Fields!", normalize-space($part), ".Value")
    return "=" || string-join($vb-parts, " & ")
};
```

#### Master XSLT Transformation

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Master transformation: XSL-FO (BI Publisher) → RDL (SSRS)
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:bip="http://xmlns.oracle.com/oxp/xmlp"
    xmlns:rd="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition"
    xmlns:local="http://bip2ssrs.org/local"
    exclude-result-prefixes="fo xs bip local">

  <!-- Parameters from XQuery orchestration -->
  <xsl:param name="rdl-namespace" as="xs:string" 
             select="'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'"/>
  <xsl:param name="preserve-formatting" as="xs:boolean" select="true()"/>
  <xsl:param name="convert-charts" as="xs:boolean" select="true()"/>
  
  <!-- Import modular stylesheets -->
  <xsl:include href="fo-to-rdl/page-layout.xsl"/>
  <xsl:include href="fo-to-rdl/tables.xsl"/>
  <xsl:include href="fo-to-rdl/blocks.xsl"/>
  <xsl:include href="fo-to-rdl/graphics.xsl"/>
  <xsl:include href="fo-to-rdl/styles.xsl"/>
  <xsl:include href="xsl-logic/for-each.xsl"/>
  <xsl:include href="xsl-logic/conditionals.xsl"/>
  <xsl:include href="xsl-logic/expressions.xsl"/>
  
  <!-- Output configuration -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  
  <!-- Identity transform as fallback -->
  <xsl:mode on-no-match="shallow-skip"/>
  
  <!-- ============================================
       ROOT TEMPLATE
       ============================================ -->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- fo:root or xsl:stylesheet root → Report -->
  <xsl:template match="fo:root | xsl:stylesheet[.//fo:root]">
    <Report xmlns="{$rdl-namespace}">
      <xsl:call-template name="generate-report-id"/>
      
      <AutoRefresh>0</AutoRefresh>
      
      <!-- Data sources will be added from data model -->
      <DataSources/>
      
      <!-- Datasets derived from xsl:for-each bindings -->
      <DataSets>
        <xsl:call-template name="extract-datasets"/>
      </DataSets>
      
      <!-- Report body -->
      <xsl:apply-templates select=".//fo:page-sequence"/>
      
      <!-- Page configuration -->
      <xsl:call-template name="page-settings">
        <xsl:with-param name="layout-master" 
                        select=".//fo:simple-page-master[1]"/>
      </xsl:call-template>
    </Report>
  </xsl:template>
  
  <!-- ============================================
       PAGE SEQUENCE → BODY
       ============================================ -->
  <xsl:template match="fo:page-sequence">
    <Body>
      <ReportItems>
        <xsl:apply-templates select="fo:flow/*"/>
      </ReportItems>
      <xsl:call-template name="body-dimensions"/>
    </Body>
    
    <!-- Static content → Page Header/Footer -->
    <xsl:apply-templates select="fo:static-content[@flow-name='xsl-region-before']" 
                         mode="header"/>
    <xsl:apply-templates select="fo:static-content[@flow-name='xsl-region-after']" 
                         mode="footer"/>
  </xsl:template>
  
  <!-- ============================================
       HELPER TEMPLATES
       ============================================ -->
  
  <xsl:template name="generate-report-id">
    <xsl:attribute name="Name">
      <xsl:value-of select="'ConvertedReport_' || format-dateTime(current-dateTime(), '[Y0001][M01][D01]_[H01][m01][s01]')"/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template name="extract-datasets">
    <!-- Find all xsl:for-each and create corresponding datasets -->
    <xsl:for-each-group select=".//xsl:for-each" group-by="@select">
      <DataSet Name="{local:dataset-name(current-grouping-key())}">
        <Query>
          <DataSourceName>DataSource1</DataSourceName>
          <CommandText>
            <!-- Placeholder - actual query comes from data model -->
            <xsl:text>/* Query for: </xsl:text>
            <xsl:value-of select="current-grouping-key()"/>
            <xsl:text> */</xsl:text>
          </CommandText>
        </Query>
        <Fields>
          <xsl:call-template name="extract-fields">
            <xsl:with-param name="context" select="current-group()[1]"/>
          </xsl:call-template>
        </Fields>
      </DataSet>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template name="extract-fields">
    <xsl:param name="context"/>
    <!-- Extract field names from XPath expressions within the for-each -->
    <xsl:for-each-group select="$context//*[contains(., 'current()') or matches(., '^\./\w+$')]" 
                        group-by="local:extract-field-name(.)">
      <Field Name="{current-grouping-key()}">
        <DataField><xsl:value-of select="current-grouping-key()"/></DataField>
      </Field>
    </xsl:for-each-group>
  </xsl:template>
  
  <!-- ============================================
       UTILITY FUNCTIONS
       ============================================ -->
  
  <xsl:function name="local:dataset-name" as="xs:string">
    <xsl:param name="xpath" as="xs:string"/>
    <xsl:value-of select="replace(replace($xpath, '[^a-zA-Z0-9]', '_'), '^_+|_+$', '')"/>
  </xsl:function>
  
  <xsl:function name="local:extract-field-name" as="xs:string">
    <xsl:param name="expr"/>
    <xsl:analyze-string select="string($expr)" regex="current\(\)/(\w+)|^\./(\w+)$">
      <xsl:matching-substring>
        <xsl:value-of select="(regex-group(1), regex-group(2))[. != ''][1]"/>
      </xsl:matching-substring>
    </xsl:analyze-string>
  </xsl:function>
  
</xsl:stylesheet>
```

#### Table Conversion Module (fo-to-rdl/tables.xsl)

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rd="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition"
    xmlns:local="http://bip2ssrs.org/local"
    exclude-result-prefixes="fo xs local">

  <!-- fo:table → Tablix -->
  <xsl:template match="fo:table">
    <Tablix Name="Tablix_{generate-id()}">
      
      <!-- Determine data binding -->
      <xsl:variable name="data-source" select="ancestor::xsl:for-each[1]/@select"/>
      <xsl:if test="$data-source">
        <DataSetName><xsl:value-of select="local:dataset-name($data-source)"/></DataSetName>
      </xsl:if>
      
      <TablixBody>
        <!-- Columns -->
        <TablixColumns>
          <xsl:for-each select="fo:table-column">
            <TablixColumn>
              <Width><xsl:value-of select="local:convert-length(@column-width)"/></Width>
            </TablixColumn>
          </xsl:for-each>
          <!-- Fallback: count cells in first row -->
          <xsl:if test="not(fo:table-column)">
            <xsl:for-each select="(fo:table-header | fo:table-body)[1]/fo:table-row[1]/fo:table-cell">
              <TablixColumn>
                <Width>1in</Width>
              </TablixColumn>
            </xsl:for-each>
          </xsl:if>
        </TablixColumns>
        
        <!-- Rows -->
        <TablixRows>
          <!-- Header rows -->
          <xsl:apply-templates select="fo:table-header/fo:table-row" mode="tablix-header"/>
          <!-- Body rows -->
          <xsl:apply-templates select="fo:table-body/fo:table-row" mode="tablix-body"/>
        </TablixRows>
      </TablixBody>
      
      <!-- Column hierarchy (for grouping) -->
      <TablixColumnHierarchy>
        <TablixMembers>
          <xsl:for-each select="fo:table-column | (fo:table-header | fo:table-body)[1]/fo:table-row[1]/fo:table-cell">
            <TablixMember/>
          </xsl:for-each>
        </TablixMembers>
      </TablixColumnHierarchy>
      
      <!-- Row hierarchy -->
      <TablixRowHierarchy>
        <TablixMembers>
          <!-- Static header member -->
          <xsl:if test="fo:table-header">
            <TablixMember>
              <KeepWithGroup>After</KeepWithGroup>
            </TablixMember>
          </xsl:if>
          <!-- Detail/grouped rows -->
          <TablixMember>
            <xsl:if test="ancestor::xsl:for-each">
              <Group Name="DetailGroup_{generate-id()}"/>
            </xsl:if>
          </TablixMember>
        </TablixMembers>
      </TablixRowHierarchy>
      
    </Tablix>
  </xsl:template>
  
  <!-- Table row templates -->
  <xsl:template match="fo:table-row" mode="tablix-header tablix-body">
    <TablixRow>
      <Height><xsl:value-of select="local:convert-length((@height, '0.25in')[1])"/></Height>
      <TablixCells>
        <xsl:apply-templates select="fo:table-cell"/>
      </TablixCells>
    </TablixRow>
  </xsl:template>
  
  <!-- Table cell → TablixCell with Textbox -->
  <xsl:template match="fo:table-cell">
    <TablixCell>
      <CellContents>
        <Textbox Name="Textbox_{generate-id()}">
          <CanGrow>true</CanGrow>
          <Paragraphs>
            <Paragraph>
              <TextRuns>
                <TextRun>
                  <Value>
                    <xsl:apply-templates select="fo:block" mode="cell-content"/>
                  </Value>
                  <xsl:call-template name="text-style">
                    <xsl:with-param name="fo-element" select="fo:block"/>
                  </xsl:call-template>
                </TextRun>
              </TextRuns>
            </Paragraph>
          </Paragraphs>
          <xsl:call-template name="cell-style">
            <xsl:with-param name="fo-cell" select="."/>
          </xsl:call-template>
        </Textbox>
      </CellContents>
      <xsl:if test="@number-columns-spanned > 1">
        <ColSpan><xsl:value-of select="@number-columns-spanned"/></ColSpan>
      </xsl:if>
      <xsl:if test="@number-rows-spanned > 1">
        <RowSpan><xsl:value-of select="@number-rows-spanned"/></RowSpan>
      </xsl:if>
    </TablixCell>
  </xsl:template>
  
  <!-- Cell content: handle xsl:value-of, plain text, expressions -->
  <xsl:template match="fo:block" mode="cell-content">
    <xsl:choose>
      <xsl:when test="xsl:value-of">
        <xsl:call-template name="translate-expression">
          <xsl:with-param name="xpath" select="xsl:value-of/@select"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="normalize-space(.)">
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- Length conversion utility -->
  <xsl:function name="local:convert-length" as="xs:string">
    <xsl:param name="fo-length"/>
    <xsl:choose>
      <xsl:when test="ends-with($fo-length, 'pt')">
        <xsl:value-of select="concat(number(replace($fo-length, 'pt', '')) div 72, 'in')"/>
      </xsl:when>
      <xsl:when test="ends-with($fo-length, 'cm')">
        <xsl:value-of select="concat(number(replace($fo-length, 'cm', '')) * 0.3937, 'in')"/>
      </xsl:when>
      <xsl:when test="ends-with($fo-length, 'mm')">
        <xsl:value-of select="concat(number(replace($fo-length, 'mm', '')) * 0.03937, 'in')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$fo-length"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>
```

#### REST API Controller

```xquery
xquery version "3.1";

(:~
 : REST API controller for BIP-to-SSRS conversion
 :)
module namespace api = "http://bip2ssrs.org/api";

import module namespace transform = "http://bip2ssrs.org/transform";
import module namespace extract = "http://bip2ssrs.org/extract";
import module namespace config = "http://bip2ssrs.org/config";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : POST /api/convert
 : Convert a single BI Publisher file to SSRS RDL
 :)
declare
    %rest:POST
    %rest:path("/api/convert")
    %rest:consumes("multipart/form-data")
    %rest:form-param("file", "{$file}")
    %rest:form-param("options", "{$options}")
    %output:method("json")
function api:convert($file as map(*), $options as xs:string?) {
    try {
        let $filename := $file?filename
        let $content := $file?content
        
        (: Determine file type and extract XSL-FO :)
        let $xslfo := 
            if (ends-with($filename, '.xdo')) then
                extract:from-xdo($content)
            else if (ends-with($filename, '.xpt')) then
                extract:from-xpt($content)
            else if (ends-with($filename, '.xml') or ends-with($filename, '.xsl')) then
                parse-xml(util:binary-to-string($content))/*
            else
                error((), "Unsupported file type: " || $filename)
        
        (: Parse options :)
        let $opts := if ($options) then parse-json($options) else ()
        
        (: Execute conversion :)
        let $result := transform:convert($xslfo, (), $opts)
        
        return map {
            "success": true(),
            "filename": replace($filename, '\.[^.]+$', '.rdl'),
            "rdl": serialize($result?rdl),
            "valid": $result?valid,
            "statistics": $result?statistics,
            "warnings": array { $result?report//warning/string() }
        }
    } catch * {
        map {
            "success": false(),
            "error": $err:description,
            "code": $err:code
        }
    }
};

(:~
 : POST /api/batch
 : Batch convert multiple files
 :)
declare
    %rest:POST
    %rest:path("/api/batch")
    %rest:consumes("application/json")
    %output:method("json")
function api:batch($body as item()*) {
    let $request := parse-json(util:binary-to-string($body))
    let $files := $request?files
    
    return map {
        "jobId": util:uuid(),
        "totalFiles": array:size($files),
        "results": array {
            for $file at $i in $files?*
            return
                try {
                    let $content := util:binary-doc($file?path)
                    let $xslfo := extract:from-xdo($content)
                    let $result := transform:convert($xslfo, (), ())
                    return map {
                        "index": $i,
                        "source": $file?path,
                        "success": true(),
                        "valid": $result?valid
                    }
                } catch * {
                    map {
                        "index": $i,
                        "source": $file?path,
                        "success": false(),
                        "error": $err:description
                    }
                }
        }
    }
};

(:~
 : GET /api/health
 : Health check endpoint
 :)
declare
    %rest:GET
    %rest:path("/api/health")
    %output:method("json")
function api:health() {
    map {
        "status": "healthy",
        "version": "1.0.0",
        "existdb": system:get-version(),
        "xslt-modules-loaded": exists(doc($config:xslt-root || "/main-transform.xsl"))
    }
};
```

#### CLI Usage Example

```bash
# Start the environment
docker-compose up -d

# Wait for eXist-db to be ready
until curl -s http://localhost:8080/exist/rest/db > /dev/null; do
    echo "Waiting for eXist-db..."
    sleep 2
done

# Convert a single file
curl -X POST http://localhost:8080/exist/restxq/api/convert \
    -F "file=@invoice-report.xdo" \
    -F 'options={"validate-output": true}' \
    -o invoice-report.rdl

# Batch convert directory
curl -X POST http://localhost:8080/exist/restxq/api/batch \
    -H "Content-Type: application/json" \
    -d '{
        "files": [
            {"path": "/input/report1.xdo"},
            {"path": "/input/report2.xdo"},
            {"path": "/input/report3.xdo"}
        ]
    }'
```

#### Development Workflow

```powershell
# 1. Start containers
docker-compose up -d

# 2. Deploy app (first time only)
.\scripts\setup-existdb.ps1

# 3. Edit XSLT/XQuery in src/ locally, then sync to eXist-db
.\scripts\sync-to-existdb.ps1

# 4. Test via eXist-db's eXide IDE
# Open http://localhost:8088/exist/apps/eXide/

# 5. Test via web UI
# Open http://localhost:8088/exist/apps/bip2ssrs/

# 6. Build deployment package (XAR)
# PowerShell (see Appendix E for detailed instructions):
Compress-Archive -Path .\src\* -DestinationPath output\bip2ssrs-1.4.0.zip -Force
Move-Item output\bip2ssrs-1.4.0.zip output\bip2ssrs-1.4.0.xar -Force

# 7. Deploy to production
# Via Package Manager UI, or:
docker cp output\bip2ssrs-1.4.0.xar production-existdb:/exist/autodeploy/
```

---

### Option 2: .NET Core with XML Libraries

**Overview:** Traditional application using C#/.NET with specialized XML processing libraries.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    .NET Core Application                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      Core Services                         │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐    │  │
│  │  │  RtfPipe    │  │   System    │  │  RdlObjectModel │    │  │
│  │  │  (RTF→XML)  │  │  .Xml.Xsl   │  │   (RDL Gen)     │    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

#### Feasibility Assessment

| Factor | Rating | Analysis |
|--------|--------|----------|
| **XML-to-XML Transformation** | ★★★★☆ | Good support via System.Xml.Xsl, but more verbose than pure XSLT |
| **Expression Translation** | ★★★★★ | Full programming language - can build AST parsers, regex, etc. |
| **RTF Handling** | ★★★★☆ | Libraries like RtfPipe exist; full control over extraction |
| **Layout Preservation** | ★★★★☆ | Programmatic control enables precise layout mapping |
| **Debugging** | ★★★★★ | Full Visual Studio debugging experience |
| **Development Speed** | ★★★☆☆ | More boilerplate than XSLT, but familiar to most teams |

#### Pros
- Mature ecosystem and tooling
- Strong typing and compile-time checks
- Easy debugging and testing
- Can leverage existing SSRS libraries (RdlObjectModel)
- Team likely has .NET skills

#### Cons
- More code to write than XSLT approach
- XML manipulation is verbose in C#
- Requires managing object model mappings manually

---

### Option 3: Hybrid Approach (Recommended)

**Overview:** Combine eXist-db/XSLT for XML transformation with .NET for pre/post-processing and orchestration.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Conversion Pipeline                         │
│                                                                  │
│  ┌──────────────────┐                                           │
│  │   .NET Service   │ ◄─── CLI / API Entry Point                │
│  │   Orchestrator   │                                           │
│  └────────┬─────────┘                                           │
│           │                                                      │
│           ▼                                                      │
│  ┌──────────────────┐                                           │
│  │  Pre-Processing  │ ◄─── RTF→XML, XPT extraction (.NET)       │
│  │  (C# / Python)   │      Binary format handling               │
│  └────────┬─────────┘                                           │
│           │                                                      │
│           ▼                 ┌────────────────────────────────┐  │
│  ┌──────────────────┐      │     eXist-db Container          │  │
│  │   Normalized     │─────▶│  ┌────────────────────────────┐ │  │
│  │   XML Input      │      │  │  XSLT Transformation       │ │  │
│  └──────────────────┘      │  │  - Structure conversion    │ │  │
│                            │  │  - Element mapping         │ │  │
│           ┌────────────────│  │  - Basic expressions       │ │  │
│           │                │  └────────────────────────────┘ │  │
│           ▼                └────────────────────────────────┘  │
│  ┌──────────────────┐                                           │
│  │ Post-Processing  │ ◄─── Complex expression translation       │
│  │  (C# / Roslyn)   │      VB.NET code generation               │
│  └────────┬─────────┘      RDL validation                       │
│           │                                                      │
│           ▼                                                      │
│  ┌──────────────────┐                                           │
│  │   Final RDL      │                                           │
│  │   Output         │                                           │
│  └──────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

#### Responsibility Split

| Component | Technology | Responsibility |
|-----------|------------|----------------|
| **Orchestrator** | .NET 8 | Pipeline coordination, error handling, logging |
| **RTF Extractor** | C# (RtfPipe) | Extract XML tags from RTF templates |
| **XPT Parser** | C# | Unpack and parse XPT format |
| **XML Normalizer** | C# | Convert to common intermediate representation |
| **Structure Transform** | XSLT 3.0 (eXist-db) | BIP→RDL element mapping |
| **Expression Mapper** | XSLT 3.0 (eXist-db) | Simple expression patterns |
| **Complex Expressions** | C# (Parser) | XPath→VB.NET AST translation |
| **RDL Finalizer** | C# | Schema validation, packaging |

#### Feasibility Assessment

| Factor | Rating | Analysis |
|--------|--------|----------|
| **XML-to-XML Transformation** | ★★★★★ | Best of both worlds - XSLT for structure, C# for edge cases |
| **Expression Translation** | ★★★★★ | XSLT handles 80% of patterns; C# parser for complex cases |
| **RTF Handling** | ★★★★☆ | .NET handles binary formats well |
| **Layout Preservation** | ★★★★☆ | XSLT templates + C# post-processing |
| **Container Portability** | ★★★★★ | Docker Compose orchestrates both containers |
| **Development Speed** | ★★★★☆ | Parallel development possible |
| **Debugging** | ★★★★☆ | Mixed - C# parts easy, XSLT parts harder |
| **Maintainability** | ★★★★☆ | Clear separation of concerns |

#### Pros
- Leverages XSLT for what it does best (XML→XML)
- .NET handles non-XML formats and complex logic
- Clear separation of concerns
- Can optimize each layer independently
- Gradual migration: start with more .NET, migrate to XSLT as patterns emerge

#### Cons
- Two technology stacks to maintain
- Inter-container communication overhead
- More complex deployment

---

### Option 4: Python with lxml + Saxon

**Overview:** Python orchestration with Saxon-C for XSLT 3.0 processing.

#### Feasibility Assessment

| Factor | Rating | Analysis |
|--------|--------|----------|
| **XML Processing** | ★★★★☆ | lxml is excellent; Saxon-C provides XSLT 3.0 |
| **RTF Handling** | ★★★☆☆ | Libraries exist but less mature than .NET |
| **Development Speed** | ★★★★☆ | Python is rapid for prototyping |
| **Debugging** | ★★★★☆ | Good Python debugging; XSLT still challenging |

#### Pros
- Rapid prototyping
- Good for batch processing scripts
- lxml is very fast

#### Cons
- Saxon-C licensing costs for enterprise features
- Less mature RTF libraries
- Type safety concerns for large project

---

### Comparison Matrix

*Updated to reflect XSL-FO as source format*

| Criteria | Weight | eXist-db + XSLT | .NET Core | Hybrid | Python + Saxon |
|----------|--------|-----------------|-----------|--------|----------------|
| XML Transformation | 25% | 5 | 4 | 5 | 4 |
| Expression Handling | 20% | 4 | 5 | 5 | 4 |
| RTF/XSL-FO Processing | 15% | 4 | 4 | 4 | 3 |
| Development Speed | 15% | 5 | 3 | 4 | 4 |
| Debugging | 10% | 3 | 5 | 4 | 4 |
| Deployment | 10% | 5 | 4 | 4 | 4 |
| Team Skills | 5% | 2 | 5 | 4 | 3 |
| **Weighted Score** | 100% | **4.30** | **4.15** | **4.45** | **3.75** |

### Recommendation

Given that **BI Publisher uses XSL-FO internally**, the pure XSLT approach becomes significantly more viable. The recommendation depends on available expertise:

#### If XSLT/XQuery expertise is available: **Option 1 (eXist-db + XSLT)**

1. **XSL-FO → RDL is XSLT's sweet spot**: Both formats are XML. No impedance mismatch.
2. **Direct element mapping**: `fo:table` → `Tablix`, `fo:block` → `Textbox`, `xsl:for-each` → RowGroup.
3. **Bypass RTF entirely**: Use compiled `.xdo` files which contain XSL-FO directly.
4. **Faster iteration**: XSLT templates can be tested directly in eXist-db.
5. **Simpler architecture**: Single container, pure transformation pipeline.

#### If .NET expertise dominates: **Option 3 (Hybrid)**

1. **.NET handles orchestration and edge cases**: Complex expression parsing, validation.
2. **XSLT handles core transformation**: Structural mapping delegated to eXist-db.
3. **Fallback path**: Can handle RTF if .xdo files unavailable.

#### Source File Strategy

| Source Available | Recommended Approach |
|-----------------|---------------------|
| `.xdo` files (compiled XSL-FO) | Direct XSLT transformation — optimal path |
| `.xpt` templates | Extract embedded XSL-FO, then transform |
| `.rtf` templates only | Pre-process with .NET/Python to extract tags, or compile via BIP first |
| `.xdm` data models | Direct XML parsing (already XML) |

---

## Runtime Integration: SSRS + eXist-db REST API

An alternative architecture where SSRS consumes artifacts directly from eXist-db at runtime, rather than deploying converted RDL files to Report Server.

### Architecture Concept

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Runtime Integration Options                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Option A: Dynamic RDL Generation (On-Demand Conversion)            │
│  ┌─────────┐     ┌─────────────┐     ┌──────────────────────┐      │
│  │  User   │────▶│ SSRS Report │────▶│ eXist-db REST API    │      │
│  │ Request │     │ Server      │     │ /api/convert?report= │      │
│  └─────────┘     └─────────────┘     └──────────────────────┘      │
│                         │                       │                    │
│                         │◀──────── RDL ────────┘                    │
│                         ▼                                            │
│                  Render Report                                       │
│                                                                      │
│  Option B: XML Data Source (eXist-db serves data)                   │
│  ┌─────────┐     ┌─────────────┐     ┌──────────────────────┐      │
│  │  User   │────▶│ SSRS Report │────▶│ eXist-db REST API    │      │
│  │ Request │     │ (Static RDL)│     │ /data/report.xml     │      │
│  └─────────┘     └─────────────┘     └──────────────────────┘      │
│                         │                       │                    │
│                         │◀──────── XML Data ───┘                    │
│                         ▼                                            │
│                  Render with data                                    │
│                                                                      │
│  Option C: Custom Data Extension (Deep Integration)                 │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ SSRS with Custom Data Processing Extension                   │   │
│  │ ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐   │   │
│  │ │ Report      │──│ eXist-db     │──│ XQuery Execution  │   │   │
│  │ │ Definition  │  │ Data Provider│  │ via REST          │   │   │
│  │ └─────────────┘  └──────────────┘  └───────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Option A: Dynamic RDL Generation

**Concept:** SSRS fetches the RDL definition from eXist-db on each request. eXist-db performs conversion on-demand.

#### Feasibility: ⚠️ Not Directly Supported

SSRS does not natively support fetching RDL from an HTTP endpoint. RDL files must be:
- Deployed to the Report Server catalog
- Stored as `.rdl` files on the file system (Report Builder)

**Workarounds:**

```powershell
# 1. Scheduled sync: Pull RDL from eXist-db and deploy to SSRS
# sync-reports.ps1 (run as scheduled task)

$existUrl = "http://existdb:8080/exist/restxq/api/reports"
$reports = Invoke-RestMethod -Uri $existUrl

foreach ($report in $reports) {
    # Fetch converted RDL
    $rdl = Invoke-RestMethod -Uri "$existUrl/$($report.name)/rdl"
    
    # Deploy to SSRS
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($rdl)
    $proxy.CreateCatalogItem("Report", $report.name, "/Converted", $true, $bytes, $null, [ref]$null)
}
```

```csharp
// 2. Custom ReportServer extension (advanced)
// Intercept report requests and fetch from eXist-db
// Requires deep SSRS customization - not recommended
```

**Verdict:** Not practical for runtime RDL fetching. Use batch sync instead.

---

### Option B: XML Data Source from eXist-db (✅ Viable)

**Concept:** Deploy static RDL to SSRS, but the report's data source points to eXist-db REST API. eXist-db returns XML data that SSRS consumes.

#### How It Works

```
┌─────────────┐                ┌─────────────┐                ┌─────────────┐
│   SSRS      │   1. Execute   │   Report    │   2. Fetch    │  eXist-db   │
│   Report    │───────────────▶│   with XML  │───────────────▶│  REST API   │
│   Server    │                │   DataSource│                │             │
└─────────────┘                └─────────────┘                └─────────────┘
                                      │                              │
                                      │◀───────── XML Data ─────────┘
                                      │
                                      ▼
                               Render report with
                               eXist-db sourced data
```

#### RDL Configuration for XML Data Source

```xml
<Report xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
  <DataSources>
    <DataSource Name="ExistDbSource">
      <ConnectionProperties>
        <!-- Use XML data provider -->
        <DataProvider>XML</DataProvider>
        <ConnectString>http://existdb:8080/exist/restxq/data/invoice</ConnectString>
      </ConnectionProperties>
    </DataSource>
  </DataSources>
  
  <DataSets>
    <DataSet Name="InvoiceData">
      <Query>
        <DataSourceName>ExistDbSource</DataSourceName>
        <!-- XPath query within the XML response -->
        <CommandText>/Report/Invoice</CommandText>
      </Query>
      <Fields>
        <Field Name="InvoiceNumber">
          <DataField>InvoiceNumber</DataField>
        </Field>
        <Field Name="CustomerName">
          <DataField>Customer/Name</DataField>
        </Field>
        <!-- ... more fields -->
      </Fields>
    </DataSet>
  </DataSets>
  
  <!-- Rest of report definition -->
</Report>
```

#### eXist-db Data Endpoint

```xquery
xquery version "3.1";

(:~
 : Serve report data as XML for SSRS consumption
 :)
module namespace data = "http://bip2ssrs.org/data";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : GET /data/{report-name}
 : Returns XML data for a specific report
 :)
declare
    %rest:GET
    %rest:path("/data/{$report-name}")
    %rest:query-param("startDate", "{$start-date}")
    %rest:query-param("endDate", "{$end-date}")
    %rest:query-param("customerId", "{$customer-id}")
    %output:method("xml")
    %output:media-type("application/xml")
function data:get-report-data(
    $report-name as xs:string,
    $start-date as xs:string?,
    $end-date as xs:string?,
    $customer-id as xs:string?
) {
    (: Route to appropriate data query based on report :)
    switch ($report-name)
        case "invoice" return data:invoice-data($customer-id)
        case "sales-summary" return data:sales-data($start-date, $end-date)
        case "employee-list" return data:employee-data()
        default return <error>Unknown report: {$report-name}</error>
};

(:~
 : Invoice data query
 :)
declare function data:invoice-data($customer-id as xs:string?) {
    <Report>
        {
            for $invoice in collection("/db/data/invoices")/invoice
            where empty($customer-id) or $invoice/customer-id = $customer-id
            order by $invoice/date descending
            return
                <Invoice>
                    <InvoiceNumber>{$invoice/number/text()}</InvoiceNumber>
                    <InvoiceDate>{$invoice/date/text()}</InvoiceDate>
                    <Customer>
                        <Name>{$invoice/customer/name/text()}</Name>
                        <Address>{$invoice/customer/address/text()}</Address>
                    </Customer>
                    <Items>
                        {
                            for $item in $invoice/items/item
                            return
                                <Item>
                                    <Description>{$item/description/text()}</Description>
                                    <Quantity>{$item/quantity/text()}</Quantity>
                                    <UnitPrice>{$item/unit-price/text()}</UnitPrice>
                                    <Total>{$item/quantity * $item/unit-price}</Total>
                                </Item>
                        }
                    </Items>
                    <Subtotal>{sum($invoice/items/item/(quantity * unit-price))}</Subtotal>
                    <Tax>{sum($invoice/items/item/(quantity * unit-price)) * 0.1}</Tax>
                    <GrandTotal>{sum($invoice/items/item/(quantity * unit-price)) * 1.1}</GrandTotal>
                </Invoice>
        }
    </Report>
};
```

#### Passing Parameters from SSRS to eXist-db

```xml
<DataSet Name="InvoiceData">
  <Query>
    <DataSourceName>ExistDbSource</DataSourceName>
    <!-- Parameters appended to URL -->
    <CommandText>
      http://existdb:8080/exist/restxq/data/invoice?customerId=@CustomerId&amp;startDate=@StartDate
    </CommandText>
  </Query>
</DataSet>

<ReportParameters>
  <ReportParameter Name="CustomerId">
    <DataType>String</DataType>
    <Prompt>Customer ID</Prompt>
  </ReportParameter>
  <ReportParameter Name="StartDate">
    <DataType>DateTime</DataType>
    <Prompt>Start Date</Prompt>
  </ReportParameter>
</ReportParameters>
```

#### Pros & Cons

| Pros | Cons |
|------|------|
| ✅ Single source of truth in eXist-db | ❌ Requires network call per report execution |
| ✅ XQuery handles complex data transformations | ❌ XML data provider has limitations |
| ✅ Easy to update data logic without redeploying RDL | ❌ No connection pooling like SQL |
| ✅ Can return pre-aggregated data | ❌ May not support all SSRS features |
| ✅ Works with existing eXist-db infrastructure | ❌ Authentication between SSRS→eXist-db needed |

---

### Option C: Custom Data Processing Extension (✅ Most Powerful)

**Concept:** Build a custom SSRS Data Processing Extension that connects directly to eXist-db and executes XQuery.

#### Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                      SSRS Report Server                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Data Processing Layer                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐   │  │
│  │  │ SQL Server  │  │   Oracle    │  │  eXist-db Custom    │   │  │
│  │  │ Provider    │  │   Provider  │  │  Data Extension     │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘   │  │
│  │                                             │                  │  │
│  └─────────────────────────────────────────────│──────────────────┘  │
│                                                │                     │
└────────────────────────────────────────────────│─────────────────────┘
                                                 │
                                                 ▼
                                    ┌────────────────────┐
                                    │    eXist-db        │
                                    │    REST API        │
                                    │    XQuery Engine   │
                                    └────────────────────┘
```

#### Implementation Skeleton (C#)

```csharp
// ExistDbDataExtension/ExistDbConnection.cs
using Microsoft.ReportingServices.DataProcessing;
using System.Net.Http;
using System.Xml.Linq;

namespace ExistDbDataExtension
{
    public class ExistDbConnection : IDbConnection
    {
        private string _connectionString;
        private HttpClient _httpClient;
        
        public string ConnectionString 
        { 
            get => _connectionString;
            set => _connectionString = value;
        }
        
        // Connection string format:
        // "Server=http://existdb:8080;Database=/db/apps/data;User=admin;Password=xxx"
        
        public void Open()
        {
            var parts = ParseConnectionString(_connectionString);
            _httpClient = new HttpClient();
            _httpClient.BaseAddress = new Uri(parts["Server"]);
            
            // Set basic auth if provided
            if (parts.ContainsKey("User"))
            {
                var auth = Convert.ToBase64String(
                    Encoding.ASCII.GetBytes($"{parts["User"]}:{parts["Password"]}"));
                _httpClient.DefaultRequestHeaders.Authorization = 
                    new AuthenticationHeaderValue("Basic", auth);
            }
        }
        
        public void Close() => _httpClient?.Dispose();
        
        public IDbCommand CreateCommand() => new ExistDbCommand(this);
        
        internal async Task<XDocument> ExecuteXQueryAsync(string xquery)
        {
            var content = new StringContent(xquery, Encoding.UTF8, "application/xquery");
            var response = await _httpClient.PostAsync("/exist/rest/db", content);
            response.EnsureSuccessStatusCode();
            
            var xml = await response.Content.ReadAsStringAsync();
            return XDocument.Parse(xml);
        }
    }
    
    public class ExistDbCommand : IDbCommand
    {
        private ExistDbConnection _connection;
        private string _commandText;
        private ExistDbParameterCollection _parameters = new();
        
        public ExistDbCommand(ExistDbConnection connection)
        {
            _connection = connection;
        }
        
        public string CommandText 
        { 
            get => _commandText;
            set => _commandText = value;
        }
        
        public IDataParameterCollection Parameters => _parameters;
        
        public IDataReader ExecuteReader(CommandBehavior behavior)
        {
            // Substitute parameters into XQuery
            var xquery = SubstituteParameters(_commandText, _parameters);
            
            // Execute against eXist-db
            var result = _connection.ExecuteXQueryAsync(xquery).Result;
            
            // Return data reader over XML result
            return new ExistDbDataReader(result);
        }
        
        private string SubstituteParameters(string xquery, ExistDbParameterCollection parameters)
        {
            foreach (ExistDbParameter param in parameters)
            {
                var placeholder = $"${param.ParameterName}";
                var value = param.Value?.ToString() ?? "";
                xquery = xquery.Replace(placeholder, $"'{value}'");
            }
            return xquery;
        }
    }
    
    public class ExistDbDataReader : IDataReader
    {
        private XDocument _document;
        private IEnumerator<XElement> _rows;
        private XElement _currentRow;
        private string[] _fieldNames;
        
        public ExistDbDataReader(XDocument document)
        {
            _document = document;
            // Assume first child elements are "rows"
            var root = _document.Root;
            var firstRow = root.Elements().FirstOrDefault();
            
            if (firstRow != null)
            {
                _fieldNames = firstRow.Elements().Select(e => e.Name.LocalName).ToArray();
                _rows = root.Elements().GetEnumerator();
            }
        }
        
        public int FieldCount => _fieldNames?.Length ?? 0;
        
        public string GetName(int i) => _fieldNames[i];
        
        public object GetValue(int i)
        {
            var fieldName = _fieldNames[i];
            return _currentRow.Element(fieldName)?.Value;
        }
        
        public bool Read()
        {
            if (_rows.MoveNext())
            {
                _currentRow = _rows.Current;
                return true;
            }
            return false;
        }
        
        // ... implement other IDataReader members
    }
}
```

#### Registration in SSRS

```xml
<!-- rsreportserver.config -->
<Configuration>
  <Extensions>
    <Data>
      <Extension Name="EXISTDB" 
                 Type="ExistDbDataExtension.ExistDbConnection, ExistDbDataExtension"/>
    </Data>
  </Extensions>
</Configuration>
```

#### Usage in RDL

```xml
<DataSource Name="ExistDbSource">
  <ConnectionProperties>
    <DataProvider>EXISTDB</DataProvider>
    <ConnectString>Server=http://existdb:8080;Database=/db/data;User=admin;Password=admin</ConnectString>
  </ConnectionProperties>
</DataSource>

<DataSet Name="InvoiceData">
  <Query>
    <DataSourceName>ExistDbSource</DataSourceName>
    <!-- CommandText contains XQuery! -->
    <CommandText>
      for $inv in collection('/db/data/invoices')/invoice
      where $inv/date >= $StartDate and $inv/date <= $EndDate
      return $inv
    </CommandText>
  </Query>
</DataSet>
```

#### Pros & Cons

| Pros | Cons |
|------|------|
| ✅ Native SSRS integration | ❌ Requires custom extension development |
| ✅ Full XQuery power in CommandText | ❌ Must deploy DLL to Report Server |
| ✅ Parameters work naturally | ❌ Maintenance burden |
| ✅ Appears as normal data source | ❌ Debugging is harder |
| ✅ Can use SSRS designer features | ❌ SSRS version-specific builds |

---

### Recommendation Summary

| Approach | Effort | Runtime Integration | Best For |
|----------|--------|--------------------|---------| 
| **Batch Sync** (convert → deploy) | Low | ❌ No | Most scenarios |
| **XML Data Source** | Medium | ✅ Yes | Dynamic data, simple reports |
| **Custom Extension** | High | ✅ Yes | Enterprise, XQuery-centric shops |

**For most use cases:** Convert once, deploy RDL to SSRS, done. Runtime integration adds complexity without proportional benefit.

**If you need live eXist-db data:** Use XML data source with REST endpoints. It's supported out-of-the-box and requires no custom code.

**If you're all-in on XQuery:** Custom data extension lets you write XQuery directly in report datasets, but it's a significant investment.

---

## Preferred Solution: Unified eXist-db + SSRS Platform

A single Docker Compose deployment that combines eXist-db (conversion + data) with SSRS (rendering) into one integrated reporting platform.

### Purpose & Goals

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PRIMARY GOAL                                    │
│                                                                              │
│   ╔═══════════════════════════════════════════════════════════════════════╗ │
│   ║  CONVERSION: Produce standalone RDL files that can be deployed to     ║ │
│   ║              any production SSRS instance WITHOUT eXist-db            ║ │
│   ╚═══════════════════════════════════════════════════════════════════════╝ │
│                                                                              │
│                             SECONDARY GOAL                                   │
│                                                                              │
│   ┌───────────────────────────────────────────────────────────────────────┐ │
│   │  QA/TESTING: Live integration with SSRS allows immediate validation  │ │
│   │              of converted reports using mock or real data             │ │
│   └───────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**The ultimate deliverable is converted RDL files**, not a runtime platform. The integrated SSRS container serves as a **QA environment** to:

1. **Validate conversions immediately** — See if the converted RDL renders correctly
2. **Test with mock data** — Verify layout/formatting without production data
3. **Catch errors early** — Identify expression translation issues before production
4. **Preview before deploy** — QA team can review reports in a real SSRS instance

Once validated, the RDL files are exported and deployed to production SSRS (which uses real SQL/Oracle data sources, not eXist-db).

### Workflow: Conversion → QA → Production

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   DEVELOPMENT/QA ENVIRONMENT                    PRODUCTION                  │
│   (This Docker Compose)                         (Your existing SSRS)        │
│                                                                              │
│   ┌─────────┐      ┌─────────────┐                                          │
│   │  BIP    │─────▶│  eXist-db   │                                          │
│   │ Sources │      │  Converter  │                                          │
│   │.xdm/.xsl│      └──────┬──────┘                                          │
│   └─────────┘             │                                                 │
│                           │ Convert                                         │
│                           ▼                                                 │
│                    ┌─────────────┐       ┌─────────────────────────────┐   │
│                    │    RDL      │──────▶│  QA: Deploy to test SSRS   │   │
│                    │   Files     │       │  (with mock/test data)     │   │
│                    └──────┬──────┘       └─────────────────────────────┘   │
│                           │                           │                     │
│                           │                           │ Validate            │
│                           │                           ▼                     │
│                           │                    ┌─────────────┐              │
│                           │                    │  QA Signs   │              │
│                           │                    │    Off      │              │
│                           │                    └──────┬──────┘              │
│                           │                           │                     │
│   ════════════════════════╪═══════════════════════════╪═════════════════   │
│                           │                           │                     │
│                           │         EXPORT            │                     │
│                           │◀──────────────────────────┘                     │
│                           │                                                 │
│                           ▼                                                 │
│                    ┌─────────────┐      ┌──────────────────────────────┐   │
│                    │ Production  │─────▶│  Production SSRS             │   │
│                    │    RDL      │      │  (SQL Server data sources)   │   │
│                    │  (modified  │      │  No eXist-db dependency      │   │
│                    │ data source)│      └──────────────────────────────┘   │
│                    └─────────────┘                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Production deployment requires:**
- Replace XML data source with production SQL/Oracle connection
- Update parameter bindings if needed
- Deploy to production SSRS catalog

### Solution Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    BIP-to-SSRS Unified Platform                              │
│                       (Single Docker Compose)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   INPUTS                    PROCESSING                    OUTPUTS           │
│   ┌─────────┐              ┌─────────────────────────────────────────────┐  │
│   │  .xdm   │─────────────▶│              eXist-db Container             │  │
│   │  .xsl-fo│              │  ┌─────────────────────────────────────────┐│  │
│   │  (data) │              │  │  1. Store XDM + XSL-FO templates       ││  │
│   └─────────┘              │  │  2. Convert XSL-FO → RDL on upload     ││  │
│                            │  │  3. Serve data via REST (from XDM      ││  │
│                            │  │     or mock data when source missing)  ││  │
│                            │  │  4. Deploy RDL to SSRS via API         ││  │
│                            │  └─────────────────────────────────────────┘│  │
│                            │                     │                       │  │
│                            │                     │ REST API              │  │
│                            │                     ▼                       │  │
│                            │  ┌─────────────────────────────────────────┐│  │
│                            └──│           Internal Network              │┘  │
│                               │  existdb ◄────────────► ssrs            │   │
│                               └─────────────────────────────────────────┘   │
│                                              │                               │
│                            ┌─────────────────┴───────────────────────────┐  │
│                            │            SSRS Container                    │  │
│                            │  ┌─────────────────────────────────────────┐│  │
│                            │  │  1. Host converted RDL reports         ││  │
│                            │  │  2. Fetch live data from eXist-db      ││  │
│                            │  │  3. Render PDF/Excel/HTML on demand    ││  │
│                            │  └─────────────────────────────────────────┘│  │
│                            └─────────────────────────────────────────────┘  │
│                                              │                               │
│                                              ▼                               │
│                            ┌─────────────────────────────────────────────┐  │
│                            │  Report Viewer (Web Portal)                 │  │
│                            │  http://localhost:8080/reports              │  │
│                            └─────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Input Artifacts

| Artifact | Description | Required |
|----------|-------------|----------|
| `.xdm` | BI Publisher Data Model - defines data structure, queries, parameters | ✅ Yes |
| `.xsl-fo` / `.xdo` | Compiled XSL-FO template (or extracted from XPT) | ✅ Yes |
| Source Data | Actual data (XML, database, etc.) | ⚠️ Optional |

**When source data is unavailable:** eXist-db generates mock/sample data based on the XDM schema for testing and preview.

### Architecture Components

```yaml
# docker-compose.yml - Complete Platform
version: '3.8'

services:
  # ═══════════════════════════════════════════════════════════════
  # eXist-db: Conversion Engine + Data Server
  # ═══════════════════════════════════════════════════════════════
  existdb:
    image: existdb/existdb:6.2.0
    container_name: bip2ssrs-existdb
    ports:
      - "8081:8080"           # eXist-db web UI + REST API
    volumes:
      - existdb-data:/exist/data
      - ./existdb/autodeploy:/exist/autodeploy
      - ./input:/input:ro     # Mount input XDM/XSL-FO files
      - ./src:/exist/src:ro   # Application source
    environment:
      - EXIST_ENV=production
      - JAVA_OPTS=-Xms512m -Xmx2g
      # Internal SSRS connection
      - SSRS_INTERNAL_URL=http://ssrs/ReportServer
      - SSRS_DEPLOY_USER=admin
      - SSRS_DEPLOY_PASSWORD=admin
    networks:
      - bip2ssrs-net
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/exist/rest/db"]
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped

  # ═══════════════════════════════════════════════════════════════
  # SQL Server: Required database backend for SSRS
  # ═══════════════════════════════════════════════════════════════
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: bip2ssrs-sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=${SQL_SA_PASSWORD:-YourStrong!Passw0rd}
      - MSSQL_PID=Express
    volumes:
      - sqlserver-data:/var/opt/mssql
    networks:
      - bip2ssrs-net
    healthcheck:
      test: /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$${SA_PASSWORD}" -Q "SELECT 1" -C
      interval: 10s
      timeout: 5s
      retries: 10
    restart: unless-stopped

  # ═══════════════════════════════════════════════════════════════
  # SSRS: Report Server (Windows Container)
  # ═══════════════════════════════════════════════════════════════
  ssrs:
    build:
      context: ./docker/ssrs
      dockerfile: Dockerfile
    container_name: bip2ssrs-ssrs
    ports:
      - "8080:80"             # SSRS Web Portal
      - "8443:443"            # SSRS HTTPS (optional)
    environment:
      - SQL_SERVER=sqlserver
      - SQL_SA_PASSWORD=${SQL_SA_PASSWORD:-YourStrong!Passw0rd}
      - SSRS_ADMIN_USER=admin
      - SSRS_ADMIN_PASSWORD=admin
      # Allow XML data sources to external URLs
      - ENABLE_EXTERNAL_DATA=true
    volumes:
      - ssrs-data:/var/opt/ssrs
      - ./output:/reports:ro  # Converted RDL files
    networks:
      - bip2ssrs-net
    depends_on:
      sqlserver:
        condition: service_healthy
    # Note: SSRS requires Windows containers on Windows hosts
    # For Linux hosts, use ReportServer alternatives or hybrid setup
    restart: unless-stopped

  # ═══════════════════════════════════════════════════════════════
  # Web Portal: Unified UI for upload, convert, preview
  # ═══════════════════════════════════════════════════════════════
  portal:
    build:
      context: ./docker/portal
      dockerfile: Dockerfile
    container_name: bip2ssrs-portal
    ports:
      - "3000:3000"           # Web UI
    environment:
      - EXISTDB_URL=http://existdb:8080
      - SSRS_URL=http://ssrs/Reports
    networks:
      - bip2ssrs-net
    depends_on:
      - existdb
      - ssrs
    restart: unless-stopped

networks:
  bip2ssrs-net:
    driver: bridge

volumes:
  existdb-data:
  sqlserver-data:
  ssrs-data:
```

### SSRS Container (Windows)

```dockerfile
# docker/ssrs/Dockerfile
# Note: SSRS requires Windows Server Core
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Install SSRS
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Download and install SSRS
RUN Invoke-WebRequest -Uri 'https://download.microsoft.com/download/...' \
    -OutFile 'SQLServerReportingServices.exe' ; \
    Start-Process -FilePath 'SQLServerReportingServices.exe' \
    -ArgumentList '/quiet', '/IAcceptLicenseTerms', '/Edition=Developer' \
    -Wait ; \
    Remove-Item 'SQLServerReportingServices.exe'

# Configure SSRS
COPY configure-ssrs.ps1 /
RUN /configure-ssrs.ps1

# Enable XML data sources (critical for eXist-db integration)
COPY rsreportserver.config /Program\ Files/Microsoft\ SQL\ Server\ Reporting\ Services/SSRS/ReportServer/

EXPOSE 80 443

ENTRYPOINT ["powershell", "-File", "/start-ssrs.ps1"]
```

```powershell
# docker/ssrs/configure-ssrs.ps1
# Configure SSRS to connect to SQL Server and enable features

param(
    [string]$SqlServer = $env:SQL_SERVER,
    [string]$SaPassword = $env:SQL_SA_PASSWORD
)

# Wait for SQL Server
do {
    Start-Sleep -Seconds 5
    $result = sqlcmd -S $SqlServer -U sa -P $SaPassword -Q "SELECT 1" 2>&1
} while ($LASTEXITCODE -ne 0)

# Initialize SSRS databases
$rsConfig = Get-WmiObject -Namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v15\Admin" `
    -Class "MSReportServer_ConfigurationSetting"

# Create ReportServer database
$rsConfig.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script | 
    sqlcmd -S $SqlServer -U sa -P $SaPassword

# Set database connection
$rsConfig.SetDatabaseConnection($SqlServer, "ReportServer", 2, "", "")

# Set service URLs
$rsConfig.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
$rsConfig.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
$rsConfig.ReserveURL("ReportServerWebService", "http://+:80", 1033)
$rsConfig.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

# Initialize
$rsConfig.InitializeReportServer($rsConfig.InstallationID)

Write-Host "SSRS configured successfully"
```

### eXist-db Application Structure

```
existdb/
├── autodeploy/
│   └── bip2ssrs-platform.xar     # Main application package
│
└── src/
    ├── collection.xconf
    ├── expath-pkg.xml
    │
    ├── modules/
    │   ├── config.xqm              # Configuration
    │   ├── xdm-parser.xqm          # Parse .xdm data models
    │   ├── xslfo-converter.xqm     # XSL-FO → RDL conversion
    │   ├── data-generator.xqm      # Generate mock data from XDM
    │   ├── data-server.xqm         # Serve data via REST
    │   ├── ssrs-deployer.xqm       # Deploy RDL to SSRS
    │   └── workflow.xqm            # Orchestrate upload→convert→deploy
    │
    ├── xslt/
    │   ├── xslfo-to-rdl.xsl        # Main transformation
    │   ├── xdm-to-dataset.xsl      # Data model → RDL DataSet
    │   └── ... (other modules)
    │
    └── api/
        ├── upload.xql              # Upload XDM/XSL-FO
        ├── convert.xql             # Trigger conversion
        ├── deploy.xql              # Deploy to SSRS
        ├── data.xql                # Data endpoint for SSRS
        └── status.xql              # Conversion status
```

### Core XQuery Modules

#### XDM Parser - Extract Data Structure

```xquery
xquery version "3.1";

(:~
 : Parse BI Publisher .xdm data model files
 : Extracts data structure, queries, parameters for RDL generation
 :)
module namespace xdm = "http://bip2ssrs.org/xdm";

declare namespace dm = "http://xmlns.oracle.com/oxp/xmlp";

(:~
 : Parse XDM and extract metadata
 :)
declare function xdm:parse($xdm-doc as document-node()) as map(*) {
    let $root := $xdm-doc/dm:dataModel
    return map {
        "name": string($root/@name),
        "description": string($root/dm:description),
        
        "dataSets": array {
            for $ds in $root//dm:dataSet
            return map {
                "name": string($ds/@name),
                "source": string($ds/dm:source/@type),  (: SQL, XML, etc :)
                "query": string($ds/dm:sql),
                "fields": array {
                    for $field in $ds//dm:element
                    return map {
                        "name": string($field/@name),
                        "type": string($field/@dataType),
                        "nullable": string($field/@nullable) = "true"
                    }
                }
            }
        },
        
        "parameters": array {
            for $param in $root//dm:parameter
            return map {
                "name": string($param/@name),
                "type": string($param/@dataType),
                "required": string($param/@required) = "true",
                "defaultValue": string($param/dm:defaultValue),
                "lov": string($param/dm:lovQuery)
            }
        },
        
        "structure": xdm:extract-structure($root//dm:output/dm:element)
    }
};

(:~
 : Extract hierarchical data structure for mock data generation
 :)
declare function xdm:extract-structure($elements as element()*) as array(*) {
    array {
        for $el in $elements
        return map {
            "name": string($el/@name),
            "type": string($el/@dataType),
            "maxOccurs": (string($el/@maxOccurs), "1")[1],
            "children": 
                if ($el/dm:element) then
                    xdm:extract-structure($el/dm:element)
                else
                    array {}
        }
    }
};
```

#### Data Generator - Mock Data When Source Unavailable

```xquery
xquery version "3.1";

(:~
 : Generate mock/sample data from XDM structure
 : Used when actual source data is not available
 :)
module namespace datagen = "http://bip2ssrs.org/datagen";

import module namespace xdm = "http://bip2ssrs.org/xdm";

(:~
 : Generate sample data based on XDM structure
 :)
declare function datagen:generate($xdm-meta as map(*), $options as map(*)?) as element() {
    let $row-count := ($options?rowCount, 10)[1]
    let $structure := $xdm-meta?structure
    
    return
        <Report>
            {datagen:generate-elements($structure, $row-count)}
        </Report>
};

(:~
 : Recursively generate elements
 :)
declare function datagen:generate-elements($structure as array(*), $count as xs:integer) as element()* {
    for $field in $structure?*
    let $max-occurs := $field?maxOccurs
    let $repeat := 
        if ($max-occurs = "unbounded") then $count
        else xs:integer(($max-occurs, 1)[1])
    return
        for $i in 1 to $repeat
        return
            element { $field?name } {
                if (array:size($field?children) > 0) then
                    datagen:generate-elements($field?children, $count)
                else
                    datagen:sample-value($field?name, $field?type, $i)
            }
};

(:~
 : Generate sample value based on field name and type
 :)
declare function datagen:sample-value($name as xs:string, $type as xs:string?, $index as xs:integer) as xs:string {
    let $name-lower := lower-case($name)
    return
        (: Smart generation based on field name patterns :)
        if (contains($name-lower, "date")) then
            format-date(current-date() - xs:dayTimeDuration("P" || $index || "D"), "[Y0001]-[M01]-[D01]")
        else if (contains($name-lower, "email")) then
            concat("user", $index, "@example.com")
        else if (contains($name-lower, "phone")) then
            concat("555-", format-number($index * 111, "0000"))
        else if (contains($name-lower, "amount") or contains($name-lower, "price") or contains($name-lower, "total")) then
            format-number(random-number-generator()?next() * 1000, "#0.00")
        else if (contains($name-lower, "quantity") or contains($name-lower, "count")) then
            string(($index mod 10) + 1)
        else if (contains($name-lower, "id") or contains($name-lower, "number")) then
            concat(upper-case(substring($name, 1, 3)), "-", format-number($index, "0000"))
        else if (contains($name-lower, "name")) then
            ("Acme Corp", "Globex", "Initech", "Umbrella", "Wayne Enterprises")[$index mod 5 + 1]
        else if (contains($name-lower, "address")) then
            concat($index * 100, " Main Street")
        else if (contains($name-lower, "city")) then
            ("New York", "Los Angeles", "Chicago", "Houston", "Phoenix")[$index mod 5 + 1]
        else if ($type = "xs:decimal" or $type = "NUMBER") then
            format-number($index * 10.5, "#0.00")
        else if ($type = "xs:integer" or $type = "INTEGER") then
            string($index * 10)
        else if ($type = "xs:boolean" or $type = "BOOLEAN") then
            string($index mod 2 = 0)
        else
            concat("Sample ", $name, " ", $index)
};

(:~
 : Use actual data if available, otherwise generate mock
 :)
declare function datagen:get-data($report-id as xs:string, $xdm-meta as map(*)) as element() {
    let $data-path := concat("/db/data/", $report-id, ".xml")
    return
        if (doc-available($data-path)) then
            doc($data-path)/*
        else
            (: No source data - generate mock :)
            datagen:generate($xdm-meta, map { "rowCount": 10 })
};
```

#### Data Server - REST Endpoint for SSRS

```xquery
xquery version "3.1";

(:~
 : Serve report data to SSRS via REST
 : SSRS XML data source points to these endpoints
 :)
module namespace data = "http://bip2ssrs.org/data";

import module namespace xdm = "http://bip2ssrs.org/xdm";
import module namespace datagen = "http://bip2ssrs.org/datagen";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : GET /data/{report-id}
 : Main data endpoint for SSRS to consume
 :)
declare
    %rest:GET
    %rest:path("/data/{$report-id}")
    %rest:query-param("_params", "{$params}")
    %output:method("xml")
    %output:media-type("application/xml")
function data:get-report-data($report-id as xs:string, $params as xs:string?) as element() {
    
    (: Load XDM metadata :)
    let $xdm-path := concat("/db/reports/", $report-id, "/model.xdm")
    let $xdm-doc := doc($xdm-path)
    let $xdm-meta := xdm:parse($xdm-doc)
    
    (: Parse incoming parameters :)
    let $param-map := 
        if ($params) then
            map:merge(
                for $p in tokenize($params, "&amp;")
                let $parts := tokenize($p, "=")
                return map { $parts[1]: $parts[2] }
            )
        else
            map {}
    
    (: Try to get real data, fall back to mock :)
    let $data := datagen:get-data($report-id, $xdm-meta)
    
    (: Apply parameter filters if any :)
    let $filtered := data:apply-filters($data, $param-map, $xdm-meta)
    
    return $filtered
};

(:~
 : Apply parameter-based filtering
 :)
declare function data:apply-filters($data as element(), $params as map(*), $xdm-meta as map(*)) as element() {
    (: For each parameter, filter the data accordingly :)
    let $param-defs := $xdm-meta?parameters
    return
        element { node-name($data) } {
            $data/@*,
            for $child in $data/*
            where data:matches-filters($child, $params, $param-defs)
            return $child
        }
};

declare function data:matches-filters($element as element(), $params as map(*), $param-defs as array(*)) as xs:boolean {
    every $param-name in map:keys($params)
    satisfies
        let $param-value := $params($param-name)
        let $param-def := array:filter($param-defs, function($p) { $p?name = $param-name })
        return
            (: Simple equality filter - expand as needed :)
            if (array:size($param-def) > 0) then
                let $field-name := $param-name
                let $element-value := $element//*[local-name() = $field-name]/string()
                return empty($element-value) or $element-value = $param-value
            else
                true()
};

(:~
 : GET /data/{report-id}/schema
 : Returns XSD schema for the data (helps SSRS designer)
 :)
declare
    %rest:GET
    %rest:path("/data/{$report-id}/schema")
    %output:method("xml")
function data:get-schema($report-id as xs:string) as element() {
    let $xdm-path := concat("/db/reports/", $report-id, "/model.xdm")
    let $xdm-doc := doc($xdm-path)
    let $xdm-meta := xdm:parse($xdm-doc)
    
    return data:generate-xsd($xdm-meta)
};

declare function data:generate-xsd($meta as map(*)) as element() {
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="Report">
            <xs:complexType>
                <xs:sequence>
                    {data:structure-to-xsd($meta?structure)}
                </xs:sequence>
            </xs:complexType>
        </xs:element>
    </xs:schema>
};
```

#### SSRS Deployer - Push RDL to Report Server

```xquery
xquery version "3.1";

(:~
 : Deploy converted RDL to SSRS Report Server
 :)
module namespace deploy = "http://bip2ssrs.org/deploy";

import module namespace http = "http://expath.org/ns/http-client";
import module namespace config = "http://bip2ssrs.org/config";

(:~
 : Deploy RDL to SSRS
 :)
declare function deploy:to-ssrs($report-id as xs:string, $rdl as element()) as map(*) {
    let $ssrs-url := $config:ssrs-internal-url
    let $soap-url := $ssrs-url || "/ReportService2010.asmx"
    
    (: Build SOAP request for CreateCatalogItem :)
    let $rdl-bytes := util:string-to-binary(serialize($rdl), "UTF-8")
    let $rdl-base64 := util:binary-to-string(xs:base64Binary($rdl-bytes))
    
    let $soap-body :=
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
            <soap:Body>
                <CreateCatalogItem xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">
                    <ItemType>Report</ItemType>
                    <Name>{$report-id}</Name>
                    <Parent>/Converted</Parent>
                    <Overwrite>true</Overwrite>
                    <Definition>{$rdl-base64}</Definition>
                    <Properties/>
                </CreateCatalogItem>
            </soap:Body>
        </soap:Envelope>
    
    (: Send to SSRS :)
    let $response := http:send-request(
        <http:request method="POST" href="{$soap-url}">
            <http:header name="Content-Type" value="text/xml; charset=utf-8"/>
            <http:header name="SOAPAction" 
                         value="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer/CreateCatalogItem"/>
            <http:body media-type="text/xml">{$soap-body}</http:body>
        </http:request>
    )
    
    return
        if ($response[1]/@status = "200") then
            map { 
                "success": true(),
                "reportUrl": $config:ssrs-portal-url || "/report/Converted/" || $report-id
            }
        else
            map { 
                "success": false(), 
                "error": string($response[2]) 
            }
};

(:~
 : Create folder in SSRS if not exists
 :)
declare function deploy:ensure-folder($folder-path as xs:string) as xs:boolean {
    let $ssrs-url := $config:ssrs-internal-url || "/ReportService2010.asmx"
    
    let $soap-body :=
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
            <soap:Body>
                <CreateFolder xmlns="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer">
                    <Folder>{tokenize($folder-path, '/')[last()]}</Folder>
                    <Parent>{string-join(tokenize($folder-path, '/')[position() < last()], '/')}</Parent>
                </CreateFolder>
            </soap:Body>
        </soap:Envelope>
    
    let $response := http:send-request(
        <http:request method="POST" href="{$ssrs-url}">
            <http:header name="Content-Type" value="text/xml; charset=utf-8"/>
            <http:header name="SOAPAction" 
                         value="http://schemas.microsoft.com/sqlserver/reporting/2010/03/01/ReportServer/CreateFolder"/>
            <http:body media-type="text/xml">{$soap-body}</http:body>
        </http:request>
    )
    
    return $response[1]/@status = ("200", "400")  (: 400 = already exists :)
};
```

#### Workflow - Complete Upload→Convert→Deploy Pipeline

```xquery
xquery version "3.1";

(:~
 : Main workflow orchestration
 :)
module namespace workflow = "http://bip2ssrs.org/workflow";

import module namespace xdm = "http://bip2ssrs.org/xdm";
import module namespace transform = "http://bip2ssrs.org/transform";
import module namespace deploy = "http://bip2ssrs.org/deploy";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : POST /workflow/process
 : Complete pipeline: upload → convert → deploy
 :)
declare
    %rest:POST
    %rest:path("/workflow/process")
    %rest:consumes("multipart/form-data")
    %rest:form-param("xdm", "{$xdm-file}")
    %rest:form-param("xslfo", "{$xslfo-file}")
    %rest:form-param("data", "{$data-file}")  
    %rest:form-param("reportId", "{$report-id}")
    %output:method("json")
function workflow:process(
    $xdm-file as map(*)?,
    $xslfo-file as map(*),
    $data-file as map(*)?,
    $report-id as xs:string
) as map(*) {
    try {
        let $start-time := util:system-time()
        
        (: 1. Store uploaded files :)
        let $report-path := "/db/reports/" || $report-id
        let $_ := xmldb:create-collection("/db/reports", $report-id)
        
        let $xdm-doc := 
            if (exists($xdm-file)) then
                let $content := util:binary-to-string($xdm-file?content)
                let $doc := parse-xml($content)
                let $_ := xmldb:store($report-path, "model.xdm", $doc)
                return $doc
            else ()
        
        let $xslfo-doc := 
            let $content := util:binary-to-string($xslfo-file?content)
            let $doc := parse-xml($content)
            let $_ := xmldb:store($report-path, "template.xsl", $doc)
            return $doc
        
        (: Store source data if provided :)
        let $_ :=
            if (exists($data-file)) then
                let $content := util:binary-to-string($data-file?content)
                let $doc := parse-xml($content)
                return xmldb:store("/db/data", $report-id || ".xml", $doc)
            else ()
        
        (: 2. Parse XDM for metadata :)
        let $xdm-meta := 
            if (exists($xdm-doc)) then 
                xdm:parse($xdm-doc) 
            else 
                map {}
        
        (: 3. Convert XSL-FO → RDL :)
        let $rdl-result := transform:convert(
            $xslfo-doc/*,
            $xdm-meta,
            map {
                (: Point data source to eXist-db REST endpoint :)
                "dataSourceUrl": "http://existdb:8080/exist/restxq/data/" || $report-id,
                "dataSourceType": "XML"
            }
        )
        
        (: Store converted RDL :)
        let $_ := xmldb:store($report-path, "report.rdl", $rdl-result?rdl)
        
        (: 4. Deploy to SSRS :)
        let $deploy-result := deploy:to-ssrs($report-id, $rdl-result?rdl)
        
        let $end-time := util:system-time()
        
        return map {
            "success": $deploy-result?success,
            "reportId": $report-id,
            "rdlValid": $rdl-result?valid,
            "deployedTo": $deploy-result?reportUrl,
            "dataEndpoint": "http://localhost:8081/exist/restxq/data/" || $report-id,
            "previewUrl": "http://localhost:8080/Reports/report/Converted/" || $report-id,
            "processingTime": string($end-time - $start-time),
            "warnings": array { $rdl-result?report//warning/string() },
            "hasSourceData": exists($data-file)
        }
        
    } catch * {
        map {
            "success": false(),
            "error": $err:description,
            "code": string($err:code)
        }
    }
};

(:~
 : GET /workflow/status/{report-id}
 : Check status of a processed report
 :)
declare
    %rest:GET
    %rest:path("/workflow/status/{$report-id}")
    %output:method("json")
function workflow:status($report-id as xs:string) as map(*) {
    let $report-path := "/db/reports/" || $report-id
    return
        if (xmldb:collection-available($report-path)) then
            map {
                "exists": true(),
                "hasXdm": doc-available($report-path || "/model.xdm"),
                "hasTemplate": doc-available($report-path || "/template.xsl"),
                "hasRdl": doc-available($report-path || "/report.rdl"),
                "hasData": doc-available("/db/data/" || $report-id || ".xml")
            }
        else
            map { "exists": false() }
};
```

### RDL Template with eXist-db Data Source

The converter generates RDL that points to eXist-db for data:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Report xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
  <Description>Converted from BI Publisher</Description>
  
  <!-- Data source pointing to eXist-db REST API -->
  <DataSources>
    <DataSource Name="ExistDbData">
      <ConnectionProperties>
        <DataProvider>XML</DataProvider>
        <!-- Internal Docker network URL -->
        <ConnectString>http://existdb:8080/exist/restxq/data/{{REPORT_ID}}</ConnectString>
      </ConnectionProperties>
    </DataSource>
  </DataSources>
  
  <!-- Dataset using XML data from eXist-db -->
  <DataSets>
    <DataSet Name="MainData">
      <Query>
        <DataSourceName>ExistDbData</DataSourceName>
        <!-- XPath to select rows from XML response -->
        <CommandText>/Report/*[1]</CommandText>
      </Query>
      <Fields>
        <!-- Fields extracted from XDM -->
        {{FIELDS}}
      </Fields>
    </DataSet>
  </DataSets>
  
  <!-- Report parameters pass through to eXist-db -->
  <ReportParameters>
    {{PARAMETERS}}
  </ReportParameters>
  
  <!-- Converted layout from XSL-FO -->
  <Body>
    {{BODY_CONTENT}}
  </Body>
  
</Report>
```

### Web Portal (Simple Upload UI)

```html
<!-- docker/portal/index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>BIP-to-SSRS Converter</title>
    <style>
        body { font-family: -apple-system, sans-serif; max-width: 800px; margin: 50px auto; }
        .upload-zone { border: 2px dashed #ccc; padding: 40px; text-align: center; margin: 20px 0; }
        .upload-zone.dragover { background: #e3f2fd; border-color: #2196F3; }
        input[type="file"] { margin: 10px 0; }
        button { background: #2196F3; color: white; padding: 10px 20px; border: none; cursor: pointer; }
        .result { margin-top: 20px; padding: 20px; background: #f5f5f5; }
        .success { border-left: 4px solid #4CAF50; }
        .error { border-left: 4px solid #f44336; }
    </style>
</head>
<body>
    <h1>BIP-to-SSRS Converter</h1>
    
    <form id="uploadForm">
        <div class="upload-zone" id="dropZone">
            <h3>Upload BI Publisher Files</h3>
            
            <div>
                <label>XDM (Data Model) - Optional:</label><br>
                <input type="file" name="xdm" accept=".xdm,.xml">
            </div>
            
            <div>
                <label>XSL-FO Template (Required):</label><br>
                <input type="file" name="xslfo" accept=".xsl,.xslfo,.xdo,.fo" required>
            </div>
            
            <div>
                <label>Source Data (Optional):</label><br>
                <input type="file" name="data" accept=".xml">
            </div>
            
            <div>
                <label>Report ID:</label><br>
                <input type="text" name="reportId" placeholder="my-report" required>
            </div>
            
            <button type="submit">Convert & Deploy</button>
        </div>
    </form>
    
    <div id="result" class="result" style="display:none;"></div>
    
    <script>
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const formData = new FormData(e.target);
            const resultDiv = document.getElementById('result');
            
            resultDiv.innerHTML = 'Processing...';
            resultDiv.style.display = 'block';
            resultDiv.className = 'result';
            
            try {
                const response = await fetch('http://localhost:8081/exist/restxq/workflow/process', {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.success) {
                    resultDiv.className = 'result success';
                    resultDiv.innerHTML = `
                        <h3>✓ Conversion Successful</h3>
                        <p><strong>Report ID:</strong> ${result.reportId}</p>
                        <p><strong>Preview:</strong> <a href="${result.previewUrl}" target="_blank">Open in SSRS</a></p>
                        <p><strong>Data Endpoint:</strong> <a href="${result.dataEndpoint}" target="_blank">${result.dataEndpoint}</a></p>
                        <p><strong>Has Source Data:</strong> ${result.hasSourceData ? 'Yes' : 'No (using mock data)'}</p>
                        <p><strong>Processing Time:</strong> ${result.processingTime}</p>
                        ${result.warnings.length > 0 ? 
                            '<p><strong>Warnings:</strong><br>' + result.warnings.join('<br>') + '</p>' : ''}
                    `;
                } else {
                    resultDiv.className = 'result error';
                    resultDiv.innerHTML = `
                        <h3>✗ Conversion Failed</h3>
                        <p><strong>Error:</strong> ${result.error}</p>
                    `;
                }
            } catch (err) {
                resultDiv.className = 'result error';
                resultDiv.innerHTML = `<h3>✗ Error</h3><p>${err.message}</p>`;
            }
        });
    </script>
</body>
</html>
```

### Usage Workflow

```bash
# 1. Start the platform
docker-compose up -d

# 2. Wait for all services to be ready
docker-compose logs -f  # Watch for "SSRS configured successfully"

# 3. Open the web portal
# http://localhost:3000

# 4. Upload your files:
#    - invoice.xdm (data model)
#    - invoice.xsl-fo (template)
#    - (optionally) invoice-data.xml

# 5. Click "Convert & Deploy"

# 6. View the report:
#    http://localhost:8080/Reports/report/Converted/invoice

# --- Or via CLI ---

# Upload and convert via curl
curl -X POST http://localhost:8081/exist/restxq/workflow/process \
    -F "xdm=@invoice.xdm" \
    -F "xslfo=@invoice.xsl-fo" \
    -F "data=@sample-data.xml" \
    -F "reportId=invoice"

# Check data endpoint (SSRS will use this)
curl http://localhost:8081/exist/restxq/data/invoice

# View in SSRS
open http://localhost:8080/Reports/report/Converted/invoice
```

### Data Flow at Runtime

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         Report Execution Flow                               │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. User requests report from SSRS                                          │
│     http://localhost:8080/Reports/report/Converted/invoice?StartDate=...   │
│                                                                             │
│  2. SSRS loads RDL from catalog                                             │
│     ┌─────────────┐                                                         │
│     │    SSRS     │                                                         │
│     │   Report    │                                                         │
│     │   Server    │                                                         │
│     └──────┬──────┘                                                         │
│            │                                                                │
│  3. RDL specifies XML data source: http://existdb:8080/exist/restxq/data/invoice
│            │                                                                │
│            ▼                                                                │
│     ┌──────────────┐                                                        │
│     │   eXist-db   │                                                        │
│     │              │                                                        │
│     │  Has actual  │──── YES ──▶ Return actual data                        │
│     │    data?     │                                                        │
│     │              │──── NO ───▶ Generate mock data from XDM               │
│     └──────┬───────┘                                                        │
│            │                                                                │
│            ▼                                                                │
│     ┌──────────────┐                                                        │
│     │  XML Data    │                                                        │
│     │  <Report>    │                                                        │
│     │   <Invoice>  │                                                        │
│     │    ...       │                                                        │
│     └──────┬───────┘                                                        │
│            │                                                                │
│            ▼                                                                │
│  4. SSRS receives XML, binds to RDL, renders output                        │
│     ┌─────────────┐                                                         │
│     │   PDF/      │                                                         │
│     │   Excel/    │                                                         │
│     │   HTML      │                                                         │
│     └─────────────┘                                                         │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### Key Benefits of This Architecture

| Benefit | Description |
|---------|-------------|
| **Conversion-focused** | Primary output is standalone RDL files for production SSRS |
| **Integrated QA** | Test converted reports immediately without manual deployment |
| **Mock data fallback** | Validate layout/formatting even without source data |
| **Fast iteration** | Convert → Test → Fix → Repeat in one environment |
| **Single deployment** | One `docker-compose up` starts everything |
| **Portable** | Works on any Docker host |
| **No production dependency** | Exported RDL works in any SSRS instance |

### Output Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| **RDL Files** | `/db/reports/{id}/report.rdl` | Primary deliverable — deploy to production SSRS |
| **Conversion Report** | `/db/reports/{id}/conversion-report.xml` | QA documentation of conversion issues |
| **Data Model** | `/db/reports/{id}/model.xdm` | Reference for production data source setup |

#### Exporting RDL for Production

```bash
# Export converted RDL via REST
curl -o invoice.rdl "http://localhost:8081/exist/rest/db/reports/invoice/report.rdl"

# Or via the portal UI: Download button on each converted report

# The exported RDL contains:
# - Complete report layout
# - Placeholder data source (needs update for production)
# - All expressions converted to VB.NET
# - SSRS-compatible formatting
```

#### Production Data Source Update

Before deploying to production, update the data source in the RDL:

```xml
<!-- QA version (points to eXist-db) -->
<DataSource Name="ExistDbData">
  <ConnectionProperties>
    <DataProvider>XML</DataProvider>
    <ConnectString>http://existdb:8080/exist/restxq/data/invoice</ConnectString>
  </ConnectionProperties>
</DataSource>

<!-- Production version (points to SQL Server) -->
<DataSource Name="ProductionData">
  <ConnectionProperties>
    <DataProvider>SQL</DataProvider>
    <ConnectString>Data Source=prod-sql;Initial Catalog=ReportDB;</ConnectString>
  </ConnectionProperties>
</DataSource>
```

### Platform Endpoints Summary

| Endpoint | URL | Purpose |
|----------|-----|---------|
| **Portal UI** | http://localhost:3000 | Upload/convert web interface |
| **eXist-db UI** | http://localhost:8081 | eXist-db admin, XQuery IDE |
| **eXist-db REST** | http://localhost:8081/exist/restxq/... | API endpoints |
| **SSRS Portal** | http://localhost:8080/Reports | Report viewer, management |
| **SSRS Web Service** | http://localhost:8080/ReportServer | SOAP API |

### Limitations & Considerations

| Issue | Mitigation |
|-------|------------|
| **SSRS requires Windows** | Use Windows Docker host or hybrid setup |
| **Cold start time** | SQL Server + SSRS take 1-2 minutes to initialize |
| **No SQL data sources** | XML data source only; no direct Oracle/SQL queries |
| **Memory usage** | Minimum 8GB RAM for all containers |

### Licensing Requirements

#### Summary

| Component | License | Cost for Dev/Test | Cost for Production |
|-----------|---------|-------------------|---------------------|
| **eXist-db** | LGPL 2.1 | ✅ Free | ✅ Free |
| **Docker Engine** | Apache 2.0 | ✅ Free | ✅ Free |
| **Docker Desktop** | Commercial | ⚠️ Free (<250 employees) | ⚠️ Subscription for large orgs |
| **SQL Server Developer** | Microsoft EULA | ✅ Free | ❌ Not permitted |
| **SQL Server Express** | Microsoft EULA | ✅ Free | ✅ Free (limited) |
| **SQL Server Standard/Enterprise** | Commercial | ❌ Paid | ⚠️ Per-core licensing |
| **SSRS** | Included with SQL Server | (see SQL Server) | (see SQL Server) |

#### Component Details

##### eXist-db — ✅ Free (Open Source)

- **License:** LGPL 2.1 (GNU Lesser General Public License)
- **Cost:** Free for all uses including commercial
- **Restrictions:** None for this use case. LGPL allows use in proprietary systems.
- **Source:** https://exist-db.org

##### Docker — ✅ Free / ⚠️ Depends

| Product | License | Notes |
|---------|---------|-------|
| **Docker Engine (Linux)** | Apache 2.0 | Always free |
| **Docker Compose** | Apache 2.0 | Always free |
| **Docker Desktop** | Commercial | Free for: small businesses (<250 employees AND <$10M revenue), personal use, education, open source. **Paid subscription required** for larger organizations. |

**Recommendation:** On Windows Server, use Docker Engine directly (not Docker Desktop) if licensing is a concern, or use Linux VMs.

##### SQL Server Express — ✅ Free (Official Container Available)

SQL Server Express is the backend database for SSRS in this tool:

| Component | License | Container Image |
|-----------|---------|----------------|
| **SQL Server Express** | Free | `mcr.microsoft.com/mssql/server:2022-latest` |
| **SSRS** | Included with SQL Server Express | N/A (bundled) |

**Express Edition Specifications:**
- **Cost:** Free for all uses (dev, test, and production)
- **Database limit:** 10GB per database (sufficient for QA/testing)
- **RAM limit:** 1GB (adequate for validation workloads)
- **Cores:** 4 cores max
- **SSRS:** Full SSRS functionality included

**Official Microsoft Container:**
```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - MSSQL_PID=Express    # Use Express Edition
      - SA_PASSWORD=YourStrong!Passw0rd
```

The `MSSQL_PID=Express` environment variable configures the container to run SQL Server Express (free) rather than Developer or Evaluation editions.

**No separate SSRS license is required** — SSRS is included with SQL Server Express.

#### Production Deployment (After Conversion)

The **converted RDL files** can be deployed to any SSRS instance your organization already has licensed. The conversion tool's licensing is separate from production SSRS licensing.

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        LICENSING SCOPE                                      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   THIS TOOL (Dev/QA)                      YOUR PRODUCTION SSRS             │
│   ┌─────────────────────┐                 ┌─────────────────────┐          │
│   │ eXist-db: Free      │                 │ SQL Server: Your    │          │
│   │ SQL Express: Free   │    RDL Files    │ existing license     │          │
│   │ SSRS: Free          │ ──────────────▶ │ SSRS: Included       │          │
│   │ Docker: Free*       │                 │                      │          │
│   └─────────────────────┘                 └─────────────────────┘          │
│         * Docker Desktop: Free for <250 employees or <$10M revenue          │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Recommended Configuration

**All users (no licensing cost):**
- Use SQL Server Express Edition via official Microsoft container
- SSRS is included with Express at no additional cost
- Container: `mcr.microsoft.com/mssql/server:2022-latest` with `MSSQL_PID=Express`

**For open-source preference (avoid Microsoft licensing entirely):**
- Use eXist-db for conversion only (no SSRS container)
- Export RDL files and validate manually in Report Builder
- Or use schema validation (Layer 1 testing) which requires no SSRS

#### License Compliance Checklist

| Question | Answer |
|----------|--------|
| Is SQL Server Express free? | ✅ Yes — Free for all uses including production |
| Is SSRS included with Express? | ✅ Yes — Full SSRS functionality included |
| Are the converted RDL files licensed? | N/A — RDL is just XML, no license required |
| Does production SSRS need additional licensing? | No — Use your existing SSRS license |

---

## Conversion Mapping

### Template Elements

| BI Publisher Element | SSRS Equivalent | Notes |
|---------------------|-----------------|-------|
| `<?for-each:?>` | Tablix/List with dataset grouping | Loop constructs |
| `<?if:?>..<?end if?>` | Visibility expression | Conditional display |
| `<?choose?><?when?><?otherwise?>` | Switch expression | Multi-condition logic |
| `<?xdoxslt:variable?>` | Report variable | Variable declaration |
| `<?call-template?>` | Subreport | Template invocation |
| Form Fields | Textbox with expression | Data placeholders |
| Repeating Groups | Tablix row groups | Data iteration |
| Cross-tabs | Matrix (Tablix) | Pivot tables |

### Expression Translation

| BI Publisher (XPath/XSL) | SSRS (VB Expression) |
|--------------------------|---------------------|
| `current()` | `=Fields!FieldName.Value` |
| `sum(./AMOUNT)` | `=Sum(Fields!AMOUNT.Value)` |
| `count(./ITEM)` | `=Count(Fields!ITEM.Value)` |
| `format-number(., '#,##0.00')` | `=Format(Fields!Field.Value, "#,##0.00")` |
| `concat(FIRST, ' ', LAST)` | `=Fields!FIRST.Value & " " & Fields!LAST.Value` |
| `substring(., 1, 10)` | `=Left(Fields!Field.Value, 10)` |
| `translate(., 'abc', 'ABC')` | `=UCase(Fields!Field.Value)` |
| `position()` | `=RowNumber(Nothing)` |
| `../PARENT_FIELD` | `=Fields!PARENT_FIELD.Value` (with scope) |

### Formatting Conversion

| BI Publisher Format | SSRS Format |
|--------------------|-------------|
| Font specifications | TextStyle properties |
| Paragraph alignment | TextAlign property |
| Cell borders | BorderStyle, BorderWidth, BorderColor |
| Background colors | BackgroundColor property |
| Number masks | Format property |
| Date formats | Format property with date patterns |
| Conditional formatting | Expression-based styling |

### Chart Mapping

| BI Publisher Chart Type | SSRS Chart Type |
|------------------------|-----------------|
| Vertical Bar | Column |
| Horizontal Bar | Bar |
| Line | Line |
| Pie | Pie |
| Combination | Multiple chart types overlaid |
| Gauge | Gauge |
| Scatter | Scatter |

---

## Data Source Handling

### Connection String Conversion

```xml
<!-- BI Publisher Connection -->
<connection>
  <jdbc>
    <driver>oracle.jdbc.OracleDriver</driver>
    <url>jdbc:oracle:thin:@host:1521:SID</url>
    <username>user</username>
  </jdbc>
</connection>

<!-- Converted SSRS Connection -->
<DataSource Name="OracleDS">
  <ConnectionProperties>
    <DataProvider>OLEDB</DataProvider>
    <ConnectString>
      Provider=OraOLEDB.Oracle;Data Source=host:1521/SID;
    </ConnectString>
  </ConnectionProperties>
</DataSource>
```

### Query Conversion

| Aspect | BI Publisher | SSRS |
|--------|-------------|------|
| Query Language | SQL (Oracle dialect) | SQL (T-SQL or native) |
| Parameters | `:param_name` | `@param_name` |
| Functions | Oracle-specific | Provider-specific or generic |
| Bind Variables | Automatic | Explicit parameter mapping |

### Parameter Handling

| BI Publisher Parameter | SSRS Parameter |
|-----------------------|----------------|
| Text parameter | Text datatype |
| Date parameter | DateTime datatype |
| Number parameter | Integer/Float datatype |
| LOV (List of Values) | Available Values from Dataset |
| Multi-select | MultiValue = true |
| Cascading parameters | Dataset with dependencies |

---

## Template Conversion

### RTF Template Processing

1. **Document Parsing**
   - Extract document structure using RTF parser
   - Identify BI Publisher tags within document
   - Parse embedded XML processing instructions

2. **Layout Analysis**
   - Determine page dimensions and margins
   - Identify header/footer regions
   - Map table structures and column widths

3. **Content Extraction**
   - Extract static text content
   - Identify dynamic field placeholders
   - Parse conditional regions
   - Extract embedded images

### XPT Template Processing

1. **XML Extraction**
   - Parse XPT container format
   - Extract layout definition XML
   - Extract associated resources

2. **Component Mapping**
   - Map XPT components to RDL report items
   - Convert positioning (absolute to relative)
   - Handle component grouping

### Layout Transformation Rules

```
┌─────────────────────────────────────┐
│ BI Publisher Page                   │
│ ┌─────────────────────────────────┐ │
│ │ Header (repeating)              │ │
│ ├─────────────────────────────────┤ │
│ │ Body                            │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ Table with for-each         │ │ │
│ │ └─────────────────────────────┘ │ │
│ ├─────────────────────────────────┤ │
│ │ Footer (repeating)              │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ SSRS Report                         │
│ ┌─────────────────────────────────┐ │
│ │ PageHeader                      │ │
│ ├─────────────────────────────────┤ │
│ │ Body                            │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ Tablix with DataSet binding │ │ │
│ │ └─────────────────────────────┘ │ │
│ ├─────────────────────────────────┤ │
│ │ PageFooter                      │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Output Formats

### Generated Artifacts

| Artifact | Format | Description |
|----------|--------|-------------|
| Report Definition | .rdl | Main report file in RDL XML format |
| Shared Data Source | .rds | Reusable connection definition |
| Shared Dataset | .rsd | Reusable query definition |
| Embedded Resources | Base64 in RDL | Images, fonts embedded in report |
| Conversion Log | .json / .txt | Detailed conversion output |
| Migration Report | .html | Human-readable summary |

### RDL Output Structure

```xml
<?xml version="1.0" encoding="utf-8"?>
<Report xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
  <DataSources>
    <DataSource Name="DataSource1">
      <!-- Connection properties -->
    </DataSource>
  </DataSources>
  <DataSets>
    <DataSet Name="DataSet1">
      <!-- Query and fields -->
    </DataSet>
  </DataSets>
  <ReportParameters>
    <!-- Converted parameters -->
  </ReportParameters>
  <Body>
    <ReportItems>
      <!-- Converted layout elements -->
    </ReportItems>
  </Body>
  <Page>
    <PageHeader><!-- Header content --></PageHeader>
    <PageFooter><!-- Footer content --></PageFooter>
  </Page>
</Report>
```

---

## Error Handling

### Error Categories

| Category | Severity | Handling |
|----------|----------|----------|
| Parse Error | Critical | Abort conversion, log details |
| Unsupported Feature | Warning | Skip element, document in log |
| Expression Translation | Warning | Generate placeholder, flag for review |
| Resource Missing | Warning | Log missing resource, continue |
| Layout Approximation | Info | Convert with best effort, note differences |

### Error Reporting

```json
{
  "conversionId": "uuid",
  "timestamp": "2026-02-19T10:30:00Z",
  "sourceFile": "report.rtf",
  "status": "CompletedWithWarnings",
  "errors": [
    {
      "code": "EXPR-001",
      "severity": "Warning",
      "message": "XPath expression not directly translatable",
      "source": "<?xdoxslt:custom_func()?>",
      "location": "Line 45",
      "suggestion": "Manual review required for custom function"
    }
  ],
  "statistics": {
    "elementsProcessed": 150,
    "elementsConverted": 145,
    "warningsGenerated": 5,
    "errorsGenerated": 0
  }
}
```

---

## Limitations

### Design Constraints

| Constraint | Rationale | See Also |
|------------|-----------|----------|
| No hardcoded element names | Converter must not rely on specific table, row, or field names (e.g., `CUSTOMER_ROW`, `SEGMENT_NAME`) to ensure scalability across arbitrary reports | [Design Constraint: No Hardcoded Element Names](#design-constraint-no-hardcoded-element-names) |
| XDM-driven logic preferred | Structural rules should be derived from XDM metadata, not inferred from synthetic test data | [BIP vs SSRS Data Model Architecture](#bip-vs-ssrs-data-model-architecture) |
| **SQL query compatibility** | The SQL query in the converted RDL must use identical column names as the XDA data source. The transformer uses only leaf element names from hierarchical XPaths (e.g., `/INVOICE/CUSTOMER/ADDRESS` → `ADDRESS`) to ensure field names match typical SQL column names. **Warning:** This may cause collisions if the same leaf name appears in different paths; in such cases, SQL queries should use aliases with unique names. | — |

### Current Scope Assumptions

The following assumptions simplify the initial implementation scope:

| Assumption | Implication | Future Enhancement |
|------------|-------------|-------------------|
| **Embedded connection string** | Production connection string is embedded in the SSRS test data file via `<ssrs-config><DataSource>` XML element. Preview RDL uses localhost SQL Server; production RDL uses the config-specified connection. | Shared data source references, JNDI lookup |
| **No report parameters** | Production reports do not use runtime parameters (`:param` syntax in SQL, parameter prompts in UI). All queries return static result sets. | Parameter conversion (`:param` → `@param`), parameter UI elements, LOV/cascading support |
| **SQL dialect preserved** | SQL queries are copied as-is without Oracle→T-SQL dialect conversion. Assumes target database is Oracle or queries are already compatible. | SQL dialect translation layer |

These assumptions allow the converter to focus on **template conversion** (XSL-FO → RDL layout) without requiring complex data source and parameter infrastructure.

### Production Connection String

The production database connection string is embedded directly in the SSRS test data file using an `<ssrs-config>` wrapper element containing the full SSRS `<DataSource>` definition. This keeps all report artifacts together and provides complete control over the DataSource properties.

**Format:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ROOT>
  <ssrs-config>
    <DataSource Name="SalesDB">
      <ConnectionProperties>
        <DataProvider>OLEDB</DataProvider>
        <ConnectString>Provider=OraOLEDB.Oracle;Data Source=oracle-prod:1521/SALESDB;User Id=reports;Password=***</ConnectString>
      </ConnectionProperties>
    </DataSource>
  </ssrs-config>
  <ssrs-data>
    <SALES_REPORT>
      <!-- data rows -->
    </SALES_REPORT>
  </ssrs-data>
</ROOT>
```

**File structure:**

| Element | Description | Required |
|---------|-------------|----------|
| `<ROOT>` | Top-level wrapper element | Yes |
| `<ssrs-config>` | Contains production DataSource configuration | No (required for production RDL) |
| `<ssrs-data>` | Contains actual report data tables | Yes |

The `<ssrs-data>` wrapper separates configuration from data, ensuring:
- The SQL sync module only processes data elements (not config)
- Clear separation of concerns between metadata and data
- Consistent structure across all SSRS test data files

**DataSource element properties:**

| Property | Description | Required |
|----------|-------------|----------|
| `@Name` | DataSource name used in the RDL | Yes |
| `DataProvider` | SSRS data provider: `SQL`, `OLEDB`, `ODBC` | Yes |
| `ConnectString` | Connection string for the target database | Yes |

**Supported connection string formats:**

| Database | DataProvider | Example Connection String |
|----------|--------------|--------------------------|
| Oracle (OLEDB) | OLEDB | `Provider=OraOLEDB.Oracle;Data Source=host:1521/SID;User Id=user;Password=pass` |
| SQL Server | SQL | `Data Source=server;Initial Catalog=database;Integrated Security=True` |
| SQL Server (SQL Auth) | SQL | `Data Source=server;Initial Catalog=database;User Id=user;Password=pass` |

**Conversion output behavior:**

| Output Type | ssrs-config Present | Data Source Used |
|-------------|---------------------|------------------|
| Preview RDL | — | Embedded localhost SQL Server connection |
| Production RDL | Yes | DataSource from `<ssrs-config>` element |
| Production RDL | No | Placeholder with TODO comment |

### Test Data File Consistency

The sample data files follow consistent wrapper structures:

**BIP data files** (`*-data-bip.xml`):
```xml
<bip-data>
  <REPORT_NAME>
    <!-- Hierarchical data matching XDM output schema -->
  </REPORT_NAME>
</bip-data>
```

**SSRS data files** (`*-data-ssrs.xml`):
```xml
<ROOT>
  <ssrs-config>
    <DataSource><!-- Production connection --></DataSource>
  </ssrs-config>
  <ssrs-data>
    <ENTITY_TABLE>
      <ROW><!-- Flat/denormalized SQL row --></ROW>
    </ENTITY_TABLE>
  </ssrs-data>
</ROOT>
```

The wrapper elements (`<bip-data>`, `<ssrs-data>`) provide clear separation between:
- Configuration metadata (production connection strings)
- Actual report data

### Known Conversion Limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Custom XSL functions | Cannot auto-convert | Manual implementation in SSRS custom code |
| Advanced conditional formatting | Partial conversion | Manual adjustment of expressions |
| Pixel-perfect positioning | Approximate conversion | Manual layout refinement |
| BiDi (Right-to-Left) text | Limited support | Manual configuration in SSRS |
| Complex nested loops | May require restructuring | Flatten data model or use subreports |
| Oracle-specific SQL | Requires manual review | Update queries for target database |
| Bursting definitions | Not converted | Manual recreation in SSRS subscriptions |
| Flash charts | Not supported | Use SSRS native charts |

### Feature Parity Matrix

| Feature | BI Publisher | SSRS | Conversion Support |
|---------|-------------|------|-------------------|
| PDF Output | ✓ | ✓ | Full |
| Excel Output | ✓ | ✓ | Full |
| HTML Output | ✓ | ✓ | Full |
| RTF Output | ✓ | ✓ | Full |
| Interactive Viewer | ✓ | ✓ | N/A (runtime) |
| Drill-through | ✓ | ✓ | Partial |
| Drill-down | ✓ | ✓ | Full |
| Subreports | ✓ | ✓ | Full |
| Charts | ✓ | ✓ | Partial |
| Gauges | ✓ | ✓ | Full |
| Maps | ✓ | ✓ | Limited |
| Sparklines | ✓ | ✓ | Full |
| Data Bars | ✓ | ✓ | Full |
| Barcode | ✓ | Custom | Manual |
| Parameters | ✓ | ✓ | Out of scope (see [Current Scope Assumptions](#current-scope-assumptions)) |
| Cascading Parameters | ✓ | ✓ | Out of scope |

---

## Report Preview Data Sync (Planned)

### Overview

Power BI Report Builder does not support XML as a data source, which means converted RDL files cannot be previewed directly with the XML test data used during BIP development. This feature automatically syncs XML test data to SQL Server when reports are uploaded, enabling seamless preview in Report Builder.

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Automatic Data Sync on Upload                     │
│                                                                      │
│  ┌───────────┐    ┌──────────────┐    ┌────────────────────────┐   │
│  │  Web UI   │───▶│  upload.xql  │───▶│  SQL Server (Docker)   │   │
│  │  XSL-FO + │    │  + sync-sql  │    │  ReportPreview DB      │   │
│  │  XML Data │    │    .xqm      │    │  - Schema per report   │   │
│  └───────────┘    └──────────────┘    │  - Tables from XML     │   │
│                         │              │  - Auto-populated data │   │
│                         │              └────────────────────────┘   │
│                         ▼                         ↑                 │
│                  ┌──────────────┐                 │                 │
│                  │ convert.xql  │─────────────────┘                 │
│                  │ RDL references│  Connection string               │
│                  │ SQL Server    │  localhost,1433                  │
│                  └──────────────┘                                   │
└─────────────────────────────────────────────────────────────────────┘
```

### Implementation Details

**Docker Services:**
- SQL Server Express container (already defined in docker-compose.yml)
- eXist-db with MS SQL JDBC driver

**XQuery Module (`sync-sql.xqm`):**
```xquery
module namespace sync = "http://bip2ssrs/sync-sql";
import module namespace sql = "http://exist-db.org/xquery/sql";

(: Connect to SQL Server and sync XML data :)
declare function sync:load-xml-to-sql($report-name as xs:string, $xml-data as document-node()) {
    let $conn := sql:get-connection(
        "com.microsoft.sqlserver.jdbc.SQLServerDriver",
        "jdbc:sqlserver://sqlserver:1433;database=ReportPreview;encrypt=false",
        "sa", $config:sql-password)
    
    (: Analyze XML structure :)
    let $tables := sync:extract-tables($xml-data/*)
    
    (: Create schema for this report :)
    let $schema-sql := concat("IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = '", 
                              $report-name, "') EXEC('CREATE SCHEMA ", $report-name, "')")
    let $_ := sql:execute($conn, $schema-sql, false())
    
    (: Create tables and insert data for each entity :)
    for $table in $tables
    return (
        sql:execute($conn, sync:generate-create-table($report-name, $table), false()),
        sync:insert-rows($conn, $report-name, $table)
    )
};

(: Extract table definitions from XML structure :)
declare function sync:extract-tables($root as element()) as element()* {
    for $entity in $root/*[*]
    let $name := local-name($entity)
    group by $name
    return element table {
        attribute name { $name },
        for $col in ($entity[1]/*[not(*)])
        return element column { 
            attribute name { local-name($col) },
            attribute type { sync:infer-sql-type($col) }
        }
    }
};

(: Infer SQL type from XML content :)
declare function sync:infer-sql-type($element as element()) as xs:string {
    let $value := string($element)
    return
        if ($value castable as xs:integer) then "INT"
        else if ($value castable as xs:decimal) then "DECIMAL(18,2)"
        else if ($value castable as xs:date) then "DATE"
        else "NVARCHAR(500)"
};
```

**Report Builder Connection:**
```
Server=localhost,1433;Database=ReportPreview;User Id=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True
```

### Workflow

1. **Upload**: User uploads XSL-FO template + XML test data via web UI
2. **Sync**: `upload.xql` calls `sync:load-xml-to-sql()` to populate SQL Server
3. **Convert**: XSL-FO → RDL with connection string pointing to SQL Server
4. **Preview**: Open RDL in Report Builder, data loads from SQL Server
5. **Iterate**: Re-uploading clears old data and syncs new data

### Estimated Effort

| Task | Hours |
|------|-------|
| Enable SQL Server in docker-compose | 0.5 |
| Add JDBC driver to eXist-db container | 1 |
| Create `sync-sql.xqm` module | 4 |
| XML-to-SQL schema inference | 3 |
| Update `upload.xql` integration | 1 |
| Update RDL connection string generation | 1 |
| Testing and debugging | 2 |
| **Total** | **~12h (1.5 days)** |

### Status

**Status:** Planned  
**Priority:** Medium  
**Dependencies:** SQL Server Docker container

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-4)
- [ ] Project setup and architecture implementation
- [ ] RTF parser implementation
- [ ] Basic XDM data model parser
- [ ] Core RDL generator structure
- [ ] Unit test framework

### Phase 2: Core Conversion (Weeks 5-10)
- [ ] Expression translator (XPath to VB)
- [ ] Table/Tablix conversion
- [ ] Basic formatting conversion
- [ ] Parameter conversion
- [ ] Data source mapping

### Phase 3: Advanced Features (Weeks 11-16)
- [ ] Chart conversion
- [ ] Subreport handling
- [ ] Complex expression support
- [ ] Cross-tab/Matrix conversion
- [ ] Image and resource handling

### Phase 4: Polish & Tooling (Weeks 17-20)
- [ ] Batch processing capability
- [ ] Conversion reporting
- [ ] Validation and verification
- [ ] Performance optimization
- [ ] Documentation

### Phase 5: Testing & Release (Weeks 21-24)
- [ ] Integration testing
- [ ] User acceptance testing
- [ ] Bug fixes and refinements
- [ ] Release preparation
- [ ] Deployment documentation

---

## Testing Strategy

### Test Categories

| Category | Description | Coverage Target |
|----------|-------------|-----------------|
| Unit Tests | Component-level testing | 80% code coverage |
| Integration Tests | End-to-end conversion testing | All supported features |
| Regression Tests | Ensure existing functionality | Run on every build |
| Performance Tests | Large report handling | Reports up to 1000 pages |
| Compatibility Tests | SSRS version compatibility | SSRS 2017, 2019, 2022 |

### Test Reports

Sample test reports should include:
- Simple tabular report
- Multi-section report with grouping
- Report with charts and graphs
- Report with subreports
- Report with complex parameters
- Report with conditional formatting
- Cross-tab report
- Form-based report (invoices, forms)

### Validation Criteria

1. **Structural Validation**
   - Generated RDL passes schema validation
   - Report can be opened in Report Builder
   - Report can be deployed to Report Server

2. **Visual Validation**
   - Layout matches original within tolerance
   - Fonts and colors preserved
   - Images render correctly

3. **Data Validation**
   - Same data produces same output
   - Calculations match original
   - Grouping and sorting preserved

---

## SSRS Output Testing

Since BI Publisher inputs are assumed valid, this section focuses on validating the generated SSRS RDL outputs.

### Testing Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    SSRS Output Validation                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: Schema Validation (Offline)                           │
│  ├── XSD validation against RDL schema                          │
│  ├── No SSRS installation required                              │
│  └── Fast, can run in CI pipeline                               │
│                                                                  │
│  Layer 2: Structural Validation (Report Builder)                │
│  ├── Open in Report Builder / Visual Studio                     │
│  ├── Catches semantic errors XSD misses                         │
│  └── Can be automated via command line                          │
│                                                                  │
│  Layer 3: Deployment Validation (Report Server)                 │
│  ├── Deploy to SSRS instance                                    │
│  ├── Validates data source compatibility                        │
│  └── Containerized SSRS for CI                                  │
│                                                                  │
│  Layer 4: Rendering Validation                                  │
│  ├── Execute report with test data                              │
│  ├── Compare output (PDF, Excel, HTML)                          │
│  └── Visual regression testing                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Layer 1: Schema Validation (No SSRS Required)

Validates RDL XML against Microsoft's official XSD schema. Fast and can run anywhere.

#### PowerShell Schema Validator

```powershell
# validate-rdl.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$RdlPath,
    
    [string]$SchemaPath = "./schemas/ReportDefinition2016.xsd"
)

function Test-RdlSchema {
    param($rdlFile, $xsdFile)
    
    $settings = New-Object System.Xml.XmlReaderSettings
    $settings.ValidationType = [System.Xml.ValidationType]::Schema
    $settings.Schemas.Add($null, $xsdFile) | Out-Null
    
    $errors = @()
    $settings.add_ValidationEventHandler({
        param($sender, $e)
        $script:errors += [PSCustomObject]@{
            Severity = $e.Severity
            Message = $e.Message
            Line = $e.Exception.LineNumber
            Position = $e.Exception.LinePosition
        }
    })
    
    try {
        $reader = [System.Xml.XmlReader]::Create($rdlFile, $settings)
        while ($reader.Read()) { }
        $reader.Close()
        
        if ($errors.Count -eq 0) {
            Write-Host "✓ Schema validation passed: $rdlFile" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ Schema validation failed: $rdlFile" -ForegroundColor Red
            $errors | ForEach-Object {
                Write-Host "  Line $($_.Line): $($_.Message)" -ForegroundColor Yellow
            }
            return $false
        }
    }
    catch {
        Write-Host "✗ Parse error: $_" -ForegroundColor Red
        return $false
    }
}

# Validate single file or directory
if (Test-Path $RdlPath -PathType Container) {
    $results = Get-ChildItem $RdlPath -Filter "*.rdl" | ForEach-Object {
        Test-RdlSchema $_.FullName $SchemaPath
    }
    $passed = ($results | Where-Object { $_ }).Count
    $total = $results.Count
    Write-Host "`nResults: $passed/$total passed"
} else {
    Test-RdlSchema $RdlPath $SchemaPath
}
```

#### RDL Schema Locations

```powershell
# Download official RDL schemas
$schemas = @{
    "2016" = "https://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition/ReportDefinition.xsd"
    "2010" = "https://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition/ReportDefinition.xsd"
    "2008" = "https://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition/ReportDefinition.xsd"
}

foreach ($version in $schemas.Keys) {
    Invoke-WebRequest $schemas[$version] -OutFile "./schemas/ReportDefinition$version.xsd"
}
```

#### XQuery Validation (in eXist-db)

```xquery
xquery version "3.1";

module namespace validate = "http://bip2ssrs.org/validate";

declare namespace rdl = "http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition";

(:~
 : Validate RDL against schema
 :)
declare function validate:rdl($rdl as element()) as map(*) {
    let $schema := doc("/db/apps/bip2ssrs/schemas/rdl-2016.xsd")
    let $result := validation:jing($rdl, $schema)
    return map {
        "valid": $result instance of xs:boolean and $result,
        "errors": 
            if ($result instance of element()+) then
                array { $result/string() }
            else
                array {}
    }
};

(:~
 : Semantic validation beyond XSD
 :)
declare function validate:semantic($rdl as element()) as map(*) {
    let $errors := (
        (: Check for empty DataSetName references :)
        for $tablix in $rdl//rdl:Tablix[not(rdl:DataSetName/text())]
        return "Tablix '" || $tablix/@Name || "' has no DataSetName",
        
        (: Check for invalid expressions :)
        for $value in $rdl//rdl:Value[starts-with(., '=')][contains(., '[REVIEW:')]
        return "Unresolved expression: " || substring($value, 1, 50),
        
        (: Check for missing fields :)
        for $field in $rdl//rdl:Value[matches(., 'Fields!\w+\.Value')]
        let $field-name := replace($field, '.*Fields!(\w+)\.Value.*', '$1')
        where not($rdl//rdl:Field[@Name = $field-name])
        return "Referenced field not in dataset: " || $field-name
    )
    return map {
        "valid": empty($errors),
        "errors": array { $errors }
    }
};
```

### Layer 2: Report Builder CLI Validation

Microsoft Report Builder can validate RDL files via command line.

#### Automated Report Builder Check

```powershell
# test-reportbuilder.ps1
param(
    [string]$RdlPath,
    [string]$ReportBuilderPath = "C:\Program Files\Microsoft SQL Server Report Builder\MSReportBuilder.exe"
)

# Report Builder doesn't have a true CLI validation mode,
# but we can attempt to open and check exit codes
$process = Start-Process -FilePath $ReportBuilderPath `
    -ArgumentList "/?" `  # Check if it launches
    -PassThru -Wait -WindowStyle Hidden

# Alternative: Use Visual Studio devenv for build validation
# devenv /build Release MyReports.sln
```

#### Visual Studio / SSDT Validation

```powershell
# Use MSBuild to validate SSRS project
$ssrsProject = @"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration>Debug</Configuration>
    <ProjectGuid>{GUID}</ProjectGuid>
  </PropertyGroup>
  <ItemGroup>
    <Report Include="*.rdl" />
  </ItemGroup>
  <Import Project="\$(MSBuildExtensionsPath)\Microsoft\VisualStudio\v15.0\SSRS\Microsoft.ReportingServices.MSBuild.targets" />
</Project>
"@

# Build validates all RDL files
msbuild TestReports.rptproj /t:Build /p:Configuration=Debug
```

### Layer 3: Deployment Validation (Containerized SSRS)

Run SSRS in Docker for automated deployment testing.

#### Docker Compose with SQL Server Reporting Services

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  # SQL Server (required for SSRS)
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong!Passw0rd
      - MSSQL_PID=Express
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
    healthcheck:
      test: /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong!Passw0rd" -Q "SELECT 1"
      interval: 10s
      timeout: 5s
      retries: 5

  # SSRS (Windows container required)
  # Note: SSRS requires Windows containers
  ssrs:
    image: mcr.microsoft.com/windows/servercore:ltsc2022
    # Or use a custom SSRS image
    build:
      context: ./docker/ssrs
      dockerfile: Dockerfile.ssrs
    ports:
      - "8081:80"
    depends_on:
      sqlserver:
        condition: service_healthy
    environment:
      - SQL_SERVER=sqlserver
      - SA_PASSWORD=YourStrong!Passw0rd

  # Test runner
  test-runner:
    build:
      context: ./test
      dockerfile: Dockerfile.test
    depends_on:
      - ssrs
    volumes:
      - ./output:/rdl-files:ro
      - ./test-results:/results
    environment:
      - SSRS_URL=http://ssrs/ReportServer
      - SSRS_USER=admin
      - SSRS_PASSWORD=admin

volumes:
  sqlserver-data:
```

#### SSRS Web Service Deployment Test

```powershell
# deploy-and-test.ps1
param(
    [string]$RdlFolder = "./output",
    [string]$ReportServerUrl = "http://localhost/ReportServer",
    [string]$TargetFolder = "/ConversionTest"
)

# SSRS Web Service proxy
$reportServerUri = "$ReportServerUrl/ReportService2010.asmx?WSDL"
$proxy = New-WebServiceProxy -Uri $reportServerUri -UseDefaultCredential

# Create test folder
try {
    $proxy.CreateFolder("ConversionTest", "/", $null)
} catch { 
    # Folder may already exist
}

# Deploy and validate each RDL
$results = @()
Get-ChildItem $RdlFolder -Filter "*.rdl" | ForEach-Object {
    $rdlFile = $_
    $reportName = $_.BaseName
    
    try {
        # Read RDL content
        $rdlContent = Get-Content $_.FullName -Raw -Encoding UTF8
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($rdlContent)
        
        # Deploy to SSRS
        $warnings = $null
        $proxy.CreateCatalogItem(
            "Report",                    # ItemType
            $reportName,                 # Name  
            $TargetFolder,               # Parent folder
            $true,                       # Overwrite
            $bytes,                      # Definition
            $null,                       # Properties
            [ref]$warnings               # Warnings output
        )
        
        $results += [PSCustomObject]@{
            Report = $reportName
            Status = "Deployed"
            Warnings = ($warnings | ForEach-Object { $_.Message }) -join "; "
            Valid = $true
        }
        
        Write-Host "✓ Deployed: $reportName" -ForegroundColor Green
        if ($warnings) {
            $warnings | ForEach-Object {
                Write-Host "  Warning: $($_.Message)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        $results += [PSCustomObject]@{
            Report = $reportName
            Status = "Failed"
            Error = $_.Exception.Message
            Valid = $false
        }
        Write-Host "✗ Failed: $reportName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
$passed = ($results | Where-Object Valid).Count
$total = $results.Count
Write-Host "`n========================================" 
Write-Host "Deployment Results: $passed/$total succeeded"
Write-Host "========================================"

$results | Export-Csv "./test-results/deployment-results.csv" -NoTypeInformation
```

### Layer 4: Rendering Validation

Execute reports and validate output.

#### Render Reports via Web Service

```powershell
# render-test.ps1
param(
    [string]$ReportServerUrl = "http://localhost/ReportServer",
    [string]$ReportPath = "/ConversionTest/Invoice",
    [string]$Format = "PDF",  # PDF, EXCEL, HTML4.0, IMAGE
    [string]$OutputPath = "./test-results"
)

# Execution service
$execUri = "$ReportServerUrl/ReportExecution2005.asmx?WSDL"
$execProxy = New-WebServiceProxy -Uri $execUri -UseDefaultCredential

# Load report
$execInfo = $execProxy.LoadReport($ReportPath, $null)

# Set parameters if needed
# $params = @()
# $params += New-Object "$($execProxy.GetType().Namespace).ParameterValue" -Property @{ Name = "StartDate"; Value = "2024-01-01" }
# $execProxy.SetExecutionParameters($params, "en-us")

# Render
$deviceInfo = "<DeviceInfo><Toolbar>False</Toolbar></DeviceInfo>"
$extension = ""
$mimeType = ""
$encoding = ""
$warnings = $null
$streamIds = $null

$result = $execProxy.Render(
    $Format,
    $deviceInfo,
    [ref]$extension,
    [ref]$mimeType,
    [ref]$encoding,
    [ref]$warnings,
    [ref]$streamIds
)

# Save output
$outputFile = Join-Path $OutputPath "$($ReportPath.Replace('/', '_')).$extension"
[System.IO.File]::WriteAllBytes($outputFile, $result)

Write-Host "Rendered to: $outputFile ($mimeType)"

# Return result for comparison
[PSCustomObject]@{
    Report = $ReportPath
    Format = $Format
    OutputFile = $outputFile
    Size = $result.Length
    Warnings = $warnings
}
```

#### Automated Render Comparison

```powershell
# compare-outputs.ps1
# Compare rendered outputs between expected baselines and generated reports

param(
    [string]$BaselineFolder = "./test/baselines",
    [string]$GeneratedFolder = "./test-results/rendered",
    [string]$Format = "PDF"
)

function Compare-PdfContent {
    param($baseline, $generated)
    
    # Use pdftotext or similar for text extraction
    $baselineText = & pdftotext -layout $baseline -
    $generatedText = & pdftotext -layout $generated -
    
    $diff = Compare-Object ($baselineText -split "`n") ($generatedText -split "`n")
    
    return @{
        Match = ($diff.Count -eq 0)
        Differences = $diff
    }
}

function Compare-ExcelContent {
    param($baseline, $generated)
    
    # Use ImportExcel module
    $baselineData = Import-Excel $baseline
    $generatedData = Import-Excel $generated
    
    $diff = Compare-Object $baselineData $generatedData -Property *
    
    return @{
        Match = ($diff.Count -eq 0)
        Differences = $diff
    }
}

# Compare all files
$results = Get-ChildItem $GeneratedFolder -Filter "*.$Format" | ForEach-Object {
    $generated = $_.FullName
    $baseline = Join-Path $BaselineFolder $_.Name
    
    if (Test-Path $baseline) {
        $comparison = switch ($Format) {
            "PDF"   { Compare-PdfContent $baseline $generated }
            "XLSX"  { Compare-ExcelContent $baseline $generated }
            default { @{ Match = (Get-FileHash $baseline).Hash -eq (Get-FileHash $generated).Hash } }
        }
        
        [PSCustomObject]@{
            File = $_.Name
            HasBaseline = $true
            Match = $comparison.Match
            Differences = $comparison.Differences
        }
    } else {
        [PSCustomObject]@{
            File = $_.Name
            HasBaseline = $false
            Match = $null
            Differences = "No baseline file"
        }
    }
}

# Report
$matched = ($results | Where-Object { $_.Match -eq $true }).Count
$total = $results.Count
Write-Host "`nComparison Results: $matched/$total matched baseline"
```

### Visual Regression Testing

Screenshot-based comparison for layout validation.

#### Using Playwright for SSRS Web Rendering

```javascript
// visual-regression.spec.js
const { test, expect } = require('@playwright/test');

const SSRS_URL = process.env.SSRS_URL || 'http://localhost/Reports';
const REPORTS_TO_TEST = [
    '/ConversionTest/Invoice',
    '/ConversionTest/SalesReport', 
    '/ConversionTest/EmployeeList'
];

test.describe('SSRS Visual Regression', () => {
    
    test.beforeEach(async ({ page }) => {
        // Authenticate to SSRS if needed
        await page.goto(SSRS_URL);
    });

    for (const reportPath of REPORTS_TO_TEST) {
        test(`Report renders correctly: ${reportPath}`, async ({ page }) => {
            // Navigate to report
            const reportUrl = `${SSRS_URL}/report${reportPath}`;
            await page.goto(reportUrl);
            
            // Wait for report to load
            await page.waitForSelector('.report-viewer', { state: 'visible' });
            await page.waitForLoadState('networkidle');
            
            // Take screenshot
            const screenshot = await page.screenshot({ 
                fullPage: true,
                animations: 'disabled'
            });
            
            // Compare to baseline
            expect(screenshot).toMatchSnapshot(`${reportPath.replace(/\//g, '_')}.png`, {
                threshold: 0.1,  // Allow 10% pixel difference
                maxDiffPixels: 100
            });
        });
    }
});
```

#### Run Visual Tests

```bash
# Install dependencies
npm install @playwright/test

# Run visual regression tests
npx playwright test visual-regression.spec.js

# Update baselines when intentional changes occur
npx playwright test --update-snapshots
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/test-ssrs-output.yml
name: Test SSRS Output

on:
  push:
    branches: [main]
  pull_request:

jobs:
  schema-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Download RDL Schema
        run: |
          mkdir -p schemas
          curl -o schemas/rdl-2016.xsd https://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition/ReportDefinition.xsd
      
      - name: Validate RDL against schema
        run: |
          for rdl in output/*.rdl; do
            xmllint --schema schemas/rdl-2016.xsd "$rdl" --noout
          done

  deployment-test:
    runs-on: windows-latest
    needs: schema-validation
    steps:
      - uses: actions/checkout@v4
      
      - name: Start SQL Server container
        run: |
          docker run -d --name sqlserver \
            -e "ACCEPT_EULA=Y" \
            -e "SA_PASSWORD=YourStrong!Passw0rd" \
            -p 1433:1433 \
            mcr.microsoft.com/mssql/server:2022-latest
      
      - name: Install SSRS
        run: |
          # Use Chocolatey or direct installer
          choco install sql-server-reporting-services -y
      
      - name: Deploy and Test Reports
        run: |
          pwsh ./scripts/deploy-and-test.ps1 -RdlFolder ./output
      
      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: deployment-results
          path: test-results/

  visual-regression:
    runs-on: ubuntu-latest
    needs: deployment-test
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Playwright
        run: npx playwright install --with-deps
      
      - name: Run Visual Tests
        run: npx playwright test
      
      - name: Upload Screenshots
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: visual-diff
          path: test-results/
```

### Test Data Strategy

Use XML test data to render reports without database:

```xml
<!-- test-data/invoice-data.xml -->
<Report>
  <Invoice>
    <InvoiceNumber>INV-001</InvoiceNumber>
    <InvoiceDate>2024-01-15</InvoiceDate>
    <Customer>
      <Name>Acme Corp</Name>
      <Address>123 Main St</Address>
    </Customer>
    <Items>
      <Item>
        <Description>Widget A</Description>
        <Quantity>10</Quantity>
        <UnitPrice>25.00</UnitPrice>
        <Total>250.00</Total>
      </Item>
      <Item>
        <Description>Gadget B</Description>
        <Quantity>5</Quantity>
        <UnitPrice>50.00</UnitPrice>
        <Total>250.00</Total>
      </Item>
    </Items>
    <Subtotal>500.00</Subtotal>
    <Tax>50.00</Tax>
    <GrandTotal>550.00</GrandTotal>
  </Invoice>
</Report>
```

```powershell
# Render with XML data source (no database needed)
$execProxy.SetExecutionParameters(@(
    New-Object "$ns.ParameterValue" -Property @{ 
        Name = "DataSource"
        Value = "XML" 
    }
), "en-us")
```

### Quick Validation Checklist

| Test | Method | Automate? | When to Run |
|------|--------|-----------|-------------|
| XSD Schema | PowerShell/xmllint | ✅ Yes | Every build |
| Well-formed XML | Any XML parser | ✅ Yes | Every build |
| Expression syntax | Regex patterns | ✅ Yes | Every build |
| Opens in Report Builder | Manual / semi-auto | ⚠️ Partial | Before release |
| Deploys to SSRS | Web Service API | ✅ Yes | CI pipeline |
| Renders without error | Web Service API | ✅ Yes | CI pipeline |
| Output matches baseline | File comparison | ✅ Yes | CI pipeline |
| Visual appearance | Playwright screenshots | ✅ Yes | PR reviews |

---

## Appendix

### A. Command Line Interface

```
bip2ssrs convert [options] <input-path>

Options:
  -o, --output <path>       Output directory (default: ./output)
  -c, --config <file>       Configuration file path
  -f, --format <format>     Output format: rdl, rds, rsd (default: rdl)
  -v, --verbose             Enable verbose logging
  -q, --quiet               Suppress console output
  --validate                Validate output against RDL schema
  --dry-run                 Parse and analyze without generating output
  --batch                   Process directory recursively
  
Examples:
  bip2ssrs convert report.rtf
  bip2ssrs convert --batch ./reports --output ./converted
  bip2ssrs convert report.xdoz --validate
```

### B. Configuration File Format

```yaml
# bip2ssrs-config.yaml
conversion:
  targetSSRSVersion: "2019"
  preserveFormatting: true
  convertCharts: true
  embedResources: true

dataSource:
  defaultProvider: "OLEDB"
  connectionStringTemplate: "Provider=OraOLEDB.Oracle;Data Source={host}:{port}/{service};"
  parameterPrefix: "@"

output:
  createSharedDataSources: true
  createSharedDatasets: false
  generateMigrationReport: true
  
logging:
  level: "Info"
  outputFile: "conversion.log"
  
mappings:
  customExpressions:
    - source: "xdoxslt:my_func"
      target: "Code.MyFunc"
```

### C. Glossary

| Term | Definition |
|------|------------|
| BIP | Business Intelligence Publisher (Oracle) |
| RDL | Report Definition Language (SSRS XML format) |
| RTF | Rich Text Format |
| XDM | XML Data Model (BI Publisher data definition) |
| XPT | BI Publisher native template format |
| SSRS | SQL Server Reporting Services |
| XPath | XML Path Language (used in BI Publisher) |
| Tablix | SSRS data region combining table/matrix/list |
| LOV | List of Values |

### D. References

- [Oracle BI Publisher Documentation](https://docs.oracle.com/middleware/bi12214/bip/)
- [SSRS Report Definition Language Specification](https://docs.microsoft.com/en-us/sql/reporting-services/reports/report-definition-language-ssrs)
- [RDL Schema Reference](https://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition/ReportDefinition.xsd)

### E. eXist-db Administration

This section documents the eXist-db deployment used by the BIP-to-SSRS converter.

#### Docker Image

The converter uses a custom Docker image based on the **stadlerpeter/existdb:6** community image:

```dockerfile
FROM stadlerpeter/existdb:6
# Adds MSSQL JDBC driver for SQL Server connectivity
COPY mssql-jdbc-12.6.1.jre11.jar /opt/exist/lib/
```

**Image Details:**
- **Base Image:** `stadlerpeter/existdb:6` (eXist-db 6.2.0)
- **Java Version:** OpenJDK 11
- **Built Image Tag:** `bip2ssrs-existdb:6.2.0`
- **Exposed Port:** 8080 (mapped to host 8088)

**Official Documentation:**
- [eXist-db Official Documentation](https://exist-db.org/exist/apps/doc/)
- [stadlerpeter Docker Hub](https://hub.docker.com/r/stadlerpeter/existdb)

#### Authentication & Passwords

**Default Credentials:**

| User | Password | Purpose |
|------|----------|---------|
| `admin` | (empty on first install) | Database administrator |
| `guest` | `guest` | Read-only access |

**Important:** The admin password should be changed immediately after first deployment.

**Changing the Admin Password:**

1. **Via eXist-db Dashboard:**
   - Navigate to `http://localhost:8088/exist/apps/dashboard/`
   - Click "User Manager"
   - Select `admin` user and set a new password

2. **Via REST API:**
   ```powershell
   # Change admin password (replace NEW_PASSWORD)
   curl.exe -u admin: -X POST "http://localhost:8088/exist/rest/db/system/security?user=admin&password=NEW_PASSWORD"
   ```

3. **Via XQuery:**
   ```xquery
   xquery version "3.1";
   import module namespace sm = "http://exist-db.org/xquery/securitymanager";
   sm:passwd("admin", "NEW_PASSWORD")
   ```

**Application Password Storage:**

The converter API endpoints use the admin password defined in [src/api/convert-stored.xql](src/api/convert-stored.xql):

```xquery
declare function local:login-admin() as xs:boolean {
    xmldb:login("/db", "admin", "YOUR_PASSWORD_HERE")
};
```

**Security Best Practices:**
- Never commit passwords to version control
- Use environment variables or secrets management
- Restrict network access to the eXist-db port
- Enable HTTPS in production (requires reverse proxy)

#### REST API Authentication

All write operations require authentication:

```powershell
# Using Basic Auth with curl
curl.exe -u admin:YOUR_PASSWORD -X PUT ...

# Using PowerShell
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:YOUR_PASSWORD"))
$headers = @{Authorization = "Basic $cred"}
Invoke-WebRequest -Uri "..." -Headers $headers
```

#### Collection Permissions

The BIP2SSRS application uses these collections:

| Collection | Path | Permissions | Purpose |
|------------|------|-------------|---------|
| App Root | `/db/apps/bip2ssrs` | `rwxr-xr-x` | Application code |
| Input | `/db/apps/bip2ssrs/input` | `rwxrwxrwx` | Uploaded BIP files |
| Output | `/db/apps/bip2ssrs/output` | `rwxrwxrwx` | Converted RDL files |
| XSLT | `/db/apps/bip2ssrs/xslt` | `rwxr-xr-x` | Transformation stylesheets |

#### Backup & Recovery

##### Creating a Backup (XAR Export)

The XAR (eXist Archive) format is a ZIP file containing application code and data.

**Method 1: Package Manager (Dashboard)**
1. Open `http://localhost:8088/exist/apps/dashboard/`
2. Go to "Package Manager"
3. Click the download icon next to `bip2ssrs`
4. Save the `.xar` file

**Method 2: REST API Export**
```powershell
# Export entire bip2ssrs app as XAR
curl.exe -u admin:PASSWORD -o bip2ssrs-backup.xar \
    "http://localhost:8088/exist/apps/eXide/download/db/apps/bip2ssrs"
```

**Method 3: Create XAR from Source**
```powershell
# Create XAR from local source files (saves to output/ folder)
$version = "1.4.0"
Remove-Item -Path "output\bip2ssrs-$version.xar" -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "src\*" -DestinationPath "output\bip2ssrs-$version.zip" -Force
Move-Item -Path "output\bip2ssrs-$version.zip" -Destination "output\bip2ssrs-$version.xar" -Force
Get-Item "output\bip2ssrs-$version.xar"  # Verify creation
```

> **Note:** The XAR format is a ZIP file with a `.xar` extension. PowerShell's `Compress-Archive` only supports `.zip`, so we create the ZIP first and rename it.

##### Restoring from Backup (XAR Import)

**Method 1: Package Manager (Dashboard)**
1. Open `http://localhost:8088/exist/apps/dashboard/`
2. Go to "Package Manager"
3. Click "Upload" or drag-and-drop the `.xar` file
4. Click "Install"

**Method 2: REST API Import**
```powershell
# Deploy XAR to eXist-db
curl.exe -u admin:PASSWORD -X POST \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@output/bip2ssrs-1.4.0.xar" \
    "http://localhost:8088/exist/rest/db/apps/?name=bip2ssrs"
```

**Method 3: Command Line (Docker)**
```powershell
# Copy XAR to container and install via autodeploy
docker cp output/bip2ssrs-1.4.0.xar bip2ssrs-existdb:/exist/autodeploy/
# eXist-db automatically deploys packages placed in /exist/autodeploy/
```

##### Full Database Backup

For disaster recovery, back up the entire eXist-db data volume:

```powershell
# Stop containers
docker compose stop

# Backup the data volume
docker run --rm -v existdb-data:/data -v ${PWD}:/backup alpine \
    tar cvzf /backup/existdb-backup-$(date +%Y%m%d).tar.gz /data

# Restart containers
docker compose start
```

##### Incremental Export (Collections)

Export specific collections:

```powershell
# Export input collection
curl.exe -u admin:PASSWORD -o input-backup.zip \
    "http://localhost:8088/exist/rest/db/apps/bip2ssrs/input?_howmany=all&_wrap=no&_method=zip"

# Export output collection
curl.exe -u admin:PASSWORD -o output-backup.zip \
    "http://localhost:8088/exist/rest/db/apps/bip2ssrs/output?_howmany=all&_wrap=no&_method=zip"
```

#### Environment Configuration

The `.env` file supports these variables:

```bash
# eXist-db Configuration
EXISTDB_ADMIN_PASSWORD=       # Set after first run via Dashboard

# SQL Server Configuration
SQL_SA_PASSWORD=YourStrong!Passw0rd

# Java Memory Settings (applied via docker-compose.yml)
JAVA_OPTS=-Xms512m -Xmx2g
```

#### Health Monitoring

```powershell
# Check container health status
docker compose ps

# View eXist-db logs
docker compose logs -f existdb

# Test REST API availability
curl.exe -s -o /dev/null -w "%{http_code}" "http://localhost:8088/exist/rest/db"
# Returns 200 if healthy, 401 if auth required (still healthy), 000 if down
```

#### Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Wrong password or missing auth | Verify credentials, check password was set |
| 404 Not Found | Collection/app not deployed | Run `.\scripts\setup-existdb.ps1` or install XAR |
| Connection refused | Container not running | Run `docker compose up -d` |
| Out of memory | JVM heap exhausted | Increase `-Xmx` in `JAVA_OPTS` |
| Transform timeout | Complex XSLT processing | Split large files, increase timeout |

---

### F. Project Maintenance

This section documents workspace organization and cleanup procedures.

#### Directory Structure

| Directory | Purpose |
|-----------|----------|
| `input/` | Sample BIP templates (XSL-FO, XDM, data XML) for testing |
| `input/tested/` | Templates that have been validated and moved after testing |
| `output/` | Generated RDL files (typically empty in development) |
| `src/` | eXist-db application source code |
| `src/api/` | XQuery REST API endpoints |
| `src/xslt/` | XSLT conversion stylesheets |
| `src/web/` | Web UI files (HTML, JS) |
| `scripts/` | PowerShell utility scripts |
| `docs/` | Additional documentation |

#### Temporary Files (Safe to Delete)

The following file patterns are generated during development and testing. They can be safely deleted:

| Pattern | Description | Typical Size |
|---------|-------------|---------------|
| `temp*` | Debugging/testing artifacts | ~360KB total |
| `employee-upload*.json` | Test upload payloads | ~300KB total |
| `clean-*.txt`, `clean-*.json` | Debug upload attempts | Variable |
| `deploy-result.xml` | Deployment output | <5KB |
| `test-rdl.xml` | Test conversion output | Variable |

**Cleanup Command:**
```powershell
# Remove all temporary and debug files
Remove-Item temp*, employee-upload*.json, clean-*.*, deploy-result.xml, test-rdl.xml -Force -ErrorAction SilentlyContinue
```

#### XSLT Backup Files

- `src/xslt/bip-to-rdl-backup.xsl` - Backup of main transformation stylesheet

If using version control (git), this backup file is redundant. Consider removing after verifying git history contains the version you need.

#### Version Artifact: XAR Packages

- `bip2ssrs-X.Y.Z.xar` - eXist-db deployable packages

Keep only the latest XAR package for deployment. Older versions can be deleted if git history is available.

#### Empty Placeholder Directories

These directories contain only README.md placeholders:
- `src/input/` - Reserved for imported templates
- `src/output/` - Reserved for converted output
- `src/schemas/` - Reserved for XSD/RNG schemas
- `output/` - Reserved for local output files

These can be kept for organizational purposes or removed if not needed.

---

### G. SQL Server Connectivity (JDBC Driver Setup)

This section documents the configuration required for eXist-db to connect to SQL Server for preview data synchronization.

#### Overview

The BIP-to-SSRS converter can optionally sync XML test data to SQL Server, allowing reports to be previewed in Power BI Report Builder with realistic data. This requires eXist-db's SQL extension module to connect to SQL Server using JDBC.

#### Docker Image Selection

**Recommended: Official eXist-db Image**
```dockerfile
FROM existdb/existdb:6.2.0
```

**Why not stadlerpeter/existdb:6?**

We initially attempted to use `stadlerpeter/existdb:6` because it:
- Has good documentation for custom configurations
- Uses a more recent Java version (Java 11)

However, this image proved problematic for JDBC driver loading:
- Uses `appassembler` launcher which has isolated classloading
- JDBC drivers placed in `/opt/exist/lib/` are not loaded by DriverManager
- The launcher's classpath management makes it difficult to add custom JARs

**Why existdb/existdb:6.2.0 works:**
- Uses Java 8, which supports the `jre/lib/ext` extension directory
- Simpler startup mechanism with more predictable classloading

#### Key Configuration Details

**1. Java Version Compatibility**

The official `existdb/existdb:6.2.0` image uses **Java 8** (OpenJDK 1.8.0_332). This means:
- Must use `jre8` version of the JDBC driver (NOT `jre11`)

**2. JDBC Driver Installation - CRITICAL**

The JDBC driver must be placed in `/exist/lib/` **AND** the `java.ext.dirs` system property must be set to include that directory. Simply copying the JAR is not sufficient - eXist-db's classloader does not automatically scan `/exist/lib/` for additional JARs.

**The fix:** Override `JAVA_TOOL_OPTIONS` to include `-Djava.ext.dirs=/exist/lib:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext`

This tells Java to load extension JARs from both `/exist/lib/` (where we put the JDBC driver) and the standard JRE extension directory.

**3. EXIST_HOME Path**

The official image uses `/exist/` as EXIST_HOME, not `/opt/exist/`:
```
-Dexist.home=/exist
-Dexist.configurationFile=/exist/etc/conf.xml
```

**4. Password Handling**

The official image uses an **empty password** by default for the admin user, unlike stadlerpeter which generates random passwords. The setup scripts detect this automatically.

#### Complete Dockerfile (Working Configuration)

```dockerfile
# Custom eXist-db image with MSSQL JDBC driver for SQL Server connectivity
# Using official existdb image which has better extension support
# NOTE: Official existdb:6.2.0 uses Java 8, so we need jre8 driver
# NOTE: Must add JDBC JAR to extension dirs for SQL module to find it

FROM alpine:3.19 AS downloader
RUN apk add --no-cache wget
RUN wget -q "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.6.1.jre8/mssql-jdbc-12.6.1.jre8.jar" -O /tmp/mssql-jdbc.jar

FROM existdb/existdb:6.2.0
# Copy JDBC driver to eXist-db lib directory
COPY --from=downloader /tmp/mssql-jdbc.jar /exist/lib/mssql-jdbc.jar

# Add JDBC JAR to classpath via JAVA_TOOL_OPTIONS (this is how eXist-db picks up JVM args)
# The base image sets JAVA_TOOL_OPTIONS with many settings - we append our java.ext.dirs
# CRITICAL: Without -Djava.ext.dirs, the JDBC driver will NOT be loaded!
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -Dsun.jnu.encoding=UTF-8 -Djava.awt.headless=true -Dorg.exist.db-connection.cacheSize=256M -Dorg.exist.db-connection.pool.max=20 -Dlog4j.configurationFile=/exist/etc/log4j2.xml -Dexist.home=/exist -Dexist.configurationFile=/exist/etc/conf.xml -Djetty.home=/exist -Dexist.jetty.config=/exist/etc/jetty/standard.enabled-jetty-configs -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError -Djava.ext.dirs=/exist/lib:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext"
```

#### Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| "No such SQL Connection" | JDBC driver not on classpath | Ensure `-Djava.ext.dirs=/exist/lib:...` is in JAVA_TOOL_OPTIONS |
| "No suitable driver found for jdbc:sqlserver://..." | Driver not loaded | Verify `java.ext.dirs` includes `/exist/lib/` |
| "No suitable driver found..." with jre11 driver | Wrong Java version | Use `mssql-jdbc-12.6.1.jre8.jar` (not jre11) |
| Driver in `/exist/lib/` but not loading | Missing java.ext.dirs | Add `-Djava.ext.dirs=/exist/lib` to JAVA_TOOL_OPTIONS |
| ClassNotFoundException for com.microsoft.sqlserver... | Driver not on extension path | Rebuild container with corrected Dockerfile |
| PowerShell script fails reading Docker logs | stderr interpretation | Use `cmd /c "docker logs ... 2>&1"` pattern |

#### Verifying SQL Server Connectivity

```powershell
# Test SQL connection from eXist-db
Invoke-RestMethod -Uri "http://localhost:8088/exist/apps/bip2ssrs/api/test-sql.xql" -Method GET

# Expected success response:
# success : True
# server  : sqlserver:1433
# message : Connected to SQL Server
```

#### Connection Settings

The SQL module configuration in `sync-sql.xqm`:

```xquery
declare variable $sync:JDBC_DRIVER := "com.microsoft.sqlserver.jdbc.SQLServerDriver";
declare variable $sync:MASTER_URL := "jdbc:sqlserver://sqlserver:1433;database=master;encrypt=false;trustServerCertificate=true";
declare variable $sync:DB_USER := "sa";
declare variable $sync:DB_PASSWORD := "YourStrong!Passw0rd";
```

**Important connection string parameters:**
- `encrypt=false` - Required for local development without SSL
- `trustServerCertificate=true` - Trust self-signed certificates
- `sqlserver:1433` - Uses Docker network hostname (container name)

---

## Appendix H. XSLT Transformation Rules

This appendix documents the transformation rules implemented in `src/xslt/bip-to-rdl.xsl` for converting Oracle BI Publisher XSL-FO templates to Microsoft SSRS RDL format.

### H.1 Document Structure Transformation

| XSL-FO Element | RDL Element | Notes |
|----------------|-------------|-------|
| `fo:root` | `Report` | Root document with SSRS 2016 namespace |
| `fo:simple-page-master` | `Page` | Page dimensions and margins |
| `fo:page-sequence/fo:flow` | `Body/ReportItems` | Main content container |
| `fo:static-content[@flow-name='xsl-region-before']` | Header textboxes | Processed as report header elements |
| `fo:static-content[@flow-name='xsl-region-after']` | `PageFooter` | Placed inside `Page` element for every-page display |

### H.2 Page Layout Rules

| XSL-FO Attribute | RDL Element | Conversion |
|------------------|-------------|------------|
| `page-height` | `PageHeight` | Direct copy with unit normalization |
| `page-width` | `PageWidth` | Direct copy with unit normalization |
| `margin` / `margin-*` | `LeftMargin`, `RightMargin`, `TopMargin`, `BottomMargin` | Individual margins or shorthand expansion |

**Unit Normalization** (`normalize-size` template):
- `pt` → Convert to inches (divide by 72)
- `cm` → Convert to inches (divide by 2.54)
- `mm` → Convert to inches (divide by 25.4)
- `in` → Direct copy
- Empty/missing → Use provided default

### H.3 Block-Level Element Transformation

#### fo:block → Textbox

| XSL-FO Attribute | RDL Element | Conversion |
|------------------|-------------|------------|
| `font-size` | `Style/FontSize` | Direct copy |
| `font-weight` | `Style/FontWeight` | `bold` → `Bold`, otherwise `Normal` |
| `font-style` | `Style/FontStyle` | `italic` → `Italic`, otherwise `Normal` |
| `color` | `Style/Color` | Direct copy (hex or named colors) |
| `background-color` | `Style/BackgroundColor` | Direct copy |
| `text-align` | `Style/TextAlign` | `left` → `Left`, `right` → `Right`, `center` → `Center`, `justify` → `Justify` |
| `padding` | `PaddingLeft/Right/Top/Bottom` | Shorthand expansion to all sides |
| `margin-top`, `margin-bottom` | Position calculation (`Top`) | Cumulative vertical positioning |

### H.4 Table Transformation

#### fo:table → Tablix

| XSL-FO Element | RDL Element | Notes |
|----------------|-------------|-------|
| `fo:table` | `Tablix` | Container with body, column/row hierarchies |
| `fo:table-column` | `TablixColumn` | Width from `column-width` attribute |
| `fo:table-header/fo:table-row` | Static `TablixMember` | Non-repeating header row |
| `fo:table-body/fo:table-row` | `TablixRow` | Data rows |
| `fo:table-cell` | `TablixCell/CellContents/Textbox` | Cell content with styling |

#### Row Hierarchy Rules

| Pattern | TablixRowHierarchy Structure |
|---------|------------------------------|
| Static table (no `xsl:for-each`) | One `TablixMember` per body row, no `Group` element |
| Single `xsl:for-each` in body | `TablixMember` with `Group Name="Details_..."` |
| Nested `xsl:for-each` (Muenchian grouping) | Outer List Tablix with `RegionGroup`, nested detail Tablix |

### H.5 Repeating/Grouping Patterns

#### Muenchian Grouping Detection

When the XSLT detects an outer `xsl:for-each` containing both `fo:block` and `fo:table`:

```
xsl:for-each[fo:block and fo:table] → List Tablix
  └── Rectangle (container)
        ├── Textbox (group header from fo:block)
        └── NestedTablix (detail table from fo:table)
```

**List Tablix Structure:**
- Single column, single row containing a Rectangle
- `TablixRowHierarchy` with `Group` element for parent grouping (e.g., REGION_NAME)
- Nested Tablix has simple Details group without parent grouping

#### Detail Row Detection

| XSL-FO Pattern | Detection | Result |
|----------------|-----------|--------|
| `fo:table-body/xsl:for-each[fo:table-row]` | Inner for-each with table-row child | Details group with repeating rows |

### H.6 Expression Conversion

#### XPath to SSRS Field Reference

The `xpath-to-field` template extracts field names:

| XPath Expression | SSRS Field |
|------------------|------------|
| `FIELD_NAME` | `Fields!FIELD_NAME.Value` |
| `path/to/FIELD_NAME` | `Fields!FIELD_NAME.Value` |
| `$variableName` | Variable expansion (see below) |

#### xsl:value-of Conversion

The `convert-xsl-value-of-to-ssrs` template handles:

| XSL Expression | SSRS Expression |
|----------------|-----------------|
| `FIELD` | `=Fields!FIELD.Value` |
| `sum(path/FIELD)` | `=Sum(Fields!FIELD.Value)` |
| `count(...)` | `=CountRows("DataSet1")` |
| `position()` | `=RowNumber("DataSet1")` |
| `A div B` | `=IIF(B = 0, 0, A / B)` (division with zero protection) |
| `(A div B) * 100` | `=IIF(B = 0, 0, A / B) * 100` |
| `format-number(expr, 'pattern')` | `=Format(expr, "pattern")` |
| `format-date(expr, 'picture')` | `=Format(expr, "dotnet-format")` |

#### Number Format Pattern Preservation

The `extract-format-pattern` template extracts the format string from `format-number()` calls:

| XSL Pattern | Preserved As |
|-------------|--------------|
| `'#,##0'` | `"#,##0"` (no decimals, thousands separator) |
| `'#,##0.00'` | `"#,##0.00"` (two decimals) |
| `'#0.0'` | `"#0.0"` (one decimal) |

### H.7 Mixed Content Handling

The `process-mixed-content` template processes text nodes and `xsl:value-of` elements together:

**Spacing Preservation Rules:**
- Leading whitespace preserved if preceded by `xsl:value-of`
- Trailing whitespace preserved if followed by `xsl:value-of`
- Internal whitespace normalized (multiple spaces → single space)

**Example transformation:**
```xml
<!-- Input -->
<fo:block>Total: <xsl:value-of select="COUNT"/> items | $<xsl:value-of select="AMOUNT"/></fo:block>

<!-- Output (multiple TextRuns in one Paragraph) -->
<TextRun><Value>Total: </Value>...</TextRun>
<TextRun><Value>=Fields!COUNT.Value</Value>...</TextRun>
<TextRun><Value> items | $</Value>...</TextRun>
<TextRun><Value>=Fields!AMOUNT.Value</Value>...</TextRun>
```

### H.8 Style Conversion

#### Text Styles (`convert-text-style` template)

| XSL-FO | RDL | Notes |
|--------|-----|-------|
| `font-size` | `FontSize` | Direct copy |
| `font-weight="bold"` | `FontWeight>Bold` | Binary conversion |
| `font-style="italic"` | `FontStyle>Italic` | Binary conversion |
| `color` | `Color` | Hex or named |
| `text-decoration="underline"` | `TextDecoration>Underline` | |

#### Cell Styles (`convert-cell-style` template)

| XSL-FO | RDL | Notes |
|--------|-----|-------|
| `background-color` | `BackgroundColor` | Direct copy |
| `padding` | `PaddingLeft/Right/Top/Bottom` | Shorthand expansion |
| `border` | `Border/Style`, `Border/Width`, `Border/Color` | Parsed from shorthand |
| `vertical-align` | `VerticalAlign` | `top` → `Top`, `middle` → `Middle`, `bottom` → `Bottom` |

#### Border Parsing

The `convert-border-style` template parses CSS-style border shorthand:

```
"1pt solid #999999" → <Border><Style>Solid</Style><Width>1pt</Width><Color>#999999</Color></Border>
```

### H.9 Page Footer Handling

Page footers require special placement inside the `Page` element (not `ReportSection`):

```xml
<Page>
    <PageHeight>...</PageHeight>
    <PageWidth>...</PageWidth>
    <LeftMargin>...</LeftMargin>
    ...
    <PageFooter>
        <Height>0.5in</Height>
        <PrintOnFirstPage>true</PrintOnFirstPage>
        <PrintOnLastPage>true</PrintOnLastPage>
        <ReportItems>
            <Textbox>...</Textbox>
        </ReportItems>
    </PageFooter>
</Page>
```

**Footer Content Processing** (`page-footer` mode):
- `fo:page-number` → `=Globals!PageNumber`
- `fo:page-number-citation-last` → `=Globals!TotalPages`
- Text and `xsl:value-of` → Standard text processing

### H.10 Date Format Conversion

The `convert-date-picture-to-dotnet` template converts Oracle/XSLT date pictures to .NET format:

| XSL Picture | .NET Format | Example Output |
|-------------|-------------|----------------|
| `[MNn] [D], [Y]` | `MMMM d, yyyy` | February 25, 2026 |
| `[Y]-[M01]-[D01]` | `yyyy-MM-dd` | 2026-02-25 |
| `[M01]/[D01]/[Y]` | `MM/dd/yyyy` | 02/25/2026 |
| `[D01]-[MNn,*-3]-[Y]` | `dd-MMM-yyyy` | 25-Feb-2026 |

### H.11 Field Generation

The `generate-fields` template scans all `xsl:value-of` elements to build the DataSet field list:

1. Extract XPath from `@select` attribute
2. Unwrap functions (`format-number`, `sum`, etc.)
3. Convert path to field name
4. Deduplicate field names
5. Generate `<Field Name="..."><DataField>...</DataField></Field>` elements

### H.12 Suppressed Elements

The following XSL-FO/XSLT elements are intentionally not output:

| Element | Reason |
|---------|--------|
| `fo:layout-master-set` | Page layout handled separately |
| `xsl:template` | Not applicable to RDL |
| `xsl:output` | Not applicable to RDL |
| `fo:static-content[@flow-name='xsl-region-after']` (default mode) | Handled in `page-footer` mode |

### H.13 Debugging Comments

The transformation inserts XML comments at key points:

- `<!-- Repeating row from xsl:for-each select="..." -->` - Marks detail rows
- `<!-- Conditional: test="..." -->` - Marks `xsl:if` boundaries

---

## Appendix I. Standalone XSLT Packaging Feasibility

This appendix analyzes the feasibility of packaging the XSLT transformation as a standalone tool (without eXist-db) that can be run via Ant, Maven, or command-line XSLT processors.

> **Note:** A working proof of concept is implemented in the `standalone/` folder. See [Method 5: Standalone Command-Line](#method-5-standalone-command-line-no-docker) in Quick Start for usage instructions.

### Executive Summary

| Aspect | Assessment |
|--------|------------|
| **Feasibility** | ✅ **High** - Core transformation is 99% pure XSLT |
| **Complexity** | Low - Minimal wrapper needed |
| **Single Codebase** | ✅ Yes - Same `bip-to-rdl.xsl` works in both environments |
| **Effort Estimate** | 1-2 days to create Ant/Maven wrapper |

### Architecture Analysis: What's in XSLT vs XQuery

#### Core Transformation (100% XSLT)

The actual BIP-to-RDL conversion is entirely contained in `src/xslt/bip-to-rdl.xsl`:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    XSLT Transformation (bip-to-rdl.xsl)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  INPUT:  XSL-FO template (.xsl-fo file)                                    │
│                                                                             │
│  PROCESSING (all in XSLT):                                                 │
│  • fo:root → Report wrapper                                                 │
│  • fo:table → Tablix with TablixColumns, TablixRows, TablixCells           │
│  • fo:block → Textbox with Paragraphs/TextRuns                             │
│  • xsl:for-each → TablixRowHierarchy groups                                │
│  • xsl:value-of → =Fields!FIELD.Value expressions                          │
│  • Arithmetic (a - b, a + b) → VB expressions                              │
│  • format-number() → Format() calls                                        │
│  • sum() → Sum(Fields!X.Value)                                             │
│  • Page layout (margins, headers, footers)                                 │
│  • Style conversion (fonts, colors, borders)                               │
│                                                                             │
│  OUTPUT: Complete RDL document                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Lines of code:** ~2100 lines in `bip-to-rdl.xsl`

**Single-File Architecture:** The XSLT is intentionally self-contained with no `xsl:import` or `xsl:include` statements. This simplifies standalone deployment — just copy the one file. The modular XSLT files in `src/xslt/fo-to-rdl/`, `xsl-logic/`, and `data-model/` folders are **not currently used** by `bip-to-rdl.xsl`.

> ⚠️ **MAINTENANCE NOTE:** If future development adds `xsl:import` or `xsl:include` to leverage the modular files, the standalone package will need to either:
> 1. Copy all imported/included files to `standalone/xslt/`, or
> 2. Flatten the XSLT back into a single file before copying

#### XQuery Orchestration Layer (Optional Features)

The XQuery code in `convert-stored.xql` provides features **not needed** for basic conversion:

| XQuery Function | Purpose | Needed for Standalone? |
|-----------------|---------|----------------------|
| `transform:transform()` | Call XSLT | ❌ No - Any XSLT processor does this |
| `local:extract-xdm-field-mappings()` | Parse XDM for field aliases | ⚠️ Optional - only affects SQL column naming |
| ~~`local:extract-sql-from-xdm()`~~ | ~~Extract SQL query~~ | ✅ Now in XSLT - via `xdm-uri` parameter |
| `local:create-test-rdl()` | SQL Server preview setup | ❌ No - Only for testing |
| `local:inject-params()` | Add report parameters | ⚠️ Optional - can add manually |
| `sync:upload-to-sql()` | Load test data | ❌ No - Preview feature only |
| File storage/retrieval | eXist-db collections | ❌ No - Use filesystem |

> **Update (v1.15):** SQL extraction is now handled directly by the XSLT when `xdm-uri` parameter is provided. The XSLT reads the XDM file and extracts the SQL from `<xdm:sql>` element.

### Standalone Package Structure

```
bip2ssrs-standalone/
├── build.xml                    # Ant build script
├── pom.xml                      # Maven alternative
├── README.md
│
├── xslt/
│   └── bip-to-rdl.xsl          # ← COPY FROM src/xslt/ (unchanged)
│
├── input/                       # Place .xsl-fo files here
│   └── *.xsl-fo
│
├── output/                      # Generated .rdl files
│   └── *.rdl
│
└── lib/                         # Saxon JAR (XSLT 2.0 processor)
    └── saxon-he-10.9.jar        # v10.9 is self-contained (11.x+ requires xmlresolver)
```

### Sample Ant Build Script

See the actual [standalone/build.xml](standalone/build.xml) for the full implementation. Key features:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="bip2ssrs" default="convert" basedir=".">
    <!-- Core properties -->
    <property name="saxon.jar" value="lib/saxon-he-10.9.jar"/>
    <property name="xslt.file" value="xslt/bip-to-rdl.xsl"/>
    <property name="input.dir" value="input"/>
    <property name="output.dir" value="output"/>
    
    <!-- XSLT Parameters (default values) -->
    <property name="connection-string" 
              value="Data Source=localhost;Initial Catalog=ReportData;Integrated Security=True"/>
    <property name="data-source-name" value="ReportDataSource"/>
    <property name="data-provider" value="SQL"/>
    
    <target name="convert">
        <fail unless="input.file" message="Usage: ant convert -Dinput.file=..."/>
        <basename property="base.name" file="${input.file}" suffix=".xsl-fo"/>
        <java jar="${saxon.jar}" fork="true" failonerror="true">
            <arg value="-s:${input.file}"/>
            <arg value="-xsl:${xslt.file}"/>
            <arg value="-o:${output.dir}/${base.name}.rdl"/>
            <arg value="connection-string=${connection-string}"/>
            <arg value="data-source-name=${data-source-name}"/>
            <arg value="data-provider=${data-provider}"/>
        </java>
    </target>
    
    <target name="convert-with-xdm">
        <fail unless="input.file" message="Usage: ant convert-with-xdm -Dinput.file=... -Dxdm.file=..."/>
        <fail unless="xdm.file" message="Specify -Dxdm.file=path/to/file.xdm"/>
        <basename property="base.name" file="${input.file}" suffix=".xsl-fo"/>
        <java jar="${saxon.jar}" fork="true" failonerror="true">
            <arg value="-s:${input.file}"/>
            <arg value="-xsl:${xslt.file}"/>
            <arg value="-o:${output.dir}/${base.name}.rdl"/>
            <arg value="xdm-uri=${xdm.file}"/>
            <arg value="connection-string=${connection-string}"/>
            <arg value="data-source-name=${data-source-name}"/>
            <arg value="data-provider=${data-provider}"/>
        </java>
    </target>
</project>
```

**Usage:**

```bash
# Convert single file (default connection string)
ant convert -Dinput.file=input/invoice.xsl-fo

# With XDM for SQL extraction
ant convert-with-xdm -Dinput.file=input/invoice.xsl-fo -Dxdm.file=input/invoice.xdm

# With custom connection string
ant convert -Dinput.file=input/invoice.xsl-fo \
    -Dconnection-string="Data Source=prodserver;Initial Catalog=Reports;..."
```

### Command-Line Usage (No Ant Required)

```bash
# Using Saxon directly (basic)
java -jar lib/saxon-he-10.9.jar \
    -s:input/invoice.xsl-fo \
    -xsl:xslt/bip-to-rdl.xsl \
    -o:output/invoice.rdl \
    connection-string="Data Source=myserver;Initial Catalog=ReportDB;..." \
    data-source-name="ReportDataSource"

# With XDM for SQL extraction (URI format required)
java -jar lib/saxon-he-10.9.jar \
    -s:input/invoice.xsl-fo \
    -xsl:xslt/bip-to-rdl.xsl \
    -o:output/invoice.rdl \
    xdm-uri="file:///C:/path/to/invoice.xdm" \
    connection-string="Data Source=server;..."
```

### Folder Batch Conversion Scripts

For batch converting multiple reports, use the provided scripts:

**PowerShell (Windows):**
```powershell
.\scripts\convert-folder.ps1 -InputFolder .\input -OutputFolder .\output `
    -ConnectionString "Data Source=myserver;Initial Catalog=ReportDB;..."
```

**Bash (Linux/macOS):**
```bash
./scripts/convert-folder.sh ./input ./output \
    "Data Source=myserver;Initial Catalog=ReportDB;..."
```

See [Method 5: Standalone Command-Line](#method-5-standalone-command-line-no-docker) for complete documentation.

### XSLT Processor Requirements

The XSLT uses **XSLT 2.0** features:

| Feature Used | XSLT Version |
|--------------|--------------|
| `xsl:analyze-string` | 2.0 |
| `xsl:function` | 2.0 |
| `generate-id()` | 1.0 |
| Named templates | 1.0 |
| `normalize-space()` | 1.0 |

**Compatible Processors:**

| Processor | License | Notes |
|-----------|---------|-------|
| **Saxon-HE** | Open Source (MPL) | ✅ Recommended - full XSLT 2.0/3.0 |
| Saxon-PE/EE | Commercial | Full features + streaming |
| Altova XML | Commercial | IDE included |
| eXist-db | Open Source (LGPL) | Current solution |

**Not Compatible:**
- `xsltproc` (libxslt) - XSLT 1.0 only
- Browser built-in - XSLT 1.0 only
- .NET `XslCompiledTransform` - XSLT 1.0 only (use Saxon.NET for 2.0)

### Potential Challenges

| Challenge | Mitigation |
|-----------|------------|
| **XSLT 2.0 requirement** | Use Saxon-HE (free, well-supported) |
| **Large files** | Saxon supports streaming; not needed for typical reports |
| **XDM parameter extraction** | Add optional pre-processing script, or skip (add params manually in Report Builder) |
| **Namespace handling** | Already handled in XSLT; no changes needed |
| **Error reporting** | Saxon provides detailed XSLT error messages |
| **Hierarchical BIP vs Flat SQL data structure** | BIP templates use XDM-defined hierarchical XPaths (e.g., `/DASHBOARD/KPIS/NPS_SCORE` → field `KPIS_NPS_SCORE`), while SQL result sets are flat rows with simple column names (e.g., `AVG_NPS`). For SSRS preview with SQL data, either: (1) use SQL column aliases matching BIP field names, (2) update the SSRS report field bindings manually, or (3) use PDF preview with hierarchical BIP test data instead. Simple reports with shallow nesting convert cleanly; complex dashboards with deeply nested KPIs require careful field mapping. |

### What Would Be Lost Without eXist-db

| Feature | Impact | Workaround |
|---------|--------|------------|
| Web UI upload | Low | Use command line / file system |
| SQL Server preview | None | Not needed for conversion |
| XDM SQL extraction | Low | Copy SQL manually to SSRS |
| XDM parameter extraction | Low | Add parameters in Report Builder |
| REST API | Low | Use command line instead |
| Report storage | None | Use file system |

### Maintaining Single Codebase

The same `bip-to-rdl.xsl` file works in both environments:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SINGLE SOURCE FILE                                  │
│                                                                             │
│                       src/xslt/bip-to-rdl.xsl                              │
│                              │                                              │
│              ┌───────────────┴───────────────┐                              │
│              ▼                               ▼                              │
│     ┌─────────────────┐             ┌─────────────────┐                    │
│     │   eXist-db      │             │   Standalone    │                    │
│     │   Deployment    │             │   Package       │                    │
│     ├─────────────────┤             ├─────────────────┤                    │
│     │ sync-to-existdb │             │ Copy to         │                    │
│     │ uploads to      │             │ bip2ssrs-       │                    │
│     │ /db/apps/...    │             │ standalone/xslt/│                    │
│     └─────────────────┘             └─────────────────┘                    │
│              │                               │                              │
│              ▼                               ▼                              │
│     Web UI + Preview              Command Line + Ant                        │
│     SQL Server Test Data          File System I/O                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Sync strategy:** When `bip-to-rdl.xsl` changes:
1. Test changes via eXist-db (existing workflow)
2. Copy to standalone package (manual or scripted)
3. Both deployments stay in sync

### Recommendation

**Creating a standalone Ant/Maven package is highly feasible** because:

1. **99% of logic is in XSLT** - The transformation is self-contained
2. **XQuery is just orchestration** - File I/O and SQL preview features, not core logic
3. **Single source file** - No code duplication needed
4. **Saxon-HE is free** - No licensing concerns for XSLT 2.0 processor
5. **Batch processing works** - Simple shell/Ant loop over input files

**Estimated effort:** 1-2 days to:
- Create Ant build.xml and document usage
- Test with Saxon-HE
- Package with README and sample workflow

---

## Release Readiness Assessment

This section provides a consolidated view of implementation status, known limitations, and pre-release checklist items.

### Implementation Status

#### Fully Implemented (Release Ready)

| Category | Feature | Status |
|----------|---------|--------|
| **Core Conversion** | XSL-FO → RDL transformation | ✅ Complete |
| **Tables** | `fo:table` → Tablix with TablixColumns, TablixRows, TablixCells | ✅ Complete |
| **Text** | `fo:block` → Textbox with Paragraphs/TextRuns | ✅ Complete |
| **Loops** | `xsl:for-each` → TablixRowHierarchy groups | ✅ Complete |
| **Conditionals** | `xsl:if`/`xsl:choose` → Visibility expressions | ✅ Complete |
| **Field References** | XPath `select` → `=Fields!FIELD.Value` | ✅ Complete |
| **Arithmetic** | `a - b`, `a + b`, `a * b` → VB.NET expressions | ✅ Complete |
| **Aggregates** | `sum()`, `format-number()` → `Sum()`, `Format()` | ✅ Complete |
| **SQL Extraction** | XDM `<sql>` element → RDL `<CommandText>` | ✅ Complete |
| **Type Inference** | XDM `dataType` → `rd:TypeName` (xsd:integer→Int32, xsd:decimal→Decimal, etc.) | ✅ Complete |
| **Standalone Converter** | Saxon-HE batch conversion with CLI parameters | ✅ Complete |
| **Web UI** | Upload and convert via browser | ✅ Complete |
| **REST API** | `/api/convert-stored`, `/api/upload`, `/api/list-reports` | ✅ Complete |
| **Connection Strings** | Centralized config, CLI parameters, `<ssrs-config>` XML | ✅ Complete |
| **Folder Batch Scripts** | `convert-folder.ps1` (Windows), `convert-folder.sh` (Linux/macOS) | ✅ Complete |

#### Partial Implementation / Placeholder

| Feature | Current State | Notes |
|---------|---------------|-------|
| **Charts** | Documented in spec (§Chart Mapping) but **not implemented** in XSLT | Requires manual conversion in SSRS Report Builder |
| **Images** | `fo:external-graphic` → `Image` mapping documented but **not in XSLT** | Requires manual conversion |
| **Barcodes** | Not supported | Use SSRS custom code or third-party control |
| **Connection string placeholder** | `/* PLACEHOLDER - Pass connection-string parameter */` when parameter not provided | Expected behavior; pass `connection-string` parameter to customize |
| **SQL placeholder** | `/* TODO: Add SQL query */` when no XDM with `<sql>` element | Expected behavior; provide XDM or manually add SQL |
| **Field data types** | ✅ Types inferred from XDM `dataType` attribute | Falls back to `System.String` if XDM not provided or field not found |

#### Explicitly Out of Scope

| Feature | Rationale | Workaround |
|---------|-----------|------------|
| Report parameters | Scope limitation; requires `:param` → `@param` syntax conversion | Manual parameter creation in SSRS |
| Cascading parameters | Scope limitation | Manual recreation using SSRS parameter dependencies |
| Bursting definitions | BI Publisher-specific feature | Recreate using SSRS subscriptions |
| Flash charts | Deprecated technology | Use SSRS native charts |
| Custom XSL functions | Cannot auto-convert arbitrary code | Manual implementation in SSRS custom code |
| BiDi (Right-to-Left) text | Limited XSLT support | Manual configuration in SSRS properties |
| Oracle→T-SQL dialect conversion | SQL copied verbatim | Manual query updates for SQL Server |
| BI Publisher Scheduler jobs | Infrastructure, not template conversion | Manual SSRS subscription setup |
| Java-based extensions | Cannot auto-convert | Manual reimplementation |

### Known Conversion Limitations

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| ~~**SQL parameter syntax**~~ | ~~Oracle `:P_PARAM` not changed to SQL Server `@Param`~~ | ✅ **SOLVED** (v1.18): Use `mode=production` - auto-converts `:P_NAME` and `&P_NAME` to `@P_NAME` |
| **Pixel-perfect positioning** | XSLT approximates; may not be exact | Adjust layout in Report Builder |
| **Complex nested loops** | May require data model restructuring | Flatten data or use subreports |
| **Advanced conditional formatting** | Partial conversion | Manual adjustment of SSRS expressions |
| **Multi-column layouts** | Converted but may need adjustment | Verify column widths in Report Builder |

### Pre-Release Checklist

| Item | Status | Action |
|------|--------|--------|
| Update spec status from "Draft" | ⬜ Pending | Change to "Release Candidate" or "Released" |
| Run regression on all 7 sample reports | ⬜ Pending | Execute standalone converter, verify output |
| Build XAR package | ✅ Done | Version 1.5.0 in `dist/` folder |
| Test bash script on Linux/macOS | ⬜ Pending | Verify `convert-folder.sh` works |
| Document chart/image limitations | ✅ Done | Listed in this section |
| Sync to eXist-db | ⬜ Pending | Run `.\scripts\sync-to-existdb.ps1` |

### Release Recommendation

**Status:** Ready for limited/beta release

**Conditions:**
1. Users must understand that charts, images, and barcodes require manual conversion
2. ~~SQL queries using Oracle bind syntax (`:param`) need manual update for SQL Server~~ ✅ SOLVED: Use `mode=production`
3. ~~Numeric fields may need `rd:TypeName` changed from `System.String` to `System.Decimal`~~ ✅ SOLVED: Types inferred from XDM
4. Layout may require adjustment in Report Builder for pixel-perfect output

**Target Use Cases:**
- Tabular reports (lists, grouped tables, matrices)
- Form-based reports (invoices, purchase orders)
- Financial statements with calculated totals
- Reports with conditional formatting and visibility

**Not Recommended For:**
- Chart-heavy dashboards (without manual chart recreation)
- Reports with complex custom functions
- Reports requiring exact pixel-perfect layout preservation

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-19 | - | Initial specification |
| 1.1 | 2026-02-20 | - | Added troubleshooting section, updated API endpoints, fixed permission handling |
| 1.5 | 2026-02-24 | - | Added XDM data model documentation, eXist-db administration appendix |
| 1.6 | 2026-02-24 | - | Added project maintenance appendix with cleanup recommendations |
| 1.7 | 2026-02-25 | - | Added SQL Server JDBC connectivity appendix with driver configuration details |
| 1.8 | 2026-02-25 | - | Added XSLT Transformation Rules appendix (H) documenting conversion logic |
| 1.9 | 2026-02-26 | - | Added Standalone XSLT Packaging Feasibility appendix (I) |
| 1.10 | 2026-02-26 | - | Flat/hierarchical data model architecture; `-bip.xml` and `-ssrs.xml` dual file pattern; arithmetic expression handling; XAR updated to 1.4.0 |
| 1.11 | 2026-02-26 | - | Implemented standalone XSLT POC in `standalone/` folder with Saxon-HE 10.9; added Method 5 to Quick Start |
| 1.12 | 2026-03-03 | - | Replaced `<?ssrs-connection?>` PI with `<ssrs-config><DataSource>` XML element for production connection strings |
| 1.13 | 2026-03-03 | - | XDM-driven field resolution for group expressions; XAR updated to 1.5.0 |
| 1.14 | 2026-03-03 | - | Added `<bip-data>` and `<ssrs-data>` wrappers to sample data files for clean config/data separation |
| 1.15 | 2026-03-04 | - | Standalone converter: added `connection-string`, `xdm-uri`, `data-source-name`, `data-provider` XSLT parameters; added `convert-folder.ps1` and `convert-folder.sh` batch scripts; XSLT now extracts SQL from XDM `<sql>` element; centralized SQL config in `sync-sql.xqm`; `preview-bip.xql` auto-strips `<bip-data>` wrapper; upload UI updated to "4 files" |
| 1.16 | 2026-03-05 | - | Added Release Readiness Assessment section with implementation status, known limitations, out-of-scope features, and pre-release checklist; updated status to Release Candidate; fixed PowerShell `$args` reserved variable issue in `convert-folder.ps1` |
| 1.17 | 2026-03-05 | - | Added XDM-based field type inference: XSLT now reads `dataType` attribute from XDM elements and maps XSD types (xsd:integer, xsd:decimal, xsd:date, xsd:boolean) to .NET types (System.Int32, System.Decimal, System.DateTime, System.Boolean); falls back to System.String when XDM not provided |

---

*End of Specification Document*
