// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a LGPL-style license that can be found in the LICENSE file.

library SuperTableSaveAsFODS;

import 'dart:html';
//import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'supertable.dart';


class SuperTableSaveAsFODS extends SuperTableSaveAs {
  static const String S = '<?xml version="1.0" encoding="UTF-8"?>' ;
  static const String STARTWORKBOOK = 
    '<?xml version="1.0" encoding="UTF-8"?>' 
    '<office:document xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" ' 
    'xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" '
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" ' 
    'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" ' 
    'xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" ' 
    'xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" ' 
    'xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" ' 
    'xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" ' 
    'xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" ' 
    'xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0" ' 
    'xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" ' 
    'xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" ' 
    'xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" ' 
    'xmlns:math="http://www.w3.org/1998/Math/MathML" ' 
    'xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" ' 
    'xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" ' 
    'xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0" ' 
    'xmlns:ooo="http://openoffice.org/2004/office" ' 
    'xmlns:ooow="http://openoffice.org/2004/writer" ' 
    'xmlns:oooc="http://openoffice.org/2004/calc" ' 
    'xmlns:dom="http://www.w3.org/2001/xml-events" ' 
    'xmlns:xforms="http://www.w3.org/2002/xforms" ' 
    'xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' 
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' 
    'xmlns:rpt="http://openoffice.org/2005/report" ' 
    'xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" ' 
    'xmlns:xhtml="http://www.w3.org/1999/xhtml" ' 
    'xmlns:grddl="http://www.w3.org/2003/g/data-view#" ' 
    'xmlns:tableooo="http://openoffice.org/2009/table" ' 
    'xmlns:drawooo="http://openoffice.org/2010/draw" ' 
    'xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0" ' 
    'xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0" ' 
    'xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0" ' 
    'xmlns:formx="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0" ' 
    'xmlns:css3t="http://www.w3.org/TR/css3-text/" office:version="1.2" ' 
    'office:mimetype="application/vnd.oasis.opendocument.spreadsheet">' ;
  static const String SCRIPTS =
    '<office:scripts>'
      '<office:script script:language="ooo:Basic">'
      '<ooo:libraries xmlns:ooo="http://openoffice.org/2004/office" xmlns:xlink="http://www.w3.org/1999/xlink"/>'
      '</office:script>'
    '</office:scripts>';
  static const String FONTS =
    '<office:font-face-decls>'
      '<style:font-face style:name="Liberation Sans" svg:font-family="&apos;Liberation Sans&apos;" style:font-family-generic="swiss" style:font-pitch="variable"/>'
      '<style:font-face style:name="DejaVu Sans" svg:font-family="&apos;DejaVu Sans&apos;" style:font-family-generic="system" style:font-pitch="variable"/>'
      '<style:font-face style:name="Droid Sans Fallback" svg:font-family="&apos;Droid Sans Fallback&apos;" style:font-family-generic="system" style:font-pitch="variable"/>'
      '<style:font-face style:name="Lohit Marathi" svg:font-family="&apos;Lohit Marathi&apos;" style:font-family-generic="system" style:font-pitch="variable"/>'
    '</office:font-face-decls>';
  static const String STARTSTYLES =
    '<office:styles>'
      '<style:default-style style:family="table-cell">'
        '<style:paragraph-properties style:tab-stop-distance="0.5in"/>'
        '<style:text-properties style:font-name="Liberation Sans" fo:language="en" fo:country="US" style:font-name-asian="DejaVu Sans" style:language-asian="zh" style:country-asian="CN" style:font-name-complex="DejaVu Sans" style:language-complex="hi" style:country-complex="IN"/>'
      '</style:default-style>';
  static const String INTSTYLE =
    '<number:number-style style:name="N0">'
      '<number:number number:min-integer-digits="1"/>'
    '</number:number-style>';
  static const String MONEYSTYLE1 = 
    '<number:currency-style style:name="N104P0" style:volatile="true">'
      '<number:currency-symbol number:language="en" number:country="US">\$</number:currency-symbol>'
      '<number:number number:decimal-places="2" number:min-integer-digits="1" number:grouping="true"/>'
    '</number:currency-style>';
  static const String MONEYSTYLE2 = 
    '<number:currency-style style:name="N104">'
      '<style:text-properties fo:color="#ff0000"/>'
      '<number:text>-</number:text>'
      '<number:currency-symbol number:language="en" number:country="US">\$</number:currency-symbol>'
      '<number:number number:decimal-places="2" number:min-integer-digits="1" number:grouping="true"/>'
      '<style:map style:condition="value()&gt;=0" style:apply-style-name="N104P0"/>'
    '</number:currency-style>' ;
  static const String DATESTYLE1 =
    '<number:date-style style:name="N120">'
      '<number:year number:style="long"/>'
      '<number:month number:style="long"/>'
      '<number:day number:style="long"/>'
    '</number:date-style>';
  static const String DATESTYLE2 =
    '<number:date-style style:name="N121">'
      '<number:year number:style="long"/>'
      '<number:text>/</number:text>'
      '<number:month number:style="long"/>'
      '<number:text>/</number:text>'
      '<number:day number:style="long"/>'
      '<number:text> </number:text>'
      '<number:hours number:style="long"/>'
      '<number:text>:</number:text>'
      '<number:minutes number:style="long"/>'
    '</number:date-style>';
  static const String DATESTYLE3 =
    '<number:date-style style:name="N10084" number:language="en" number:country="US">'
      '<number:year number:style="long"/>'
      '<number:text>-</number:text>'
      '<number:month number:style="long"/>'
      '<number:text>-</number:text>'
      '<number:day number:style="long"/>'
    '</number:date-style>';

  static const String CELLSTYLEDEFAULT =      
    '<style:style style:name="Default" style:family="table-cell">'
      '<style:text-properties style:font-name-asian="Droid Sans Fallback" style:font-family-asian="&apos;Droid Sans Fallback&apos;" style:font-family-generic-asian="system" style:font-pitch-asian="variable" style:font-name-complex="Lohit Marathi" style:font-family-complex="&apos;Lohit Marathi&apos;" style:font-family-generic-complex="system" style:font-pitch-complex="variable"/>'
    '</style:style>';
  static const String RESULTSTYEDEFAULT =
    '<style:style style:name="Result" style:family="table-cell" style:parent-style-name="Default">'
      '<style:text-properties fo:font-style="italic" style:text-underline-style="solid" style:text-underline-width="auto" style:text-underline-color="font-color" fo:font-weight="bold"/>'
    '</style:style>';
  static const String RESULTSTYLE2 =
    '<style:style style:name="Result2" style:family="table-cell" style:parent-style-name="Result" style:data-style-name="N104"/>';
  static const String HEADINGSTYLE =
    '<style:style style:name="Heading" style:family="table-cell" style:parent-style-name="Default">'
      '<style:table-cell-properties style:text-align-source="fix" style:repeat-content="false"/>'
      '<style:paragraph-properties fo:text-align="center"/>'
      '<style:text-properties fo:font-size="16pt" fo:font-style="italic" fo:font-weight="bold"/>'
    '</style:style>';
  static const String HEADINGSTYLE1 =
    '<style:style style:name="Heading1" style:family="table-cell" style:parent-style-name="Heading">'
      '<style:table-cell-properties style:rotation-angle="90"/>'
    '</style:style>';
  static const String ENDSTYLES = '</office:styles>';
  
  // Now automatic styles
  static const String STARTAUTOMATICSTYLES = '<office:automatic-styles>';
  // We will probably need to add one of these for each column width
  static const String AUTOMATICSTYLECOLSTARTPREFIX = '<style:style style:name="';
  static const String AUTOMATICSTYLECOLSTARTSUFFIX = '" style:family="table-column">';
  static const String AUTOMATICSTYLECOLPROPPREFIX = '<style:table-column-properties fo:break-before="auto" style:column-width="';
  static const String AUTOMATICSTYLECOLPROPSUFFIX = 'in"/>';
  static const String AUTOMATICSTYLECOLEND = '</style:style>'; 
  
  static const String AUTOMATICSTYLECO1 =
    '<style:style style:name="co1" style:family="table-column">'
      '<style:table-column-properties fo:break-before="auto" style:column-width="0.889in"/>'
    '</style:style>';  
  static const String AUTOMATICSTYLECO2 =
    '<style:style style:name="co2" style:family="table-column">'
      '<style:table-column-properties fo:break-before="auto" style:column-width="1.2646in"/>'
    '</style:style>';
  static const String AUTOMATICSTYLERO1 =
    '<style:style style:name="ro1" style:family="table-row">'
      '<style:table-row-properties style:row-height="0.178in" fo:break-before="auto" style:use-optimal-row-height="true"/>'
    '</style:style>' ;
  static const String AUTOMATICSTYLETA1 =
    '<style:style style:name="ta1" style:family="table" style:master-page-name="Default">'
      '<style:table-properties table:display="true" style:writing-mode="lr-tb"/>'
    '</style:style>';
  static const String AUTOMATICSTYLEN4 = 
    '<number:number-style style:name="N4">'
      '<number:number number:decimal-places="2" number:min-integer-digits="1" number:grouping="true"/>'
    '</number:number-style>' ;
  static const String AUTOMATICSTYLEN100 = 
    '<number:text-style style:name="N100">'
      '<number:text-content/>'
    '</number:text-style>';
  static const String AUTOMATICSTYLECE1 = 
    '<style:style style:name="ce1" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N100">'
      '<style:table-cell-properties fo:border-bottom="none" fo:background-color="#e6e6e6" fo:border-left="0.06pt solid #000000" fo:border-right="0.06pt solid #000000" fo:border-top="none"/>'
      '<style:text-properties fo:font-weight="bold"/>'
    '</style:style>' ;
  // We may need to add more of these
  static const String AUTOMATICSTYLECE2 = '<style:style style:name="ce2" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N120"/>';
  static const String AUTOMATICSTYLECE3 = '<style:style style:name="ce3" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N4"/>';
  static const String AUTOMATICSTYLECE4 = '<style:style style:name="ce4" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N121"/>';
  static const String AUTOMATICSTYLEPM1 = 
    '<style:page-layout style:name="pm1">'
      '<style:page-layout-properties style:writing-mode="lr-tb"/>'
      '<style:header-style>'
        '<style:header-footer-properties fo:min-height="0.2953in" fo:margin-left="0in" fo:margin-right="0in" fo:margin-bottom="0.0984in"/>'
      '</style:header-style>'
      '<style:footer-style>'
        '<style:header-footer-properties fo:min-height="0.2953in" fo:margin-left="0in" fo:margin-right="0in" fo:margin-top="0.0984in"/>'
      '</style:footer-style>'
    '</style:page-layout>' ;
  static const String AUTOMATICSTYLEPM2 = 
    '<style:page-layout style:name="pm2">'
      '<style:page-layout-properties style:writing-mode="lr-tb"/>'
      '<style:header-style>'
        '<style:header-footer-properties fo:min-height="0.2953in" fo:margin-left="0in" fo:margin-right="0in" fo:margin-bottom="0.0984in" fo:border="2.49pt solid #000000" fo:padding="0.0071in" fo:background-color="#c0c0c0">'
          '<style:background-image/>'
        '</style:header-footer-properties>'
      '</style:header-style>'
      '<style:footer-style>'
        '<style:header-footer-properties fo:min-height="0.2953in" fo:margin-left="0in" fo:margin-right="0in" fo:margin-top="0.0984in" fo:border="2.49pt solid #000000" fo:padding="0.0071in" fo:background-color="#c0c0c0">'
          '<style:background-image/>'
        '</style:header-footer-properties>'
      '</style:footer-style>'
    '</style:page-layout>' ;
  static const String ENDAUTOMATICSTYLES = '</office:automatic-styles>';
  
  // Finally master styles
  static const String STARTMASTERSTYLES = '<office:master-styles>';
  static const String MASTERSTYLEPAGEDEFAULT = 
    '<style:master-page style:name="Default" style:page-layout-name="pm1">'
     '<style:header>'
      '<text:p><text:sheet-name>???</text:sheet-name></text:p>'
     '</style:header>'
     '<style:header-left style:display="false"/>'
     '<style:footer>'
      '<text:p>Page <text:page-number>1</text:page-number></text:p>'
     '</style:footer>'
     '<style:footer-left style:display="false"/>'
    '</style:master-page>' ;
  static const String MASTERSTYLEPAGEREPORT = 
    '<style:master-page style:name="Report" style:page-layout-name="pm2">'
     '<style:header>'
      '<style:region-left>'
       '<text:p><text:sheet-name>???</text:sheet-name> (<text:title>???</text:title>)</text:p>'
      '</style:region-left>'
      '<style:region-right>'
       '<text:p><text:date style:data-style-name="N2" text:date-value="2015-02-28">00/00/0000</text:date>, <text:time>00:00:00</text:time></text:p>'
      '</style:region-right>'
     '</style:header>'
     '<style:header-left style:display="false"/>'
     '<style:footer>'
      '<text:p>Page <text:page-number>1</text:page-number> / <text:page-count>99</text:page-count></text:p>'
     '</style:footer>'
     '<style:footer-left style:display="false"/>'
    '</style:master-page>' ;
  static const String ENDMASTERSTYLES = '</office:master-styles>';
  
  // Now the guts
  static const String STARTBODY = '<office:body>';
  static const String STARTSHEET = '<office:spreadsheet>';
  static const String STARTTABLE = '<table:table table:name="Sheet1" table:style-name="ta1">'; // may want to be able to tailor sheet name
  static const String TABLEFORMS = '<office:forms form:automatic-focus="false" form:apply-design-mode="false"/>';
  
  static const String TABLECOLUMNPREFIX = '<table:table-column table:style-name="'; // Add column style here
  static const String TABLECOLUMNPIECE2 = '" table:number-columns-repeated="1" '; // we'll simplify to one per columns
  static const String TABLECOLUMNPIECE3 = 'table:default-cell-style-name="'; // need to add default cell style here
  static const String TABLECOLUMNSUFFIX = '"/>';
  static const String STARTTABLEHEADERROWPREFIX = '<table:table-row table:style-name="'; // Add row style here
  static const String STARTTABLEHEADERROWSUFFIX = '">';
  
  // We might need to mess with this if we want to change centering of titles to match the content alignment
  static const String TABLEHEADERCELLSTART = '<table:table-cell table:style-name="ce1" office:value-type="string" calcext:value-type="string">';
  static const String TABLEHEADERCELLCONTENTSTART = '<text:p>'; // Puthe the header contents here
  static const String TABLEHEADERCELLCONTENTEND = '</text:p>';
  static const String TABLEHEADERCELLEND = '</table:table-cell>';
  
  static const String ENDTABLEHEADERROW = '</table:table-row>'; // probably the same as all row ends, but let's waste a few bytes for sanity
  
  static const String STARTTABLEDATAROWPREFIX = '<table:table-row table:style-name="';
  static const String STARTTABLEDATAROWSUFFIX = '">';
  
  static const String TABLEDATACELLCONTENTSTART = '<text:p>'; // Put the the data contents here
  static const String TABLEDATACELLCONTENTEND = '</text:p>';

  // text/string 
  static const String TABLEDATASTRINGCELLSTART = '<table:table-cell office:value-type="string" calcext:value-type="string">';
  static const String TABLEDATASTRINGCELLEND = '</table:table-cell>';
  
  // integer
  static const String TABLEDATAINTCELLSTARTPREFIX = '<table:table-cell office:value-type="float" office:value="'; // Value here
  static const String TABLEDATAINTCELLSTARTSUFFIX = '" calcext:value-type="float">';
  static const String TABLEDATAINTCELLEND = '</table:table-cell>';
  
  // date
  static const String TABLEDATADATECELLSTARTPREFIX = '<table:table-cell office:value-type="date" office:date-value="'; // YYYY-MM-DD value here
  static const String TABLEDATADATECELLSTARTSUFFIX = '" calcext:value-type="date">';
  static const String TABLEDATADATECELLEND = '</table:table-cell>';
  
  // money
  static const String TABLEDATAMONEYCELLSTARTPREFIX = '<table:table-cell office:value-type="float" office:value="'; // n.dd value here
  static const String TABLEDATAMONEYCELLSTARTSUFFIX = '" calcext:value-type="float">';
  static const String TABLEDATAMONEYCELLEND = '</table:table-cell>';
  
  // datetime
  static const String TABLEDATADATETIMECELLSTART = '<table:table-cell office:value-type="string" calcext:value-type="string">';
  static const String TABLEDATADATETIMECELLEND = '</table:table-cell>';
  
  static const String ENDTABLEDATAROW = '</table:table-row>';
  static const String ENDTABLE = '</table:table>';
  
  static const String TABLENAMEDEXPRESSIONS = '<table:named-expressions/>';
  
  static const String ENDSHEET = '</office:spreadsheet>';
  static const String ENDBODY = '</office:body>';
  
  static const String ENDDOCUMENT = '</office:document>';
  
  double pixelsPerInch = 100.0;
  String fileContents;
  
  SuperTableSaveAsFODS({bool debug}) : super(debug: debug) {
    style = 'FlatXMLODS';
  }
  
  AnchorElement saveAs(SuperTable table) {
    // Someday we can check the size and see if we need to alocate disk space and build there instead
    fileContents = buildFileInMemory(table);
    
    List blobContents = new List();
    blobContents.add(fileContents);
    // For now, just save everything in table.id.csv
    String fileName;
    fileName = table.id + '.fods';
    
    Blob blob = new Blob(blobContents, 'text/xml', 'native');
    String url = Url.createObjectUrlFromBlob(blob);
        
    AnchorElement link = new AnchorElement()
          ..href = url
          ..download = fileName
          ..text = 'Download now...';
    
    return link;
  }
  
  String buildFileInMemory(SuperTable table) {
    StringBuffer sb = new StringBuffer();
    Element tr;
    List<Element> trs, cols;
    int columnCount, rowCount;
    
    trs = table.table.querySelectorAll('tr'); // We'll use this more than once
    
    // Before building the start, we need to know the number of rows and columns to get the number of cells
    columnCount = getColumnCount(table);
    rowCount = getRowCount(table,trs);
    
    sb.writeln(buildTopOfFile(columnCount * rowCount));
    
    sb.write(buildStyles(table));
    
    // Start the body
    sb.writeln(STARTBODY);
    sb.writeln(STARTSHEET);
    sb.writeln(STARTTABLE);
    sb.writeln(TABLEFORMS);
    
    // Now define the columns
    sb.write(buildColumns(table));
    
    sb.write(buildHeaderRow(table));
    
    cols = table.colGroup.querySelectorAll('col');
    
    // Rows will be in their current order
    for (tr in trs) {
      sb.write(buildDataRow(table, cols, tr));
    }
    
    sb.writeln(ENDTABLE);
    sb.writeln(TABLENAMEDEXPRESSIONS);
    sb.writeln(ENDSHEET);
    sb.writeln(ENDBODY);
    sb.writeln(ENDDOCUMENT);
    
    return sb.toString();
  }
  
  String buildHeaderRow(SuperTable table) {
    StringBuffer s;
    Element th;
    List<Element>ths;
    
    s = new StringBuffer();
    
    // For now we just use ro1
    s.write(STARTTABLEHEADERROWPREFIX); s.write('ro1'); s.writeln(STARTTABLEHEADERROWSUFFIX);
    
    ths = table.headerTable.querySelectorAll('th');
    // Later we'll look for selected columns, but for now all columns
    for (th in ths) {
      s.writeln(TABLEHEADERCELLSTART);
      s.write(TABLEHEADERCELLCONTENTSTART);
      s.write(getHeaderCellText(table,th));
      s.write(TABLEHEADERCELLCONTENTEND);
      s.writeln(TABLEHEADERCELLEND);
    }
    
    s.writeln(ENDTABLEHEADERROW);
    
    return s.toString();
  }

  String buildDataRow(SuperTable table, List<Element> cols, Element tr) {
    StringBuffer s;
    List<Element> tds;
    Element td, col;
    String dataTypeName;
    int pos;
    
    s = new StringBuffer();
    
    // For now we just use ro1
    s.write(STARTTABLEDATAROWPREFIX); s.write('ro1'); s.writeln(STARTTABLEDATAROWSUFFIX);
    
    tds = tr.querySelectorAll('td');
    pos = 0;
    for (td in tds) {
      col = cols[pos];
      dataTypeName = col.getAttribute(table.DataTypeAttrName);

      s.write(buildDataCell(dataTypeName, td));
      pos++;
    }
    
    s.writeln(ENDTABLEDATAROW);
    
    return s.toString();
  }

  
  String buildDataCell(String dataTypeName, Element td) {
    StringBuffer s;
       
    s = new StringBuffer();
          
    if (dataTypeName == 'text') {
      s.writeln(TABLEDATASTRINGCELLSTART);
      s.write(TABLEDATACELLCONTENTSTART); s.write(td.text); s.writeln(TABLEDATACELLCONTENTEND);
      s.writeln(TABLEDATASTRINGCELLEND);
    } else if (dataTypeName == 'money') {
      s.write(TABLEDATAMONEYCELLSTARTPREFIX); s.write(td.text); s.writeln(TABLEDATAMONEYCELLSTARTSUFFIX); 
      s.write(TABLEDATACELLCONTENTSTART); s.write(td.text); s.writeln(TABLEDATACELLCONTENTEND);
      s.writeln(TABLEDATAMONEYCELLEND);
   } else if (dataTypeName == 'integer') {
      s.write(TABLEDATAINTCELLSTARTPREFIX); s.write(td.text); s.writeln(TABLEDATAINTCELLSTARTSUFFIX); 
      s.write(TABLEDATACELLCONTENTSTART); s.write(td.text); s.writeln(TABLEDATACELLCONTENTEND);
      s.writeln(TABLEDATAINTCELLEND);
    } else if (dataTypeName == 'datetime') {
      s.writeln(TABLEDATADATETIMECELLSTART);
      s.write(TABLEDATACELLCONTENTSTART); s.write(td.text); s.writeln(TABLEDATACELLCONTENTEND);
      s.writeln(TABLEDATADATETIMECELLEND);
    } else if (dataTypeName == 'date') {  
      // the value must be in format YYYY-MM-DD.  The contents can be however.
      s.write(TABLEDATADATECELLSTARTPREFIX); 
      s.write(td.text.substring(0,4) + '-' + td.text.substring(5,7) + '-' + td.text.substring(8,10)); 
      s.writeln(TABLEDATAMONEYCELLSTARTSUFFIX); 
      s.write(TABLEDATACELLCONTENTSTART); s.write(td.text); s.writeln(TABLEDATACELLCONTENTEND);
      s.writeln(TABLEDATADATECELLEND);
    } else {  
      s.writeln(TABLEDATASTRINGCELLSTART);
      s.write(TABLEDATACELLCONTENTSTART); s.write(td.text); s.writeln(TABLEDATACELLCONTENTEND);
      s.writeln(TABLEDATASTRINGCELLEND);
    }
    
    return s.toString();
  }
  
  String buildColumns(SuperTable table) {
    StringBuffer s;
    Element col;
    String colPos, dataTypeName;
    
    s = new StringBuffer();
    
    List<Element> cols;
    cols = table.colGroup.querySelectorAll('col');

    for (col in cols) {
      colPos = col.getAttribute(table.InitialDataPosAttrName);
      s.write(TABLECOLUMNPREFIX);
      s.write('COC'); s.write(colPos);
      s.write(TABLECOLUMNPIECE2);
      s.write(TABLECOLUMNPIECE3);
      dataTypeName = col.getAttribute(table.DataTypeAttrName);
      s.write(makeCellStyleName(dataTypeName));
      s.writeln(TABLECOLUMNSUFFIX);
    }
    
    return s.toString();
  }
  

  
  String buildTopOfFile(int cellCount) {
    StringBuffer s;
    s = new StringBuffer();
    s.writeln(STARTWORKBOOK);
    s.writeln(buildMeta(cellCount));
    s.writeln(SCRIPTS);
    s.writeln(FONTS);
    
    return s.toString();
  }
  
  String buildStyles(SuperTable table) {
    Element col;
    StringBuffer s;
    String colPos, colWidth;
    double width;
    SuperTableDataType sddt;
    s = new StringBuffer();
    
    s.writeln(STARTSTYLES);
    s.writeln(INTSTYLE);
    s.writeln(MONEYSTYLE1);
    s.writeln(MONEYSTYLE2);
    s.writeln(DATESTYLE1);
    s.writeln(DATESTYLE2);
    s.writeln(DATESTYLE3);
    s.writeln(CELLSTYLEDEFAULT);
    s.writeln(RESULTSTYEDEFAULT);
    s.writeln(RESULTSTYLE2);
    s.writeln(HEADINGSTYLE);
    s.writeln(HEADINGSTYLE1);
    s.writeln(ENDSTYLES);
    
    s.writeln(STARTAUTOMATICSTYLES);
    // Need to change this to a loop and create one column style for each to handle varying widths
    List<Element> cols;
    cols = table.colGroup.querySelectorAll('col');

    for (col in cols) {
      colPos = col.getAttribute(table.InitialDataPosAttrName);
      s.write(AUTOMATICSTYLECOLSTARTPREFIX);
      s.write('COC'); s.write(colPos);
      s.writeln(AUTOMATICSTYLECOLSTARTSUFFIX);
      s.write(AUTOMATICSTYLECOLPROPPREFIX);
      colWidth = col.getAttribute(table.InitialWidthAttrName);
      width = double.parse(colWidth, (_) { return 100.0; } );
      s.write((width / pixelsPerInch).toString());
      s.writeln(AUTOMATICSTYLECOLPROPSUFFIX);
      s.writeln(AUTOMATICSTYLECOLEND);
    }
    //s.writeln(AUTOMATICSTYLECO1);    
    //s.writeln(AUTOMATICSTYLECO2);
    
    s.writeln(AUTOMATICSTYLERO1);
    s.writeln(AUTOMATICSTYLETA1);
    s.writeln(AUTOMATICSTYLEN4);
    s.writeln(AUTOMATICSTYLEN100);
    
    s.writeln(AUTOMATICSTYLECE1); // The header style (maybe we'll rename later)
    
    // Really need to do one of these for each unique data type, but maybe easier just to duplicate some
    // instead, let's just build one for each datatype defined
    for (sddt in table.superTableDataTypes) {
      s.write(buildCellStyle(sddt.dataTypeName));
    }
    
//    s.writeln(AUTOMATICSTYLECE2);
//    s.writeln(AUTOMATICSTYLECE3);
//    s.writeln(AUTOMATICSTYLECE4);
    
    
    s.writeln(AUTOMATICSTYLEPM1);
    s.writeln(AUTOMATICSTYLEPM2);
    s.writeln(ENDAUTOMATICSTYLES);
    
    
    s.writeln(STARTMASTERSTYLES);
    s.writeln(MASTERSTYLEPAGEDEFAULT);
    s.writeln(MASTERSTYLEPAGEREPORT);
    s.writeln(ENDMASTERSTYLES);
        
    return s.toString();
  }
  
  // If you need to add your own datatypes, subclass and override, or extend, this function.
  String buildCellStyle(String dataTypeName) {
    StringBuffer s;
    s = new StringBuffer();
    String cellStyleName;
    
    cellStyleName = makeCellStyleName(dataTypeName);
    if (dataTypeName == 'text') {
      s.write('<style:style style:name="');
      s.write(cellStyleName);
      s.writeln('" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N100"/>');
    } else if (dataTypeName == 'money') {
      s.write('<style:style style:name="');
      s.write(cellStyleName);
      s.writeln('" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N4"/>');
    } else if (dataTypeName == 'integer') {
      s.write('<style:style style:name="');
      s.write(cellStyleName);
      s.writeln('" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N1"/>');
    } else if (dataTypeName == 'datetime') {
      s.write('<style:style style:name="');
      s.write(cellStyleName);
      s.writeln('" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N121"/>');
    } else if (dataTypeName == 'date') {
      s.write('<style:style style:name="');
      s.write(cellStyleName);
      s.writeln('" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N10084"/>');
    } else {
      // we'll just make a text name for this one
      s.write('<style:style style:name="');
      s.write(cellStyleName);
      s.writeln('" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N100"/>');
    }
    
    return s.toString();
  }
  
  String makeCellStyleName(String dataTypeName) {
    StringBuffer s;
    s = new StringBuffer();
    s.write('CEC'); // For now we'll just prefix it with CEC
    s.write(dataTypeName);
    return s.toString();
  }
  
  String buildMeta(int cellCount) {
    StringBuffer s;
    s = new StringBuffer();
    s.writeln('<office:meta>');
    DateTime dt = new DateTime.now();
    DateFormat df;
    df = new DateFormat('yyyy-MM-ddThh:MM:ss.SSSSSSSSS', "en_US");
    s.writeln('<meta:creation-date>' + dt.toIso8601String() + '</meta:creation-date>');
    s.writeln('<meta:generator>SuperTableSaveAsFODS</meta:generator>');
    s.writeln('<meta:document-statistic meta:table-count="1" meta:cell-count="' + cellCount.toString() + '" meta:object-count="0"/>');
    s.writeln('</office:meta>');
    
    return s.toString();
  }
  
  String buildRow(Element tr) {
    return '';
  }
  
  int getColumnCount(SuperTable table) {
    int count = 0;
    Element col;
    List<Element> cols;
    cols = table.colGroup.querySelectorAll('col');

    for (col in cols) {
      // Someday we will check for selected columns but, until that is ready, just do all columns.
      count++;
    }
    return count;
  }
 
  int getRowCount(SuperTable table, List<Element> trs) {
    int count = 0;
    Element tr;
    for (tr in trs) {
      if (rowsToSave == SuperTableSaveAs.SELECTED) {
        if (tr.classes.contains(table.SelectedRowClass)) count++;
      } else if (rowsToSave == SuperTableSaveAs.UNSELECTED) {
        if (! tr.classes.contains(table.SelectedRowClass)) count++;
      } else count++; // Must be ALL
    }
    return count;
  }
}