# BIP Conversion Intermediary Model

A practical intermediate model should preserve three things:

1. **Report semantics** — datasets, parameters, fields, groups, calculations.
2. **Layout intent** — pages, headers, tables, text, styles, regions.
3. **Source traceability** — where every item came from in BI Publisher/XSL-FO/Excel.

The model should not try to reproduce all XSL-FO or Excel XML. It should use a small, controlled vocabulary that maps cleanly to SSRS RDL.

Below is a workable first version, called `report-model.xml`.

## Example intermediate XML

This example represents an invoice report with a report header, parameter, repeating line table, and total.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<report-model
    xmlns="
    version="1.0"
    name="PLI010 Invoice Report">

    <!-- How this model was created and where its elements came from -->
    <sources>
        <source id="xdoz"
                type="xdoz"
                path="pli010.xdoz"/>

        <source id="template"
                type="excel-template"
                path="pli010_en.xls"/>

        <source id="reportDefinition"
                type="bip-report-definition"
                path="_report.xdo"/>

        <source id="fo"
                type="xsl-fo"
                path="pli010-debug.fo"
                optional="true"/>

        <source id="sampleData"
                type="xml-data"
                path="pli010-sample-data.xml"
                optional="true"/>
    </sources>

    <!-- Report execution model. Populate from _report.xdo or a separately
         supplied data-model export. -->
    <data>
        <data-source id="ERP"
                     provider="Oracle"
                     name="ERP_PROD"
                     connection-ref="ERP_PROD"/>

        <parameters>
            <parameter id="P_INVOICE_ID"
                       name="P_INVOICE_ID"
                       data-type="String"
                       nullable="false"
                       prompt="Invoice ID">
                <source-ref source-id="reportDefinition"
                            location=">
            </parameter>
        </parameters>

        <datasets>
            <dataset id="InvoiceData"
                     name="InvoiceData"
                     data-source-ref="ERP">

                <query language="sql"><![CDATA[
SELECT
    h.invoice_id,
    h.invoice_number,
    h.customer_name,
    l.line_number,
    l.item_description,
    l.amount
FROM invoice_header h
JOIN invoice_line l
  ON l.invoice_id = h.invoice_id
WHERE h.invoice_id = :P_INVOICE_ID
ORDER BY l.line_number
                ]]></query>

                <!-- Lets the RDL generator rewrite Oracle bind syntax if needed. -->
                <query-parameters>
                    <query-parameter name="P_INVOICE_ID"
                                     source-parameter-ref="P_INVOICE_ID"
                                     source-token=":P_INVOICE_ID"/>
                </query-parameters>

                <fields>
                    <field name="INVOICE_ID" type="String"/>
                    <field name="INVOICE_NUMBER" type="String"/>
                    <field name="CUSTOMER_NAME" type="String"/>
                    <field name="LINE_NUMBER" type="Integer"/>
                    <field name="ITEM_DESCRIPTION" type="String"/>
                    <field name="AMOUNT" type="Decimal"/>
                </fields>

                <source-ref source-id="reportDefinition"
                            location=">
            </dataset>
        </datasets>
    </data>

    <!-- Page-level layout. For XSL-FO this comes mainly from
          For Excel it can come from print setup. -->
    <page width="11in"
          height="8.5in"
          orientation="landscape"
          margin-top="0.40in"
          margin-bottom="0.40in"
          margin-left="0.35in"
          margin-right="0.35in">

        <header height="0.35in">
            <textbox id="HeaderTitle"
                     x="0in"
                     y="0in"
                     width="7in"
                     height="0.25in"
                     value="Invoice Report">
                <style font-family="Arial"
                       font-size="9pt"
                       font-weight="bold"/>
            </textbox>

            <textbox id="HeaderPage"
                     x="9.25in"
                     y="0in"
                     width="1.4in"
                     height="0.25in"
                     value="Page {page-number} of {total-pages}"
                     text-align="right">
                <style font-family="Arial"
                       font-size="9pt"/>
            </textbox>
        </header>

        <footer height="0.25in">
            <textbox id="FooterGenerated"
                     x="0in"
                     y="0in"
                     width="10.3in"
                     height="0.20in"
                     value="Generated {execution-time}"
                     text-align="right">
                <style font-family="Arial"
                       font-size="8pt"
                       color="#666666"/>
            </textbox>
        </footer>
    </page>

    <body width="10.30in">

        <!-- Static report title, possibly derived from a merged Excel range
             or an  in XSL-FO. -->
        <textbox id="ReportTitle"
                 x="0in"
                 y="0in"
                 width="10.30in"
                 height="0.32in"
                 value="Invoice Detail"
                 text-align="center">
            <style font-family="Arial"
                   font-size="16pt"
                   font-weight="bold"/>
            <source-ref source-id="template"
                        location="Sheet1!
                        source-range=">
        </textbox>

        <region id="InvoiceHeader"
                type="freeform"
                x="0in"
                y="0.48in"
                width="10.30in"
                height="0.62in">

            <textbox id="InvoiceLabel"
                     x="0in"
                     y="0in"
                     width="1.1in"
                     height="0.22in"
                     value=">
                <style font-weight="bold"/>
            </textbox>

            <textbox id="InvoiceNumber"
                     x="1.1in"
                     y="0in"
                     width="2.2in"
                     height="0.22in"
                     expression="field('INVOICE_NUMBER')"
                     dataset-ref="InvoiceData">
                <source-ref source-id="template"
                            location="Sheet1!B3"
                            source-expression="&lt;?INVOICE_NUMBER?&gt;"/>
            </textbox>

            <textbox id="CustomerLabel"
                     x="0in"
                     y="0.30in"
                     width="1.1in"
                     height="0.22in"
                     value=">
                <style font-weight="bold"/>
            </textbox>

            <textbox id="CustomerName"
                     x="1.1in"
                     y="0.30in"
                     width="4.0in"
                     height="0.22in"
                     expression="field('CUSTOMER_NAME')"
                     dataset-ref="InvoiceData">
                <source-ref source-id="template"
                            location="Sheet1!B4"
                            source-expression="&lt;?CUSTOMER_NAME?&gt;"/>
            </textbox>
        </region>

        <!-- A repeating BI Publisher group becomes a tablix. -->
        <tablix id="InvoiceLines"
                dataset-ref="InvoiceData"
                x="0in"
                y="1.30in"
                width="10.30in"
                repeat-header-on-new-page="true">

            <source-ref source-id="template"
                        location="Sheet1!
                        source-range=">

            <source-ref source-id="template"
                        location="Sheet1!A8"
                        source-expression="&lt;?>

            <groups>
                <group id="LineDetails"
                       type="details"
                       data-path="/DATA_DS/G_INVOICE/G_LINE">
                    <source-ref source-id="fo"
                                location="/
                                optional="true"/>
                </group>
            </groups>

            <columns>
                <column id="LineNumberColumn" width="0.85in"/>
                <column id="DescriptionColumn" width="6.65in"/>
                <column id="AmountColumn" width="2.80in"/>
            </columns>

            <header-row height="0.26in">
                <cell column-ref="LineNumberColumn" value="Line">
                    <style background-color="#D9EAF7"
                           font-weight="bold"
                           border-bottom="solid 1pt #4F81BD"
                           padding-left="3pt"
                           vertical-align="middle"/>
                </cell>

                <cell column-ref="DescriptionColumn" value="Description">
                    <style background-color="#D9EAF7"
                           font-weight="bold"
                           border-bottom="solid 1pt #4F81BD"
                           padding-left="3pt"
                           vertical-align="middle"/>
                </cell>

                <cell column-ref="AmountColumn"
                      value="Amount"
                      text-align="right">
                    <style background-color="#D9EAF7"
                           font-weight="bold"
                           border-bottom="solid 1pt #4F81BD"
                           padding-right="3pt"
                           vertical-align="middle"/>
                </cell>
            </header-row>

            <detail-row height="0.24in">
                <cell column-ref="LineNumberColumn"
                      expression="field('LINE_NUMBER')">
                    <style border-bottom="solid 0.25pt #CCCCCC"
                           padding-left="3pt"/>
                    <source-ref source-id="template"
                                location="Sheet1!A9"
                                source-expression="&lt;?LINE_NUMBER?&gt;"/>
                </cell>

                <cell column-ref="DescriptionColumn"
                      expression="field('ITEM_DESCRIPTION')">
                    <style border-bottom="solid 0.25pt #CCCCCC"
                           padding-left="3pt"/>
                    <source-ref source-id="template"
                                location="Sheet1!B9"
                                source-expression="&lt;?ITEM_DESCRIPTION?&gt;"/>
                </cell>

                <cell column-ref="AmountColumn"
                      expression="field('AMOUNT')"
                      format="#,##0.00"
                      text-align="right">
                    <style border-bottom="solid 0.25pt #CCCCCC"
                           padding-right="3pt"/>
                    <source-ref source-id="template"
                                location="Sheet1!C9"
                                source-expression="&lt;?AMOUNT?&gt;"/>
                </cell>
            </detail-row>

            <footer-row height="0.28in">
                <cell column-span="2"
                      value="Total"
                      text-align="right">
                    <style font-weight="bold"
                           border-top="solid 1pt #000000"
                           padding-right="3pt"/>
                </cell>

                <cell column-ref="AmountColumn"
                      expression="sum(field('AMOUNT'))"
                      format="#,##0.00"
                      text-align="right">
                    <style font-weight="bold"
                           border-top="solid 1pt #000000"
                           padding-right="3pt"/>
                    <source-ref source-id="template"
                                location="Sheet1!C10"
                                source-expression="&lt;?sum(AMOUNT)?&gt;"/>
                </cell>
            </footer-row>
        </tablix>
    </body>

    <!-- Preserve anything not automatically converted. -->
    <conversion-notes>
        <note severity="warning"
              code="DATA_MODEL_UNVERIFIED">
            Dataset definition has not yet been validated against a live BI
            Publisher data model or sample XML data.
        </note>

        <note severity="info"
              code="SOURCE_TEMPLATE">
            Layout items were inferred from Excel coordinates and BI Publisher
            commands. Verify visual output against BI Publisher PDF output.
        </note>
    </conversion-notes>
</report-model>
```

## Why this is a useful model

It is deliberately not tied to either BI Publisher or SSRS:

| Intermediate element | BI Publisher/XSL-FO/Excel origin | SSRS RDL target |
|---|---|---|
| `parameter` | XDO/report definition | `ReportParameter` |
| `dataset` | XDO/report definition | `DataSet` |
| `textbox` | Excel cell / ` | `Textbox` |
| `region` | Excel area / FO block container | Rectangle or report body area |
| `tablix` | Excel repeating rows / ` | `Tablix` |
| `group` | `for-each` / XML hierarchy | Row group or details group |
| `expression` | BIP tag/XPath/calculation | SSRS expression |
| `style` | Excel formatting / FO properties | RDL `Style` |
| `source-ref` | Original source coordinate/path | Conversion audit trail |
| `conversion-notes` | Unsupported or uncertain constructs | Manual-review list |

## Expression conventions

Keep the intermediate model expressions independent of SSRS syntax. For an initial prototype, support a small set:

```xml
expression="field('AMOUNT')"
expression="parameter('P_INVOICE_ID')"
expression="sum(field('AMOUNT'))"
expression="concat(field('FIRST_NAME'), ' ', field('LAST_NAME'))"
expression="if(field('STATUS') = 'CLOSED', 'Closed', 'Open')"
```

The RDL generator then translates them:

```text
field('AMOUNT')
→ =Fields!AMOUNT.Value

parameter('P_INVOICE_ID')
→ =Parameters!P_INVOICE_ID.Value

sum(field('AMOUNT'))
→ =Sum(Fields!AMOUNT.Value)

if(field('STATUS') = 'CLOSED', 'Closed', 'Open')
→ =IIF(Fields!STATUS.Value = "CLOSED", "Closed", "Open")
```

Do not store raw BI Publisher expressions as the only representation. Preserve the original expression in `source-ref`, but convert it into an intermediate expression only when it is understood.

## Minimum XSD skeleton

This is not a complete schema, but it is enough to validate the top-level document and establish a versioned contract.

```xml
<?xml version="1.0" encoding="UTF-8"?>
< 
           targetNamespace="
           xmlns="
           elementFormDefault="qualified">

    
        
            
                
                
                
                
                < name="conversion-notes" type="notesType"
                            minOccurs="0"/>
            </>
            
            
        </>
    </>

    
        
            
        </>
    </>

    
        
            < name="data-source" minOccurs="0"
                        maxOccurs="unbounded"/>
            
            
        </>
    </>

    
        
            
            
        </>
        
        
        
    </>

    
        
            
            
            
        </>
        
    </>

    
        
            
        </>
    </>
</>
```

In a real project, use Relax NG or a fuller XSD once the model stabilizes. Do not over-design the schema before you have seen several actual reports.

## Suggested pipeline

```text
XDOZ / RTF / XSL-FO / sample XML
            │
            ▼
      Source-specific parsers
  ┌─────────────────────────────┐
  │ Excel parser: Apache POI    │
  │ XDO parser: Java XML/Saxon  │
  │ FO parser: Java XML/Saxon   │
  │ RTF: optional, indirect     │
  └─────────────────────────────┘
            │
            ▼
       report-model.xml
            │
            ├─ Validate against model schema
            ├─ Record unsupported constructs
            └─ Review/edit if necessary
            │
            ▼
        RDL generator
            │
            ▼
          report.rdl
```

## Practical first scope

For a first prototype, support only:

- Static text
- Single field references
- Simple parameters
- One dataset
- One repeating table/details group
- Column headers
- Numeric/date formatting
- `sum()` aggregates
- Basic page header/footer
- Cell borders, background colors, font settings, and alignment
- Warning records for everything else

That scope is enough to prove the architecture with either:

- an Excel BI Publisher template, or
- a debug XSL-FO output from an RTF BI Publisher report.

The key design choice is that `report-model.xml` becomes your stable contract. Apache POI, Saxon, BI Publisher formats, and RDL versions can change independently behind that contract.
