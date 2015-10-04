// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a LGPL-style license that can be found in the LICENSE file.

library SuperTable;

import 'dart:html';
import 'dart:async';
import 'package:intl/intl.dart';
import 'resizable.dart';

/*****************************************************************/
/*****************************************************************/
// Begin Double Click Handler
/*****************************************************************/
/*****************************************************************/

abstract class SuperTableDblClkHandler {
  bool enabled = true;
  void handleDblClk(MouseEvent me);
}

/*****************************************************************/
/*****************************************************************/
// End Double Click Handler
/*****************************************************************/
/*****************************************************************/
// Begin Sort rows functions
/*****************************************************************/
/*****************************************************************/

class SuperTableSortColumn {
  String columnClassName;
  String columnDataTypeName;
  SuperTableDataType columnDataType;
  int position;
  bool ascending = true;
}
class SuperTableSortRow {
  Element row;
  int currentPosition;
  // lazy instantiated as needed
  List<Object> sortItemValues;
}

class SuperTableSort {
  SuperTable table;
  List<SuperTableSortRow> rows;
  List<SuperTableSortColumn> sortColumns;
  Element dummyRow = new Element.tr();
  bool debug = false;
  
  SuperTableSort(SuperTable this.table, List<String> columnClassNamesInSortKeyOrder, {this.debug: false}) {
    List<Element> columns, rows;
    Element table, column;
    SuperTableSortRow superRow;
    SuperTableSortColumn sortColumn;
    int colonPos;
    String ascdesc;
    
    sortColumns = new List<SuperTableSortColumn>();
    
    this.rows = new List<SuperTableSortRow>();  
    
    table = this.table.table;
    columns = table.querySelectorAll('th');
    for (String columnClassName in columnClassNamesInSortKeyOrder) {

      sortColumn = new SuperTableSortColumn();
      
      // Let's look at it and see if there is a : (colon) to specify Ascending/Descending
      Debug('columnClassName=' + columnClassName);
      colonPos = columnClassName.indexOf(':');
      Debug('colonPos=' + colonPos.toString());
      if (colonPos >= 0) {
        Debug('We need top parse out the Ascending/Decending');
        sortColumn.columnClassName = columnClassName.substring(0,colonPos);
        Debug('sortColumn.columnClassName=' + sortColumn.columnClassName);
        Debug('columnClassName.length=' + columnClassName.length.toString());
        if (columnClassName.length > colonPos + 1) {
          ascdesc = columnClassName.substring(colonPos + 1);
          Debug('ascdesc=' + ascdesc);
          sortColumn.ascending = ! ascdesc.startsWith('D');
        } else sortColumn.ascending = true;
      } else {
        sortColumn.columnClassName = columnClassName;
        sortColumn.ascending = true;
      }
      
      
      sortColumn.position = 1;
      columns = this.table.colGroup.querySelectorAll('col');
      for (column in columns) {
        Debug('columnClassName=' + sortColumn.columnClassName);
        if (column.classes.contains(sortColumn.columnClassName)) {
          break;
        }
        sortColumn.position ++;
      }
      //column = table.querySelector('th.' + columnClassName);
      sortColumn.columnDataTypeName = column.getAttribute(this.table.DataTypeAttrName);
          
      // Until I figure out how to lookup in a list, just spool thru
      SuperTableDataType columnDataType;
      for (columnDataType in this.table.superTableDataTypes) {
        if (columnDataType.dataTypeName == sortColumn.columnDataTypeName) {
          sortColumn.columnDataType = columnDataType; break;
        }
      }
      sortColumns.add(sortColumn);
    }
    
    // Now get all the rows
    int rowCounter = 1;
    rows = table.querySelectorAll('#' + table.id + ' tr');
    for (Element row in rows) {
      superRow = new SuperTableSortRow();
      superRow.row = row;
      superRow.currentPosition = rowCounter;
      superRow.sortItemValues = new List();
      this.rows.add(superRow);
      rowCounter++;      
    }
  }
  
  void sort() {
    // Is it faster to remove the whole body table from the DOM, then sort, then put it back?
    // Or is it faster just to sort in place?
    // Remember, we need to sort the splitBodey too (if there is one)
    // Need to execute quickSort on the whole list
    quickSort(0,rows.length - 1);

    if (this.table.isSplit) {
      // Need the split row too.  Hmmmm.  Is this the best way?
      this.table
        ..splitBodyTable.remove()
        ..splitBodyTable = this.table.table.clone(true)
        ..splitBodyWrapper_b.insertAdjacentElement('afterBegin',this.table.splitBodyTable);
    }
  }
  
  void quickSort(int left, int right) {
    int i = left, j = right;
    SuperTableSortRow tmp;
    SuperTableSortRow pivot = rows[(left + right) ~/ 2];
     
    /* partition */
    while (i <= j) {
      while (compareRows(rows[i],pivot) < 0)
        i++;
      while (compareRows(rows[j],pivot) > 0)
        j--;
      if (i <= j) {
        // Swap rows, need more brains here to handle the DOM
        tmp = rows[i];
        tmp.row.insertAdjacentElement('beforeBegin', dummyRow);
        rows[j].row.insertAdjacentElement('beforeBegin', rows[i].row);
        dummyRow.insertAdjacentElement('beforeBegin', rows[j].row);
        dummyRow.remove();
        rows[i] = rows[j];
        rows[j] = tmp;
        i++;
        j--;
      }
    };
     
    /* recursion */
    if (left < j)
          quickSort(left, j);
    if (i < right)
          quickSort(i, right);
  }
  
  int compareRows(SuperTableSortRow row1, SuperTableSortRow row2) {
    int sortKey = 1, diff;
    SuperTableSortColumn sortColumn;
    Element cell;
    String cellData;
    Object cellValue;
    
    for (sortColumn in sortColumns) {
      // In order to avoid parsing data more than once, we'll cache them in SuperTableSortRow.sortItemValues
      if (row1.sortItemValues.length < sortKey) {
        Debug('Need to get the data row1 - position=' + sortColumn.position.toString());        
        cell = row1.row.querySelector('td:nth-of-type(' + sortColumn.position.toString() + ')');
        cellData = cell.getAttribute(table.CellValueAttrName);
        if (cellData == null) {
          cellData = cell.text;
          cellValue = sortColumn.columnDataType.parse(cellData);
        } else {
          cellValue = sortColumn.columnDataType.value(cellData);
        }
        row1.sortItemValues.add(cellValue);
      }
      if (row2.sortItemValues.length < sortKey) {
        Debug('Need to get the data row2 - position=' + sortColumn.position.toString());        
        cell = row2.row.querySelector('td:nth-of-type(' + sortColumn.position.toString() + ')');
        cellData = cell.getAttribute(table.CellValueAttrName);
        if (cellData == null) {
          cellData = cell.text;
          cellValue = sortColumn.columnDataType.parse(cellData);
        } else {
          cellValue = sortColumn.columnDataType.value(cellData);
        }
        row2.sortItemValues.add(cellValue);
      }
      
      // need to compare each key
      Debug("left=" + row1.sortItemValues[sortKey - 1].toString());
      Debug("right=" + row2.sortItemValues[sortKey - 1].toString());
      if (sortColumn.ascending)
        diff = sortColumn.columnDataType.compare(row1.sortItemValues[sortKey - 1], row2.sortItemValues[sortKey - 1]);
      else
        diff = sortColumn.columnDataType.compare(row2.sortItemValues[sortKey - 1], row1.sortItemValues[sortKey - 1]);
      if (diff != 0) break;
      sortKey++;
    }
    
    return diff;
  }
  
  void Debug(String s) {
    if (debug) print('SuperTableSort ' + s);
  }
}

/*****************************************************************/
/*****************************************************************/
// End Sort rows functions
/*****************************************************************/
/*****************************************************************/
// Begin Data Types
/*****************************************************************/
/*****************************************************************/

abstract class SuperTableDataType {
  static const String DATATYPEINPUTPREFIX = 'data-datatype-'; // for normal
  static const String UNKNOWNDATATYPE = 'Unknown'; 
  String dataTypeName = UNKNOWNDATATYPE;
  String exportDataTypeName = UNKNOWNDATATYPE;
  String DataTypeInputPrefix = DATATYPEINPUTPREFIX; // for normal, but can be overridden
  bool storeDataValue = true;
  bool debug = false;
  
  bool isType(String s) { return s == dataTypeName; }
  int compare (Object o1, Object o2);
  bool validate(Object o);
  Object parse(String v) ; // Parse the string provided in the original data to generate the object value
  Object value(String v) ; // parse the stored value formatted string into an object
  String show (Object o) ; // How to show it in the cell from the stored string
  String save (Object o) ; // How to generate the string for cell storage - Override for specials
  
  String showValue(String s) { return show(value(s)); } // Takes the stored value string and formats it for display
  String display(Element cell, String storedValueAttrName) {
    String storedValueText;
    Object storedValue;
    if (storeDataValue) {
      storedValueText = cell.getAttribute(storedValueAttrName);
      if (storedValueText == null) {
        storedValue = this.parse(cell.text);
      } else {
        storedValue = value(storedValueText);
      }
    }
    return show(storedValue);
  }
  
  InputElement getCellEditor(Element cell, SuperTable superTable) {
    return getDataTypeCellEditor(cell,superTable, type: 'text');
  }
  
  InputElement getDataTypeCellEditor(Element cell, SuperTable superTable, {String type: 'text', List<String> inputAttributes: null } ) {
    InputElement ie;
    // An input element will be returned.  It will look for attributes from the cell, or column
    // for things like maxchars.  They will have the same attr names as the input field, except be prefixed
    // with DATATYPEINPUTPREFIX.  Recommended to put them in the column instead of on every cell.
    // cell values will override column values.
    String initDataPos, value = null;
    Element col = null;
    
    ie = new InputElement(type: type);
    
    initDataPos = cell.getAttribute(superTable.InitialDataPosAttrName);
    if (initDataPos != null) {
      col = superTable.getColumn(initDataPos);
    }
    
    if (inputAttributes != null) setInputElementAttrs(ie,cell,col,inputAttributes);
    
    if (storeDataValue) {
      value = cell.getAttribute(superTable.CellValueAttrName);
      // Note: the storedCell value is the same as InputElement uses for all normal datatypes
      // If you need something different, either define your own datatype, or 
      // your own CellUpdateHandler
      if (value != null) {
        ie.setAttribute('value',value);
      }
    } else {
      ie.setAttribute('value',cell.text);
    }
      
    return ie;
  }
    
  void setInputElementAttrs(InputElement ie, Element cell, Element col, List<String> attrs, {String prefix: DATATYPEINPUTPREFIX} ) {
    String attr, attrString = '';
    for (attr in attrs) {
      // First see if that attr is in the cell
      attrString = cell.getAttribute(prefix + attr);
      if (attrString == null) attrString = col.getAttribute(prefix + attr);
      if (attrString != null) ie.setAttribute(attr,attrString);
    }
  }
  
  String toString() { return "dataType " + dataTypeName; }
  void Debug(String s) { if (debug) print(dataTypeName + ' ' + s); }
}

class SuperTableDataTypeText extends SuperTableDataType {
  static List<String> inputAttributes = const ['maxlength'];
  SuperTableDataTypeText() {
    storeDataValue = false;
    dataTypeName = 'text';
    exportDataTypeName = 'text';
  }
  int compare (String o1, String o2) {
    return o1.compareTo(o2);
  }
  bool validate(String s){ return true; }

  String parse(String s) { return s; }
  Object value(String s) { return s; }
  String show (Object o) { return o.toString(); }
  String save (Object o) { return o.toString(); }
  InputElement getCellEditor(Element cell, SuperTable superTable) { return getDataTypeCellEditor(cell,superTable, type: 'text', inputAttributes: inputAttributes ); }
}

class SuperTableDataTypeMoney extends SuperTableDataType {
  static List<String> inputAttributes = const ['step','pattern','min','max'];
  NumberFormat displayFormat, parseFormat;
  SuperTableDataTypeMoney({String moneyDisplayString: "#,##0.00", String moneyParseString: "."} ) {
    dataTypeName = 'money';
    exportDataTypeName = 'money';
    displayFormat = new NumberFormat(moneyDisplayString);
    parseFormat = new NumberFormat(moneyParseString);
  }
  int compare (double o1, double o2) {
    return o1.compareTo(o2);
  }
  bool validate(String s) {
    bool ret = true;
    // hmmm, must be parseable
    double.parse(s, (_) { ret = false; return 0.0; });
    return ret;
  }
  
  double parse(String s) { Debug('parse'); return parseFormat.parse(s); }
  double value(String s) { Debug('value'); return double.parse(s, (_) => 0.0); }
  String show (double d) { Debug('show' ); return displayFormat.format(d); }
  String save (double d) { Debug('save' ); return d.toString(); }
  InputElement getCellEditor(Element cell, SuperTable superTable) { 
    InputElement ie = super.getDataTypeCellEditor(cell,superTable, type: 'number', inputAttributes: inputAttributes ); 
    ie.style.textAlign = 'right';
    return ie;
  }
}

class SuperTableDataTypeInteger extends SuperTableDataType {
  static List<String> inputAttributes = const ['step','pattern','min','max'];
  NumberFormat displayFormat;
  SuperTableDataTypeInteger({String integerDisplayString: "#,##0" } ) {
    dataTypeName = 'integer';
    exportDataTypeName = 'integer';
    displayFormat = new NumberFormat(integerDisplayString);
  }
  int compare (int o1, int o2) {
    return o1.compareTo(o2);
  }
  bool validate(String s) {
    bool ret = true;
    // hmmm, must be parseable
    int.parse(s, onError: (_) { ret = false; return 0; });
    return ret;
  }
  int    parse(String s) { Debug('parse'); return int.parse(s, onError: (_) => 0); }
  int    value(String s) { Debug('value'); return int.parse(s, onError: (_) => 0); }
  String show (int    i) { Debug('show' ); return displayFormat.format(i); }
  String save (int    i) { Debug('save' ); return i.toString(); }
  InputElement getCellEditor(Element cell, SuperTable superTable) { 
    InputElement ie =  getDataTypeCellEditor(cell,superTable, type: 'number', inputAttributes: inputAttributes ); 
    ie.style.textAlign = 'right';
    return ie;
  }
}

class SuperTableDataTypeDateTime extends SuperTableDataType {
  static List<String> inputAttributes = const ['maxlength'];
  DateFormat storedFormat; // Used to store the value (make it string sortable for easier sorting)
  DateFormat parseFormat; // Used to parse the initial value
  DateFormat displayFormat; // Used to display 
  SuperTableDataTypeDateTime({String dateStoredString: "yyyy-MM-dd'T'HH:mm:ss", 
                              String dateParseString: "yyyy-MM-dd'T'HH:mm:ss",
                              String dateDisplayString: null} ) { //"yyyy-MM-dd HH:mm:ss"
    dataTypeName = 'datetime';
    exportDataTypeName = 'datetime';
    storedFormat  = new DateFormat(dateStoredString);
    parseFormat   = new DateFormat(dateParseString);
    if (dateDisplayString == null) displayFormat = new DateFormat.yMd().add_Hm();
    else displayFormat = new DateFormat(dateDisplayString);
  }
  int compare (DateTime o1, DateTime o2) {
    return o1.compareTo(o2);
  }
  bool validate(String s) {
    bool ret = true;
    try {
      DateTime.parse(s);
    } on FormatException {
      ret = false;
    }
    return ret;
  }
  DateTime _parse (String s) {
    DateTime dt;
    try {
      dt = DateTime.parse(s);
    } on FormatException {
      dt = new DateTime.now();
    }
    return dt;
  }
  
  DateTime parse(String    s) { return parseFormat.parse(s); }
  DateTime value(String    s) { return storedFormat.parse(s); }
  String   show (DateTime dt) { return displayFormat.format(dt); }
  String   save (DateTime dt) { return storedFormat.format(dt); }
  
  InputElement getCellEditor(Element cell, SuperTable superTable) { return getDataTypeCellEditor(cell,superTable, type: 'datetime-local', inputAttributes: inputAttributes ); }
}

class SuperTableDataTypeDate extends SuperTableDataType {
  static List<String> inputAttributes = const ['maxlength'];
  DateFormat storedFormat; // Used to store the value (make it string sortable for easier sorting)
  DateFormat parseFormat; // Used to parse the initial value
  DateFormat displayFormat;
  // If you're sending a different format into the the table text, change dateParseString accordingly
  SuperTableDataTypeDate({String dateStoredString: "yyyy-MM-dd", 
                          String dateParseString: "yyyy-MM-dd",
                          String dateDisplayString: null} ) { // "yyyy-MM-dd" 
    dataTypeName = 'date';
    exportDataTypeName = 'date';
    storedFormat  = new DateFormat(dateStoredString);
    parseFormat   = new DateFormat(dateParseString);
    if (dateDisplayString == null) displayFormat = new DateFormat.yMd();
    else displayFormat = new DateFormat(dateDisplayString);
  }
  int compare (DateTime o1, DateTime o2) {
    return o1.compareTo(o2);
  }
  DateTime _parse (String s) {
    int y,m,d;
    DateTime dt;
    try {
      dt = DateTime.parse(s);
    } on FormatException {
      dt = new DateTime.now();
    }
    return dt;
  }
  bool validate(String s) {
    bool ret = true;
    try {
      DateTime.parse(s);
    } on FormatException {
      ret = false;
    }
    return ret;
  }
  DateTime parse(String    s) { Debug('parse'); return parseFormat.parse(s); }
  DateTime value(String    s) { Debug('value'); return storedFormat.parse(s); }
  String   show (DateTime dt) { Debug('show' ); return displayFormat.format(dt); }
  String   save (DateTime dt) { Debug('save' ); return storedFormat.format(dt); }
  
  InputElement getCellEditor(Element cell, SuperTable superTable) { return getDataTypeCellEditor(cell,superTable, type: 'date', inputAttributes: inputAttributes ); }
}


/*****************************************************************/
/*****************************************************************/
// End Data Types
/*****************************************************************/
/*****************************************************************/
// Begin row selection policies
/*****************************************************************/
/*****************************************************************/

// The user can subclass this and override to set up a different policy
abstract class SuperTableRowSelectPolicy {
  SuperTable superTable;
  bool shift = false, control = false, alt = false, meta = false;
  bool debug = false;
  SuperTableRowSelectPolicy(this.superTable){}
    
  void rowSelect(MouseEvent e) {
    Element td, tr;
    td = e.target;
    tr = td.parent;
    String rowId;
    rowId = tr.getAttribute(superTable.RowIdAttrName);
    // OK, now get the main table row and pass it in
    rowSelectAction(e, rowId);
  }
  
  void rowSelectAction(MouseEvent e, String rowId) ;
  
  void setSelectedAll (bool selected) {
    List<Element> rows;
    Element row;
    rows = superTable.table.querySelectorAll('tr');
    
    if (selected) {
      for (row in rows) if ( ! row.classes.contains(superTable.SelectedRowClass)) row.classes.add(superTable.SelectedRowClass);
      if (superTable.isSplit) {
        rows = superTable.splitBodyTable.querySelectorAll('tr');
        for (row in rows) if (! row.classes.contains(superTable.SelectedRowClass)) row.classes.add(superTable.SelectedRowClass);
      } 
    } else {
      for (row in rows) if (row.classes.contains(superTable.SelectedRowClass)) row.classes.remove(superTable.SelectedRowClass);
      if (superTable.isSplit) {
        rows = superTable.splitBodyTable.querySelectorAll('tr');
        for (row in rows) if (row.classes.contains(superTable.SelectedRowClass)) row.classes.remove(superTable.SelectedRowClass);  
      }
    }
    superTable.computedFieldsRefresh();
    superTable.computedFieldsSelectionChanged();
  }
    
  // Want to add a flip split row function in the base class for all of them to call
  void flipSplitRow(String rowIdAttr) {
    if (superTable.isSplit) {
      Element splitRow;
      splitRow = superTable.splitBodyTable.querySelector('[' + superTable.RowIdAttrName + '="' + rowIdAttr + '"]');
      if (splitRow.classes.contains(superTable.SelectedRowClass)) {
        splitRow.classes.remove(superTable.SelectedRowClass);
      }
      else {
        splitRow.classes.add(superTable.SelectedRowClass);
      }
    }
  }
  
  void Debug(String s) {
    if (debug) print(s);
  }
}

class SuperTableRowSelectPolicyNormal extends SuperTableRowSelectPolicy {
  SuperTableRowSelectPolicyNormal(SuperTable st) : super(st) { }
  Element lastRow;
  void rowSelectAction (MouseEvent e, String rowId) {
     // Need to figure out which row this is
     // Maybe the best is a binary search until we can get all 
     // elements we clicked on.
    Debug('rowSelect rowId=' + rowId);
    Element tr;
    tr = superTable.table.querySelector('[' + superTable.RowIdAttrName +'="' + rowId + '"]');
    if (e.shiftKey && e.ctrlKey) {
      // Do nothing because this indicates a click that shouldn't change the selected rows
    } else if (e.ctrlKey) {
      // Just flip the current row
    
      if (tr.classes.contains(superTable.SelectedRowClass)) {
        tr.classes.remove(superTable.SelectedRowClass);
        superTable.computedFieldsFlipSelectedRow(tr, false);
      } else {
        tr.classes.add(superTable.SelectedRowClass);
        superTable.computedFieldsFlipSelectedRow(tr, true);
      }
      flipSplitRow(tr.getAttribute(superTable.RowIdAttrName));
      lastRow = tr;
    } else if (e.shiftKey) {
      if (lastRow == null) {
        if (tr.classes.contains(superTable.SelectedRowClass)) {
          tr.classes.remove(superTable.SelectedRowClass);
        } else {
          tr.classes.add(superTable.SelectedRowClass);
        }        
      } else {
        // need to select a range
        List<Element> rows;
        Element row;
        String lastRowId, currentRowId, thisRowId;
        bool flipNext = false;
        lastRowId = lastRow.getAttribute(superTable.RowIdAttrName);
        currentRowId = tr.getAttribute(superTable.RowIdAttrName);
        if (lastRowId == currentRowId) return; // Quick exit if no change needed
        rows = superTable.table.querySelectorAll('tr');
        for (row in rows) {
          thisRowId = row.getAttribute(superTable.RowIdAttrName);
          if (thisRowId == lastRowId) {
            if ( ! row.classes.contains(superTable.SelectedRowClass)) {
              row.classes.add(superTable.SelectedRowClass);
              superTable.computedFieldsFlipSelectedRow(row, true);
            }
            if (flipNext) break;
            flipNext = true;
          } else if (thisRowId == currentRowId) {
            if ( ! row.classes.contains(superTable.SelectedRowClass)) {
              row.classes.add(superTable.SelectedRowClass);
              superTable.computedFieldsFlipSelectedRow(row, true);
            }
            if (flipNext) break;
            flipNext = true;
          } else {
            if (flipNext) if ( ! row.classes.contains(superTable.SelectedRowClass)) {
              row.classes.add(superTable.SelectedRowClass);
              superTable.computedFieldsFlipSelectedRow(row, true);
            }
          }          
        }
        if (superTable.isSplit) {
          flipNext = false;
          rows = superTable.splitBodyTable.querySelectorAll('tr');
          for (row in rows) {
            thisRowId = row.getAttribute(superTable.RowIdAttrName);
            if (thisRowId == lastRowId) {
              if ( ! row.classes.contains(superTable.SelectedRowClass)) row.classes.add(superTable.SelectedRowClass);
              if (flipNext) break;
              flipNext = true;
            } else if (thisRowId == currentRowId) {
              if ( ! row.classes.contains(superTable.SelectedRowClass)) row.classes.add(superTable.SelectedRowClass);
              if (flipNext) break;
              flipNext = true;
            } else {
              if (flipNext) if ( ! row.classes.contains(superTable.SelectedRowClass)) row.classes.add(superTable.SelectedRowClass);
            }          
          }          
        }
      }
      
      lastRow = tr;
    } else {
      // Unselect everything except this row
      setSelectedAll(false);
      tr.classes.add(superTable.SelectedRowClass);
      superTable.computedFieldsFlipSelectedRow(tr, true);
      // but, need to do the split table too
      flipSplitRow(tr.getAttribute(superTable.RowIdAttrName));
      lastRow = tr;
    }
    superTable.computedFieldsSelectionChanged();
    //e.preventDefault();
    //e.stopPropagation();  
    //e.stopImmediatePropagation();
  }
}

class SuperTableRowSelectPolicyPlainClick extends SuperTableRowSelectPolicy {
  SuperTableRowSelectPolicyPlainClick(SuperTable st) : super(st) { }
  
  void rowSelectAction (MouseEvent e, String rowId) {
    Debug('rowSelect rowId=' + rowId);
    Element tr;
    tr = superTable.table.querySelector('[' + superTable.RowIdAttrName +'="' + rowId + '"]');;
    if (tr.classes.contains(superTable.SelectedRowClass)) {
      tr.classes.remove(superTable.SelectedRowClass);
    } else {
      tr.classes.add(superTable.SelectedRowClass);
    }    
  }
}
/*****************************************************************/
/*****************************************************************/
// End row selection policies
/*****************************************************************/
/*****************************************************************/
// Begin save as functions
/*****************************************************************/
/*****************************************************************/
abstract class SuperTableSaveAs {
  static const int SELECTED = 1, ALL = 0, UNSELECTED = -1;
  String style;
//  SuperTable table;
  bool debug;
  int rowsToSave = ALL;
  // Someday, columnsToSave = ALL;
  //FileSystem _filesystem;
  
  SuperTableSaveAs({this.debug}) { }
  
  AnchorElement saveAs(SuperTable table);
  
  // Because the text was moved into a div below for column mover
  String getHeaderCellText(SuperTable table, Element th) {    
    return table.getHeaderCellText(th);
  }
  
  void Debug(String s) {
    if (debug) print('SuperTableSaveAs ' + s);
  }
}



class SuperTableSaveAsCSV extends SuperTableSaveAs {
  String delim = ',', quote = '"', escape = '\\';
  String fileContents;
  SuperTableSaveAsCSV({bool debug}) : super(debug: debug) {
    style = 'CSV';
  }
  AnchorElement saveAs(SuperTable table) {
    // OK, need to ask a few questions
    // 1. Do we want to save all the rows, or just the selected ones?
    // 2. What do you want to use as a separator, quote and escape?
    // 3. What the filename should be? 
    
    // Need to figure out how much space we really need
    // We know we need all the header row + data + the commas + cr (do we need lf too?)
    // Can we determine the record separator of the host system?  For now, crlf
    // Maybe the easiest thing to do is build the whole thing in memory, and check the size,
    // This may fail on memory starved systems, so maybe later we'll find another way to 
    // optionally just get the space than we need.
    
    fileContents = buildFileInMemory(table);
    List blobContents = new List();
    blobContents.add(fileContents);
    // For now, just save everything in table.id.csv
    String fileName;
    fileName = table.id + '.csv';
    
    Blob blob = new Blob(blobContents, 'text/plain', 'native');
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
    List<Element> trs;
    
    sb.write(buildHeaderRow(table));
    
    // Rows will be in their current order
    trs = table.table.querySelectorAll('tr');
    for (tr in trs) {
      sb.write(buildRow(tr,table));
    }
    
    return sb.toString();
  }
  
  String buildHeaderRow(SuperTable table) {
    StringBuffer sb = new StringBuffer();
    // Remember, the header row has some extra divs in it for 
    // getHeaderCellText
    Element th, row;
    List<Element> ths;
    
    row = table.headerTable.querySelector('tr'); 
    // Note: columns will be in their current order, not their original order
    ths = row.querySelectorAll('th');
    for (th in ths) {
      // What if the cell contins more than just text, like an <a> ??
      // We'll look at that later.
      if (sb.length > 0) sb.write(delim); // No leading delimiter
      sb.write(cleanse(getHeaderCellText(table, th)));
    }
    sb.writeln(delim); // We'll add an ending delim.
    
    return sb.toString();
  }
  
  String buildRow(Element row, SuperTable table) {
    StringBuffer sb = new StringBuffer();
    Element td;
    List<Element> tds;
    String value;
    
    // Note: columns will be in their current order, not their original order
    tds = row.querySelectorAll('td');
    for (td in tds) {
      // What if the cell contins more than just text, like an <a> ??
      // We'll look at that later.
      if (sb.length > 0) sb.write(delim); // No leading delimiter
      value = td.getAttribute(table.CellValueAttrName); 
      if (value == null) value = td.text; 
      sb.write(cleanse(value));
    }
    sb.writeln(delim); // We'll add an ending delim.
    return sb.toString();
  }
  
  String cleanse(String s) {
    StringBuffer sb = new StringBuffer();
    int i;
    
    // Are there any imbedded delim in s
    if (s.contains(delim)) {
      // Need to see if it contains quote too
      if (s.contains(quote)) {
        // The most difficult case because we can't just quote the string
        // So, we need to escape all the guts and surround with unescaped quotes
        sb.write(quote); // The unescaped start quote
        for (i = 1; i < s.length ; i++) {
          if (s[i] == quote || s[i] == escape) {
            sb.write(escape); // An escape for chrs that need it
          }
          sb.write(s[i]); // The char
        }
        sb.write(quote);  // The unescaped end quote
      } else {
        sb.write(quote + s + quote); 
      }
    } else {
      // No imbedded delims, so just put it back out
      sb.write(s);      
    }
      
    return sb.toString();
  }
}

/*****************************************************************/
/*****************************************************************/
// End save as functions
/*****************************************************************/
/*****************************************************************/
// Begin computed field
/*****************************************************************/
/*****************************************************************/
abstract class SuperTableComputedField {
  static const int MODEALL = 0;
  static const int MODESELECTED = 1;
  static const int MODEUNSELECTED = 2;
  SuperTable table;
  int mode = MODEALL;
  // Usualls used to put sums in the running footer
  SuperTableComputedField(this.table, [this.mode]) {}
    
  // selectedRow will be called for each row that flips selection 
  // the implication is that it changed
  // Do not call this if it did not change selection
  void selectedRowFlippedTo(Element row, bool selected);
  
  // selectionChanged will be called after a row, or a number of rows, are changed selection.
  // This will, at least, update the displayed value.
  // Sometimes only seeing the recent flips is not enough, so more work than just updating the
  // display may be needed.  Add that code here.
  void selectionChanged();
  
  // If the table data are refreshed, then call this to refresh any values
  void refresh();
}

abstract class SuperTableComputedFieldColumn extends SuperTableComputedField {
  String targetColumnClass; // Use a class so we can get both the main and split footer
  SuperTableComputedFieldColumn(SuperTable table, String this.targetColumnClass, [int mode] ) : super(table, mode) {}
}

class SuperTableComputedFieldCount extends SuperTableComputedFieldColumn {
  int count = 0;
  SuperTableComputedFieldCount(SuperTable table, String targetColumnClass, [int mode] ) : super(table,targetColumnClass,  mode) {}
  void selectedRowFlippedTo(Element row, bool selected) {
    count += (selected) ? 1 : -1 ;
  }
  
  void selectionChanged() {
    // Need to find the footer record with the targetColumnClass and update it
    Element td;
    td = table.footerTable.querySelector('.' + targetColumnClass);
    td.text = count.toString();
    if (table.isSplit) {
      td = table.splitFooterTable.querySelector('.' + targetColumnClass);
      td.text = count.toString();
    }
  }
  
  void refresh() {
    Element tr;
    List<Element> trs;
    count = 0;
    if (mode == SuperTableComputedField.MODEALL) count = trs.length; 
    else {
      trs = table.table.querySelectorAll('tr');
      for (tr in trs) {
        if (tr.classes.contains(table.SelectedRowClass)) {
          if (mode == SuperTableComputedField.MODESELECTED) count++;
        } else {
          if (mode == SuperTableComputedField.MODEUNSELECTED) count++;
        }         
      }
    }
    selectionChanged();
  }
}

class SuperTableComputedFieldColumnIntSum extends SuperTableComputedFieldColumn {
  SuperTableDataTypeInteger dataType;
  int sum = 0;
  
  SuperTableComputedFieldColumnIntSum(SuperTable table, String targetColumnClass, [int mode] ) : super(table, targetColumnClass, mode) {
    dataType = table.getSuperTableDataType('integer');
    dataType.debug = true;
  }
  
  void selectedRowFlippedTo(Element row, bool selected) {
    sum += ((selected) ? 1 : -1) * getColumnValue(row);
  }
  
  void selectionChanged() {
    // Need to find the footer record with the targetColumnClass and update it
    Element td;
    td = table.footerTable.querySelector('.' + targetColumnClass);
    td.text = dataType.show(sum);
    if (table.isSplit) {
      td = table.splitFooterTable.querySelector('.' + targetColumnClass);
      td.text = dataType.show(sum);
    }    
  }
  
  void refresh() {
    Element tr;
    List<Element> trs;
    
    sum = 0;    
    trs = table.table.querySelectorAll('tr');
    for (tr in trs) {
      if (mode == SuperTableComputedField.MODEALL) sum += getColumnValue(tr);
      else {
        if (tr.classes.contains(table.SelectedRowClass)) {
          if (mode == SuperTableComputedField.MODESELECTED) sum += getColumnValue(tr);
        } else {
          if (mode == SuperTableComputedField.MODEUNSELECTED) sum += getColumnValue(tr);
        }   
      }
    }
    
    selectionChanged();    
  }
  
  int getColumnValue(Element row) {
    int val;
    Element cell;
    
    cell = row.querySelector('.' + targetColumnClass);
    String value;
    value = cell.getAttribute(table.CellValueAttrName);
    if (value == null) {
      val = int.parse(value, onError: (_) => 0);
    } else {
      val = dataType.value(value);
    }
    
    return val;
  }
}

class SuperTableComputedFieldColumnMoneySum extends SuperTableComputedFieldColumn {
  SuperTableDataTypeMoney dataType;
  double sum = 0.0;
  
  SuperTableComputedFieldColumnMoneySum(SuperTable table, String targetColumnClass, [int mode] ) : super(table, targetColumnClass, mode) {
    dataType = table.getSuperTableDataType('money');
    dataType.debug = true;
  }
  
  void selectedRowFlippedTo(Element row, bool selected) {
    sum += ((selected) ? 1 : -1) * getColumnValue(row);
  }
  
  void selectionChanged() {
    // Need to find the footer record with the targetColumnClass and update it
    Element td;
    td = table.footerTable.querySelector('.' + targetColumnClass);
    td.text = dataType.show(sum);
    if (table.isSplit) {
      td = table.splitFooterTable.querySelector('.' + targetColumnClass);
      td.text = dataType.show(sum);
    }    
  }
  
  void refresh() {
    Element tr;
    List<Element> trs;
    
    sum = 0.0;    
    trs = table.table.querySelectorAll('tr');
    for (tr in trs) {
      if (mode == SuperTableComputedField.MODEALL) sum += getColumnValue(tr);
      else {
        if (tr.classes.contains(table.SelectedRowClass)) {
          if (mode == SuperTableComputedField.MODESELECTED) sum += getColumnValue(tr);
        } else {
          if (mode == SuperTableComputedField.MODEUNSELECTED) sum += getColumnValue(tr);
        }   
      }
    }
    
    selectionChanged();    
  }
  
  double getColumnValue(Element row) {
    double val;
    Element cell;
    
    cell = row.querySelector('.' + targetColumnClass);
    String value;
    value = cell.getAttribute(table.CellValueAttrName);
    if (value == null) {
      val = int.parse(value, onError: (_) => 0);
    } else {
      val = dataType.value(value);
    }
    
    return val;
  }
}



/*****************************************************************/
/*****************************************************************/
// End computed field
/*****************************************************************/
/*****************************************************************/
// Begin cellUpdateActions
/*****************************************************************/
/*****************************************************************/

// Subclass this to have updates to cells do something.  This might be useful if
// you need a cell update to call the server, or something like that.
abstract class SuperTableCellUpdateHandler {
  Object preValue; // to compare to be sure we have a change
  String name;
  SuperTableDataType dataType;
  SuperTable superTable;
  Element cell;
  
  SuperTableCellUpdateHandler(String this.name);
  
  // Override if you need to do something immediatly before an update attempt
  bool preUpdate(Element cell, SuperTable superTable) {
    this.cell = cell;
    this.superTable = superTable;
    print("SuperTableCellUpdateHandler Enter preUpdate");   
    this.dataType = superTable.getSuperTableDataTypeFromCell(cell);
    print("SuperTableCellUpdateHandler dataType=" + this.dataType.toString());  
    
    return true; // May return false if cannot set things up
  }
  
  InputElement getInputElement(); 
  bool valueChanged();
  void update();
  bool validate();
  bool validateCell(String value) { 
    // Check that the data is valid for the datatype
    return dataType.validate(value);
  } // Override for complicated validations and call this super to check before updating contents
  
  // Must define this action.  Will be called only if data changes
  void updateCell(String newValueString) {
    Object origCellValue, cellValue;
    String origCellValueString;
    
    if (dataType.storeDataValue) cell.setAttribute(superTable.CellValueAttrName,newValueString);
    cell.text = dataType.show(dataType.value(newValueString));
    
    origCellValueString = cell.getAttribute(superTable.OrigCellValueAttrName);
    if (origCellValueString == null) {
      cell.classes.add(superTable.CellEditedClass);
      cell.setAttribute(superTable.OrigCellValueAttrName,dataType.save(preValue));
    } else {
      origCellValue = dataType.value(origCellValueString);
      cellValue = dataType.value(newValueString);
      if (dataType.compare(origCellValue,cellValue) == 0) {
        cell.classes.remove(superTable.CellEditedClass);
        cell.attributes.remove(superTable.OrigCellValueAttrName);
      } else {
        //cell.attributes.remove(superTable.CellEditedClass);
      }
    }
    
    superTable.closeCellEditing(true);
    cell = null; // Cleanup to guarantee virginity
    superTable = null;
    dataType = null;
  } 
  
  bool reset() {
    String origCellValueString;
    bool ret = false;
    origCellValueString = cell.getAttribute(superTable.OrigCellValueAttrName);
    if (origCellValueString != null) {
      cell.setAttribute(superTable.CellValueAttrName,origCellValueString);
      cell.attributes.remove(superTable.OrigCellValueAttrName);
      cell.text = dataType.show(dataType.value(origCellValueString));
      cell.classes.remove(superTable.CellEditedClass);
    }
    cell = null; // Cleanup to guarantee virginity
    superTable = null;
    dataType = null;    
  }  
}

// Note that a preValue of the cell contents is saved here.  If you have two, or more, tables on your page,
// in order to prevent conflict on this variable, be sure to instantiate one of these for each table.
// Also, note that this is also called from the cloned split table editing.  Clone seems to copy ids too, 
// so an id on a table element may not be unique in your document.

class SuperTableDataTypeCellUpdateHandler extends SuperTableCellUpdateHandler {
  InputElement ie;
  // This one will use the datatype, and any attributes on cessl of columns 
  // to build an input element for the appropriate data type.  Of course,
  // this may not be tailored enough for some situations, but is shoud be 
  // enough for most of the time
  SuperTableDataTypeCellUpdateHandler(String name) : super(name);

  InputElement getInputElement() {
    ie = dataType.getCellEditor(cell, superTable);
    if (cell.classes.contains(superTable.CellEditableClass)) {
      ie.contentEditable = "true";
      ie.readOnly = false;
    } else if (cell.classes.contains(superTable.CellNotEditableClass)) {
      ie.contentEditable = "false";
      ie.readOnly = true;
    } else if (superTable.defaultCellEditable) {
      ie.contentEditable = "true";
      ie.readOnly = false;
    } else {
      ie.contentEditable = "false";
      //cellEditor.setAttribute('readonly','true');
      ie.readOnly = true;
    }
    return ie;
  }
  
  bool valueChanged() {
    Object newValue;
    bool changed = false;
    if (dataType.validate(ie.value)) {
      newValue = dataType.value(ie.value);     
      changed = (dataType.compare(newValue,preValue) != 0);
    }
    return changed;
  }
  
  bool validate() { return validateCell(ie.value); }

  bool preUpdate(Element cell, SuperTable superTable) {
    bool ret = true;
    ret = super.preUpdate(cell,superTable);
    
    if (ret) {
      String preValueString;
      preValueString = cell.getAttribute(superTable.CellValueAttrName);
      if (preValueString == null){
        preValue = cell.text;
      } else {
        preValue = dataType.value(preValueString);
      }
    }
    
    return ret;
  }

  //InputElement getInputElement() { ie = super.getInputElement(); return ie; }
  
  update() {
//    String newValueString;
//    newValueString = dataType.store(dataType.value(ie.value));
    print("Data in cell changed from '" + preValue.toString() + "' ");
    print("Data in cell changed from '" + preValue.toString() + "' to '" + ie.value + "'");
    // It seems ie.value may not always be valid.  Need to check it out first
    if (dataType.validate(ie.value)) {
      updateCell(ie.value);
      ie = null;
    } else {
      print("SuperTableDataTypeCellUpdateHandler " + name.toString() + ' ie.value=' + ie.value + ' not valid.');
    }
  }
}

/*****************************************************************/
/*****************************************************************/
// End cellUpdateActions
/*****************************************************************/
/*****************************************************************/

/*
 * The whole thing works by the caller allocates a space on the screen with a div.  Then the SuperTable
 * puthe the whole thing into the space.  The wrapper div MUST be non-statically placed.
 */
/* The key is to watch the scrollers and mimic that same scroll in the other pieces.  So, one decision
 * to make is whether to put the horizontal scrollers above, or below the footer.  If there is no 
 * footer, then it must be below the bodies.  But, if you put them below the footer, then you must 
 * really build two completely different SuperTables.  For now, we will just build the second.
 * Note: If there are neither header nor footer, then this whole excercise is not needed.
 */

/*  Scrollers below the footer not implementd!!!!
 *  +---------------------------------------------------------------------------------------------+
 *  |                                                                                             |
 *  |  +------------------+  +-----------------------------------------------------------------+  |
 *  |  |                  |  |  +---+ +------------------------------------------------------+ |  |
 *  |  |  +------------+  |  |  |   | |  +-----------------------------------------------+   | |  |
 *  |  |  | split head |  |  |  |   | |  |               main head                       |   | |  |
 *  |  |  +------------+  |  |  | s | |  +-----------------------------------------------+   | |  |
 *  |  |                  |  |  | p | |                                                      | |  |
 *  |  |  +------------+  |  |  | l | |  +-----------------------------------------------+ ^ | |  |
 *  |  |  |            |  |  |  | i | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | t | |  |                                               | ! | |  |
 *  |  |  | split      |  |  |  |   | |  |              main body                        | ! | |  |
 *  |  |  | body       |  |  |  |   | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  |   | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | g | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | r | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | a | |  |                                               | ! | |  |
 *  |  |  +------------+  |  |  | b | |  +-----------------------------------------------+ v | |  |
 *  |  |                  |  |  | b | |                                                      | |  |
 *  |  |  +------------+  |  |  | e | |  +-----------------------------------------------+   | |  |
 *  |  |  | split foot |  |  |  | r | |  |             main footer                       |   | |  |
 *  |  |  +------------+  |  |  |   | |  +-----------------------------------------------+   | |  |
 *  |  |  <============>  |  |  |   | |  <===============================================>   | |  |
 *  |  |                  |  |  +---+ +------------------------------------------------------+ |  |
 *  |  +------------------+  +-----------------------------------------------------------------+  |
 *  |                                                                                             |
 *  +---------------------------------------------------------------------------------------------+
 */

/*  Scrollers above the footer (either of which may be absent)
 *  0---------------------------------------------------------------------------------------------+
 *  |                                                                                             |
 *  |                        3-----------------------------------------------------------------+  |
 *  |  1------------------+  |  G---+ 2------------------------------------------------------+ |  |
 *  |  |  h------------+  |  |  |   | |  H-----------------------------------------------+   | |  |
 *  |  |  | split head |  |  |  |   | |  |               main head                       |   | |  |
 *  |  |  +------------+  |  |  | s | |  +-----------------------------------------------+   | |  |
 *  |  |                  |  |  | p | |                                                      | |  |
 *  |  |  b------------+  |  |  | l | |  B-----------------------------------------------+ ^ | |  |
 *  |  |  |            |  |  |  | i | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | t | |  |                                               | ! | |  |
 *  |  |  | split      |  |  |  |   | |  |              main body                        | ! | |  |
 *  |  |  | body       |  |  |  |   | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  |   | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | g | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | r | |  |                                               | ! | |  |
 *  |  |  |            |  |  |  | a | |  |                                               | ! | |  |
 *  |  |  +------------+  |  |  | b | |  +-----------------------------------------------+ v | |  |
 *  |  |  <============>  |  |  | b | |  <===============================================>   | |  |
 *  |  |  f------------+  |  |  | e | |  F-----------------------------------------------+   | |  |
 *  |  |  | split foot |  |  |  | r | |  |             main footer                       |   | |  |
 *  |  |  +------------+  |  |  |   | |  +-----------------------------------------------+   | |  |
 *  |  |                  |  |  |   | |                                                      | |  |
 *  |  +------------------+  |  +---+ +------------------------------------------------------+ |  |
 *  |                        +-----------------------------------------------------------------+  |
 *  |                                                                                             |
 *  +---------------------------------------------------------------------------------------------+
 */

class SuperTable implements Resizable {
  // The default class names.  Set instance values if you need different names
  static const String ATTRNAMEPREFIX           = 'data-'; // So the attributes become application specific
  static const String CONTAINERCLASSNAME       = 'tablescroll_wrapper';
  static const String MAINHOLDERCLASSNAME      = 'mainHolder';
  static const String BODYTABLECLASS           = 'superTableBody';
  static const String HEADERTABLECLASS         = 'superTableHeader';
  static const String FOOTERTABLECLASS         = 'superTableFooter';
  
  static const String INITIALWIDTHATTRNAME     = 'initwidth';
  static const String INITIALDATAPOSATTRNAME   = 'initdatapos';
  static const String ROWIDATTRNAME            = 'RowId';
  static const String DATATYPEATTRNAME         = 'datatype';
  static const String SUPERTABLEPREFIX         = 'super';
  static const String COLUMNCLASSATTRNAME      = 'ColumnClass';
  static const String COLUMNRESIZEGRABBERCLASS = 'columnResizeGrabber';
  static const String COLUMNMOVERHOLDERCLASS   = 'columnMoverHolder';
  static const String SPLITGRABBERCLASS        = 'SplitTableGrabber';
  static const String SELECTEDROWCLASS         = 'selected';
  static const String SHOWSTUFFCLASS           = 'ShowStuff';
  static const String CELLEDITABLECLASS        = 'Editable';
  static const String CELLNOTEDITABLECLASS     = 'NotEditable';
  static const String CELLEDITEDCLASS          = "cellEdited";
  static const String CELLEDITINGCLASS         = 'Editing';
  static const String CELLUPDATEHANDLERATTRNAME= 'cellEditHandler';
  static const String CELLVALUEATTRNAME        = 'cellvalue';
  static const String ORIGCELLVALUEATTRNAME    = 'origcellvalue';
  static const int    MINCOLUMNWIDTH           = 5;
  static const int    MINMAINWIDTH             = 100;
  static const int    SPLITGRABBERWIDTH        = 5;
  static const int    GRABBERZINDEXOFFSET      = 10;
  static const String NECESSARYTABLESTYLE      = 'table-layout:fixed;';

  // Override these if you need to use different class names in your code
  String ContainerClassName        = CONTAINERCLASSNAME;
  String MainHolderClassName       = MAINHOLDERCLASSNAME;
  String BodyTableClass            = BODYTABLECLASS;
  String HeaderTableClass          = HEADERTABLECLASS;
  String FooterTableClass          = FOOTERTABLECLASS;
  String InitialWidthAttrName      = ATTRNAMEPREFIX + INITIALWIDTHATTRNAME;
  String InitialDataPosAttrName    = ATTRNAMEPREFIX + INITIALDATAPOSATTRNAME;
  String RowIdAttrName             = ATTRNAMEPREFIX + ROWIDATTRNAME;
  String DataTypeAttrName          = ATTRNAMEPREFIX + DATATYPEATTRNAME;
  String SuperTablePrefix          = SUPERTABLEPREFIX;
  String ColumnClassAttrName       = ATTRNAMEPREFIX + COLUMNCLASSATTRNAME;
  String ColumnResizeGrabberClass  = COLUMNRESIZEGRABBERCLASS;
  String ColumnMoverHolderClass    = COLUMNMOVERHOLDERCLASS;
  String SplitGrabberClass         = SPLITGRABBERCLASS;
  String SelectedRowClass          = SELECTEDROWCLASS;
  String ShowStuffClass            = SHOWSTUFFCLASS;
  String CellEditableClass         = CELLEDITABLECLASS;
  String CellNotEditableClass      = CELLNOTEDITABLECLASS;
  String CellEditedClass           = CELLEDITEDCLASS;
  String CellEditingClass          = CELLEDITINGCLASS;
  String CellUpdateHandlerAttrName = ATTRNAMEPREFIX + CELLUPDATEHANDLERATTRNAME;
  String CellValueAttrName         = ATTRNAMEPREFIX + CELLVALUEATTRNAME;
  String OrigCellValueAttrName     = ATTRNAMEPREFIX + ORIGCELLVALUEATTRNAME;
  int    SplitGrabberWidth         = SPLITGRABBERWIDTH;
  int    GrabberZIndexOffset       = GRABBERZINDEXOFFSET;
  SuperTableRowSelectPolicy rowSelectPolicy;
  int MinColumnWidth = MINCOLUMNWIDTH; // If you change this, you may want to change the CSS too.
  int MinMainWidth = MINMAINWIDTH; // When you split the table, at least this much must be visible, but breaks if table smaller than 100
    
  int VScrollBarThick, HScrollBarThick; // need only be set once.  Someone else can make them static
  StreamSubscription<Event> scroller, splitScroller, splitter;
  StreamSubscription<Event> resizer; // attempt to make the resize get called by window resizing, but not yet!!
  List<SuperTableComputedField> computedFields;
  List<SuperTableCellUpdateHandler> cellUpdateHandlers;
  List<SuperTableSaveAs> saveAsCreators;
  SuperTableCellUpdateHandler defaultCellUpdateHandler = null;
  
  bool debug = false;
  String id;  // The id of the table
  bool hasFooter = false;
  bool isSplit = false;
  bool lastSortAscending = false;
  bool defaultCellEditable = false;
  int tableEditCount = 0;
  // So, this shows the DOM heirarchy for all of the pieces
  Element wrapper_0; // 0 may be provided by the caller.  Better if it is!!
  Element     splitTableWrapper_1;
  Element          splitHeaderWrapper_h;
  Element               splitHeaderTable;
  Element          splitBodyWrapper_b;
  Element               splitBodyTable;
  Element          splitFooterWrapper_f; 
  Element               splitFooterTable;
  Element     mainHolder_3;
  Element          splitGrabber_G;
  Element          tableWrapper_2;
  Element               headerWrapper_H;
  Element                     headerTable;
  Element               bodyWrapper_B;
  Element                     table;
  Element               footerWrapper_F; 
  Element                     footerTable = null;
    
  Element colGroup, splitColGroup;
  CssStyleSheet sheet;
  List<SuperTableDataType> superTableDataTypes;
    
  int headerWrapperHeight = 0, footerWrapperHeight = 0;
  int splitWidth = 0;
  
  int vscrollthick = -1;
  int hscrollthick = -1;
  
  // Begin Splitting Table holders
  // startx used here too
  int startw = 0;
  bool splitCloned = false;
  // End Splitting Table holders
  
  // Begin column Moving holders
  Element movingColumn;
  int docx;
  Point pos;
  Element draggingView;
  bool nodeAdded = false;
  // End column Moving holders
  
  // Begin column resizing holders
  Element resizingColumn;
  String resizingClass;
  int startx;
  Stream<MouseEvent> mouseUpHolder; // currently used but not correctly
  Stream<MouseEvent> mouseMoveHolder; // currently used but not correctly
  String cursorHolder;
  StreamSubscription<MouseEvent> mouseUp, mouseMove, splitMouseUp, splitMouseMove;
  // End column resizing holders
  
  // Begin showStuff
  DateTime cellEditClickTime;
  Element showBackground, cellEdited;
  Element cellEditor;
  SuperTableCellUpdateHandler cellUpdateHandler; // current one being done
  bool editingSplit = false;
  // End showStuff
  SuperTableDblClkHandler dblClkHandler;
  
  SuperTable.presizedContainer(String this.id, {ParentNode container, SuperTableDblClkHandler dblClkHandler}) {
    computedFields = new List<SuperTableComputedField>();
    cellUpdateHandlers = new List<SuperTableCellUpdateHandler>();
    saveAsCreators = new List<SuperTableSaveAs>();
    saveAsCreators.add(new SuperTableSaveAsCSV()); // We'll force in a CSV saver, but user can remove before calling init.
    defaultCellUpdateHandler = new SuperTableDataTypeCellUpdateHandler('dataType');
    cellEditClickTime = new DateTime.now();
    table = (container == null) ? document.querySelector('#' + id) : container.querySelector('#' + id);
    table.classes.add(id);
    setDblClkHandler(dblClkHandler);
  }
        
  void init() {
    firsttime();
    prepareMain();
  }
  
  void setDblClkHandler(SuperTableDblClkHandler dblClkHandler) {
    this.dblClkHandler = dblClkHandler;
    if (dblClkHandler != null) table.onDoubleClick.listen(dblClkHandler.handleDblClk);
  }
  
  void enableDblClkHandler(bool enable) {
    if (dblClkHandler != null) dblClkHandler.enabled = enable;
  }
  
  void forcedTableStyle(Element tbl) {
    tbl.style.tableLayout = 'fixed';
  }
  
  void buildAllMainElements() {
    // First let's create the three (or two) main wrappers for each of the pieces
    headerWrapper_H = new Element.div();
    bodyWrapper_B = new Element.div();
    if (hasFooter) footerWrapper_F = new Element.div();

    // Next the two (or one) new tables (the original table will hold the main body) 
    Element thead, tfoot;
    headerTable = new Element.table(); // If there's no header, what's the purpose of using SuperTable
    forcedTableStyle(headerTable);
    headerTable.classes.add(HeaderTableClass);
    // table will remain the bodyTable
    if (hasFooter) {
      footerTable = new Element.table();
      forcedTableStyle(footerTable);
      footerTable.classes.add(FooterTableClass);
    }
    
    // Nove the header cells into the header table
    thead = table.querySelector('thead');
    headerTable.insertAdjacentElement('afterBegin', thead);
    
    // If necessary, move the footer cells into the footer table
    if (hasFooter) {
      Element tfootbody, tfootrow;
      tfoot = table.querySelector('tfoot');
      tfootrow = tfoot.querySelector('tr');
      //Element tfootbody = new Element.html
      //footerTable.insertAdjacentHtml('afterBegin', '<tbody></tbody>');
      //tfootbody = footerTable.querySelector('tbody');
      tfootbody = new Element.tag('tbody');
      
      Debug("tfootbody=" + tfootbody.toString());
      //tfootbody.insertAdjacentHtml('afterBegin', tfoot.innerHtml);
      tfootbody.insertAdjacentElement('afterBegin', tfootrow);
      footerTable.insertAdjacentElement('afterBegin', tfootbody); 
      tfoot.remove();
    }
    
    // Now build wrapper to surround the main and the grabber
    // The grabber will hold a small invisible element that allows the 
    // user to reveal the split table
    mainHolder_3 = new Element.div();  
    splitGrabber_G = new Element.div();
    splitGrabber_G.classes.add(SplitGrabberClass);
    tableWrapper_2 = new Element.div();     
    
    // The mainHolder_3 contains the grabber on the left
    // and the main table on the right.
    mainHolder_3.insertAdjacentElement('afterBegin',splitGrabber_G);
    mainHolder_3.insertAdjacentElement('beforeEnd',tableWrapper_2);
    
    tableWrapper_2.insertAdjacentElement('afterBegin', headerWrapper_H);
    tableWrapper_2.insertAdjacentElement('beforeEnd', bodyWrapper_B);
    
    if (hasFooter) {
      footerWrapper_F = new Element.div();
      tableWrapper_2.insertAdjacentElement('beforeEnd', footerWrapper_F);
    }
    
    wrapper_0.insertAdjacentElement('afterBegin', mainHolder_3);
    
    headerWrapper_H.insertAdjacentElement('afterBegin', headerTable);
    bodyWrapper_B.insertAdjacentElement('afterBegin', table);
    if (hasFooter) {
      footerWrapper_F.insertAdjacentElement('afterBegin', footerTable);
    }
  }
  
  void prepareMain() {
    // Need a wrapper
    table.classes.add(BodyTableClass);
    
    Element parent;
    parent = table.parent;
    if ( ! parent.classes.contains(ContainerClassName)) {
      // Need to create a container div
      wrapper_0 = new Element.div();
      wrapper_0.classes.add(ContainerClassName);
      
      parent.insertAdjacentElement('afterBegin', wrapper_0);
      
      wrapper_0.style.width = '800px';
      wrapper_0.insertAdjacentElement('afterBegin',table);
    } else wrapper_0 = parent;
    
    // The wrapper must be positioned non-statically
    // relative is the least jarring, just give offset 0
    String position;
    position = wrapper_0.style.position;
    if ((position == null) || (position == '') || (position == 'static')) {
      // This won't work.  We'll force relative.
      wrapper_0.style.position = 'relative';
      wrapper_0.style.top = '0px';
    }
    
    // Now ensure it has height and width
    int height;
    height = wrapper_0.offsetHeight;
    if ((height == null) || (height <= 0)) {
      wrapper_0.style.height = '300px'; // Just a couple of defaults so it works
    }
    int width;
    width = wrapper_0.offsetWidth;
    if ((width == null) || (width <= 0)) {
      wrapper_0.style.height = '800px'; // Just a couple of defaults so it works
    }
    
    buildAllMainElements();
    
    // We also build the splitTableWrappers and set width to 0.
    // These will get reset later, but if they exists, resize() can be simpler
    splitTableWrapper_1 = new Element.div();
    splitTableWrapper_1.style
      ..width = "0px"
      ..left = "0px";
    splitHeaderWrapper_h = new Element.div();
    splitBodyWrapper_b = new Element.div();
    if (hasFooter) splitFooterWrapper_f = new Element.div();
    
    // Now size things that likely won't change
    headerWrapperHeight = headerTable.offsetHeight;
    Debug('headerTable.offsetHeight=' + headerWrapperHeight.toString());
    if (hasFooter) {
      footerWrapperHeight = footerTable.offsetHeight;
    }
    
    // Now we need to set positions of things that are all "absolute" and don't change
    // These are mostly the tops of the pieces.  We'll start with the outside first.
    mainHolder_3.style
      ..position = 'absolute'
      ..top = '0px'
      ..left = '0px'
      ..height = wrapper_0.clientHeight.toString() + 'px';
    mainHolder_3.classes.add(MainHolderClassName);
    
    splitGrabber_G.style
      ..position = 'absolute'
      ..top = '0px'
      ..left = '0px'
      ..width = SplitGrabberWidth.toString() + 'px'
      ..zIndex = (int.parse(mainHolder_3.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset).toString();
    
    tableWrapper_2.style
      ..position = 'absolute'
      ..top = '0px'
      ..left = '0px';
    
    headerWrapper_H.style
      ..position = 'absolute'
      ..top = '0px'
      ..left = '0px'
      ..overflow = 'hidden'
      ..height = headerTable.offsetHeight.toString() + 'px';
    
    bodyWrapper_B.style
      ..position = 'absolute'
      ..top = (mainHolder_3.offsetTop + headerTable.offsetHeight).toString() + 'px'
      ..left = '0px';
    
    if (hasFooter) {
      footerWrapper_F.style
        ..position = 'absolute'
        ..overflowX = 'hidden'  
        ..left = '0px'
        ..overflow = 'hidden' 
        ..height = footerTable.offsetHeight.toString() + 'px';
      
    }
    
   
    
    
    // The scroller will be used for moving the header (and split pane) when the body scrolls
    scroller = bodyWrapper_B.onScroll.listen(null);
    scroller.onData((mouseEvent) { bodyScroll(); } );
    
    // The splitter will be used to change the size of the split table
    splitter = splitGrabber_G.onMouseDown.listen(null);
    splitter.onData(startSplit);
    
    // Now resize and reshape pieces that can change when columns or table are resized or split changed
    resize();
  }
  
  void insertSplitElements() {    
    wrapper_0.insertAdjacentElement('afterBegin', splitTableWrapper_1);
    splitTableWrapper_1.insertAdjacentElement('afterBegin',splitHeaderWrapper_h);
    splitTableWrapper_1.insertAdjacentElement('beforeEnd',splitBodyWrapper_b);
    splitHeaderTable = headerTable.clone(true);
    splitHeaderWrapper_h.insertAdjacentElement('afterBegin', splitHeaderTable);
    splitBodyTable = table.clone(true);
    splitBodyWrapper_b.insertAdjacentElement('afterBegin', splitBodyTable);
    splitColGroup = splitBodyWrapper_b.querySelector('colgroup');
    if (hasFooter) {
      splitFooterTable = footerTable.clone(true);
      splitFooterWrapper_f.insertAdjacentElement('afterBegin', splitFooterTable);
      splitTableWrapper_1.insertAdjacentElement('beforeEnd',splitFooterWrapper_f);
    }
    
    // Need to add the listeners here for resize and reorder columns
    Element grabber;
    List<Element> grabbers;
    var resizer;
    grabbers = splitHeaderTable.querySelectorAll('.' + ColumnResizeGrabberClass);
    for (grabber in grabbers) {
      resizer = grabber.onMouseDown.listen(startColumnResize);
    }
    
    Element holder;
    List<Element> holders;
    var mover, sorter;
    holders = splitHeaderTable.querySelectorAll('.' + ColumnMoverHolderClass);
    for (holder in holders) {
      mover = holder.onMouseDown.listen(startSplitColumnMove);
      sorter = holder.onDoubleClick.listen(columnSort);
    }
    
    splitBodyTable.onClick.listen(rowSelectPolicy.rowSelect);
    splitBodyTable.onClick.listen(splitCellSelect);

  }
  
  void prepareSplit () {
    splitTableWrapper_1.style
      ..position = 'absolute'
      ..left = '0px'
      ..top = '0px'
      ..height = tableWrapper_2.style.height;
    splitTableWrapper_1.classes.add('splitHolder');
    
    splitBodyWrapper_b.style
      ..position = 'absolute'
      ..left = '0px'    
      ..overflowY = 'hidden' // Always.  Scroll controlled from main
      ..height = bodyWrapper_B.style.height;
    
    splitHeaderWrapper_h.style
      ..position = 'absolute'
      ..overflowX = 'hidden'
      ..overflowY = 'hidden'
      ..left = '0px' 
      ..height = headerWrapper_H.style.height;
    
    if (hasFooter) {
      splitFooterWrapper_f.style
        ..position = 'absolute'
        ..left = '0px'
        ..overflowX = 'hidden'
        ..height = footerWrapper_F.style.height;
    }

    splitBodyWrapper_b.scrollTop = bodyWrapper_B.scrollTop;

    // The scroller will be used for moving the header (and footer) when the body scrolls
    splitScroller = splitBodyWrapper_b.onScroll.listen(null);
    splitScroller.onData((mouseEvent) { splitBodyScroll(); } );
  }
  
  void resize() {
    mainHolder_3.style.height = wrapper_0.clientHeight.toString() + 'px';    
    splitGrabber_G.style.height = mainHolder_3.style.height;
    tableWrapper_2.style.height = mainHolder_3.style.height;
    Debug("resize - headerWrapperHeight=" + headerWrapperHeight.toString() + ' footerWrapperHeight=' + footerWrapperHeight.toString());
    bodyWrapper_B.style.height = (tableWrapper_2.clientHeight - (headerWrapperHeight + footerWrapperHeight)).toString() + 'px';

    if (isSplit) {
      splitTableWrapper_1.style.height = tableWrapper_2.style.height;
      splitBodyWrapper_b.style.height = bodyWrapper_B.style.height;
    }
    
    if (hasFooter) {
      footerWrapper_F.style.top = (tableWrapper_2.clientHeight - footerWrapperHeight).toString() + 'px';
      if (isSplit) splitFooterWrapper_f.style.top = footerWrapper_F.style.top;
    }
        
    reShape();
    if (showBackground != null) {
        setShowBackgroundSize(showBackground);
    }
  }
    
  void reShape() {    
    Debug('resize begin');
        
    // setSplitWidth
    if (isSplit) {
      splitBodyWrapper_b.scrollTop = bodyWrapper_B.scrollTop;
      if (splitTableWrapper_1.offsetWidth > wrapper_0.clientWidth - MinMainWidth) setSplitWidth(wrapper_0.clientWidth - MinMainWidth);
    }
    
    mainHolder_3.style.width = (wrapper_0.clientWidth - splitTableWrapper_1.offsetWidth).toString() + 'px';
    if (splitTableWrapper_1.offsetWidth > 0) { 
      tableWrapper_2.style.width = (mainHolder_3.clientWidth - SplitGrabberWidth).toString() + 'px';
      tableWrapper_2.style.left = (mainHolder_3.clientLeft + SplitGrabberWidth).toString() + 'px';
      splitGrabber_G.style.backgroundColor = 'black';
    } else {
      tableWrapper_2.style.width = mainHolder_3.style.width;
      tableWrapper_2.style.left = '0px';
      splitGrabber_G.style.backgroundColor = 'transparent';
    }
    
    Debug('prepare height=' + wrapper_0.offsetHeight.toString());
    
    
    // There are four possibilities:
    // 1. no scroll bars
    // 2. both scroll bars
    // 3. verticle only
    // 4. horizontal only
    // 4a. horizontal on main
    // 4b. horizontal on split
    // 4c. horizontal on main and split.
    // Having one might force the other.
    // The difficult cases are where things are close (i.e. less than the thickness of a scrollbar)
    
    // OK, for now, let's split this into two pieces depending on split vs nosplit
    // We should be able to normalize this for speed later 
    
    splitTableWrapper_1.style.height = wrapper_0.offsetHeight.toString() + 'px';

    Debug("resize -" +
          " table.offsetWidth=" + table.offsetWidth.toString() + 
          " tableWrapper_2.clientWidth=" + tableWrapper_2.clientWidth.toString() +
          " splitTableWrapper_1.clientWidth=" + splitTableWrapper_1.clientWidth.toString() +
          " table.offsetWidth=" + table.offsetWidth.toString() +
          " table.offsetHeight=" + table.offsetHeight.toString() + 
          " tableWrapper_2.clientHeight=" + tableWrapper_2.clientHeight.toString() + 
          " headerWrapperHeight=" + headerWrapperHeight.toString() + 
          " footerWrapperHeight=" + footerWrapperHeight.toString());
    if ((table.offsetWidth <= tableWrapper_2.clientWidth) &&
        (splitTableWrapper_1.clientWidth <= 0 || table.offsetWidth <= splitTableWrapper_1.clientWidth) &&
        (table.offsetHeight <= tableWrapper_2.clientHeight - (headerWrapperHeight + footerWrapperHeight))) {
      Debug("resize No scrollbars needed.  Why they split the table when everything can be seen is anyone's guess");
      // No scrollbars needed.  Why they split the table when everything can be seen is anyone's guess
      bodyWrapper_B.style.width = mainHolder_3.offsetWidth.toString() + 'px';
      bodyWrapper_B.style.overflowX = 'hidden';
      bodyWrapper_B.style.overflowY = 'hidden';
      headerWrapper_H.style.width = bodyWrapper_B.style.width;
      splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
      splitHeaderWrapper_h.style.width = splitBodyWrapper_b.style.width;
      
    } else {
      Debug("resize We might need scroll bars - " +
          "table.offsetHeight=" + table.offsetHeight.toString() + 
          " height=" + wrapper_0.offsetHeight.toString() +
          " headerWrapperHeight=" + headerWrapperHeight.toString() +
          " footerWrapperHeight=" + footerWrapperHeight.toString());
      if (table.offsetHeight < wrapper_0.clientHeight - (headerWrapperHeight + footerWrapperHeight)) {
        Debug("resize so far, do not need verticle scroll, BUT if a horiz scroll is needed, then that may change");
        if ((table.offsetWidth > tableWrapper_2.clientWidth) ||
            (splitTableWrapper_1.clientWidth > 0 && table.offsetWidth > splitTableWrapper_1.clientWidth)) {
          Debug("resize Definitely need horizontal scroll on main or split.  Force on both.");
          if (table.offsetHeight > wrapper_0.clientHeight - (headerWrapperHeight + footerWrapperHeight + HScrollBarThick)) {
            Debug("resize The HScrollbar forced the need for a verticle scroll bar, so here we need both");
            bodyWrapper_B.style.width = tableWrapper_2.clientWidth.toString() + 'px';
            bodyWrapper_B.style.overflowX = 'scroll';
            bodyWrapper_B.style.overflowY = 'scroll';
            headerWrapper_H.style.width = (tableWrapper_2.clientWidth - VScrollBarThick).toString() + 'px';
            splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
            splitBodyWrapper_b.style.overflowX = 'scroll';
          } else {
            Debug("resize The HScrollbar did not affect the unnecessary verticle scroll");
            bodyWrapper_B.style.width = tableWrapper_2.clientWidth.toString() + 'px';
            bodyWrapper_B.style.overflowX = 'scroll';
            bodyWrapper_B.style.overflowY = 'hidden';
            headerWrapper_H.style.width = bodyWrapper_B.style.width;
            splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
            splitBodyWrapper_b.style.overflowX = 'scroll';             
          }
        } else {
          Debug("resize Definitely need a verticle scroll");
          if ((table.offsetWidth > tableWrapper_2.clientWidth - VScrollBarThick) ||
              (splitTableWrapper_1.clientWidth > 0 && table.offsetWidth > splitTableWrapper_1.clientWidth)) {
            Debug("resize The verticle scroll bar forced a horizontal one");
            bodyWrapper_B.style.width = tableWrapper_2.clientWidth.toString() + 'px';
            bodyWrapper_B.style.overflowX = 'scroll';
            bodyWrapper_B.style.overflowY = 'scroll';
            headerWrapper_H.style.width = (tableWrapper_2.clientWidth - VScrollBarThick).toString() + 'px';
            splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
            splitBodyWrapper_b.style.overflowX = 'scroll';
          } else {
            Debug("resize The verticle scroll bar did not affect horiz scrolling");
            bodyWrapper_B.style.width = (table.clientWidth + VScrollBarThick).toString() + 'px';
            bodyWrapper_B.style.overflowX = 'hidden';
            bodyWrapper_B.style.overflowY = 'scroll';
            headerWrapper_H.style.width = (tableWrapper_2.clientWidth - VScrollBarThick).toString() + 'px';
            splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
            splitBodyWrapper_b.style.overflowX = 'hidden';
          }
        }
      } else {
        Debug("resize Since we need a vert scroll let's see if horiz is needed" +
            " splitTableWrapper_1.clientWidth=" + splitTableWrapper_1.clientWidth.toString() +
            " tableWrapper_2.clientWidth=" + tableWrapper_2.clientWidth.toString() 
            );
        if ((table.offsetWidth > tableWrapper_2.clientWidth - VScrollBarThick) ||
            (splitTableWrapper_1.clientWidth > 0 && table.offsetWidth > splitTableWrapper_1.clientWidth)) {
          Debug("resize The verticle scroll bar forced a horizontal one");
          bodyWrapper_B.style.width = tableWrapper_2.clientWidth.toString() + 'px';
          bodyWrapper_B.style.overflowX = 'scroll';
          bodyWrapper_B.style.overflowY = 'scroll';
          headerWrapper_H.style.width = (bodyWrapper_B.clientWidth).toString() + 'px'; //  - VScrollBarThick
          splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
          splitBodyWrapper_b.style.overflowX = 'scroll';
        } else {
          Debug("resize The verticle scroll bar did not affect horiz scrolling");
          bodyWrapper_B.style.width = (table.clientWidth + VScrollBarThick).toString() + 'px';
          bodyWrapper_B.style.overflowX = 'hidden';
          bodyWrapper_B.style.overflowY = 'scroll';
          headerWrapper_H.style.width = (mainHolder_3.clientWidth - VScrollBarThick).toString() + 'px';
          splitBodyWrapper_b.style.width = splitTableWrapper_1.clientWidth.toString() + 'px';
          splitBodyWrapper_b.style.overflowX = 'hidden';
        }
      }
    }
    
    //splitHeaderWrapper_h.style.width = 
    if (hasFooter) {
      footerWrapper_F.style.top = (tableWrapper_2.offsetTop + tableWrapper_2.offsetHeight - footerWrapperHeight).toString() + 'px';
      footerWrapper_F.style.width = headerWrapper_H.style.width;
      splitFooterWrapper_f.style.top = footerWrapper_F.style.top;
      splitFooterWrapper_f.style.width = splitHeaderWrapper_h.style.width;
    }
        
    splitBodyWrapper_b.style.top = (splitTableWrapper_1.offsetTop + splitHeaderWrapper_h.offsetHeight).toString() + 'px';
    
    if (hasFooter) {
      //footerWrapper_F.style.top = (splitTableWrapper_1.offsetTop + splitTableWrapper_1.offsetHeight - footerWrapperHeight).toString() + 'px';
      //splitFooterWrapper_f.style.top = (splitTableWrapper_1.offsetTop + splitTableWrapper_1.offsetHeight - footerWrapperHeight).toString() + 'px';
    }
  }
  
  void bodyScroll() {
    // This needs to check the scroll bosition of the body and move the header (and footer) the same amount
    headerWrapper_H.scrollLeft = bodyWrapper_B.scrollLeft;
    if (hasFooter) footerWrapper_F.scrollLeft = bodyWrapper_B.scrollLeft;
    if (isSplit) {
      // Need to verticle scroll the split body to match
      splitBodyWrapper_b.scrollTop = bodyWrapper_B.scrollTop;
    }
    Debug('bodyScroll - scrollTop=' + bodyWrapper_B.scrollTop.toString() + ', scrollLeft=' + bodyWrapper_B.scrollLeft.toString());
  }
  
  void splitBodyScroll() {
    splitHeaderWrapper_h.scrollLeft = splitBodyWrapper_b.scrollLeft;
    if (hasFooter) splitFooterWrapper_f.scrollLeft = splitBodyWrapper_b.scrollLeft;
    Debug('splitBodyScroll - scrollLeft=' + splitBodyWrapper_b.scrollLeft.toString());
  }
  
  // firsttime runs against the existing table and assigns classes etc.
  // after this, the headers and footers will be gone, so this cannot
  // be run again.
  void firsttime() {
    List<Element> cols, rows;
    Element th, td, resizerHolderDiv, resizerGrabberDiv;
    String colClass, swidth, rule, headerContent, dataType, zIndex;
    int columnPos = 1;
    
    // Set up all the "well known" data types.  Users can define and add their own.
    superTableDataTypes = new List<SuperTableDataType>();
    superTableDataTypes.add(new SuperTableDataTypeText());
    superTableDataTypes.add(new SuperTableDataTypeMoney());
    superTableDataTypes.add(new SuperTableDataTypeInteger());
    superTableDataTypes.add(new SuperTableDataTypeDate());
    
    getScrollbarThicks();
    
    // create a stylesheet element to hold column styles
    StyleElement styleElement = new StyleElement();
    document.head.append(styleElement);
    // use the styleSheet from that
    sheet = styleElement.sheet;
    
    // See if we have a footer
    Element tfoot = table.querySelector('tfoot');
    hasFooter = (tfoot != null);
    
    // We'll do zIndex as an offset from the table in case it's places otherwise
    zIndex = (int.parse(table.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset).toString();
    
    colGroup = table.querySelector('colgroup');
    cols = colGroup.querySelectorAll('col');
    for (Element col in cols) {
      colClass = generateColClassName(columnPos);
      col.classes.add(colClass);
      col.setAttribute(ColumnClassAttrName,colClass);
      col.setAttribute(InitialDataPosAttrName, columnPos.toString());  //If columns are reordered, this will allow finding data refreshed.
            
      swidth = col.getAttribute(InitialWidthAttrName);
      rule = '.' + colClass + ' { max-width:' + swidth + 'px; min-width:' + swidth + 'px;}';
      sheet.insertRule(rule,columnPos - 1);
      
      dataType = col.getAttribute(DataTypeAttrName);
      th = table.querySelector('th:nth-of-type(' + columnPos.toString() + ')');
      th.classes.add(colClass); th.classes.add(dataType);
      th.setAttribute(ColumnClassAttrName, colClass);
      headerContent = th.innerHtml;
      th.innerHtml = '';
      
      resizerGrabberDiv = new Element.div();
      resizerGrabberDiv
        ..style.position = 'absolute'
        ..style.height = '100%'
        ..style.top = '0px'
        ..classes.add(ColumnResizeGrabberClass)
        ..setAttribute(ColumnClassAttrName, colClass)
        ..setAttribute(InitialDataPosAttrName, columnPos.toString())
        ..style.zIndex = (int.parse(th.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset).toString();
      
      resizerHolderDiv = new Element.div();
      resizerHolderDiv
        ..style.position = 'relative'
        ..style.height = '100%'
        ..style.width = '100%'
        ..classes.add(ColumnMoverHolderClass)
        ..setAttribute(ColumnClassAttrName, colClass)
        ..setAttribute(InitialDataPosAttrName, columnPos.toString())
        ..innerHtml = headerContent
        ..insertAdjacentElement('afterBegin', resizerGrabberDiv);
      
      
      var sorter = resizerHolderDiv.onDoubleClick.listen(columnSort);
      var resizer = resizerGrabberDiv.onMouseDown.listen(startColumnResize);
      var mover = resizerHolderDiv.onMouseDown.listen(startColumnMove);
            
      th.insertAdjacentElement('afterBegin', resizerHolderDiv);
 
      if (hasFooter) {
         td = tfoot.querySelector('td:nth-of-type(' + columnPos.toString() + ')');
         td.classes.add(colClass);  // For the sizing
         td.setAttribute(ColumnClassAttrName, colClass);
         // Theoretically, we could add resizers to the footer too.
      }
          
      columnPos++;
    }
    
    // Set up row selection events
    if (rowSelectPolicy == null) rowSelectPolicy = new SuperTableRowSelectPolicyNormal(this);
    table.onClick.listen(rowSelectPolicy.rowSelect);
    table.onClick.listen(cellSelect);
    // This goes through the data rows.  If the data are later updated, then recall refreshBody.
    refreshBodyFromDOM();
  }
  
  String generateColClassName(int columnPos) {
    return SuperTablePrefix + '_' + id + 'col' + columnPos.toString();
  }
  /*****************************************************************/
  /*****************************************************************/
  // Begin single column Sort function.
  /*****************************************************************/
  /*****************************************************************/
  
  void columnSort(MouseEvent e) {
    Element target;
    Debug('columnSort' + e.target.toString());
    target = e.target;  // Should be 'th' from splitHeaderTable;
    Debug('columnSort target=' + target.text + ' classname=' + target.getAttribute(ColumnClassAttrName).toString());
    // Need to find movingColumn
    String columnClassName = target.getAttribute(ColumnClassAttrName);
    List<String> classNames;
    classNames = new List<String>();
    classNames.add(columnClassName + ':' + ((lastSortAscending) ? 'D' : 'A'));
    lastSortAscending = ! lastSortAscending;
    SuperTableSort sorter;
    sorter = new SuperTableSort(this,classNames, debug: false);
    sorter.sort();
  }
  /*****************************************************************/
  /*****************************************************************/
  // End single column Sort function.
  /*****************************************************************/
  /*****************************************************************/
  // Begin the split table functions.
  /*****************************************************************/
  /*****************************************************************/
  // For the dragger to be in the right place, we need to place the dragger.
  // This is because we cannot get the grabber to go along the left edge of 
  // table unless the table is positioned absolute.
  // To get around this, we will have an exposed function.  If the table moves,
  // or the splitter moves, we will recalculate this positioning.
  // For now, relative to screen.
    
  void startSplit (MouseEvent e) {
    startw = splitTableWrapper_1.offsetWidth;
    startx = e.page.x;
    Debug('startSplit - startw=' + startw.toString() + ' startx=' + startx.toString());
    mouseMove = document.onMouseMove.listen(splitTableMove);
    mouseUp = document.onMouseUp.listen(endSplitTable);
    e.preventDefault();
    e.stopPropagation();
  }
  
  void splitTableMove (MouseEvent e) {
    Debug('Enter splitTableMove');
    if ( ! splitCloned ) {
      if (((e.page.x - startx).abs()) > 5) {
        // Start the move
        splitCloned = true;
        createSplitView();
      }
    }
    changeSplitWidth(e.page.x - startx);
    resize();
    e.preventDefault();
    e.stopPropagation();    
  }
  
  void endSplitTable (MouseEvent e) {
    mouseMove.cancel();
    mouseUp.cancel();
    e.preventDefault();
    e.stopPropagation();    
  }
  
  void createSplitView () {
    if (! isSplit) {      
      insertSplitElements();      
      prepareSplit();
      isSplit = true;
    }
  }
  
  void setSplitWidth(int width) {
    Debug('Enter setSplitWidth - width=' + width.toString());
    splitTableWrapper_1.style.width = width.toString() + 'px';   
    
    splitHeaderWrapper_h.style.width = splitTableWrapper_1.style.width;      
    splitBodyWrapper_b.style.width = splitTableWrapper_1.style.width;      
    if (hasFooter) {
      splitFooterWrapper_f.style.width = splitTableWrapper_1.style.width;
    }
    
    // Now, shrink the main pieces
    mainHolder_3.style.width = (wrapper_0.clientWidth - width).toString() + 'px';
    mainHolder_3.style.left = (width).toString() + 'px';      
    tableWrapper_2.style.width = mainHolder_3.style.width;         
    headerWrapper_H.style.width = mainHolder_3.style.width;      
    if (hasFooter) {
      footerWrapper_F.style.width = mainHolder_3.style.width;
    }
  }
  
  void changeSplitWidth(int diff) {
    int width;
    Debug('Enter changeSplitWidth - diff=' + diff.toString() + ' startw=' + startw.toString());
    
    width = startw + diff;
    
    // BUT, should we have a minimum exposure so that the split doesn't 
    // take either a tint slice or the whole thing.
    if (width < 0) width = 0;
    else if (width > wrapper_0.clientWidth - MinMainWidth) width = wrapper_0.clientWidth - MinMainWidth;
    
    if (isSplit) {
      setSplitWidth(width);
    }
  }
  
  /*****************************************************************/
  /*****************************************************************/
  // End split table functions.
  /*****************************************************************/
  /*****************************************************************/
  // Begin the column reordering functions.
  /*****************************************************************/
  /*****************************************************************/
  void startSplitColumnMove (MouseEvent e) {
    Element target;
    Debug('startSplitColumnMove' + e.target.toString());
    target = e.target;  // Should be 'th' from splitHeaderTable;
    Debug('startSplitColumnMove target=' + target.text + ' classname=' + target.getAttribute(ColumnClassAttrName).toString());
    // Need to find movingColumn
    String columnClassName = target.getAttribute(ColumnClassAttrName);
    List<Element> cols;
    Element col;
    cols = splitColGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(ColumnClassAttrName) == columnClassName) {
        movingColumn = col;
        break;
      }
    }
    Debug('startSplitColumnMove' + e.page.toString());
    startx = e.page.x;
    // Since we need to get data, we need to know the current column and it's position
    
    nodeAdded = false;
    
    splitMouseMove = document.onMouseMove.listen(splitMoveColumnMove);
    splitMouseUp = document.onMouseUp.listen(splitEndColumnMove);
    // Will commenting these fix the double click issue?
    e.preventDefault();
    e.stopPropagation();   
  }
    
  void startColumnMove (MouseEvent e) {
    Element target;
    Debug('startColumnMove' + e.target.toString());
    target = e.target;  // Should be 'th' from headerTable;
    Debug('startColumnMove target=' + target.text + ' classname=' + target.getAttribute(ColumnClassAttrName).toString());
    // Need to find movingColumn
    String columnClassName = target.getAttribute(ColumnClassAttrName);
    List<Element> cols;
    Element col;
    cols = colGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(ColumnClassAttrName) == columnClassName) {
        movingColumn = col;
        break;
      }
    }
    Debug('startColumnMove' + e.page.toString());
    startx = e.page.x;
    // Since we need to get data, we need to know the current column and it's position
    
    nodeAdded = false;
    
    mouseMove = document.onMouseMove.listen(moveColumnMove);
    mouseUp = document.onMouseUp.listen(endColumnMove);
    e.preventDefault();
    e.stopPropagation();   
  }
  
  void splitMoveColumnMove (MouseEvent e) {
    // Need to see how far we've moved before adding to DOM
    if ( ! nodeAdded ) {
      if (((e.page.x - startx).abs()) > 5) {
        Debug('splitMoveColumnMove Start the move');
        nodeAdded = true;
        createDraggingView();
        splitTableWrapper_1.insertAdjacentElement('afterBegin', draggingView);
      }
    }
    if (nodeAdded) {
      //headerWrapper.scrollLeft;
      Debug('splitMoveColumnMove' +
          ' docx=' + docx.toString() + 
          ' e.page.x=' + e.page.x.toString() + 
          ' splitHeaderWrapper_h.scrollLeft=' + splitHeaderWrapper_h.scrollLeft.toString() );
      draggingView.style.left = (docx + e.page.x - startx - splitHeaderWrapper_h.scrollLeft).toString() + 'px';
      pos = e.page;
      // OK, where are we?  We need to decide what we're between
      Element t, th;
      CssClassSet classes;
      String clas;
      t = e.target;
      th = t.parent;//.querySelector('th');
      if (th != null) {
        classes = th.classes;
        for (clas in classes) {
          Debug('splitMoveColumnMove clas=' + clas);
        }
        Debug('splitMoveColumnMove' + t.querySelector('th').toString());
      }
    }
    e.preventDefault();
    e.stopPropagation();   
  }

  void moveColumnMove (MouseEvent e) {
    // Need to see how far we've moved before adding to DOM
    if ( ! nodeAdded ) {
      if (((e.page.x - startx).abs()) > 5) {
        Debug('moveColumnMove Start the move');
        nodeAdded = true;
        createDraggingView();
        mainHolder_3.insertAdjacentElement('afterBegin', draggingView);
      }
    }
    if (nodeAdded) {
      //headerWrapper.scrollLeft;
      Debug('moveColumnMove' +
          ' docx=' + docx.toString() + 
          ' e.page.x=' + e.page.x.toString() + 
          ' headerWrapper_H.scrollLeft=' + headerWrapper_H.scrollLeft.toString() );
      draggingView.style.left = (docx + e.page.x - startx - headerWrapper_H.scrollLeft).toString() + 'px';
      pos = e.page;
      // OK, where are we?  We need to decide what we're between
      Element t, th;
      CssClassSet classes;
      String clas;
      t = e.target;
      th = t.parent;//.querySelector('th');
      if (th != null) {
        classes = th.classes;
        for (clas in classes) {
          Debug('moveColumnMove clas=' + clas);
        }
        Debug('moveColumnMove' + t.querySelector('th').toString());
      }
    }
    e.preventDefault();
    e.stopPropagation();   
  }

  void splitEndColumnMove (MouseEvent e) {
    splitMouseMove.cancel();
    splitMouseUp.cancel();
    if (nodeAdded) {
      Debug('splitEndColumnMove pos.y=' + pos.y.toString() + ' offsetTop=' + wrapper_0.offsetTop.toString());
      if ((pos.y > wrapper_0.offsetTop) && (pos.y < wrapper_0.offsetTop + wrapper_0.offsetHeight)) {
        Debug("splitEndColumnMove we're in the header, but are we in a column??");
        Debug('splitEndColumnMove pos.x=' + pos.x.toString() + ' offsetLeft=' + splitHeaderWrapper_h.offsetLeft.toString());
        Debug('splitEndColumnMove pos.x=' + pos.x.toString() + ' clientLeft=' + splitHeaderWrapper_h.clientLeft.toString());
        Debug('splitEndColumnMove pos.x=' + pos.x.toString() + ' scrollLeft=' + splitHeaderWrapper_h.scrollLeft.toString());
        Debug('splitEndColumnMove pos.x=' + pos.x.toString() + ' documentOffset=' + splitHeaderWrapper_h.documentOffset.x.toString());
        
        int follows;
        follows = columnMoveGetMoveDestColumnPos(true);
 
        if (follows >= 0) {
          // Need to move the columns around
          // Need to find column in List 
          columnMoveMove(follows);
        }
      }
       
      draggingView.remove();
    }
    draggingView = null;
    e.preventDefault();
    e.stopPropagation();    
  }
  
  void endColumnMove (MouseEvent e) {
    mouseMove.cancel();
    mouseUp.cancel();
    if (nodeAdded) {
      Debug('endColumnMove pos.y=' + pos.y.toString() + ' offsetTop=' + wrapper_0.offsetTop.toString());
      //if ((pos.y > wrapper_0.offsetTop) && (pos.y < wrapper_0.offsetTop + wrapper_0.offsetHeight)) {
        Debug("endColumnMove we're in the header, but are we in a column??");
        Debug('endColumnMove pos.x=' + pos.x.toString() + ' offsetLeft=' + headerWrapper_H.offsetLeft.toString());
        Debug('endColumnMove pos.x=' + pos.x.toString() + ' clientLeft=' + headerWrapper_H.clientLeft.toString());
        Debug('endColumnMove pos.x=' + pos.x.toString() + ' scrollLeft=' + headerWrapper_H.scrollLeft.toString());
        Debug('endColumnMove pos.x=' + pos.x.toString() + ' documentOffset=' + headerWrapper_H.documentOffset.x.toString());
        
        int follows;
        follows = columnMoveGetMoveDestColumnPos(false);
 
        if (follows >= 0) {
          // Need to move the columns around
          // Need to find column in List 
          columnMoveMove(follows);
        }
      //}
       
      draggingView.remove();
    }
    draggingView = null;
    e.preventDefault();
    e.stopPropagation();    
  }

  
  void columnMoveMove(int follows) {
    // Here we need to do the real move.
    // There are two steps:
    // 1. Update SuperColumns
    // 2. Move the columns (header, body and footer)
    int movingColumnPos = getColumnPositionByColumnClassName(movingColumn.getAttribute(ColumnClassAttrName));
    if (movingColumnPos == follows) return; // Was not moving at all
    if (movingColumnPos == follows + 1) return; // Was not moving at all
    
    // So, in order to update , need to spool through them all and reorder
    List<Element> columns;
    Element columnToMove, columnToFollow;
    columnToMove = colGroup.querySelector('col:nth-of-type(' + movingColumnPos.toString() + ')');
    if (follows == 0) {
      colGroup.insertAdjacentElement('afterBegin', columnToMove);
    } else {
      columnToFollow = colGroup.querySelector('col:nth-of-type(' + follows.toString() + ')');
      columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
    }
      
    columnToMove = headerTable.querySelector('th:nth-of-type(' + movingColumnPos.toString() + ')');
    if (follows == 0) {
      columnToMove.parent.insertAdjacentElement('afterBegin', columnToMove);
    } else {
      columnToFollow = headerTable.querySelector('th:nth-of-type(' + follows.toString() + ')');
      columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
    }
    
    List<Element> rows;
    Element row;
    rows = table.querySelectorAll('tr');
    for (row in rows) {
      columnToMove = row.querySelector('td:nth-of-type(' + movingColumnPos.toString() + ')');
      if (follows == 0) {
        row.insertAdjacentElement('afterBegin', columnToMove);
      } else {
        columnToFollow = row.querySelector('td:nth-of-type(' + follows.toString() + ')');
        columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
      }
    }
    
    // Footer Table later
    if (hasFooter) {
      columnToMove = footerTable.querySelector('td:nth-of-type(' + movingColumnPos.toString() + ')');
      if (follows == 0) {
        columnToMove.parent.insertAdjacentElement('afterBegin', columnToMove);
      } else {
        columnToFollow = footerTable.querySelector('td:nth-of-type(' + follows.toString() + ')');
        columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
      }      
    }
    
    if (isSplit) {
      // Need to do the whole thing again with the split tables
      columnToMove = splitColGroup.querySelector('col:nth-of-type(' + movingColumnPos.toString() + ')');
      if (follows == 0) {
        splitColGroup.insertAdjacentElement('afterBegin', columnToMove);
      } else {
        columnToFollow = splitColGroup.querySelector('col:nth-of-type(' + follows.toString() + ')');
        columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
      }
        
      columnToMove = splitHeaderTable.querySelector('th:nth-of-type(' + movingColumnPos.toString() + ')');
      if (follows == 0) {
        columnToMove.parent.insertAdjacentElement('afterBegin', columnToMove);
      } else {
        columnToFollow = splitHeaderTable.querySelector('th:nth-of-type(' + follows.toString() + ')');
        columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
      }
      
      List<Element> rows;
      Element row;
      rows = splitBodyTable.querySelectorAll('tr');
      for (row in rows) {
        columnToMove = row.querySelector('td:nth-of-type(' + movingColumnPos.toString() + ')');
        if (follows == 0) {
          row.insertAdjacentElement('afterBegin', columnToMove);
        } else {
          columnToFollow = row.querySelector('td:nth-of-type(' + follows.toString() + ')');
          columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
        }
      }
      
      // Footer Table later
      if (hasFooter) {
        columnToMove = splitFooterTable.querySelector('td:nth-of-type(' + movingColumnPos.toString() + ')');
        if (follows == 0) {
          columnToMove.parent.insertAdjacentElement('afterBegin', columnToMove);
        } else {
          columnToFollow = splitFooterTable.querySelector('td:nth-of-type(' + follows.toString() + ')');
          columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
        }      
      }
    }
    
  }
  
  void createDraggingView() {
    List<Element> rows;
    Element row, cell;
   // OK, we need to build a table with a single column to drag around
    int rowcount = 0, colPosition;
    String tablestuff, contents, columnClassName;
    Element td, th;
    columnClassName = movingColumn.getAttribute(ColumnClassAttrName);
    colPosition = getColumnPositionByColumnClassName(columnClassName);
    // First the header
    th = headerTable.querySelector('th:nth-of-type(' + colPosition.toString() + ')');
    // BUT, we don't want the resizing/moving divs
    td = th.querySelector('.' + ColumnMoverHolderClass);
    Debug('createDraggingView header text=' + td.text);
    Debug('createDraggingView colClass=' + columnClassName);
    tablestuff = '<thead><tr><th class="' + columnClassName + '">' + td.text + '</th></tr></thead>';
    tablestuff += '<tbody>';
    
    rows = table.querySelectorAll('tr');
    Debug('createDraggingView rows.length=' + rows.length.toString());
    for (row in rows) {
      cell = row.querySelector('td:nth-of-type(' + colPosition.toString() + ')');
      Debug('createDraggingView adding cell.text=' + cell.text);
      tablestuff += '<tr><td class="' + columnClassName + '">' + cell.text + '</td></tr>';
      if (rowcount > 5) break; // Just do the first 5 rows for now.  Later we will figure out the number of rows in the scroll area
      rowcount++;
    }
    tablestuff += '</tbody>';
    
    docx = th.offsetLeft;
    draggingView = new Element.table();
    draggingView.innerHtml = tablestuff;
    Debug('createDraggingView innerHtml = ' + draggingView.innerHtml);
    draggingView
      ..classes.add(BodyTableClass)
      ..classes.add('movingColumnTable')
      ..style.tableLayout = 'fixed'
      ..style.whiteSpace = "nowrap"
      ..style.position = "absolute"
      ..style.left = docx.toString() + 'px'
      ..style.top = '0px'
      ..style.opacity = ".7"
      ..style.zIndex = (int.parse(headerTable.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset).toString();
    // Need the get the correct data class too
  }
  
  int columnMoveGetMoveDestColumnPos(bool startFromSplit) {
    int half, colpos = 1, follows = -1, xpos, offset;
    List<Element> cols;
    Element col;
    
    xpos = draggingView.offsetLeft + (draggingView.offsetWidth ~/ 2);

    if (startFromSplit) {
      // We started dragging from the split table, but which area are we in now?
      if (xpos > splitTableWrapper_1.offsetWidth ) { // May need to add some here for split grabber width
        // we've traversed over into the main table
        cols = headerTable.querySelectorAll('th');
        offset = headerWrapper_H.scrollLeft - splitTableWrapper_1.offsetWidth;          
      } else {
        // we're still back in the split table
        cols = splitHeaderTable.querySelectorAll('th');
        offset = 0;
      }
    } else {    
      // We started dragging in the main table, but which area are we in now
      if (splitTableWrapper_1.offsetWidth > 0 && xpos < 0) {
        // we are definitely messing in the split area
        cols = splitHeaderTable.querySelectorAll('th');
        offset = mainHolder_3.offsetLeft + splitGrabber_G.offsetWidth + splitHeaderWrapper_h.scrollLeft;
      } else {
        cols = headerTable.querySelectorAll('th');
        offset = headerWrapper_H.scrollLeft;  
      }
    }
      
    Debug("columnMoveGetMoveDestColumnPos xpos=" + xpos.toString());

    if (xpos + offset < 0) {
      follows = 0; // Special case to move before first.  Maybe we'll do the other spacial case later
    } else {
      for (col in cols) {
        Debug("columnMoveGetMoveDestColumnPos offsetLeft=" + col.offsetLeft.toString() + 
                                                           ' clientLeft=' + col.clientLeft.toString() + 
                                                           ' scrollLeft=' + col.scrollLeft.toString() );
        Debug("columnMoveGetMoveDestColumnPos offsetwidth=" + col.offsetWidth.toString() + 
                                                           ' clientWidth=' + col.clientWidth.toString() + 
                                                           ' scrollWidth=' + col.scrollWidth.toString() );
        // So, which column are we going after??
        // Let's find the center of draggingView
        // Remember, we may need to go before the first column, or may not move at all
        
        half = col.offsetWidth ~/ 2;
        Debug("columnMoveGetMoveDestColumnPos col.offsetLeft=" + col.offsetLeft.toString() +
                                                                     " xpos=" + xpos.toString() +
                                                                     " right=" + (col.offsetLeft + half).toString());
        Debug("columnMoveGetMoveDestColumnPos left=" + (col.offsetLeft + half).toString() +
                                                           " xpos=" + xpos.toString() +
                                                           " right=" + (col.offsetLeft + col.offsetWidth).toString());
        if (xpos + offset > col.offsetLeft && 
            xpos + offset < col.offsetLeft + half ) {
          // we precede this column
          follows = colpos - 1;
          Debug("columnMoveGetMoveDestColumnPos follow column " );
        } else if (xpos + offset >= col.offsetLeft + half  && 
                   xpos + offset <= col.offsetLeft + col.offsetWidth ) {
          // We follow this column
          follows = colpos;
        }
        if (follows >= 0) break;
        colpos++;
      }
    }
    return follows; // follows = 0 means it goes to the front
  }

  /*****************************************************************/
  /*****************************************************************/
  // End the column reordering functions.
  /*****************************************************************/
  /*****************************************************************/
  // Begin the column resizing functions
  /*****************************************************************/
  /*****************************************************************/
  void startColumnResize(MouseEvent e) {
    Element p;
    Debug('startColumnResize' + e.target.toString());
    p = e.target;
    Debug('startColumnResize ' + p.classes.first);
    Debug('colclass=' + p.getAttribute(ColumnClassAttrName).toString());
    Debug('columnPos=' + p.getAttribute(InitialDataPosAttrName).toString());
    // We'll keep a copy of these for now, even though we don't know how to reapply them.
    mouseUpHolder = document.onMouseUp;
    mouseMoveHolder = document.onMouseMove;    
    // We do know how to reapply the cursor.
    cursorHolder = document.body.style.cursor;
    
    // page and screen seem to work.  offset does not.
    //startx = e.screen.x;
    startx = e.page.x;
    //resizingColumn = int.parse(p.getAttribute(InitialDataPosAttrName).toString());
    resizingClass = p.getAttribute(ColumnClassAttrName);
    List<Element> cols = colGroup.querySelectorAll('col');
    Element col;
    for (col in cols) {
      if (col.getAttribute(ColumnClassAttrName) == resizingClass) {
        // This is the column
        resizingColumn = col; break;
      }
    }
   
    document.body.style.cursor = 'w-resize';
    mouseMove = document.onMouseMove.listen(moveColumnResize);
    mouseUp = document.onMouseUp.listen(endColumnResize);
    e.preventDefault();
    e.stopPropagation();
  }
  
  void moveColumnResize(MouseEvent e) {
    Debug('moveColumnResize - x=' + e.page.x.toString());
    int colWidth;
    colWidth = int.parse(resizingColumn.getAttribute(InitialWidthAttrName));
    resizeColumn(colWidth + e.page.x - startx);
    
    e.preventDefault();
    e.stopPropagation();
  }
  
  void endColumnResize(MouseEvent e) {
    mouseUp.cancel();
    mouseMove.cancel();
    document.body.style.cursor = cursorHolder; // put the cursor back
    int colWidth = int.parse(resizingColumn.getAttribute(InitialWidthAttrName));
    if (colWidth + e.page.x - startx < MinColumnWidth) 
      resizingColumn.setAttribute(InitialWidthAttrName, MinColumnWidth.toString() );
    else
      resizingColumn.setAttribute(InitialWidthAttrName, (colWidth + e.page.x - startx).toString());
    resizeColumn(colWidth + e.page.x - startx);
    e.stopPropagation();
    reShape();
  }
  
  // This is used by the column resizing functions, but may be called elsewhere
  void resizeColumn(int width) {
    if (width >= MinColumnWidth) {
      int resizingColumnRulePos = int.parse(resizingColumn.getAttribute(InitialDataPosAttrName)) - 1;
      sheet.deleteRule(resizingColumnRulePos);
      Debug('resizeColumn - width=' + width.toString());
      String rule = '.' + resizingClass + ' { max-width:' + width.toString() + 'px; min-width:' + width.toString() + 'px;}';
      sheet.insertRule(rule,resizingColumnRulePos);
    }
  }
  /*****************************************************************/
  /*****************************************************************/
  // End the column resizing functions
  /*****************************************************************/
  /*****************************************************************/
  // Begin showStuff (for notifications like alerts)
  /*****************************************************************/
  /*****************************************************************/
  void showStuff(Element toBeShown) {
    Element holder, button, p;
    showBackground = getShowBackground();
    
    p = new Element.p();    
    showBackground.classes.add(ShowStuffClass);
    p.insertAdjacentElement('afterBegin', toBeShown);
    
    
    // OK, lets add a button
    button = new ButtonElement();
    button.text = "Done";
    var clicker = button.onClick.listen(null);
    clicker.onData((mouseEvent) { showBackground.remove(); showBackground = null;} );
    
    showBackground.insertAdjacentElement('beforeEnd', button);
    showBackground.insertAdjacentElement('afterBegin', p);
    
    wrapper_0.insertAdjacentElement('afterBegin', showBackground);
  }
  
  void splitCellSelect(MouseEvent e) {   
    bool editing = false;
    Debug("Enter splitCellSelect.hashCode=" + cellEdited.hashCode.toString() + ' e.target.hashCode=' + e.target.hashCode.toString());
    if (cellEdited.hashCode == e.target.hashCode) {
      DateTime clickTime = new DateTime.now();
      Duration duration = clickTime.difference(cellEditClickTime);
      editing = ((duration.inMilliseconds > 300) && (duration.inMilliseconds < 1000));
    }
    if (editing) {
      String cellUpdateHandlerName;
      cellUpdateHandlerName = cellEdited.getAttribute(CellUpdateHandlerAttrName);
      if (cellUpdateHandlerName != null) {
        // OK, a handler is named, let's find it.  Linear search should be good enough.
        for (cellUpdateHandler in cellUpdateHandlers) {
          if (cellUpdateHandler.name == cellUpdateHandlerName) break;
        }
      } 
      if (cellUpdateHandler == null) cellUpdateHandler = defaultCellUpdateHandler; // Try to use defaultCellUpdateHandler
      
      if (cellUpdateHandler != null) {
        editingSplit = true;
        cellUpdateHandler.preUpdate(cellEdited,this); // Need to get dataType
        if (e.shiftKey) {
          cellUpdateHandler.reset();
          setMainTdEditedFromSplit(cellEdited);
        } else {
          openCell(cellEdited, true);                  
          // Now need to register an event to 
          StreamSubscription<Event> undo = showBackground.onClick.listen(null);
          undo.onData(endSplitCellEdit); 
        }
      } else { print("No SuperTableCellUpdateHandler available"); }      
    } else {
      cellEdited = e.target;
      cellEditClickTime = new DateTime.now();
    }
  }
  
  void endSplitCellEdit(MouseEvent e) {
    // If the cell was editable, need to put the new data in place.
    if (e.target != cellEditor) {
      bool valid;
      valid = cellUpdateHandler.validate(); // rudimentary element validation, but not application
      if (! valid) {
        cellEditor.focus();
      } else {
        cellUpdateHandler.update();
      }
    }
  }
  
  void cellSelect(MouseEvent e) {   
    bool editing = false;
    Debug("Enter cellSelect.hashCode=" + cellEdited.hashCode.toString() + ' e.target.hashCode=' + e.target.hashCode.toString());
    if (cellEdited.hashCode == e.target.hashCode) {
      DateTime clickTime = new DateTime.now();
      Duration duration = clickTime.difference(cellEditClickTime);
      editing = ((duration.inMilliseconds > 300) && (duration.inMilliseconds < 1000));
    }
    if (editing) {
      // If there is a CellEditUpdateAttrName then need to look for an update handler
      String cellUpdateHandlerName;
      cellUpdateHandlerName = cellEdited.getAttribute(CellUpdateHandlerAttrName);
      if (cellUpdateHandlerName != null) {
        // OK, a handler is named, let's find it.  Linear search should be good enough.
        for (cellUpdateHandler in cellUpdateHandlers) {
          if (cellUpdateHandler.name == cellUpdateHandlerName) break;
        }
      } 
      if (cellUpdateHandler == null) cellUpdateHandler = defaultCellUpdateHandler; // Try to use defaultCellUpdateHandler
      
      if (cellUpdateHandler != null) {
        editingSplit = false;
        cellUpdateHandler.preUpdate(cellEdited,this); // Need to get dataType
        if (e.shiftKey) {
          cellUpdateHandler.reset();
          setSplitTdEditedFromMain(cellEdited);
        } else {
          // OK, now get the main table row and pass it in
          openCell(cellEdited, false);                  
          // Now need to register an event to 
          StreamSubscription<Event> undo = showBackground.onClick.listen(null);
          undo.onData(endCellEdit); 
        }
      } else { print("No SuperTableCellUpdateHandler available"); }
    } else {
      cellEdited = e.target;
      cellEditClickTime = new DateTime.now();
    }
  }

  void endCellEdit(MouseEvent e) {
    // If the cell was editable, need to put the new data in place.
    if (e.target != cellEditor) {
      Debug("cellEditor.isContentEditable=" + cellEditor.isContentEditable.toString());
      if (cellEditor.isContentEditable) {
        
        if (cellUpdateHandler.valueChanged()) {
          bool valid;
          // Now we pass control to the cellUpdateHandler to do the update.
          // There may be other validations that need to be done that require 
          // web server and Futuresm so, when it is done, it will call closeCellEditing
          
          valid = cellUpdateHandler.validate(); // rudimentary element validation, but not application
          if (! valid) {
            cellEditor.focus();
          } else {
            cellUpdateHandler.update();
          }
              
//          if (validateEdit(cellEdited,cellEditor.value)) {
//            cellEdited.text = cellEditor.value;
//            cellEdited.classes.add(CellEditedClass);
//            if (cellUpdateHandler != null) cellUpdateHandler.update(cellEdited);
//            tableEditCount++;
//            if (isSplit) {
//              setSplitTdEditedFromMain(cellEdited);
//            }  
//            showBackground.remove();
//          } else {
//            showBackground.remove();
//            Element msg;
//            msg = new Element.div();
//            msg.text = 'Changed value is not valid.  Change Ignored.';
//            showStuff(msg);
//          }        
        } else closeCellEditing(true);
      } else closeCellEditing(true);
      
    }
  }
  
// Callback from cellUpdateHandler when all is good or bad
  void closeCellEditing(bool close, {String message: null} ) { 
    if (close) {
      if (cellEditor.isContentEditable) {
        
      }
      showBackground.remove();
      if (editingSplit) setMainTdEditedFromSplit(cellEdited);
      else setSplitTdEditedFromMain(cellEdited);
      
    } else {
      // need to display message with OK and Cancel, but not get rid of editor yet
    }
  } 
  
  InputElement getEditArea(int x, int y, int h, int w) {
    InputElement ie;

    // Let's keep the text area inside the table wrapper (at least horizontally)
    if (x < 0) {
      w += x;
      x = 0;
    }
    
    if (x + w > wrapper_0.clientWidth) {
      w -= (x + w - wrapper_0.clientWidth);
    }
    
    ie = cellUpdateHandler.getInputElement();
    
    ie.style
      ..position = 'absolute'
      ..left = x.toString() + 'px'
      ..top = y.toString() + 'px'
      ..height = h.toString() + 'px'
      ..maxHeight = h.toString() + 'px'
      ..width = w.toString() + 'px'
      ..maxWidth = w.toString() + 'px'
    ;
    
    return ie;
  }
  
  void openCell(Element td, bool split) {
    showBackground = getShowBackground();
    
    if (split) {
      cellEditor = getEditArea(td.offsetLeft - splitBodyWrapper_b.scrollLeft,
          td.offsetTop + splitHeaderWrapper_h.offsetHeight - splitBodyWrapper_b.scrollTop,td.offsetHeight,td.offsetWidth);      
    } else {
      cellEditor = getEditArea(td.offsetLeft - bodyWrapper_B.scrollLeft + splitTableWrapper_1.offsetWidth, 
          td.offsetTop + headerWrapper_H.offsetHeight - bodyWrapper_B.scrollTop,td.offsetHeight,td.offsetWidth);
    }        
    cellEditor.classes.add(CellEditingClass);
   
    showBackground.insertAdjacentElement('afterBegin', cellEditor);
    wrapper_0.insertAdjacentElement('afterBegin', showBackground);
  }
   
  Element getShowBackground() {
    Element background;
    background = new Element.div();

  setShowBackgroundSize(background);

    background.style
      ..position = 'absolute'
      ..left = '0px'
      ..top = '0px'
      ..zIndex = (int.parse(wrapper_0.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset + GrabberZIndexOffset).toString()
    ;    

    return background;
  }

  void setShowBackgroundSize(Element background) {
    background.style
      ..height = wrapper_0.clientHeight.toString() + 'px'
      ..width = wrapper_0.clientWidth.toString() + 'px'
    ;
  }
  
  bool validateEdit(Element td, String s) {
    bool ret = true;
    SuperTableDataType dataType;
    for (dataType in superTableDataTypes) {
      if (td.classes.contains(dataType.dataTypeName)) {
        if (! dataType.validate(s)) ret = false;
      }
    }
    return ret;
  }
  
  void setSplitTdEditedFromMain(Element mainTd) {
    // First find the row and column of the mainCell
    Element mainTr, splitTr, splitTd;
    String initdatapos, mainrowid, origCellValueString;
    SuperTableDataType dataType;
        
    if (! isSplit) return;
    
    dataType = getSuperTableDataTypeFromCell(mainTd);
    
    mainTr = mainTd.parent;
    mainrowid = mainTr.getAttribute(RowIdAttrName);
    initdatapos = mainTd.getAttribute(InitialDataPosAttrName);
    splitTr = splitBodyTable.querySelector('[' + RowIdAttrName + '="' + mainrowid + '"]');
    splitTd = splitTr.querySelector('[' + InitialDataPosAttrName + '="' + initdatapos + '"]');
    splitTd.text = mainTd.text;
    dataType = getSuperTableDataTypeFromCell(mainTd);
    if (dataType.storeDataValue) splitTd.setAttribute(CellValueAttrName,mainTd.getAttribute(CellValueAttrName));
    origCellValueString = mainTd.getAttribute(OrigCellValueAttrName);
    if (origCellValueString != null) splitTd.setAttribute(OrigCellValueAttrName,origCellValueString);
    if (mainTd.classes.contains(CellEditedClass)) splitTd.classes.add(CellEditedClass);
    else splitTd.classes.remove(CellEditedClass);
  }
  
  void setMainTdEditedFromSplit(Element splitTd) {
    // First find the row and column of the mainCell
    Element mainTr, splitTr, mainTd;
    String initdatapos, splitrowid, origCellValueString;
    SuperTableDataType dataType;
    
    splitTr = splitTd.parent;
    splitrowid = splitTr.getAttribute(RowIdAttrName);
    initdatapos = splitTd.getAttribute(InitialDataPosAttrName);    
    mainTr = table.querySelector('[' + RowIdAttrName + '="' + splitrowid + '"]');    
    mainTd = mainTr.querySelector('[' + InitialDataPosAttrName + '="' + initdatapos + '"]');    
    mainTd.text = splitTd.text;
    dataType = getSuperTableDataTypeFromCell(mainTd);
    if (dataType.storeDataValue) mainTd.setAttribute(CellValueAttrName,splitTd.getAttribute(CellValueAttrName));
    origCellValueString = splitTd.getAttribute(OrigCellValueAttrName);
    if (origCellValueString != null) mainTd.setAttribute(OrigCellValueAttrName,origCellValueString);
    if (splitTd.classes.contains(CellEditedClass)) mainTd.classes.add(CellEditedClass);
    else mainTd.classes.remove(CellEditedClass);
  }
  
  /*****************************************************************/
  /*****************************************************************/
  // End showStuff 
  /*****************************************************************/
  /*****************************************************************/
  // Begin computedFields
  /*****************************************************************/
  /*****************************************************************/
  void addComputedField(SuperTableComputedField computedField) {
    computedFields.add(computedField);
    computedField.refresh();
  }
  
  void computedFieldsFlipSelectedRow(Element tr, bool selected) {
    Debug('Enter computedFieldsFlipSelectedRow');
    SuperTableComputedField computedField;
    for (computedField in computedFields) {
      computedField.selectedRowFlippedTo(tr, selected);
    }
  }
  
  void computedFieldsSelectionChanged() {
    Debug('Enter computedFieldsSelectionChanged');
    SuperTableComputedField computedField;
    for (computedField in computedFields) {
      computedField.selectionChanged();
    }    
  }
  
  void computedFieldsRefresh() {
    Debug('Enter computedFieldsRefresh');
    SuperTableComputedField computedField;
    for (computedField in computedFields) {
      computedField.refresh();
    }       
  }
  
  /*****************************************************************/
  /*****************************************************************/
  // End computedFields
  /*****************************************************************/
  /*****************************************************************/
  // Begin tools
  /*****************************************************************/
  /*****************************************************************/
  SuperTableDataType getSuperTableDataTypeFromCell( Element cell ) {
    String initialDataPos, dataTypeString;
    Element column;
    initialDataPos = cell.getAttribute(InitialDataPosAttrName);
    column = getColumn(initialDataPos);
    dataTypeString = column.getAttribute(DataTypeAttrName);
    Debug("getSuperTableDataTypeFromCell dataTypeString= " + dataTypeString);
    return getSuperTableDataType(dataTypeString);
  }
  
  SuperTableDataType getSuperTableDataType(String dataType) {
    SuperTableDataType superTableDataType;
    for (superTableDataType in superTableDataTypes) {
      if ( superTableDataType.isType(dataType) ) {
        return superTableDataType;
      }
    }
    return null;
  }
  
  Element getColumn(String initialDataPos) {
    List<Element> cols;
    Element col;
    colGroup = table.querySelector('colgroup');
    cols = colGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(InitialDataPosAttrName) == initialDataPos) break;
    }
    return col;
  }
  
  int getColumnPositionByColumnClassName (String columnClassName) {
    List<Element> cols;
    Element col;
    int i = 1;  // First column is 1
    cols = colGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(ColumnClassAttrName) == columnClassName)
        break;
      i++;
    }
    return i;
  }
  
  // This need only be called once at the beginning of the page
  // For now it is called once per instance, but someone else 
  // could make it static.
  void getScrollbarThicks() {
    int noScroll, withScroll;

    Element outerdiv, innerdiv;
    String val1;
    outerdiv = new DivElement();
    innerdiv = new DivElement();

    innerdiv.style
      ..height = "100px"
      ..width = "100px";

    outerdiv.style
      ..width = "50px"
      ..height = "50px"
      ..overflow = "hidden"
      ..position = "absolute"
      ..top = "200px"
      ..left = "200px";
    
    outerdiv.insertAdjacentElement('afterBegin',innerdiv);

    document.body.children.add(outerdiv);
    noScroll = outerdiv.clientWidth;
    outerdiv.style.overflowY = 'auto';
    withScroll = outerdiv.clientWidth;
    
    VScrollBarThick = noScroll - withScroll;
    
    outerdiv.style.overflowY = 'hidden';
    
    noScroll = outerdiv.clientHeight;
    outerdiv.style.overflowX = 'auto';
    withScroll = outerdiv.clientHeight;
    HScrollBarThick = noScroll - withScroll;
    document.body.children.remove(outerdiv);
  }
  
  void removeBodyRows() {
    Element row;
    ElementList<Element> rows;
    rows = table.querySelectorAll('tbody > tr');
    Debug('rows.length=' + rows.length.toString());
    for (row in rows) {
      row.remove();
    }
  }
  
  int updateCounter = 0; // This ensure only the last update is done
  
  void refreshBodyFromHTMLRows(String tbodyContents, {NodeTreeSanitizer nodeTreeSanitizer} ) {
    int updateCounter;
    TableSectionElement tbodyDOM, tbody;
    Debug("Enter refreshBodyFromHTMLRows - tbodyContents=" + tbodyContents);
    updateCounter = ++ this.updateCounter;
    tbodyDOM = table.querySelector('tbody');
    tbody = tbodyDOM.clone(false);
    
    tbody.setInnerHtml(tbodyContents, treeSanitizer: nodeTreeSanitizer );
    
    _prepareNewRows(tbody).then((int value) {
      Debug("Start of _prepareNewRows - then before replaceWith");
      if (updateCounter == this.updateCounter) {
        tbodyDOM.replaceWith(tbody);
    
        Debug("refreshBodyFromHTMLRows - Reset all the computed fields");
        computedFieldsRefresh();
      
        if (isSplit) {
          Debug("refreshBodyFromHTMLRows - Need to clone the body and put in split");
          splitBodyTable.remove();
          splitBodyTable = table.clone(true);
          splitBodyWrapper_b.insertAdjacentElement('afterBegin',splitBodyTable);
        }
        resize();
      }
      Debug("End of _prepareNewRows then");
    });   
  }
  
  void refreshBodyFromDOM() {
    int updateCounter;
    TableSectionElement tbodyDOM, tbody;
    Debug("Enter refreshBodyFromDOM");
    updateCounter = ++ this.updateCounter;
    tbodyDOM = table.querySelector('tbody');
    tbody = tbodyDOM.clone(true);
    
    _prepareNewRows(tbody).then((int value) {
      
      if (updateCounter == this.updateCounter) {
        tbodyDOM.replaceWith(tbody);
  
        Debug("Reset all the computed fields");
        computedFieldsRefresh();
    
        if (isSplit) {
          Debug("Need to clone the body and put in split");
          splitBodyTable.remove();
          splitBodyTable = table.clone(true);
          splitBodyWrapper_b.insertAdjacentElement('afterBegin',splitBodyTable);
        }
        resize();
      }
    });
    
  }
  
  Future<int> _prepareNewRows(TableSectionElement tbody) {
    var completer = new Completer();
    prepareNewRows(tbody);
    completer.complete(0);
    
    return completer.future;
  }
  
  int prepareNewRows(TableSectionElement tbody) {
    List<Element> rows, cells, columns;
    int colpos, rowId = 1, cellPos;
    Element row, cell;
    Element column;
    String datatypename, cellValueText;
    
    Debug("Enter prepareNewRows");
    colpos = 1;
    columns = colGroup.querySelectorAll('col');
    // First step is to ensure the cell text is correctly formatted
    for (column in columns) {
      SuperTableDataType dataType;
      Object o;
      
      datatypename = column.getAttribute(DataTypeAttrName);
      dataType = getSuperTableDataType(datatypename);
      if (dataType.storeDataValue) {
        rows = tbody.querySelectorAll('tr');
        for (Element row in rows) {
          cells = row.querySelectorAll('td');
          cell = cells[colpos - 1];
          cell.classes.add(datatypename);
          cellValueText = cell.getAttribute(CellValueAttrName);
          if (cellValueText == null) {
            // Need to fill it in from the cell text
            o = dataType.parse(cell.text);
            cellValueText = dataType.save(o);
            cell.setAttribute(CellValueAttrName,cellValueText);
          } else {
            o = dataType.value(cellValueText);
          }
          cell.text = dataType.show(o);
        }
      }
      colpos++;
    }
    
    Debug("prepareNewRows - They must be in the order columns currently are when we start this");
    rows = tbody.querySelectorAll('tr');
    for (Element row in rows) {
      row.setAttribute(RowIdAttrName, rowId.toString());
      cells = row.querySelectorAll('td');
      for (column in columns) {
        colpos = int.parse(column.getAttribute(InitialDataPosAttrName));
        
        Debug('prepareNewRows - colpos=' + colpos.toString());
        cell = cells[colpos - 1];        
        cell.setAttribute(InitialDataPosAttrName, colpos.toString());        
        cell.classes.add(column.getAttribute(ColumnClassAttrName));
      }
      rowId++;
    }
    
    // We may need to reorder data to match columns when data are refreshed after 
    // the user has spent some time with moving columns around 
    if (rows.length > 1) { // If there are no data rows, or even just one row, just skip this entirely
      bool outoforder = true;
      int pos, i;
      int debugCount = 0;
      while (outoforder) {
        outoforder = false; // Now let's see if we get through the loop
        pos = 0;
        cells = rows[0].querySelectorAll('td'); // use this ae a prototype, get the newest since the last iteration
        for (column in columns) {
          colpos = int.parse(column.getAttribute(InitialDataPosAttrName));
          cellPos = int.parse(cells[pos].getAttribute(InitialDataPosAttrName));
          Debug('prepareNewRows colpos=' + colpos.toString() + ' cellPos=' + cellPos.toString());
          debugCount++;
          if (debugCount > 100) return 0;
          if (cellPos != colpos) {
            // They're not in the correct order
            // gotta find the correct data that should be here
            for (i = pos; i < columns.length; i++) {
              cellPos = int.parse(cells[i].getAttribute(InitialDataPosAttrName));
              if (cellPos == colpos) {
                // This is the one that should go in pos
                break;
              }
            }
            columnMoveMoveData(i + 1, pos);
            outoforder = true;
            break;
          }
          pos++;
          if (pos > 100) return 0; // Cheat exit for testing
        }
      }
    }
    Debug("Exit prepareNewRows");
    return 0;
  }
  
  void columnMoveMoveCell(TableSectionElement tbody, int movingColumnPos, int follows) {
    List<Element> rows;
    Element row, columnToMove, columnToFollow;
    Debug('columnMoveMoveCell moving=' + movingColumnPos.toString() + ' follows=' + follows.toString());
    rows = tbody.querySelectorAll('tr');
    for (row in rows) {
      columnToMove = row.querySelector('td:nth-of-type(' + movingColumnPos.toString() + ')');
      if (follows == 0) {
        row.insertAdjacentElement('afterBegin', columnToMove);
      } else {
        columnToFollow = row.querySelector('td:nth-of-type(' + follows.toString() + ')');
        columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
      }
    }    
  }
  
  // Call refreshBody after the cells are filled or refilled.
  @deprecated
  void refreshBody() {
    refreshBodyFromDOM();
  }
  
  void columnMoveMoveData(int movingColumnPos, int follows) {
    List<Element> rows;
    Element row, columnToMove, columnToFollow;
    Debug('columnMoveMoveData moving=' + movingColumnPos.toString() + ' follows=' + follows.toString());
    rows = table.querySelectorAll('tr');
    for (row in rows) {
      columnToMove = row.querySelector('td:nth-of-type(' + movingColumnPos.toString() + ')');
      if (follows == 0) {
        row.insertAdjacentElement('afterBegin', columnToMove);
      } else {
        columnToFollow = row.querySelector('td:nth-of-type(' + follows.toString() + ')');
        columnToFollow.insertAdjacentElement('afterEnd', columnToMove);
      }
    }    
  }

  String getHeaderCellText(Element th) {
    Element holder;
    holder = th.querySelector('.' + ColumnMoverHolderClass);
     
    return holder.text;
  }

  void Debug(String s) {
    if (debug) print('SuperTable ' + id + ' - ' + s);
  }
}

