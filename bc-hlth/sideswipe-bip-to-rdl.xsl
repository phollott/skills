<!--
  Simplified single-file XSL-FO to SSRS RDL transformation
  This version has no includes for simpler deployment
-->
<xsl:stylesheet xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rd="http://schemas.microsoft.com/SQLServer/reporting/reportdesigner" xmlns:xdofo="http://xmlns.oracle.com/oxp/fo/extensions" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://local.functions" xmlns:xdm="http://xmlns.oracle.com/oxp/xmlp" version="2.0" exclude-result-prefixes="fo xdofo xs local xdm">

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <!-- XDM URI parameter for field resolution - loaded via doc() -->
    <xsl:param name="xdm-uri" as="xs:string?" select="()"/>
    <xsl:variable name="xdm" as="document-node()?" select="if (exists($xdm-uri) and $xdm-uri != '') then doc($xdm-uri) else ()"/>
    
    <!-- Connection string parameter for standalone conversion -->
    <xsl:param name="connection-string" as="xs:string" select="''"/>
    <xsl:param name="data-source-name" as="xs:string" select="'DataSource1'"/>
    <xsl:param name="data-provider" as="xs:string" select="'SQL'"/>
    
    <!-- Mode: 'preview' uses sample table, 'production' uses XDM SQL with param conversion -->
    <xsl:param name="mode" as="xs:string" select="'production'"/>
    <xsl:param name="preview-table-name" as="xs:string" select="'SampleData'"/>
    <xsl:param name="report-author" as="xs:string" select="'BIP-to-SSRS Converter'"/>
    
    <!-- ========== TYPE MAPPING: XSD to .NET ========== -->
    <!-- Look up dataType from XDM for a given field name -->
    <xsl:function name="local:get-xdm-type" as="xs:string">
        <xsl:param name="field-name" as="xs:string"/>
        <xsl:param name="xdm-doc" as="document-node()?"/>
        <xsl:variable name="xdm-element" select="$xdm-doc//*[@name = $field-name][@dataType][1]"/>
        <xsl:choose>
            <xsl:when test="$xdm-element/@dataType">
                <xsl:value-of select="local:xsd-to-dotnet(string($xdm-element/@dataType))"/>
            </xsl:when>
            <xsl:otherwise>System.String</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Map XSD types to .NET types -->
    <xsl:function name="local:xsd-to-dotnet" as="xs:string">
        <xsl:param name="xsd-type" as="xs:string"/>
        <xsl:variable name="type" select="lower-case(replace($xsd-type, '^xsd:', ''))"/>
        <xsl:choose>
            <xsl:when test="$type = 'integer' or $type = 'int' or $type = 'long' or $type = 'short'">System.Int32</xsl:when>
            <xsl:when test="$type = 'decimal' or $type = 'float' or $type = 'double' or $type = 'number'">System.Decimal</xsl:when>
            <xsl:when test="$type = 'date' or $type = 'datetime' or $type = 'time'">System.DateTime</xsl:when>
            <xsl:when test="$type = 'boolean' or $type = 'bool'">System.Boolean</xsl:when>
            <xsl:otherwise>System.String</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Map XSD types to SSRS ReportParameter DataType -->
    <xsl:function name="local:xsd-to-ssrs-datatype" as="xs:string">
        <xsl:param name="xsd-type" as="xs:string"/>
        <xsl:variable name="type" select="lower-case(replace($xsd-type, '^xsd:', ''))"/>
        <xsl:choose>
            <xsl:when test="$type = 'integer' or $type = 'int' or $type = 'long' or $type = 'short'">Integer</xsl:when>
            <xsl:when test="$type = 'decimal' or $type = 'float' or $type = 'double' or $type = 'number'">Float</xsl:when>
            <xsl:when test="$type = 'date' or $type = 'datetime' or $type = 'time'">DateTime</xsl:when>
            <xsl:when test="$type = 'boolean' or $type = 'bool'">Boolean</xsl:when>
            <xsl:otherwise>String</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Convert BIP parameter syntax (:P_NAME or &P_NAME) to SSRS syntax (@P_NAME) -->
    <xsl:function name="local:convert-bip-params" as="xs:string">
        <xsl:param name="sql" as="xs:string"/>
        <xsl:param name="xdm-doc" as="document-node()?"/>
        <xsl:choose>
            <xsl:when test="$xdm-doc//*[local-name()='parameter']">
                <!-- Build regex pattern from known parameter names -->
                <xsl:variable name="param-names" select="$xdm-doc//*[local-name()='parameters']/*[local-name()='parameter']/@name"/>
                <xsl:variable name="converted" as="xs:string">
                    <xsl:value-of>
                        <xsl:analyze-string select="$sql" regex=":({string-join($param-names, '|')})([^A-Za-z0-9_]|$)" flags="i">
                            <xsl:matching-substring>@<xsl:value-of select="regex-group(1)"/><xsl:value-of select="regex-group(2)"/></xsl:matching-substring>
                            <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:value-of>
                </xsl:variable>
                <!-- Also convert &P_NAME syntax -->
                <xsl:value-of>
                    <xsl:analyze-string select="$converted" regex="&amp;({string-join($param-names, '|')})([^A-Za-z0-9_]|$)" flags="i">
                        <xsl:matching-substring>@<xsl:value-of select="regex-group(1)"/><xsl:value-of select="regex-group(2)"/></xsl:matching-substring>
                        <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:value-of>
            </xsl:when>
            <xsl:otherwise>
                <!-- No XDM params - do basic conversion of :P_ and &P_ prefixes -->
                <xsl:value-of select="replace(replace($sql, ':P_', '@P_'), '&amp;P_', '@P_')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- ========== ROOT TEMPLATE ========== -->
    <xsl:template match="/">
        <Report xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition" xmlns:rd="http://schemas.microsoft.com/SQLServer/reporting/reportdesigner">
            <rd:ReportUnitType>Inch</rd:ReportUnitType>
            <AutoRefresh>0</AutoRefresh>
            
            <!-- Report metadata from XDM -->
            <xsl:if test="$xdm//*[local-name()='description']">
                <Description><xsl:value-of select="$xdm//*[local-name()='dataModel']/*[local-name()='description'][1]"/></Description>
            </xsl:if>
            <Author><xsl:value-of select="$report-author"/></Author>
            
            <!-- Data Sources -->
            <DataSources>
                <DataSource Name="{$data-source-name}">
                    <ConnectionProperties>
                        <DataProvider><xsl:value-of select="$data-provider"/></DataProvider>
                        <ConnectString>
                            <xsl:choose>
                                <xsl:when test="$connection-string != ''">
                                    <xsl:value-of select="$connection-string"/>
                                </xsl:when>
                                <xsl:otherwise>/* PLACEHOLDER - Pass connection-string parameter */</xsl:otherwise>
                            </xsl:choose>
                        </ConnectString>
                    </ConnectionProperties>
                    <rd:DataSourceID>12345678-1234-1234-1234-123456789abc</rd:DataSourceID>
                </DataSource>
            </DataSources>
            
            <!-- Generate DataSets from field references -->
            <DataSets>
                <DataSet Name="DataSet1">
                    <Query>
                        <DataSourceName><xsl:value-of select="$data-source-name"/></DataSourceName>
                        <CommandText>
                            <xsl:choose>
                                <!-- Production mode: use XDM SQL with BIP-to-SSRS param conversion -->
                                <xsl:when test="$mode = 'production' and $xdm//xdm:sql">
                                    <xsl:value-of select="local:convert-bip-params(normalize-space($xdm//xdm:sql[1]), $xdm)"/>
                                </xsl:when>
                                <xsl:when test="$mode = 'production' and $xdm//*[local-name()='sql']">
                                    <xsl:value-of select="local:convert-bip-params(normalize-space($xdm//*[local-name()='sql'][1]), $xdm)"/>
                                </xsl:when>
                                <!-- Preview mode: use simple SELECT from sample table -->
                                <xsl:when test="$mode = 'preview'">SELECT * FROM <xsl:value-of select="$preview-table-name"/></xsl:when>
                                <!-- Fallback: Only triggered when XDM is missing or has no <sql> element.
                                     A well-formed XDM with a complete <sql> section will never reach this branch. -->
                                <xsl:otherwise>/* TODO: Add SQL query */
SELECT * FROM YourTable</xsl:otherwise>
                            </xsl:choose>
                        </CommandText>
                        <!-- Generate QueryParameters in production mode to link SQL @params to ReportParameters -->
                        <xsl:if test="$mode = 'production' and $xdm//*[local-name()='parameter']">
                            <QueryParameters>
                                <xsl:for-each select="$xdm//*[local-name()='parameters']/*[local-name()='parameter']">
                                    <QueryParameter Name="@{@name}">
                                        <Value>=Parameters!<xsl:value-of select="@name"/>.Value</Value>
                                    </QueryParameter>
                                </xsl:for-each>
                            </QueryParameters>
                        </xsl:if>
                    </Query>
                    <Fields>
                        <xsl:call-template name="generate-fields"/>
                    </Fields>
                </DataSet>
            </DataSets>
            
            <!-- Generate ReportParameters from XDM in production mode only -->
            <xsl:if test="$mode = 'production' and $xdm//*[local-name()='parameter']">
                <ReportParameters>
                    <xsl:for-each select="$xdm//*[local-name()='parameters']/*[local-name()='parameter']">
                        <ReportParameter Name="{@name}">
                            <DataType>
                                <xsl:choose>
                                    <xsl:when test="@dataType">
                                        <xsl:value-of select="local:xsd-to-ssrs-datatype(string(@dataType))"/>
                                    </xsl:when>
                                    <xsl:otherwise>String</xsl:otherwise>
                                </xsl:choose>
                            </DataType>
                            <xsl:if test="@defaultValue">
                                <DefaultValue>
                                    <Values>
                                        <Value><xsl:value-of select="@defaultValue"/></Value>
                                    </Values>
                                </DefaultValue>
                            </xsl:if>
                            <Nullable><xsl:value-of select="if (@required = 'false' or not(@required)) then 'true' else 'false'"/></Nullable>
                            <AllowBlank><xsl:value-of select="if (@required = 'true') then 'false' else 'true'"/></AllowBlank>
                            <Prompt>
                                <xsl:choose>
                                    <xsl:when test="*[local-name()='description']">
                                        <xsl:value-of select="*[local-name()='description']"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="@name"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </Prompt>
                        </ReportParameter>
                    </xsl:for-each>
                </ReportParameters>
                
                <!-- Generate ReportParametersLayout to match ReportParameters (required by SSRS) -->
                <ReportParametersLayout>
                    <GridLayoutDefinition>
                        <NumberOfColumns>2</NumberOfColumns>
                        <xsl:variable name="param-count" select="count($xdm//*[local-name()='parameters']/*[local-name()='parameter'])"/>
                        <NumberOfRows><xsl:value-of select="ceiling($param-count div 2)"/></NumberOfRows>
                        <CellDefinitions>
                            <xsl:for-each select="$xdm//*[local-name()='parameters']/*[local-name()='parameter']">
                                <xsl:variable name="pos" select="position() - 1"/>
                                <CellDefinition>
                                    <ColumnIndex><xsl:value-of select="$pos mod 2"/></ColumnIndex>
                                    <RowIndex><xsl:value-of select="floor($pos div 2)"/></RowIndex>
                                    <ParameterName><xsl:value-of select="@name"/></ParameterName>
                                </CellDefinition>
                            </xsl:for-each>
                        </CellDefinitions>
                    </GridLayoutDefinition>
                </ReportParametersLayout>
            </xsl:if>
            
            <!-- Apply templates to fo:root (only process one, even if wrapped in xsl:stylesheet) -->
            <xsl:choose>
                <xsl:when test="/xsl:stylesheet//fo:root">
                    <!-- BIP compiled template - fo:root inside xsl:stylesheet -->
                    <xsl:apply-templates select="/xsl:stylesheet//fo:root[1]"/>
                </xsl:when>
                <xsl:when test="//fo:root">
                    <!-- Direct fo:root document -->
                    <xsl:apply-templates select="//fo:root[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Fallback: Empty report shell for malformed input without fo:root.
                         A valid BIP XSL-FO template will always have fo:root and skip this branch. -->
                    <ReportSections>
                        <ReportSection>
                            <Body>
                                <ReportItems/>
                                <Height>11in</Height>
                            </Body>
                            <Width>8.5in</Width>
                            <Page>
                                <PageHeight>11in</PageHeight>
                                <PageWidth>8.5in</PageWidth>
                            </Page>
                        </ReportSection>
                    </ReportSections>
                </xsl:otherwise>
            </xsl:choose>
        </Report>
    </xsl:template>

    <!-- ========== GENERATE FIELDS FROM XSL:VALUE-OF, XSL:WITH-PARAM, AND XSL:VARIABLE ========== -->
    <xsl:template name="generate-fields">
        <!-- Collect selects from xsl:value-of, xsl:with-param, and xsl:variable (for grouping contexts) -->
        <xsl:variable name="all-selects" select="//xsl:value-of/@select | //xsl:with-param/@select | //xsl:variable/@select"/>
        <!-- Use a key-based approach to get unique field names -->
        <xsl:for-each select="$all-selects">
            <xsl:variable name="raw-xpath" select="string(.)"/>
            <xsl:choose>
                <!-- Arithmetic expressions: use helper to extract all operand fields -->
                <xsl:when test="contains($raw-xpath, ' - ') or contains($raw-xpath, ' + ')">
                    <xsl:call-template name="generate-unique-field-from-expr">
                        <xsl:with-param name="expr" select="$raw-xpath"/>
                        <xsl:with-param name="position" select="position()"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- Regular single-field expressions -->
                <xsl:otherwise>
                    <!-- Extract the xpath - handle function wrappers like format-number(xpath, ...) -->
                    <xsl:variable name="extracted-xpath">
                        <xsl:call-template name="extract-xpath-from-expr">
                            <xsl:with-param name="expr" select="$raw-xpath"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:if test="normalize-space($extracted-xpath) != ''">
                        <xsl:variable name="field-name">
                            <xsl:call-template name="xpath-to-field">
                                <xsl:with-param name="xpath" select="$extracted-xpath"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <!-- Check if this field name was already generated by checking preceding elements -->
                        <xsl:variable name="current-field" select="normalize-space($field-name)"/>
                        <xsl:variable name="is-duplicate">
                            <xsl:for-each select="(preceding::xsl:value-of/@select | preceding::xsl:with-param/@select | preceding::xsl:variable/@select)">
                                <xsl:variable name="prev-extracted">
                                    <xsl:call-template name="extract-xpath-from-expr">
                                        <xsl:with-param name="expr" select="string(.)"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:variable name="prev-field">
                                    <xsl:call-template name="xpath-to-field">
                                        <xsl:with-param name="xpath" select="$prev-extracted"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="normalize-space($prev-field) = $current-field">
                                    <xsl:text>yes</xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:if test="$is-duplicate = '' and $current-field != '' and $current-field != 'Field1' and $current-field != '.'">
                            <xsl:element name="Field" namespace="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                                <xsl:attribute name="Name">
                                    <xsl:value-of select="$current-field"/>
                                </xsl:attribute>
                                <xsl:element name="DataField" namespace="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                                    <xsl:value-of select="$current-field"/>
                                </xsl:element>
                                <rd:TypeName><xsl:value-of select="local:get-xdm-type($current-field, $xdm)"/></rd:TypeName>
                            </xsl:element>
                        </xsl:if>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ========== HELPER: Generate unique Field from expression (handles arithmetic) ========== -->
    <xsl:template name="generate-unique-field-from-expr">
        <xsl:param name="expr"/>
        <xsl:param name="position"/>
        <xsl:variable name="trimmed" select="normalize-space($expr)"/>
        <xsl:choose>
            <!-- Subtraction: process both sides -->
            <xsl:when test="contains($trimmed, ' - ')">
                <xsl:variable name="left" select="normalize-space(substring-before($trimmed, ' - '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($trimmed, ' - '))"/>
                <xsl:call-template name="generate-unique-field-from-expr">
                    <xsl:with-param name="expr" select="$left"/>
                    <xsl:with-param name="position" select="$position"/>
                </xsl:call-template>
                <xsl:call-template name="generate-unique-field-from-expr">
                    <xsl:with-param name="expr" select="$right"/>
                    <xsl:with-param name="position" select="$position"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Addition: process both sides -->
            <xsl:when test="contains($trimmed, ' + ')">
                <xsl:variable name="left" select="normalize-space(substring-before($trimmed, ' + '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($trimmed, ' + '))"/>
                <xsl:call-template name="generate-unique-field-from-expr">
                    <xsl:with-param name="expr" select="$left"/>
                    <xsl:with-param name="position" select="$position"/>
                </xsl:call-template>
                <xsl:call-template name="generate-unique-field-from-expr">
                    <xsl:with-param name="expr" select="$right"/>
                    <xsl:with-param name="position" select="$position"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Single field: output it if not a duplicate -->
            <xsl:otherwise>
                <xsl:variable name="extracted">
                    <xsl:call-template name="extract-xpath-from-expr">
                        <xsl:with-param name="expr" select="$trimmed"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="normalize-space($extracted) != ''">
                    <xsl:variable name="field-name">
                        <xsl:call-template name="xpath-to-field">
                            <xsl:with-param name="xpath" select="$extracted"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="current-field" select="normalize-space($field-name)"/>
                    <!-- Check if already generated (simplified check for arithmetic operands) -->
                    <xsl:variable name="is-duplicate">
                        <xsl:for-each select="(//xsl:value-of/@select | //xsl:with-param/@select | //xsl:variable/@select)[position() &lt; $position]">
                            <xsl:if test="contains(string(.), $current-field)">
                                <xsl:text>yes</xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:if test="$is-duplicate = '' and $current-field != '' and $current-field != 'Field1' and $current-field != '.'">
                        <xsl:element name="Field" namespace="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                            <xsl:attribute name="Name">
                                <xsl:value-of select="$current-field"/>
                            </xsl:attribute>
                            <xsl:element name="DataField" namespace="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                                <xsl:value-of select="$current-field"/>
                            </xsl:element>
                            <rd:TypeName><xsl:value-of select="local:get-xdm-type($current-field, $xdm)"/></rd:TypeName>
                        </xsl:element>
                    </xsl:if>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========== HELPER: Extract xpath from expression (handles function wrappers) ========== -->
    <xsl:template name="extract-xpath-from-expr">
        <xsl:param name="expr"/>
        <xsl:variable name="trimmed" select="normalize-space($expr)"/>
        <xsl:choose>
            <!-- format-number(xpath, format) - extract first argument -->
            <xsl:when test="starts-with($trimmed, 'format-number(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-number(')"/>
                <xsl:variable name="first-arg">
                    <xsl:choose>
                        <xsl:when test="contains($inner, ',')">
                            <xsl:value-of select="substring-before($inner, ',')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring-before($inner, ')')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- Recursively extract in case of nested functions -->
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$first-arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- sum(xpath) - extract argument -->
            <xsl:when test="starts-with($trimmed, 'sum(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'sum(')"/>
                <xsl:variable name="arg" select="substring-before($inner, ')')"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- count(xpath) - skip, not a data field -->
            <xsl:when test="starts-with($trimmed, 'count(')"/>
            <!-- position() - skip, not a data field -->
            <xsl:when test="starts-with($trimmed, 'position(')"/>
            <!-- string(xpath) -->
            <xsl:when test="starts-with($trimmed, 'string(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'string(')"/>
                <xsl:variable name="arg" select="substring-before($inner, ')')"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- number(xpath) -->
            <xsl:when test="starts-with($trimmed, 'number(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'number(')"/>
                <xsl:variable name="arg" select="substring-before($inner, ')')"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- format-date(xpath, picture) - extract first argument -->
            <xsl:when test="starts-with($trimmed, 'format-date(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-date(')"/>
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$first-arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- format-dateTime(xpath, picture) - extract first argument -->
            <xsl:when test="starts-with($trimmed, 'format-dateTime(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-dateTime(')"/>
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$first-arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- substring(xpath, ...) - extract first argument (the field) -->
            <xsl:when test="starts-with($trimmed, 'substring(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'substring(')"/>
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$first-arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- string-length(xpath) - extract the argument -->
            <xsl:when test="starts-with($trimmed, 'string-length(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'string-length(')"/>
                <xsl:variable name="arg" select="normalize-space(substring-before($inner, ')'))"/>
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="$arg"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Other function calls - skip -->
            <xsl:when test="contains($trimmed, '(') and not(contains(substring-before($trimmed, '('), '/'))"/>
            <!-- String literals (quoted values) - skip, not field references -->
            <xsl:when test="starts-with($trimmed, &quot;'&quot;) and substring($trimmed, string-length($trimmed)) = &quot;'&quot;"/>
            <!-- Numeric literals - skip -->
            <xsl:when test="number($trimmed) = number($trimmed)"/>
            <!-- Arithmetic expressions: extract first operand -->
            <xsl:when test="contains($trimmed, ' - ')">
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="normalize-space(substring-before($trimmed, ' - '))"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="contains($trimmed, ' + ')">
                <xsl:call-template name="extract-xpath-from-expr">
                    <xsl:with-param name="expr" select="normalize-space(substring-before($trimmed, ' + '))"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Regular xpath -->
            <xsl:otherwise>
                <xsl:value-of select="$trimmed"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== FO:ROOT TEMPLATE ========== -->
    <xsl:template match="fo:root">
        <xsl:variable name="page-master" select="fo:layout-master-set/fo:simple-page-master[1]"/>
        
        <ReportSections xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
            <ReportSection>
                <Body>
                    <ReportItems>
                        <!-- Process header content first (static-content for region-before) -->
                        <xsl:apply-templates select="fo:page-sequence/fo:static-content[@flow-name='xsl-region-before']"/>
                        <!-- Process main body content -->
                        <xsl:apply-templates select="fo:page-sequence/fo:flow/*"/>
                        <!-- Footer is in PageFooter section, not here -->
                    </ReportItems>
                    <Height>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="$page-master/@page-height"/>
                            <xsl:with-param name="default" select="'11in'"/>
                        </xsl:call-template>
                    </Height>
                </Body>
                <Width>
                    <xsl:call-template name="normalize-size">
                        <xsl:with-param name="size" select="$page-master/@page-width"/>
                        <xsl:with-param name="default" select="'8.5in'"/>
                    </xsl:call-template>
                </Width>
                <Page>
                    <PageHeight>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="$page-master/@page-height"/>
                            <xsl:with-param name="default" select="'11in'"/>
                        </xsl:call-template>
                    </PageHeight>
                    <PageWidth>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="$page-master/@page-width"/>
                            <xsl:with-param name="default" select="'8.5in'"/>
                        </xsl:call-template>
                    </PageWidth>
                    <!-- Handle both shorthand 'margin' and individual margin-* attributes -->
                    <LeftMargin>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="if ($page-master/@margin-left) then $page-master/@margin-left else $page-master/@margin"/>
                            <xsl:with-param name="default" select="'1in'"/>
                        </xsl:call-template>
                    </LeftMargin>
                    <RightMargin>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="if ($page-master/@margin-right) then $page-master/@margin-right else $page-master/@margin"/>
                            <xsl:with-param name="default" select="'1in'"/>
                        </xsl:call-template>
                    </RightMargin>
                    <TopMargin>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="if ($page-master/@margin-top) then $page-master/@margin-top else $page-master/@margin"/>
                            <xsl:with-param name="default" select="'1in'"/>
                        </xsl:call-template>
                    </TopMargin>
                    <BottomMargin>
                        <xsl:call-template name="normalize-size">
                            <xsl:with-param name="size" select="if ($page-master/@margin-bottom) then $page-master/@margin-bottom else $page-master/@margin"/>
                            <xsl:with-param name="default" select="'1in'"/>
                        </xsl:call-template>
                    </BottomMargin>
                    <!-- Page Footer - appears on every page (must be inside Page element) -->
                    <xsl:if test="fo:page-sequence/fo:static-content[@flow-name='xsl-region-after']">
                        <xsl:variable name="footer-content">
                            <xsl:apply-templates select="fo:page-sequence/fo:static-content[@flow-name='xsl-region-after']" mode="page-footer"/>
                        </xsl:variable>
                        <xsl:if test="normalize-space($footer-content) != '' or $footer-content/*">
                            <PageFooter>
                                <Height>0.5in</Height>
                                <PrintOnFirstPage>true</PrintOnFirstPage>
                                <PrintOnLastPage>true</PrintOnLastPage>
                                <ReportItems>
                                    <xsl:copy-of select="$footer-content"/>
                                </ReportItems>
                            </PageFooter>
                        </xsl:if>
                    </xsl:if>
                </Page>
            </ReportSection>
        </ReportSections>
    </xsl:template>

    <!-- ========== FO:BLOCK to TEXTBOX ========== -->
    <xsl:template match="fo:block">
        <xsl:param name="inherited-text-align" select="''"/>
        
        <!-- Determine effective text-align: own or inherited -->
        <xsl:variable name="effective-text-align">
            <xsl:choose>
                <xsl:when test="@text-align"><xsl:value-of select="@text-align"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$inherited-text-align"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <!-- If this block contains child fo:block elements, process them as separate textboxes -->
            <xsl:when test="fo:block">
                <xsl:apply-templates select="fo:block">
                    <xsl:with-param name="inherited-text-align" select="$effective-text-align"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- Leaf block - create a single textbox -->
            <xsl:otherwise>
        <Textbox>
            <xsl:attribute name="Name">
                <xsl:value-of select="concat('Textbox', generate-id())"/>
            </xsl:attribute>
            <CanGrow>true</CanGrow>
            <KeepTogether>true</KeepTogether>
            <Paragraphs>
                <Paragraph>
                    <TextRuns>
                        <xsl:call-template name="process-mixed-content">
                            <xsl:with-param name="node" select="."/>
                        </xsl:call-template>
                    </TextRuns>
                    <Style>
                        <xsl:call-template name="convert-paragraph-style">
                            <xsl:with-param name="inherited-text-align" select="$effective-text-align"/>
                        </xsl:call-template>
                    </Style>
                </Paragraph>
            </Paragraphs>
            <!-- Calculate vertical position based on element order and margins -->
            <Top>
                <!-- Count preceding top-level blocks (not inside tables) and tables in flow -->
                <xsl:variable name="header-blocks" select="count(//fo:static-content[@flow-name='xsl-region-before']//fo:block[not(ancestor::fo:table)])"/>
                <xsl:variable name="preceding-flow-blocks" select="preceding::fo:block[ancestor::fo:flow and not(ancestor::fo:table)]"/>
                <xsl:variable name="preceding-flow-tables" select="count(preceding::fo:table[ancestor::fo:flow])"/>
                <xsl:variable name="own-region" select="count(preceding::fo:block[ancestor::fo:static-content[@flow-name='xsl-region-before'] and not(ancestor::fo:table)])"/>
                
                <!-- Calculate accumulated margin-bottom from preceding blocks (convert pt to in: 1pt = 1/72in) -->
                <xsl:variable name="accumulated-margins">
                    <xsl:variable name="margin-values">
                        <xsl:for-each select="$preceding-flow-blocks">
                            <xsl:variable name="mb" select="@margin-bottom"/>
                            <xsl:choose>
                                <xsl:when test="contains($mb, 'pt')">
                                    <xsl:value-of select="number(translate($mb, 'pt', '')) div 72"/>
                                </xsl:when>
                                <xsl:when test="contains($mb, 'in')">
                                    <xsl:value-of select="number(translate($mb, 'in', ''))"/>
                                </xsl:when>
                                <xsl:otherwise>0</xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="position() != last()">+</xsl:if>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- Sum the margins -->
                    <xsl:value-of select="sum(for $m in tokenize(replace($margin-values, '\+$', ''), '\+') return if ($m != '') then number($m) else 0)"/>
                </xsl:variable>
                
                <!-- Add own margin-top if present -->
                <xsl:variable name="own-margin-top">
                    <xsl:variable name="mt" select="@margin-top"/>
                    <xsl:choose>
                        <xsl:when test="contains($mt, 'pt')">
                            <xsl:value-of select="number(translate($mt, 'pt', '')) div 72"/>
                        </xsl:when>
                        <xsl:when test="contains($mt, 'in')">
                            <xsl:value-of select="number(translate($mt, 'in', ''))"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:choose>
                    <!-- If we're in static-content header, just count preceding in that region -->
                    <xsl:when test="ancestor::fo:static-content[@flow-name='xsl-region-before']">
                        <xsl:value-of select="concat($own-region * 0.3, 'in')"/>
                    </xsl:when>
                    <!-- If we're in flow, count blocks + tables + accumulated margins -->
                    <xsl:otherwise>
                        <xsl:value-of select="concat(($header-blocks * 0.3) + (count($preceding-flow-blocks) * 0.3) + ($preceding-flow-tables * 0.55) + $accumulated-margins + $own-margin-top, 'in')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </Top>
            <Left>0in</Left>
            <Height>0.25in</Height>
            <Width>6.5in</Width>
            <Style>
                <xsl:call-template name="convert-border-style"/>
            </Style>
        </Textbox>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Process mixed content (text + xsl:value-of) into multiple TextRuns -->
    <xsl:template name="process-mixed-content">
        <xsl:param name="node"/>
        <xsl:for-each select="$node/node()">
            <xsl:choose>
                <!-- Text node -->
                <xsl:when test="self::text()">
                    <!-- Preserve spacing intelligently: normalize internal whitespace but keep boundary spaces -->
                    <xsl:variable name="raw" select="."/>
                    <xsl:variable name="normalized" select="normalize-space($raw)"/>
                    <xsl:if test="$normalized != ''">
                        <!-- Check if original had leading/trailing space -->
                        <xsl:variable name="has-leading-space" select="starts-with($raw, ' ') or starts-with($raw, '&#10;') or starts-with($raw, '&#13;') or starts-with($raw, '&#9;')"/>
                        <xsl:variable name="has-trailing-space" select="substring($raw, string-length($raw)) = ' ' or substring($raw, string-length($raw)) = '&#10;' or substring($raw, string-length($raw)) = '&#13;' or substring($raw, string-length($raw)) = '&#9;'"/>
                        <!-- Check if there are adjacent xsl:value-of elements -->
                        <xsl:variable name="has-preceding-valueof" select="preceding-sibling::*[1][self::xsl:value-of]"/>
                        <xsl:variable name="has-following-valueof" select="following-sibling::*[1][self::xsl:value-of]"/>
                        <TextRun>
                            <Value>
                                <!-- Add leading space if original had whitespace and there's preceding content -->
                                <xsl:if test="$has-leading-space and $has-preceding-valueof"><xsl:text> </xsl:text></xsl:if>
                                <xsl:value-of select="$normalized"/>
                                <!-- Add trailing space if original had whitespace and there's following content -->
                                <xsl:if test="$has-trailing-space and $has-following-valueof"><xsl:text> </xsl:text></xsl:if>
                            </Value>
                            <Style>
                                <xsl:call-template name="convert-text-style">
                                    <xsl:with-param name="node" select="$node"/>
                                </xsl:call-template>
                            </Style>
                        </TextRun>
                    </xsl:if>
                </xsl:when>
                <!-- xsl:value-of element -->
                <xsl:when test="self::xsl:value-of">
                    <TextRun>
                        <Value>
                            <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                                <xsl:with-param name="select" select="@select"/>
                            </xsl:call-template>
                        </Value>
                        <Style>
                            <xsl:call-template name="convert-text-style">
                                <xsl:with-param name="node" select="$node"/>
                            </xsl:call-template>
                        </Style>
                    </TextRun>
                </xsl:when>
                <!-- xsl:call-template element (e.g., formatCurrency) - extract field from with-param -->
                <xsl:when test="self::xsl:call-template">
                    <TextRun>
                        <Value>
                            <xsl:choose>
                                <!-- If it has a with-param with @select, use that field -->
                                <xsl:when test="xsl:with-param[@select]">
                                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                                        <xsl:with-param name="select" select="xsl:with-param[@select][1]/@select"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>
                        </Value>
                        <Style>
                            <xsl:call-template name="convert-text-style">
                                <xsl:with-param name="node" select="$node"/>
                            </xsl:call-template>
                        </Style>
                    </TextRun>
                </xsl:when>
                <!-- Nested fo:block or fo:inline - get its content -->
                <xsl:when test="self::fo:block or self::fo:inline">
                    <xsl:call-template name="process-mixed-content">
                        <xsl:with-param name="node" select="."/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
        <!-- If no content was generated, output an empty TextRun -->
        <xsl:if test="not($node/node()[self::text()[normalize-space(.) != ''] or self::xsl:value-of or self::xsl:call-template or self::fo:block or self::fo:inline])">
            <TextRun>
                <Value>
                    <xsl:value-of select="normalize-space($node)"/>
                </Value>
                <Style>
                    <xsl:call-template name="convert-text-style">
                        <xsl:with-param name="node" select="$node"/>
                    </xsl:call-template>
                </Style>
            </TextRun>
        </xsl:if>
    </xsl:template>

    <!-- ========== FO:TABLE to TABLIX ========== -->
    <xsl:template match="fo:table">
        <!-- Calculate position: header blocks + preceding flow elements + accumulated margins -->
        <xsl:variable name="header-blocks" select="count(//fo:static-content[@flow-name='xsl-region-before']//fo:block[not(ancestor::fo:table)])"/>
        <xsl:variable name="preceding-flow-blocks" select="preceding::fo:block[ancestor::fo:flow and not(ancestor::fo:table)]"/>
        <xsl:variable name="preceding-flow-tables" select="count(preceding::fo:table[ancestor::fo:flow])"/>
        
        <!-- Calculate accumulated margin-bottom from preceding blocks -->
        <xsl:variable name="accumulated-margins">
            <xsl:variable name="margin-values">
                <xsl:for-each select="$preceding-flow-blocks">
                    <xsl:variable name="mb" select="@margin-bottom"/>
                    <xsl:choose>
                        <xsl:when test="contains($mb, 'pt')">
                            <xsl:value-of select="number(translate($mb, 'pt', '')) div 72"/>
                        </xsl:when>
                        <xsl:when test="contains($mb, 'in')">
                            <xsl:value-of select="number(translate($mb, 'in', ''))"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="position() != last()">+</xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="sum(for $m in tokenize(replace($margin-values, '\+$', ''), '\+') return if ($m != '') then number($m) else 0)"/>
        </xsl:variable>
        
        <xsl:variable name="col-count" select="count(fo:table-column)"/>
        <Tablix>
            <xsl:attribute name="Name">
                <xsl:value-of select="concat('Tablix', generate-id())"/>
            </xsl:attribute>
            <TablixBody>
                <TablixColumns>
                    <xsl:for-each select="fo:table-column">
                        <TablixColumn>
                            <Width>
                                <xsl:call-template name="normalize-size">
                                    <xsl:with-param name="size" select="@column-width"/>
                                    <xsl:with-param name="default" select="'1in'"/>
                                </xsl:call-template>
                            </Width>
                        </TablixColumn>
                    </xsl:for-each>
                    <!-- If no columns defined, create default -->
                    <xsl:if test="not(fo:table-column)">
                        <TablixColumn>
                            <Width>6.5in</Width>
                        </TablixColumn>
                    </xsl:if>
                </TablixColumns>
                <TablixRows>
                    <!-- Header rows -->
                    <xsl:apply-templates select="fo:table-header/fo:table-row">
                        <xsl:with-param name="col-count" select="if ($col-count &gt; 0) then $col-count else 1" tunnel="yes"/>
                    </xsl:apply-templates>
                    <!-- Body rows -->
                    <xsl:apply-templates select="fo:table-body/fo:table-row | fo:table-body/xsl:for-each">
                        <xsl:with-param name="col-count" select="if ($col-count &gt; 0) then $col-count else 1" tunnel="yes"/>
                    </xsl:apply-templates>
                </TablixRows>
            </TablixBody>
            
            <!-- Column hierarchy (required) -->
            <TablixColumnHierarchy>
                <TablixMembers>
                    <xsl:for-each select="fo:table-column">
                        <TablixMember/>
                    </xsl:for-each>
                    <xsl:if test="not(fo:table-column)">
                        <TablixMember/>
                    </xsl:if>
                </TablixMembers>
            </TablixColumnHierarchy>
            
            <!-- Row hierarchy (required) -->
            <TablixRowHierarchy>
                <TablixMembers>
                    <!-- Header row member -->
                    <xsl:if test="fo:table-header/fo:table-row">
                        <TablixMember/>
                    </xsl:if>
                    
                    <!-- Check if table body contains xsl:for-each (detail rows) -->
                    <xsl:variable name="inner-foreach" select="fo:table-body/descendant::*[local-name()='for-each' and namespace-uri()='http://www.w3.org/1999/XSL/Transform']"/>
                    
                    <xsl:choose>
                        <!-- Repeating rows from for-each: use detail row group (no GroupExpression) -->
                        <!-- SSRS detail groups iterate over all dataset rows without grouping -->
                        <xsl:when test="$inner-foreach">
                            <TablixMember>
                                <Group Name="Details_{generate-id()}"/>
                            </TablixMember>
                        </xsl:when>
                        <!-- Static table - one member per body row without grouping -->
                        <xsl:otherwise>
                            <xsl:for-each select="fo:table-body/fo:table-row">
                                <TablixMember/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </TablixMembers>
            </TablixRowHierarchy>
            
            <DataSetName>DataSet1</DataSetName>
            <Top>
                <xsl:value-of select="concat(($header-blocks * 0.3) + (count($preceding-flow-blocks) * 0.3) + ($preceding-flow-tables * 0.55) + $accumulated-margins, 'in')"/>
            </Top>
            <Left>0in</Left>
            <!-- Minimal height - SSRS will expand Tablix automatically with CanGrow behavior -->
            <Height>0.5in</Height>
            <Width>6.5in</Width>
        </Tablix>
    </xsl:template>

    <!-- ========== TABLE ROW ========== -->
    <xsl:template match="fo:table-row">
        <xsl:param name="col-count" select="1" tunnel="yes"/>
        <!-- Count effective columns: each cell takes 1 column, plus additional for col spans -->
        <xsl:variable name="effective-cell-count" select="sum(for $cell in fo:table-cell return if ($cell/@number-columns-spanned) then number($cell/@number-columns-spanned) else 1)"/>
        <xsl:variable name="row-bg" select="@background-color"/>
        <xsl:variable name="row-color" select="@color"/>
        
        <!-- Check for dynamic alternating row background via xsl:attribute -->
        <xsl:variable name="dynamic-bg-attr" select="xsl:attribute[@name='background-color']"/>
        <xsl:variable name="has-alternating-bg" select="exists($dynamic-bg-attr) and exists($dynamic-bg-attr//xsl:when[contains(@test, 'position()') and contains(@test, 'mod') and contains(@test, '2')])"/>
        
        <!-- Extract colors from the xsl:choose if alternating -->
        <xsl:variable name="even-color">
            <xsl:if test="$has-alternating-bg">
                <xsl:value-of select="normalize-space($dynamic-bg-attr//xsl:when[contains(@test, '= 0') or contains(@test, 'mod 2 = 0')][1])"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="odd-color">
            <xsl:if test="$has-alternating-bg">
                <xsl:value-of select="normalize-space($dynamic-bg-attr//xsl:otherwise[1])"/>
            </xsl:if>
        </xsl:variable>
        
        <TablixRow>
            <Height>0.3in</Height>
            <TablixCells>
                <xsl:apply-templates select="fo:table-cell">
                    <xsl:with-param name="row-background" select="$row-bg"/>
                    <xsl:with-param name="row-color" select="$row-color"/>
                    <xsl:with-param name="alternating-bg" select="$has-alternating-bg"/>
                    <xsl:with-param name="even-bg-color" select="$even-color"/>
                    <xsl:with-param name="odd-bg-color" select="$odd-color"/>
                </xsl:apply-templates>
                <!-- Pad with empty cells if row has fewer effective columns than table columns -->
                <xsl:if test="$effective-cell-count &lt; $col-count">
                    <xsl:call-template name="generate-empty-cells">
                        <xsl:with-param name="count" select="$col-count - $effective-cell-count"/>
                    </xsl:call-template>
                </xsl:if>
            </TablixCells>
        </TablixRow>
    </xsl:template>
    
    <!-- Generate empty TablixCells for padding -->
    <xsl:template name="generate-empty-cells">
        <xsl:param name="count"/>
        <xsl:if test="$count &gt; 0">
            <TablixCell>
                <CellContents>
                    <Textbox Name="{concat('EmptyCell', generate-id(), '_', $count)}">
                        <CanGrow>true</CanGrow>
                        <Paragraphs>
                            <Paragraph>
                                <TextRuns>
                                    <TextRun>
                                        <Value/>
                                        <Style/>
                                    </TextRun>
                                </TextRuns>
                                <Style/>
                            </Paragraph>
                        </Paragraphs>
                        <Style/>
                    </Textbox>
                </CellContents>
            </TablixCell>
            <xsl:call-template name="generate-empty-cells">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- ========== OUTER XSL:FOR-EACH (Muenchian grouping with header + table) to LIST ========== -->
    <!-- This matches xsl:for-each that contains both fo:block (region header) and fo:table (detail table) -->
    <!-- Creates a List (container Tablix) that repeats for each group value -->
    <xsl:template match="xsl:for-each[fo:block and fo:table]">
        <xsl:variable name="foreach-select" select="@select"/>
        <xsl:variable name="group-field">
            <!-- Try to extract field name from select expression -->
            <xsl:choose>
                <xsl:when test="xsl:variable[@name='currentRegion']">REGION_NAME</xsl:when>
                <xsl:when test="contains($foreach-select, 'key(')">
                    <!-- Muenchian grouping: key('keyName', FIELD)[1] - extract the key field -->
                    <xsl:call-template name="extract-group-field-from-xpath">
                        <xsl:with-param name="xpath" select="$foreach-select"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Extract from regular XPath -->
                    <xsl:call-template name="extract-group-field-from-xpath">
                        <xsl:with-param name="xpath" select="$foreach-select"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Generate a List (container Tablix) for each group -->
        <Tablix Name="List{generate-id()}">
            <TablixBody>
                <TablixColumns>
                    <TablixColumn>
                        <Width>10in</Width>
                    </TablixColumn>
                </TablixColumns>
                <TablixRows>
                    <TablixRow>
                        <Height>2in</Height>
                        <TablixCells>
                            <TablixCell>
                                <CellContents>
                                    <Rectangle Name="Container{generate-id()}">
                                        <ReportItems>
                                            <!-- Process all child elements (header blocks and tables) -->
                                            <xsl:apply-templates select="fo:block | fo:table" mode="list-content"/>
                                        </ReportItems>
                                        <Style/>
                                    </Rectangle>
                                </CellContents>
                            </TablixCell>
                        </TablixCells>
                    </TablixRow>
                </TablixRows>
            </TablixBody>
            <TablixColumnHierarchy>
                <TablixMembers>
                    <TablixMember/>
                </TablixMembers>
            </TablixColumnHierarchy>
            <TablixRowHierarchy>
                <TablixMembers>
                    <TablixMember>
                        <Group Name="RegionGroup{generate-id()}">
                            <GroupExpressions>
                                <GroupExpression>=Fields!<xsl:value-of select="$group-field"/>.Value</GroupExpression>
                            </GroupExpressions>
                        </Group>
                    </TablixMember>
                </TablixMembers>
            </TablixRowHierarchy>
            <DataSetName>DataSet1</DataSetName>
            <Top>2in</Top>
            <Left>0in</Left>
            <Height>2in</Height>
            <Width>10in</Width>
        </Tablix>
    </xsl:template>
    
    <!-- Process fo:block inside a list container -->
    <xsl:template match="fo:block" mode="list-content">
        <xsl:variable name="accumulated-height">
            <xsl:value-of select="count(preceding-sibling::fo:block) * 0.4"/>
        </xsl:variable>
        <Textbox Name="ListHeader{generate-id()}">
            <CanGrow>true</CanGrow>
            <Paragraphs>
                <Paragraph>
                    <TextRuns>
                        <xsl:call-template name="process-mixed-content">
                            <xsl:with-param name="node" select="."/>
                        </xsl:call-template>
                    </TextRuns>
                    <Style>
                        <xsl:if test="@text-align">
                            <TextAlign>
                                <xsl:choose>
                                    <xsl:when test="@text-align = 'right'">Right</xsl:when>
                                    <xsl:when test="@text-align = 'center'">Center</xsl:when>
                                    <xsl:when test="@text-align = 'justify'">Justify</xsl:when>
                                    <xsl:otherwise>Left</xsl:otherwise>
                                </xsl:choose>
                            </TextAlign>
                        </xsl:if>
                    </Style>
                </Paragraph>
            </Paragraphs>
            <Style>
                <xsl:if test="@background-color">
                    <BackgroundColor><xsl:value-of select="@background-color"/></BackgroundColor>
                </xsl:if>
                <xsl:if test="@padding">
                    <PaddingLeft><xsl:value-of select="@padding"/></PaddingLeft>
                    <PaddingRight><xsl:value-of select="@padding"/></PaddingRight>
                    <PaddingTop><xsl:value-of select="@padding"/></PaddingTop>
                    <PaddingBottom><xsl:value-of select="@padding"/></PaddingBottom>
                </xsl:if>
            </Style>
            <Top><xsl:value-of select="$accumulated-height"/>in</Top>
            <Left>0in</Left>
            <Height>0.35in</Height>
            <Width>10in</Width>
        </Textbox>
    </xsl:template>
    
    <!-- Process fo:table inside a list container - creates nested Tablix without parent grouping -->
    <xsl:template match="fo:table" mode="list-content">
        <xsl:variable name="preceding-blocks" select="count(preceding-sibling::fo:block)"/>
        <xsl:variable name="top-offset" select="$preceding-blocks * 0.4"/>
        
        <xsl:variable name="col-count" select="count(fo:table-column)"/>
        
        <!-- Count actual rows for TablixRowHierarchy matching -->
        <xsl:variable name="header-row-count" select="count(fo:table-header/fo:table-row)"/>
        <xsl:variable name="body-static-rows" select="count(fo:table-body/fo:table-row)"/>
        <xsl:variable name="body-foreach-count" select="count(fo:table-body/xsl:for-each)"/>
        
        <Tablix Name="NestedTablix{generate-id()}">
            <TablixBody>
                <TablixColumns>
                    <xsl:for-each select="fo:table-column">
                        <TablixColumn>
                            <Width>
                                <xsl:call-template name="normalize-size">
                                    <xsl:with-param name="size" select="@column-width"/>
                                    <xsl:with-param name="default" select="'1in'"/>
                                </xsl:call-template>
                            </Width>
                        </TablixColumn>
                    </xsl:for-each>
                </TablixColumns>
                <TablixRows>
                    <!-- Header rows -->
                    <xsl:apply-templates select="fo:table-header/fo:table-row">
                        <xsl:with-param name="col-count" select="if ($col-count &gt; 0) then $col-count else 1" tunnel="yes"/>
                    </xsl:apply-templates>
                    <!-- Body rows - process xsl:for-each first, then static rows -->
                    <xsl:apply-templates select="fo:table-body/xsl:for-each">
                        <xsl:with-param name="col-count" select="if ($col-count &gt; 0) then $col-count else 1" tunnel="yes"/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="fo:table-body/fo:table-row">
                        <xsl:with-param name="col-count" select="if ($col-count &gt; 0) then $col-count else 1" tunnel="yes"/>
                    </xsl:apply-templates>
                </TablixRows>
            </TablixBody>
            <TablixColumnHierarchy>
                <TablixMembers>
                    <xsl:for-each select="fo:table-column">
                        <TablixMember/>
                    </xsl:for-each>
                </TablixMembers>
            </TablixColumnHierarchy>
            <TablixRowHierarchy>
                <TablixMembers>
                    <!-- Generate members for header rows (static) -->
                    <xsl:for-each select="fo:table-header/fo:table-row">
                        <TablixMember/>
                    </xsl:for-each>
                    <!-- Generate members for body xsl:for-each (detail groups) -->
                    <xsl:for-each select="fo:table-body/xsl:for-each">
                        <TablixMember>
                            <Group Name="Details{generate-id()}"/>
                        </TablixMember>
                    </xsl:for-each>
                    <!-- Generate members for static body rows (subtotals etc) -->
                    <xsl:for-each select="fo:table-body/fo:table-row">
                        <TablixMember/>
                    </xsl:for-each>
                </TablixMembers>
            </TablixRowHierarchy>
            <DataSetName>DataSet1</DataSetName>
            <Top><xsl:value-of select="$top-offset"/>in</Top>
            <Left>0in</Left>
            <Height>0.6in</Height>
            <Width>10in</Width>
        </Tablix>
    </xsl:template>

    <!-- ========== XSL:FOR-EACH to TABLIX ROW (repeating) ========== -->
    <xsl:template match="xsl:for-each[fo:table-row]">
        <!-- This creates a detail row that repeats -->
        <xsl:comment>Repeating row from xsl:for-each select="<xsl:value-of select="@select"/>"</xsl:comment>
        <xsl:apply-templates select="fo:table-row"/>
    </xsl:template>

    <!-- ========== TABLE CELL ========== -->
    <xsl:template match="fo:table-cell">
        <xsl:param name="row-background"/>
        <xsl:param name="row-color"/>
        <xsl:param name="alternating-bg" select="false()"/>
        <xsl:param name="even-bg-color"/>
        <xsl:param name="odd-bg-color"/>
        <xsl:variable name="colspan" select="@number-columns-spanned"/>
        <TablixCell>
            <CellContents>
                <Textbox>
                    <xsl:attribute name="Name">
                        <xsl:value-of select="concat('Cell', generate-id())"/>
                    </xsl:attribute>
                    <CanGrow>true</CanGrow>
                    <Paragraphs>
                        <!-- Process ALL fo:block elements in the cell, each as a separate Paragraph -->
                        <xsl:for-each select="fo:block">
                            <Paragraph>
                                <TextRuns>
                                    <xsl:call-template name="process-cell-content">
                                        <xsl:with-param name="node" select="."/>
                                        <xsl:with-param name="row-color" select="$row-color"/>
                                    </xsl:call-template>
                                </TextRuns>
                                <Style>
                                    <xsl:call-template name="convert-paragraph-style"/>
                                </Style>
                            </Paragraph>
                        </xsl:for-each>
                        <!-- If no fo:block elements, create a single paragraph with cell content -->
                        <xsl:if test="not(fo:block)">
                            <Paragraph>
                                <TextRuns>
                                    <TextRun>
                                        <Value><xsl:value-of select="normalize-space(.)"/></Value>
                                        <Style>
                                            <xsl:if test="$row-color">
                                                <Color><xsl:value-of select="$row-color"/></Color>
                                            </xsl:if>
                                        </Style>
                                    </TextRun>
                                </TextRuns>
                                <Style/>
                            </Paragraph>
                        </xsl:if>
                    </Paragraphs>
                    <Style>
                        <xsl:call-template name="convert-cell-style"/>
                        <!-- Apply row background color: alternating, static, or from row -->
                        <xsl:choose>
                            <!-- Cell has its own background color - use it -->
                            <xsl:when test="@background-color">
                                <!-- Already handled by convert-cell-style -->
                            </xsl:when>
                            <!-- Alternating row colors via SSRS expression -->
                            <xsl:when test="$alternating-bg">
                                <BackgroundColor>=IIF(RowNumber(Nothing) Mod 2 = 0, "<xsl:value-of select="if ($even-bg-color != '') then $even-bg-color else '#f7fafc'"/>", "<xsl:value-of select="if ($odd-bg-color != '') then $odd-bg-color else 'White'"/>")</BackgroundColor>
                            </xsl:when>
                            <!-- Static row background -->
                            <xsl:when test="$row-background">
                                <BackgroundColor>
                                    <xsl:value-of select="$row-background"/>
                                </BackgroundColor>
                            </xsl:when>
                        </xsl:choose>
                    </Style>
                </Textbox>
                <!-- Column spanning support -->
                <xsl:if test="$colspan and number($colspan) &gt; 1">
                    <ColSpan><xsl:value-of select="$colspan"/></ColSpan>
                </xsl:if>
            </CellContents>
        </TablixCell>
        <!-- Generate empty cells to fill the spanned columns (required by SSRS) -->
        <xsl:if test="$colspan and number($colspan) &gt; 1">
            <xsl:call-template name="generate-spanned-empty-cells">
                <xsl:with-param name="count" select="number($colspan) - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- Generate empty TablixCells for spanned columns -->
    <xsl:template name="generate-spanned-empty-cells">
        <xsl:param name="count"/>
        <xsl:if test="$count &gt; 0">
            <TablixCell/>
            <xsl:call-template name="generate-spanned-empty-cells">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- Process cell content including mixed content -->
    <xsl:template name="process-cell-content">
        <xsl:param name="node"/>
        <xsl:param name="row-color"/>
        <xsl:choose>
            <xsl:when test="$node">
                <xsl:for-each select="$node/node()">
                    <xsl:choose>
                        <!-- Text node -->
                        <xsl:when test="self::text()">
                            <xsl:variable name="txt" select="normalize-space(.)"/>
                            <xsl:if test="$txt != ''">
                                <TextRun>
                                    <Value>
                                        <xsl:value-of select="$txt"/>
                                    </Value>
                                    <Style>
                                        <xsl:call-template name="convert-text-style">
                                            <xsl:with-param name="node" select="$node"/>
                                        </xsl:call-template>
                                        <xsl:if test="$row-color and not($node/@color)">
                                            <Color>
                                                <xsl:value-of select="$row-color"/>
                                            </Color>
                                        </xsl:if>
                                    </Style>
                                </TextRun>
                            </xsl:if>
                        </xsl:when>
                        <!-- xsl:value-of element -->
                        <xsl:when test="self::xsl:value-of">
                            <TextRun>
                                <Value>
                                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                                        <xsl:with-param name="select" select="@select"/>
                                    </xsl:call-template>
                                </Value>
                                <Style>
                                    <xsl:call-template name="convert-text-style">
                                        <xsl:with-param name="node" select="$node"/>
                                    </xsl:call-template>
                                    <xsl:if test="$row-color and not($node/@color)">
                                        <Color>
                                            <xsl:value-of select="$row-color"/>
                                        </Color>
                                    </xsl:if>
                                </Style>
                            </TextRun>
                        </xsl:when>
                        <!-- xsl:call-template element (e.g., formatCurrency) - extract field from with-param -->
                        <xsl:when test="self::xsl:call-template">
                            <xsl:if test="xsl:with-param[@select]">
                                <TextRun>
                                    <Value>
                                        <xsl:call-template name="convert-call-template-to-ssrs">
                                            <xsl:with-param name="template-name" select="@name"/>
                                            <xsl:with-param name="params" select="xsl:with-param"/>
                                        </xsl:call-template>
                                    </Value>
                                    <Style>
                                        <xsl:call-template name="convert-text-style">
                                            <xsl:with-param name="node" select="$node"/>
                                        </xsl:call-template>
                                        <xsl:if test="$row-color and not($node/@color)">
                                            <Color>
                                                <xsl:value-of select="$row-color"/>
                                            </Color>
                                        </xsl:if>
                                    </Style>
                                </TextRun>
                            </xsl:if>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
                <!-- If no content was generated, output empty TextRun with row's style -->
                <xsl:if test="not($node/node()[self::text()[normalize-space(.) != ''] or self::xsl:value-of or self::xsl:call-template])">
                    <TextRun>
                        <Value>
                            <xsl:value-of select="normalize-space($node)"/>
                        </Value>
                        <Style>
                            <xsl:call-template name="convert-text-style">
                                <xsl:with-param name="node" select="$node"/>
                            </xsl:call-template>
                            <xsl:if test="$row-color">
                                <Color>
                                    <xsl:value-of select="$row-color"/>
                                </Color>
                            </xsl:if>
                        </Style>
                    </TextRun>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- No fo:block, use cell's text content directly -->
                <TextRun>
                    <Value>
                        <xsl:value-of select="normalize-space(.)"/>
                    </Value>
                    <Style>
                        <xsl:if test="$row-color">
                            <Color>
                                <xsl:value-of select="$row-color"/>
                            </Color>
                        </xsl:if>
                    </Style>
                </TextRun>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== XSL:IF to VISIBILITY ========== -->
    <xsl:template match="xsl:if">
        <xsl:comment>Conditional: <xsl:value-of select="@test"/>
        </xsl:comment>
        <xsl:apply-templates/>
    </xsl:template>

    <!-- ========== HELPER: Convert XPath to Field name ========== -->
    <!-- For nested paths, strips root and row element based on context -->
    <!-- /EMPLOYEES/EMPLOYEE[1]/DEPARTMENT_NAME → DEPARTMENT_NAME (EMPLOYEE has [1] = row element) -->
    <!-- /PURCHASE_ORDER/COMPANY/NAME → COMPANY_NAME (COMPANY has no [1] = structural container) -->
    <!-- /INVOICE/LINE_ITEM/LINE_AMOUNT (aggregate) → LINE_AMOUNT (aggregates use last component only) -->
    <!-- 
        CONSTRAINT: SQL queries must use identical column names for both BIP (XDA) and SSRS (RDL).
        This template extracts only the leaf element name from hierarchical XPaths to ensure
        field names match typical SQL column names (e.g., /INVOICE/CUSTOMER/ADDRESS becomes ADDRESS).
        
        WARNING: This may cause collisions if the same leaf name appears in different paths
        (e.g., COMPANY/NAME and PRODUCT/NAME would both become NAME). In such cases, SQL queries
        should use aliases with unique names.
    -->
    <xsl:template name="xpath-to-field">
        <xsl:param name="xpath"/>
        <xsl:param name="aggregate-context" select="'no'"/>
        <!-- Handle sequences by taking first item, convert to string -->
        <xsl:variable name="path" select="string($xpath[1])"/>
        
        <!-- Strip predicates like [1], [position()=1], etc. -->
        <xsl:variable name="no-predicates">
            <xsl:call-template name="strip-predicates">
                <xsl:with-param name="str" select="$path"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Always use the last path component (leaf element) to match SQL column names -->
        <xsl:variable name="last-component">
            <xsl:call-template name="get-last-path-component">
                <xsl:with-param name="path" select="$no-predicates"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$path = ''">
                <xsl:text>Field1</xsl:text>
            </xsl:when>
            <!-- Handle '.' (current context) - not a valid SSRS field name -->
            <xsl:when test="$path = '.' or $last-component = '.'">
                <!-- Return empty to signal callers to skip this -->
            </xsl:when>
            <xsl:otherwise>
                <!-- Use leaf element name only - ensures SQL compatibility -->
                <xsl:variable name="cleaned" select="translate($last-component, '@[]():$', '')"/>
                <xsl:value-of select="translate($cleaned, ' +-*/', '')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Strip XPath predicates like [1], [position()=1], [@attr='value'] -->
    <xsl:template name="strip-predicates">
        <xsl:param name="str"/>
        <xsl:choose>
            <xsl:when test="contains($str, '[')">
                <xsl:variable name="before" select="substring-before($str, '[')"/>
                <xsl:variable name="after-bracket" select="substring-after($str, ']')"/>
                <xsl:value-of select="$before"/>
                <xsl:call-template name="strip-predicates">
                    <xsl:with-param name="str" select="$after-bracket"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$str"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Get the last component of an XPath (after final /) -->
    <xsl:template name="get-last-path-component">
        <xsl:param name="path"/>
        <xsl:choose>
            <xsl:when test="contains($path, '/')">
                <xsl:call-template name="get-last-path-component">
                    <xsl:with-param name="path" select="substring-after($path, '/')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$path"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========== HELPER: Extract grouping field from for-each XPath ========== -->
    <!-- Converts XPath like "/ROOT/SEGMENTS/SEGMENT" to the grouping key field -->
    <!-- Priority: 1) XDM lookup if available, 2) Heuristic fallback -->
    <!-- For XDM: finds the element with @isRepeating="true" and returns first non-complex child name -->
    <!--
         NOTE ON FALLBACKS: The heuristic fallback (appending _ID to element name) is only used when:
         - XDM is not provided, OR
         - XDM element lacks isRepeating="true" attribute, OR  
         - All child elements are isComplex="true" (no leaf fields)
         
         A well-formed XDM with proper isRepeating markers and at least one non-complex child
         per repeating element will always resolve via XDM lookup, making fallbacks unnecessary.
    -->
    <xsl:template name="extract-group-field-from-xpath">
        <xsl:param name="xpath"/>
        <xsl:variable name="trimmed" select="normalize-space($xpath)"/>
        
        <!-- Strip predicates like [1] or [@type='x'] -->
        <xsl:variable name="no-predicates">
            <xsl:call-template name="strip-predicates">
                <xsl:with-param name="str" select="$trimmed"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Get the last path component which is typically the repeating element -->
        <xsl:variable name="last-component">
            <xsl:call-template name="get-last-path-component">
                <xsl:with-param name="path" select="$no-predicates"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Try XDM lookup first if XDM document is available -->
        <xsl:variable name="xdm-field">
            <xsl:if test="exists($xdm) and string-length($last-component) &gt; 0">
                <xsl:call-template name="lookup-field-in-xdm">
                    <xsl:with-param name="element-name" select="$last-component"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        
        <xsl:choose>
            <!-- Use XDM-derived field if found -->
            <xsl:when test="normalize-space($xdm-field) != ''">
                <xsl:value-of select="$xdm-field"/>
            </xsl:when>
            <!-- No XDM field found - use element name with _ID suffix as generic fallback.
                 This heuristic works for common BIP naming conventions but may not match actual
                 field names. With a complete XDM, this branch is never executed. -->
            <xsl:otherwise>
                <xsl:value-of select="concat($last-component, '_ID')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========== HELPER: Look up grouping field from XDM ========== -->
    <!-- Finds element with @isRepeating="true" and returns first non-complex child name -->
    <xsl:template name="lookup-field-in-xdm">
        <xsl:param name="element-name"/>
        
        <!-- Find the element in XDM output structure (with or without namespace) -->
        <xsl:variable name="xdm-element" select="(
            $xdm//xdm:element[@name = $element-name][@isRepeating = 'true'] |
            $xdm//*[local-name() = 'element'][@name = $element-name][@isRepeating = 'true']
        )[1]"/>
        
        <xsl:if test="exists($xdm-element)">
            <!-- Find first child element that is NOT complex (i.e., a leaf field) -->
            <xsl:variable name="first-leaf" select="(
                $xdm-element/xdm:element[not(@isComplex = 'true')] |
                $xdm-element/*[local-name() = 'element'][not(@isComplex = 'true')]
            )[1]"/>
            
            <xsl:if test="exists($first-leaf)">
                <xsl:value-of select="$first-leaf/@name"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- ========== HELPER: Extract format pattern from format-number() call ========== -->
    <xsl:template name="extract-format-pattern">
        <xsl:param name="expr"/>
        <!-- format-number(arg1, 'pattern') or format-number(arg1, "pattern") -->
        <!-- Find the format pattern which is the second argument -->
        <xsl:variable name="after-comma">
            <xsl:choose>
                <!-- Handle nested functions like format-number(sum(...), 'pattern') -->
                <xsl:when test="contains($expr, '), ')">
                    <xsl:value-of select="substring-after($expr, '), ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Simple case: format-number(field, 'pattern') -->
                    <xsl:value-of select="substring-after($expr, ', ')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- Pattern in single quotes -->
            <xsl:when test="contains($after-comma, &quot;'&quot;)">
                <xsl:variable name="after-quote" select="substring-after($after-comma, &quot;'&quot;)"/>
                <xsl:value-of select="substring-before($after-quote, &quot;'&quot;)"/>
            </xsl:when>
            <!-- Pattern in double quotes (less common) -->
            <xsl:when test="contains($after-comma, '&quot;')">
                <xsl:variable name="after-quote" select="substring-after($after-comma, '&quot;')"/>
                <xsl:value-of select="substring-before($after-quote, '&quot;')"/>
            </xsl:when>
            <!-- Default fallback -->
            <xsl:otherwise>#,##0</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========== HELPER: Convert xsl:value-of @select to SSRS expression ========== -->
    <xsl:template name="convert-xsl-value-of-to-ssrs">
        <xsl:param name="select"/>
        <xsl:variable name="trimmed" select="normalize-space($select)"/>
        <xsl:choose>
            <!-- format-number(sum(...), ...) -> Format(Sum(...), ...) -->
            <xsl:when test="starts-with($trimmed, 'format-number(sum(')">
                <xsl:variable name="after-format" select="substring-after($trimmed, 'format-number(')"/>
                <xsl:variable name="sum-part" select="substring-after($after-format, 'sum(')"/>
                <!-- Find the xpath inside sum() - handle nested parens for expressions like sum(x) * 0.08 -->
                <xsl:variable name="sum-arg" select="substring-before($sum-part, ')')"/>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$sum-arg"/>
                        <xsl:with-param name="aggregate-context" select="'yes'"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- Extract the format pattern (second argument) -->
                <xsl:variable name="format-pattern">
                    <xsl:call-template name="extract-format-pattern">
                        <xsl:with-param name="expr" select="$trimmed"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- Check if there's multiplication after the sum -->
                <xsl:variable name="after-sum" select="substring-after($after-format, concat('sum(', $sum-arg, ')'))"/>
                <xsl:choose>
                    <xsl:when test="starts-with(normalize-space($after-sum), '*')">
                        <!-- Extract multiplier: looks like " * 0.08, ..." -->
                        <xsl:variable name="mult-part" select="normalize-space(substring-after($after-sum, '*'))"/>
                        <xsl:variable name="multiplier" select="normalize-space(substring-before($mult-part, ','))"/>
                        <xsl:text>=Format(Sum(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value) * </xsl:text>
                        <xsl:value-of select="$multiplier"/>
                        <xsl:text>, "</xsl:text>
                        <xsl:value-of select="$format-pattern"/>
                        <xsl:text>")</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>=Format(Sum(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value), "</xsl:text>
                        <xsl:value-of select="$format-pattern"/>
                        <xsl:text>")</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- format-number(field, ...) or format-number($var, ...) -> Format(..., ...) -->
            <xsl:when test="starts-with($trimmed, 'format-number(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-number(')"/>
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <!-- Extract the format pattern (second argument) -->
                <xsl:variable name="format-pattern">
                    <xsl:call-template name="extract-format-pattern">
                        <xsl:with-param name="expr" select="$trimmed"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <!-- format-number($variable, ...) - expand variable definition -->
                    <xsl:when test="starts-with($first-arg, '$')">
                        <xsl:variable name="var-name" select="substring($first-arg, 2)"/>
                        <xsl:variable name="var-def" select="ancestor::*/xsl:variable[@name = $var-name]/@select"/>
                        <xsl:choose>
                            <xsl:when test="$var-def">
                                <!-- Variable found - convert its definition with Format wrapper -->
                                <xsl:variable name="var-expr">
                                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                                        <xsl:with-param name="select" select="string($var-def)"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <!-- Extract just the expression part (remove leading =) and wrap with Format -->
                                <xsl:text>=Format(</xsl:text>
                                <xsl:value-of select="substring($var-expr, 2)"/>
                                <xsl:text>, "</xsl:text>
                                <xsl:value-of select="$format-pattern"/>
                                <xsl:text>")</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- Variable not found -->
                                <xsl:text>="[Variable: </xsl:text>
                                <xsl:value-of select="$var-name"/>
                                <xsl:text>]"</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- Regular field reference -->
                    <xsl:otherwise>
                        <xsl:variable name="field">
                            <xsl:call-template name="xpath-to-field">
                                <xsl:with-param name="xpath" select="$first-arg"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:text>=Format(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, "</xsl:text>
                        <xsl:value-of select="$format-pattern"/>
                        <xsl:text>")</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- count() -> CountRows -->
            <xsl:when test="starts-with($trimmed, 'count(')">
                <xsl:text>=CountRows("DataSet1")</xsl:text>
            </xsl:when>
            <!-- position() -> RowNumber -->
            <xsl:when test="$trimmed = 'position()'">
                <xsl:text>=RowNumber("DataSet1")</xsl:text>
            </xsl:when>
            <!-- Multiplication expression: (expr) * number - MUST check before div to handle (a div b) * c -->
            <xsl:when test="starts-with($trimmed, '(') and contains($trimmed, ') * ')">
                <xsl:variable name="paren-content">
                    <!-- Find matching closing paren - for simple cases, just find the last ) before * -->
                    <xsl:value-of select="substring-before(substring-after($trimmed, '('), ') *')"/>
                </xsl:variable>
                <xsl:variable name="multiplier" select="normalize-space(substring-after($trimmed, ') * '))"/>
                <xsl:variable name="inner-ssrs">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$paren-content"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=</xsl:text>
                <xsl:value-of select="substring($inner-ssrs, 2)"/>
                <xsl:text> * </xsl:text>
                <xsl:value-of select="$multiplier"/>
            </xsl:when>
            <!-- Division expression: $var1 div $var2 or expr div expr (not wrapped in parens) -->
            <xsl:when test="contains($trimmed, ' div ') and not(starts-with($trimmed, '('))">
                <xsl:variable name="left" select="normalize-space(substring-before($trimmed, ' div '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($trimmed, ' div '))"/>
                <xsl:variable name="left-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$left"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="right-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$right"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- Combine: remove leading = from right-expr, wrap appropriately -->
                <xsl:text>=IIF(</xsl:text>
                <xsl:value-of select="substring($right-expr, 2)"/>
                <xsl:text> = 0, 0, </xsl:text>
                <xsl:value-of select="substring($left-expr, 2)"/>
                <xsl:text> / </xsl:text>
                <xsl:value-of select="substring($right-expr, 2)"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <!-- Multiplication expression: expr * number (non-parenthetical) -->
            <xsl:when test="contains($trimmed, ' * ')">
                <xsl:variable name="left" select="normalize-space(substring-before($trimmed, ' * '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($trimmed, ' * '))"/>
                <xsl:variable name="left-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$left"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=</xsl:text>
                <xsl:value-of select="substring($left-expr, 2)"/>
                <xsl:text> * </xsl:text>
                <xsl:value-of select="$right"/>
            </xsl:when>
            <!-- Subtraction expression: expr - expr -->
            <xsl:when test="contains($trimmed, ' - ')">
                <xsl:variable name="left" select="normalize-space(substring-before($trimmed, ' - '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($trimmed, ' - '))"/>
                <xsl:variable name="left-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$left"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="right-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$right"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=</xsl:text>
                <xsl:value-of select="substring($left-expr, 2)"/>
                <xsl:text> - </xsl:text>
                <xsl:value-of select="substring($right-expr, 2)"/>
            </xsl:when>
            <!-- Addition expression: expr + expr -->
            <xsl:when test="contains($trimmed, ' + ')">
                <xsl:variable name="left" select="normalize-space(substring-before($trimmed, ' + '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($trimmed, ' + '))"/>
                <xsl:variable name="left-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$left"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="right-expr">
                    <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                        <xsl:with-param name="select" select="$right"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=</xsl:text>
                <xsl:value-of select="substring($left-expr, 2)"/>
                <xsl:text> + </xsl:text>
                <xsl:value-of select="substring($right-expr, 2)"/>
            </xsl:when>
            <!-- sum() -> Sum -->
            <xsl:when test="starts-with($trimmed, 'sum(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'sum(')"/>
                <xsl:variable name="arg" select="substring-before($inner, ')')"/>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$arg"/>
                        <xsl:with-param name="aggregate-context" select="'yes'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=Sum(Fields!</xsl:text>
                <xsl:value-of select="$field"/>
                <xsl:text>.Value)</xsl:text>
            </xsl:when>
            <!-- format-date(field, picture) -> Format(field, dotnet-format) -->
            <xsl:when test="starts-with($trimmed, 'format-date(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-date(')"/>
                <!-- Extract first argument (the date field) -->
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <!-- Extract second argument (the picture string) -->
                <xsl:variable name="after-comma" select="substring-after($inner, ',')"/>
                <xsl:variable name="picture-raw" select="normalize-space(substring-before(concat($after-comma, ')'), ')'))"/>
                <!-- Remove quotes from picture string -->
                <xsl:variable name="picture" select="translate($picture-raw, &quot;'&quot;, '')"/>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$first-arg"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="dotnet-format">
                    <xsl:call-template name="convert-date-picture-to-dotnet">
                        <xsl:with-param name="picture" select="$picture"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=Format(Fields!</xsl:text>
                <xsl:value-of select="$field"/>
                <xsl:text>.Value, "</xsl:text>
                <xsl:value-of select="$dotnet-format"/>
                <xsl:text>")</xsl:text>
            </xsl:when>
            <!-- format-dateTime(field, picture) -> Format(field, dotnet-format) -->
            <xsl:when test="starts-with($trimmed, 'format-dateTime(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-dateTime(')"/>
                <!-- Extract first argument (the dateTime field) -->
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <!-- Extract second argument (the picture string) -->
                <xsl:variable name="after-comma" select="substring-after($inner, ',')"/>
                <xsl:variable name="picture-raw" select="normalize-space(substring-before(concat($after-comma, ')'), ')'))"/>
                <!-- Remove quotes from picture string -->
                <xsl:variable name="picture" select="translate($picture-raw, &quot;'&quot;, '')"/>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$first-arg"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="dotnet-format">
                    <xsl:call-template name="convert-date-picture-to-dotnet">
                        <xsl:with-param name="picture" select="$picture"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=Format(Fields!</xsl:text>
                <xsl:value-of select="$field"/>
                <xsl:text>.Value, "</xsl:text>
                <xsl:value-of select="$dotnet-format"/>
                <xsl:text>")</xsl:text>
            </xsl:when>
            <!-- XSL Variable reference ($varName) - look up and inline the definition -->
            <xsl:when test="starts-with($trimmed, '$')">
                <xsl:variable name="var-name" select="substring($trimmed, 2)"/>
                <!-- Look up the variable definition in ancestor context -->
                <xsl:variable name="var-def" select="ancestor::*/xsl:variable[@name = $var-name]/@select"/>
                <xsl:choose>
                    <xsl:when test="$var-def">
                        <!-- Recursively convert the variable's definition -->
                        <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                            <xsl:with-param name="select" select="string($var-def)"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Variable not found - output placeholder -->
                        <xsl:text>="[Variable: </xsl:text>
                        <xsl:value-of select="$var-name"/>
                        <xsl:text>]"</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- substring(field, start, length) -> Left(field, length) when start=1 -->
            <xsl:when test="starts-with($trimmed, 'substring(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'substring(')"/>
                <!-- First arg is the field/string -->
                <xsl:variable name="first-arg" select="normalize-space(substring-before($inner, ','))"/>
                <xsl:variable name="after-first" select="substring-after($inner, ',')"/>
                <!-- Second arg is start position -->
                <xsl:variable name="second-arg" select="normalize-space(substring-before($after-first, ','))"/>
                <xsl:variable name="after-second" select="substring-after($after-first, ',')"/>
                <!-- Third arg is length (if present) -->
                <xsl:variable name="third-arg" select="normalize-space(substring-before(concat($after-second, ')'), ')'))"/>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$first-arg"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <!-- substring(field, 1, n) -> Left(field, n) -->
                    <xsl:when test="$second-arg = '1' and $third-arg != ''">
                        <xsl:text>=Left(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, </xsl:text>
                        <xsl:value-of select="$third-arg"/>
                        <xsl:text>)</xsl:text>
                    </xsl:when>
                    <!-- substring(field, n) -> Mid(field, n) - substring from position n -->
                    <xsl:when test="$third-arg = ''">
                        <xsl:text>=Mid(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, </xsl:text>
                        <xsl:value-of select="$second-arg"/>
                        <xsl:text>)</xsl:text>
                    </xsl:when>
                    <!-- substring(field, start, length) -> Mid(field, start, length) -->
                    <xsl:otherwise>
                        <xsl:text>=Mid(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, </xsl:text>
                        <xsl:value-of select="$second-arg"/>
                        <xsl:text>, </xsl:text>
                        <xsl:value-of select="$third-arg"/>
                        <xsl:text>)</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- Regular field reference -->
            <xsl:otherwise>
                <xsl:variable name="extracted-xpath">
                    <xsl:call-template name="extract-xpath-from-expr">
                        <xsl:with-param name="expr" select="$select"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="field-name">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$extracted-xpath"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <!-- Handle empty field (e.g., from '.' context selector) -->
                    <xsl:when test="$field-name = ''">
                        <xsl:text>="[Context: .]"</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>=Fields!</xsl:text>
                        <xsl:value-of select="$field-name"/>
                        <xsl:text>.Value</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== HELPER: Convert XPath arithmetic expression to SSRS expression ========== -->
    <!-- Handles expressions like "FIELD_A - FIELD_B" converting to "Fields!FIELD_A.Value - Fields!FIELD_B.Value" -->
    <xsl:template name="xpath-arithmetic-to-ssrs">
        <xsl:param name="xpath"/>
        <xsl:variable name="normalized" select="normalize-space($xpath)"/>
        
        <xsl:choose>
            <!-- Handle subtraction: A - B -->
            <xsl:when test="contains($normalized, ' - ')">
                <xsl:variable name="left" select="normalize-space(substring-before($normalized, ' - '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($normalized, ' - '))"/>
                <xsl:text>Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$left"/>
                </xsl:call-template>
                <xsl:text>.Value - </xsl:text>
                <!-- Right side might have more operators, recurse -->
                <xsl:call-template name="xpath-arithmetic-to-ssrs">
                    <xsl:with-param name="xpath" select="$right"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Handle addition: A + B -->
            <xsl:when test="contains($normalized, ' + ')">
                <xsl:variable name="left" select="normalize-space(substring-before($normalized, ' + '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($normalized, ' + '))"/>
                <xsl:text>Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$left"/>
                </xsl:call-template>
                <xsl:text>.Value + </xsl:text>
                <xsl:call-template name="xpath-arithmetic-to-ssrs">
                    <xsl:with-param name="xpath" select="$right"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Handle multiplication: A * B -->
            <xsl:when test="contains($normalized, ' * ')">
                <xsl:variable name="left" select="normalize-space(substring-before($normalized, ' * '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($normalized, ' * '))"/>
                <xsl:text>Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$left"/>
                </xsl:call-template>
                <xsl:text>.Value * </xsl:text>
                <xsl:call-template name="xpath-arithmetic-to-ssrs">
                    <xsl:with-param name="xpath" select="$right"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Handle division: A div B -->
            <xsl:when test="contains($normalized, ' div ')">
                <xsl:variable name="left" select="normalize-space(substring-before($normalized, ' div '))"/>
                <xsl:variable name="right" select="normalize-space(substring-after($normalized, ' div '))"/>
                <xsl:text>Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$left"/>
                </xsl:call-template>
                <xsl:text>.Value / </xsl:text>
                <xsl:call-template name="xpath-arithmetic-to-ssrs">
                    <xsl:with-param name="xpath" select="$right"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Simple field reference (no operators) -->
            <xsl:otherwise>
                <xsl:text>Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$normalized"/>
                </xsl:call-template>
                <xsl:text>.Value</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========== HELPER: Check if XPath contains arithmetic operators ========== -->
    <xsl:function name="local:has-arithmetic" as="xs:boolean">
        <xsl:param name="xpath"/>
        <xsl:variable name="normalized" select="normalize-space($xpath)"/>
        <xsl:sequence select="contains($normalized, ' - ') or 
                              contains($normalized, ' + ') or 
                              contains($normalized, ' * ') or 
                              contains($normalized, ' div ')"/>
    </xsl:function>
    
    <!-- ========== HELPER: Check if XPath contains aggregate function ========== -->
    <xsl:function name="local:has-aggregate" as="xs:boolean">
        <xsl:param name="xpath"/>
        <xsl:variable name="normalized" select="normalize-space($xpath)"/>
        <xsl:sequence select="starts-with($normalized, 'sum(') or 
                              starts-with($normalized, 'count(') or 
                              starts-with($normalized, 'avg(') or
                              starts-with($normalized, 'min(') or
                              starts-with($normalized, 'max(')"/>
    </xsl:function>
    
    <!-- ========== HELPER: Convert XPath aggregate to SSRS aggregate ========== -->
    <xsl:template name="xpath-aggregate-to-ssrs">
        <xsl:param name="xpath"/>
        <xsl:variable name="normalized" select="normalize-space($xpath)"/>
        
        <xsl:choose>
            <xsl:when test="starts-with($normalized, 'sum(')">
                <xsl:variable name="inner" select="substring-before(substring-after($normalized, 'sum('), ')')"/>
                <xsl:text>Sum(Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$inner"/>
                    <xsl:with-param name="aggregate-context" select="'yes'"/>
                </xsl:call-template>
                <xsl:text>.Value)</xsl:text>
            </xsl:when>
            <xsl:when test="starts-with($normalized, 'count(')">
                <xsl:variable name="inner" select="substring-before(substring-after($normalized, 'count('), ')')"/>
                <xsl:text>Count(Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$inner"/>
                    <xsl:with-param name="aggregate-context" select="'yes'"/>
                </xsl:call-template>
                <xsl:text>.Value)</xsl:text>
            </xsl:when>
            <xsl:when test="starts-with($normalized, 'avg(')">
                <xsl:variable name="inner" select="substring-before(substring-after($normalized, 'avg('), ')')"/>
                <xsl:text>Avg(Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$inner"/>
                    <xsl:with-param name="aggregate-context" select="'yes'"/>
                </xsl:call-template>
                <xsl:text>.Value)</xsl:text>
            </xsl:when>
            <xsl:when test="starts-with($normalized, 'min(')">
                <xsl:variable name="inner" select="substring-before(substring-after($normalized, 'min('), ')')"/>
                <xsl:text>Min(Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$inner"/>
                    <xsl:with-param name="aggregate-context" select="'yes'"/>
                </xsl:call-template>
                <xsl:text>.Value)</xsl:text>
            </xsl:when>
            <xsl:when test="starts-with($normalized, 'max(')">
                <xsl:variable name="inner" select="substring-before(substring-after($normalized, 'max('), ')')"/>
                <xsl:text>Max(Fields!</xsl:text>
                <xsl:call-template name="xpath-to-field">
                    <xsl:with-param name="xpath" select="$inner"/>
                    <xsl:with-param name="aggregate-context" select="'yes'"/>
                </xsl:call-template>
                <xsl:text>.Value)</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- ========== HELPER: Convert xsl:call-template to SSRS expression ========== -->
    <!-- Handles common BIP named templates like formatCurrency, formatNumber, etc. -->
    <xsl:template name="convert-call-template-to-ssrs">
        <xsl:param name="template-name"/>
        <xsl:param name="params"/>
        
        <xsl:variable name="value-param" select="$params[@name='value']/@select"/>
        
        <xsl:choose>
            <!-- formatCurrency template - apply number formatting with thousands separator -->
            <xsl:when test="$template-name = 'formatCurrency' or contains($template-name, 'Currency') or contains($template-name, 'currency')">
                <xsl:choose>
                    <!-- Check if this is an aggregate function like sum(), count() -->
                    <xsl:when test="local:has-aggregate($value-param)">
                        <xsl:text>=Format(</xsl:text>
                        <xsl:call-template name="xpath-aggregate-to-ssrs">
                            <xsl:with-param name="xpath" select="$value-param"/>
                        </xsl:call-template>
                        <xsl:text>, "#,##0")</xsl:text>
                    </xsl:when>
                    <!-- Check if this is an arithmetic expression -->
                    <xsl:when test="local:has-arithmetic($value-param)">
                        <xsl:text>=Format(</xsl:text>
                        <xsl:call-template name="xpath-arithmetic-to-ssrs">
                            <xsl:with-param name="xpath" select="$value-param"/>
                        </xsl:call-template>
                        <xsl:text>, "#,##0")</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="field">
                            <xsl:call-template name="xpath-to-field">
                                <xsl:with-param name="xpath" select="$value-param"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:text>=Format(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, "#,##0")</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- formatNumber template -->
            <xsl:when test="$template-name = 'formatNumber' or contains($template-name, 'Number') or contains($template-name, 'number')">
                <xsl:choose>
                    <!-- Check if this is an aggregate function -->
                    <xsl:when test="local:has-aggregate($value-param)">
                        <xsl:text>=Format(</xsl:text>
                        <xsl:call-template name="xpath-aggregate-to-ssrs">
                            <xsl:with-param name="xpath" select="$value-param"/>
                        </xsl:call-template>
                        <xsl:text>, "#,##0.00")</xsl:text>
                    </xsl:when>
                    <xsl:when test="local:has-arithmetic($value-param)">
                        <xsl:text>=Format(</xsl:text>
                        <xsl:call-template name="xpath-arithmetic-to-ssrs">
                            <xsl:with-param name="xpath" select="$value-param"/>
                        </xsl:call-template>
                        <xsl:text>, "#,##0.00")</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="field">
                            <xsl:call-template name="xpath-to-field">
                                <xsl:with-param name="xpath" select="$value-param"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:text>=Format(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, "#,##0.00")</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- formatPercent template -->
            <xsl:when test="contains($template-name, 'Percent') or contains($template-name, 'percent') or contains($template-name, 'Pct')">
                <xsl:choose>
                    <!-- Check if this is an aggregate function -->
                    <xsl:when test="local:has-aggregate($value-param)">
                        <xsl:text>=Format(</xsl:text>
                        <xsl:call-template name="xpath-aggregate-to-ssrs">
                            <xsl:with-param name="xpath" select="$value-param"/>
                        </xsl:call-template>
                        <xsl:text>, "0.0") &amp; "%"</xsl:text>
                    </xsl:when>
                    <xsl:when test="local:has-arithmetic($value-param)">
                        <xsl:text>=Format(</xsl:text>
                        <xsl:call-template name="xpath-arithmetic-to-ssrs">
                            <xsl:with-param name="xpath" select="$value-param"/>
                        </xsl:call-template>
                        <xsl:text>, "0.0") &amp; "%"</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="field">
                            <xsl:call-template name="xpath-to-field">
                                <xsl:with-param name="xpath" select="$value-param"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:text>=Format(Fields!</xsl:text>
                        <xsl:value-of select="$field"/>
                        <xsl:text>.Value, "0.0") &amp; "%"</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- Default: just extract the value -->
            <xsl:otherwise>
                <xsl:call-template name="convert-xsl-value-of-to-ssrs">
                    <xsl:with-param name="select" select="$params[@select][1]/@select"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== HELPER: Convert XPath date picture string to .NET format ========== -->
    <!-- XPath 2.0 picture string components mapped to .NET:
         [Y0001] -> yyyy   [Y01] -> yy
         [M01] -> MM       [M1] -> M        [MNn] -> MMMM    [MNn,3-3] -> MMM
         [D01] -> dd       [D1] -> d
         [H01] -> HH       [H1] -> H        (24-hour)
         [h01] -> hh       [h1] -> h        (12-hour)
         [m01] -> mm       [m1] -> m        (minutes)
         [s01] -> ss       [s1] -> s        (seconds)
         [P] -> tt         (AM/PM)
         [F01] -> fff      (milliseconds)
    -->
    <xsl:template name="convert-date-picture-to-dotnet">
        <xsl:param name="picture"/>
        <xsl:choose>
            <!-- Common complete patterns for efficiency -->
            <xsl:when test="$picture = '[M01]/[D01]/[Y0001]'">MM/dd/yyyy</xsl:when>
            <xsl:when test="$picture = '[D01]/[M01]/[Y0001]'">dd/MM/yyyy</xsl:when>
            <xsl:when test="$picture = '[Y0001]-[M01]-[D01]'">yyyy-MM-dd</xsl:when>
            <xsl:when test="$picture = '[MNn] [D], [Y0001]'">MMMM d, yyyy</xsl:when>
            <xsl:when test="$picture = '[MNn] [D01], [Y0001]'">MMMM dd, yyyy</xsl:when>
            <xsl:when test="$picture = '[D01]-[MNn,3-3]-[Y0001]'">dd-MMM-yyyy</xsl:when>
            <xsl:when test="$picture = '[D01] [MNn,3-3] [Y0001]'">dd MMM yyyy</xsl:when>
            <xsl:when test="$picture = '[MNn,3-3] [D01], [Y0001]'">MMM dd, yyyy</xsl:when>
            <xsl:when test="$picture = '[M01]-[D01]-[Y0001]'">MM-dd-yyyy</xsl:when>
            <xsl:when test="$picture = '[D01]-[M01]-[Y0001]'">dd-MM-yyyy</xsl:when>
            <xsl:when test="$picture = '[Y0001][M01][D01]'">yyyyMMdd</xsl:when>
            <!-- DateTime patterns -->
            <xsl:when test="$picture = '[M01]/[D01]/[Y0001] [H01]:[m01]:[s01]'">MM/dd/yyyy HH:mm:ss</xsl:when>
            <xsl:when test="$picture = '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]'">yyyy-MM-ddTHH:mm:ss</xsl:when>
            <xsl:when test="$picture = '[M01]/[D01]/[Y0001] [h01]:[m01] [P]'">MM/dd/yyyy hh:mm tt</xsl:when>
            <xsl:when test="$picture = '[MNn] [D], [Y0001] [h01]:[m01] [P]'">MMMM d, yyyy hh:mm tt</xsl:when>
            <!-- Time-only patterns -->
            <xsl:when test="$picture = '[H01]:[m01]:[s01]'">HH:mm:ss</xsl:when>
            <xsl:when test="$picture = '[H01]:[m01]'">HH:mm</xsl:when>
            <xsl:when test="$picture = '[h01]:[m01] [P]'">hh:mm tt</xsl:when>
            <xsl:when test="$picture = '[h01]:[m01]:[s01] [P]'">hh:mm:ss tt</xsl:when>
            <!-- Fallback: process picture string component by component -->
            <xsl:otherwise>
                <xsl:call-template name="convert-picture-recursive">
                    <xsl:with-param name="remaining" select="$picture"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Recursive helper to convert picture string component by component -->
    <xsl:template name="convert-picture-recursive">
        <xsl:param name="remaining"/>
        <xsl:choose>
            <xsl:when test="$remaining = ''"/>
            <!-- Handle bracketed components -->
            <xsl:when test="starts-with($remaining, '[')">
                <xsl:variable name="component" select="substring-before(substring-after($remaining, '['), ']')"/>
                <xsl:variable name="after" select="substring-after($remaining, ']')"/>
                <!-- Convert the component -->
                <xsl:choose>
                    <!-- Year -->
                    <xsl:when test="$component = 'Y0001'">yyyy</xsl:when>
                    <xsl:when test="$component = 'Y01'">yy</xsl:when>
                    <!-- Month -->
                    <xsl:when test="$component = 'M01'">MM</xsl:when>
                    <xsl:when test="$component = 'M1'">M</xsl:when>
                    <xsl:when test="$component = 'MNn'">MMMM</xsl:when>
                    <xsl:when test="starts-with($component, 'MNn,3')">MMM</xsl:when>
                    <!-- Day -->
                    <xsl:when test="$component = 'D01'">dd</xsl:when>
                    <xsl:when test="$component = 'D1'">d</xsl:when>
                    <xsl:when test="$component = 'D'">d</xsl:when>
                    <!-- Hour (24-hour) -->
                    <xsl:when test="$component = 'H01'">HH</xsl:when>
                    <xsl:when test="$component = 'H1'">H</xsl:when>
                    <!-- Hour (12-hour) -->
                    <xsl:when test="$component = 'h01'">hh</xsl:when>
                    <xsl:when test="$component = 'h1'">h</xsl:when>
                    <!-- Minute -->
                    <xsl:when test="$component = 'm01'">mm</xsl:when>
                    <xsl:when test="$component = 'm1'">m</xsl:when>
                    <!-- Second -->
                    <xsl:when test="$component = 's01'">ss</xsl:when>
                    <xsl:when test="$component = 's1'">s</xsl:when>
                    <!-- AM/PM -->
                    <xsl:when test="$component = 'P'">tt</xsl:when>
                    <!-- Milliseconds -->
                    <xsl:when test="$component = 'F01'">fff</xsl:when>
                    <!-- Unknown component - output as literal -->
                    <xsl:otherwise>
                        <xsl:value-of select="$component"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Continue with rest of string -->
                <xsl:call-template name="convert-picture-recursive">
                    <xsl:with-param name="remaining" select="$after"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Literal character - pass through -->
            <xsl:otherwise>
                <xsl:value-of select="substring($remaining, 1, 1)"/>
                <xsl:call-template name="convert-picture-recursive">
                    <xsl:with-param name="remaining" select="substring($remaining, 2)"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== HELPER: Normalize size values ========== -->
    <xsl:template name="normalize-size">
        <xsl:param name="size"/>
        <xsl:param name="default" select="'1in'"/>
        <xsl:param name="page-width" select="6.5"/> <!-- Default usable page width in inches -->
        <xsl:choose>
            <xsl:when test="not($size) or $size = ''">
                <xsl:value-of select="$default"/>
            </xsl:when>
            <!-- Percentage: convert to inches based on page width -->
            <xsl:when test="contains($size, '%')">
                <xsl:variable name="pct" select="number(translate($size, '%', ''))"/>
                <xsl:value-of select="format-number($pct div 100 * $page-width, '0.00')"/>
                <xsl:text>in</xsl:text>
            </xsl:when>
            <!-- Already has valid unit -->
            <xsl:when test="contains($size, 'in') or contains($size, 'mm') or contains($size, 'cm') or contains($size, 'pt') or contains($size, 'pc')">
                <xsl:value-of select="$size"/>
            </xsl:when>
            <!-- No unit specified, assume inches if numeric -->
            <xsl:when test="string(number($size)) != 'NaN'">
                <xsl:value-of select="$size"/>
                <xsl:text>in</xsl:text>
            </xsl:when>
            <!-- Default fallback -->
            <xsl:otherwise>
                <xsl:value-of select="$default"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ========== HELPER: Convert text styles ========== -->
    <xsl:template name="convert-text-style">
        <xsl:param name="node" select="."/>
        <!-- Use [1] to ensure we only get first node's attributes -->
        <xsl:variable name="n" select="$node[1]"/>
        <xsl:if test="$n/@font-family">
            <FontFamily>
                <xsl:value-of select="$n/@font-family"/>
            </FontFamily>
        </xsl:if>
        <xsl:if test="$n/@font-size">
            <FontSize>
                <xsl:value-of select="$n/@font-size"/>
            </FontSize>
        </xsl:if>
        <xsl:if test="$n/@font-weight = 'bold'">
            <FontWeight>Bold</FontWeight>
        </xsl:if>
        <xsl:if test="$n/@font-style = 'italic'">
            <FontStyle>Italic</FontStyle>
        </xsl:if>
        <xsl:if test="$n/@color">
            <Color>
                <xsl:value-of select="$n/@color"/>
            </Color>
        </xsl:if>
    </xsl:template>

    <!-- ========== HELPER: Convert paragraph styles ========== -->
    <xsl:template name="convert-paragraph-style">
        <xsl:param name="inherited-text-align" select="''"/>
        
        <!-- Determine effective text-align -->
        <xsl:variable name="effective-align">
            <xsl:choose>
                <xsl:when test="@text-align"><xsl:value-of select="@text-align"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$inherited-text-align"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$effective-align != ''">
            <TextAlign>
                <xsl:choose>
                    <xsl:when test="$effective-align = 'left'">Left</xsl:when>
                    <xsl:when test="$effective-align = 'right'">Right</xsl:when>
                    <xsl:when test="$effective-align = 'center'">Center</xsl:when>
                    <xsl:when test="$effective-align = 'justify'">Justify</xsl:when>
                    <xsl:otherwise>Left</xsl:otherwise>
                </xsl:choose>
            </TextAlign>
        </xsl:if>
    </xsl:template>

    <!-- ========== HELPER: Convert border styles ========== -->
    <xsl:template name="convert-border-style">
        <xsl:if test="@border or @border-top or @border-bottom or @border-left or @border-right">
            <Border>
                <Style>Solid</Style>
                <Width>1pt</Width>
            </Border>
        </xsl:if>
        <xsl:if test="@background-color">
            <BackgroundColor>
                <xsl:value-of select="@background-color"/>
            </BackgroundColor>
        </xsl:if>
        <xsl:if test="@padding">
            <PaddingLeft>
                <xsl:value-of select="@padding"/>
            </PaddingLeft>
            <PaddingRight>
                <xsl:value-of select="@padding"/>
            </PaddingRight>
            <PaddingTop>
                <xsl:value-of select="@padding"/>
            </PaddingTop>
            <PaddingBottom>
                <xsl:value-of select="@padding"/>
            </PaddingBottom>
        </xsl:if>
    </xsl:template>

    <!-- ========== HELPER: Convert cell styles (borders, padding, vertical alignment) ========== -->
    <xsl:template name="convert-cell-style">
        <!-- Borders -->
        <xsl:if test="@border or @border-top or @border-bottom or @border-left or @border-right">
            <Border>
                <Style>Solid</Style>
                <Width>1pt</Width>
            </Border>
        </xsl:if>
        <!-- Background color -->
        <xsl:if test="@background-color">
            <BackgroundColor>
                <xsl:value-of select="@background-color"/>
            </BackgroundColor>
        </xsl:if>
        <!-- Padding - handle both shorthand and individual properties -->
        <xsl:choose>
            <xsl:when test="@padding-left or @padding-right or @padding-top or @padding-bottom">
                <xsl:if test="@padding-left">
                    <PaddingLeft><xsl:value-of select="@padding-left"/></PaddingLeft>
                </xsl:if>
                <xsl:if test="@padding-right">
                    <PaddingRight><xsl:value-of select="@padding-right"/></PaddingRight>
                </xsl:if>
                <xsl:if test="@padding-top">
                    <PaddingTop><xsl:value-of select="@padding-top"/></PaddingTop>
                </xsl:if>
                <xsl:if test="@padding-bottom">
                    <PaddingBottom><xsl:value-of select="@padding-bottom"/></PaddingBottom>
                </xsl:if>
            </xsl:when>
            <xsl:when test="@padding">
                <PaddingLeft><xsl:value-of select="@padding"/></PaddingLeft>
                <PaddingRight><xsl:value-of select="@padding"/></PaddingRight>
                <PaddingTop><xsl:value-of select="@padding"/></PaddingTop>
                <PaddingBottom><xsl:value-of select="@padding"/></PaddingBottom>
            </xsl:when>
        </xsl:choose>
        <!-- Vertical alignment -->
        <xsl:if test="@display-align">
            <VerticalAlign>
                <xsl:choose>
                    <xsl:when test="@display-align = 'before'">Top</xsl:when>
                    <xsl:when test="@display-align = 'center'">Middle</xsl:when>
                    <xsl:when test="@display-align = 'after'">Bottom</xsl:when>
                    <xsl:otherwise>Top</xsl:otherwise>
                </xsl:choose>
            </VerticalAlign>
        </xsl:if>
    </xsl:template>

    <!-- ========== IGNORE THESE ELEMENTS ========== -->
    <xsl:template match="fo:layout-master-set"/>
    <xsl:template match="xsl:template"/>
    <xsl:template match="xsl:output"/>
    
    <!-- ========== FO:STATIC-CONTENT (headers/footers) ========== -->
    <!-- Process static content blocks as regular textboxes -->
    <xsl:template match="fo:static-content[@flow-name='xsl-region-before']">
        <xsl:apply-templates select="fo:block"/>
    </xsl:template>
    
    <!-- Default mode: skip footer content in body (it goes in PageFooter) -->
    <xsl:template match="fo:static-content[@flow-name='xsl-region-after']">
        <!-- Footer content is processed in page-footer mode, not here -->
    </xsl:template>
    
    <!-- Page footer mode: create proper footer textbox -->
    <xsl:template match="fo:static-content[@flow-name='xsl-region-after']" mode="page-footer">
        <xsl:for-each select="fo:block">
            <Textbox xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                <xsl:attribute name="Name">
                    <xsl:text>PageFooter_</xsl:text>
                    <xsl:value-of select="generate-id()"/>
                </xsl:attribute>
                <CanGrow>true</CanGrow>
                <KeepTogether>true</KeepTogether>
                <Paragraphs>
                    <Paragraph>
                        <TextRuns>
                            <xsl:apply-templates select="node()" mode="footer-text-runs"/>
                        </TextRuns>
                        <Style>
                            <xsl:if test="@text-align">
                                <TextAlign>
                                    <xsl:choose>
                                        <xsl:when test="@text-align = 'left'">Left</xsl:when>
                                        <xsl:when test="@text-align = 'right'">Right</xsl:when>
                                        <xsl:when test="@text-align = 'center'">Center</xsl:when>
                                        <xsl:when test="@text-align = 'justify'">Justify</xsl:when>
                                        <xsl:otherwise>Left</xsl:otherwise>
                                    </xsl:choose>
                                </TextAlign>
                            </xsl:if>
                        </Style>
                    </Paragraph>
                </Paragraphs>
                <Top>0in</Top>
                <Left>0in</Left>
                <Height>0.25in</Height>
                <Width>6.5in</Width>
                <Style>
                    <xsl:if test="@font-size">
                        <FontSize><xsl:value-of select="@font-size"/></FontSize>
                    </xsl:if>
                    <xsl:if test="@color">
                        <Color><xsl:value-of select="@color"/></Color>
                    </xsl:if>
                </Style>
            </Textbox>
        </xsl:for-each>
        <!-- Also handle fo:table in footer by extracting cells as separate textboxes -->
        <xsl:for-each select="fo:table//fo:table-cell">
            <xsl:variable name="cell-pos" select="position()"/>
            <Textbox xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                <xsl:attribute name="Name">
                    <xsl:text>PageFooter_Cell_</xsl:text>
                    <xsl:value-of select="generate-id()"/>
                </xsl:attribute>
                <CanGrow>true</CanGrow>
                <KeepTogether>true</KeepTogether>
                <Paragraphs>
                    <Paragraph>
                        <TextRuns>
                            <xsl:apply-templates select="fo:block/node()" mode="footer-text-runs"/>
                            <!-- If no content was generated -->
                            <xsl:if test="not(fo:block/node())">
                                <TextRun>
                                    <Value/>
                                    <Style/>
                                </TextRun>
                            </xsl:if>
                        </TextRuns>
                        <Style>
                            <xsl:if test="fo:block/@text-align">
                                <TextAlign>
                                    <xsl:choose>
                                        <xsl:when test="fo:block/@text-align = 'left'">Left</xsl:when>
                                        <xsl:when test="fo:block/@text-align = 'right'">Right</xsl:when>
                                        <xsl:when test="fo:block/@text-align = 'center'">Center</xsl:when>
                                        <xsl:when test="fo:block/@text-align = 'justify'">Justify</xsl:when>
                                        <xsl:otherwise>Left</xsl:otherwise>
                                    </xsl:choose>
                                </TextAlign>
                            </xsl:if>
                        </Style>
                    </Paragraph>
                </Paragraphs>
                <Top>0in</Top>
                <!-- Position cells horizontally based on position -->
                <Left><xsl:value-of select="($cell-pos - 1) * 2.3"/>in</Left>
                <Height>0.25in</Height>
                <Width>2.3in</Width>
                <Style>
                    <xsl:if test="fo:block/@font-size">
                        <FontSize><xsl:value-of select="fo:block/@font-size"/></FontSize>
                    </xsl:if>
                    <xsl:if test="fo:block/@color">
                        <Color><xsl:value-of select="fo:block/@color"/></Color>
                    </xsl:if>
                </Style>
            </Textbox>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Footer text processing -->
    <xsl:template match="text()" mode="footer-text-runs">
        <xsl:if test="normalize-space(.)">
            <TextRun xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
                <Value><xsl:value-of select="."/></Value>
                <Style/>
            </TextRun>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="fo:page-number" mode="footer-text-runs">
        <TextRun xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
            <Value>=Globals!PageNumber</Value>
            <Style/>
        </TextRun>
    </xsl:template>
    
    <xsl:template match="fo:page-number-citation" mode="footer-text-runs">
        <!-- fo:page-number-citation ref-id="lastPage" → total page count -->
        <TextRun xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
            <Value>=Globals!TotalPages</Value>
            <Style/>
        </TextRun>
    </xsl:template>
    
    <xsl:template match="xsl:value-of" mode="footer-text-runs">
        <!-- Page footer field references must use First() aggregate with dataset scope -->
        <TextRun xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition">
            <Value>
                <xsl:call-template name="convert-xsl-value-of-to-ssrs-footer">
                    <xsl:with-param name="select" select="@select"/>
                </xsl:call-template>
            </Value>
            <Style/>
        </TextRun>
    </xsl:template>
    
    <!-- Special conversion for page footer - wraps field references in First() aggregate -->
    <xsl:template name="convert-xsl-value-of-to-ssrs-footer">
        <xsl:param name="select"/>
        <xsl:variable name="trimmed" select="normalize-space($select)"/>
        
        <xsl:choose>
            <!-- Handle format-number(xpath, 'pattern') -->
            <xsl:when test="starts-with($trimmed, 'format-number(')">
                <xsl:variable name="inner" select="substring-after($trimmed, 'format-number(')"/>
                <xsl:variable name="xpath-part" select="normalize-space(substring-before($inner, ','))"/>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$xpath-part"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- Extract format pattern -->
                <xsl:variable name="format-pattern">
                    <xsl:call-template name="extract-format-pattern">
                        <xsl:with-param name="expr" select="$trimmed"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:text>=Format(First(Fields!</xsl:text>
                <xsl:value-of select="$field"/>
                <xsl:text>.Value, "DataSet1"), "</xsl:text>
                <xsl:value-of select="$format-pattern"/>
                <xsl:text>")</xsl:text>
            </xsl:when>
            <!-- Regular field reference -->
            <xsl:otherwise>
                <xsl:variable name="field">
                    <xsl:call-template name="xpath-to-field">
                        <xsl:with-param name="xpath" select="$trimmed"/>
                    </xsl:call-template>
                </xsl:variable>
                <!-- Use First() aggregate to access dataset fields from page footer -->
                <xsl:text>=First(Fields!</xsl:text>
                <xsl:value-of select="$field"/>
                <xsl:text>.Value, "DataSet1")</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Catch-all for unhandled elements -->
    <xsl:template match="*">
        <xsl:comment>Unhandled element: <xsl:value-of select="local-name()"/>
        </xsl:comment>
        <xsl:apply-templates/>
    </xsl:template>

</xsl:stylesheet>