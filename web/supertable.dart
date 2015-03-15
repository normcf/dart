// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library SuperTable;

import 'dart:html';
import 'dart:async';

import 'resizable.dart';

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
  bool debug = true;
  
  SuperTableSort(SuperTable this.table, List<String> columnClassNamesInSortKeyOrder, {this.debug}) {
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
    String cellData;
    Object cellValue;
    
    for (sortColumn in sortColumns) {
      // In order to avoid parsing data more than once, we'll cache them in SuperTableSortRow.sortItemValues
      if (row1.sortItemValues.length < sortKey) {
        Debug('Need to get the data row1 - position=' + sortColumn.position.toString());
        cellData = row1.row.querySelector('td:nth-of-type(' + sortColumn.position.toString() + ')').text;
        cellValue = sortColumn.columnDataType.parse(cellData);
        row1.sortItemValues.add(cellValue);
      }
      if (row2.sortItemValues.length < sortKey) {
        Debug('Need to get the data row2 - position=' + sortColumn.position.toString());
        cellData = row2.row.querySelector('td:nth-of-type(' + sortColumn.position.toString() + ')').text;
        cellValue = sortColumn.columnDataType.parse(cellData);
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
    if (debug) window.console.debug('SuperTableSort ' + s);
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
  static const String UNKNOWNDATATYPE = 'Unknown'; 
  String dataTypeName = UNKNOWNDATATYPE;
  String exportDataTypeName = UNKNOWNDATATYPE;
  
  bool isType(String s) { return s == dataTypeName; }
  int compare (Object o1, Object o2);
  Object parse (Object o);
  bool validate(Object o);
}

class SuperTableDataTypeText extends SuperTableDataType {
  SuperTableDataTypeText() {
    dataTypeName = 'text';
    exportDataTypeName = 'text';
  }
  int compare (String o1, String o2) {
    return o1.compareTo(o2);
  }
  String parse(String s) {
    return s;
  }
  bool validate(String s){ return true; }
}

class SuperTableDataTypeMoney extends SuperTableDataType {
  SuperTableDataTypeMoney() {
    dataTypeName = 'money';
    exportDataTypeName = 'money';
  }
  int compare (double o1, double o2) {
    return o1.compareTo(o2);
  }
  double parse (String s) {
    return double.parse(s, (_) => 0.0);
  }
  bool validate(String s) {
    bool ret = true;
    // hmmm, must be parseable
    double.parse(s, (_) { ret = false; return 0.0; });
    return ret;
  }
}

class SuperTableDataTypeInteger extends SuperTableDataType {
  SuperTableDataTypeInteger() {
    dataTypeName = 'integer';
    exportDataTypeName = 'integer';
  }
  int compare (int o1, int o2) {
    return o1.compareTo(o2);
  }
  int parse (String s) {
    return int.parse(s, onError: (_) => 0);
  }
  bool validate(String s) {
    bool ret = true;
    // hmmm, must be parseable
    int.parse(s, onError: (_) { ret = false; return 0.0; });
    return ret;
  }
}

class SuperTableDataTypeDateTime extends SuperTableDataType {
  SuperTableDataTypeDateTime() {
    dataTypeName = 'datetime';
    exportDataTypeName = 'datetime';
  }
  int compare (DateTime o1, DateTime o2) {
    return o1.compareTo(o2);
  }
  DateTime parse (String s) {
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
}

class SuperTableDataTypeDate extends SuperTableDataType {
  SuperTableDataTypeDate() {
    dataTypeName = 'date';
    exportDataTypeName = 'date';
  }
  int compare (DateTime o1, DateTime o2) {
    return o1.compareTo(o2);
  }
  DateTime parse (String s) {
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
    
  // Want to add a flip split row function in th ebase class for all of them to call
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
    if (debug) window.console.debug(s);
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
  FileSystem _filesystem;
  
  SuperTableSaveAs({this.debug}) { }
  
  AnchorElement saveAs(SuperTable table);
  
  // Because the text was moved into a div below for column mover
  String getHeaderCellText(SuperTable table, Element th) {    
    return table.getHeaderCellText(th);
  }
  
  void Debug(String s) {
    if (debug) window.console.debug('SuperTableSaveAs ' + s);
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
    
    // Need o figure out how much space we really need
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
      sb.write(buildRow(tr));
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
  
  String buildRow(Element row) {
    StringBuffer sb = new StringBuffer();
    Element td;
    List<Element> tds;
    
    // Note: columns will be in their current order, not their original order
    tds = row.querySelectorAll('td');
    for (td in tds) {
      // What if the cell contins more than just text, like an <a> ??
      // We'll look at that later.
      if (sb.length > 0) sb.write(delim); // No leading delimiter
      sb.write(cleanse(td.text));
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
  int sum = 0;
  
  SuperTableComputedFieldColumnIntSum(SuperTable table, String targetColumnClass, [int mode] ) : super(table, targetColumnClass, mode) {}
  
  void selectedRowFlippedTo(Element row, bool selected) {
    sum += ((selected) ? 1 : -1) * getColumnValue(row);
  }
  
  void selectionChanged() {
    // Need to find the footer record with the targetColumnClass and update it
    Element td;
    td = table.footerTable.querySelector('.' + targetColumnClass);
    td.text = sum.toString();
    if (table.isSplit) {
      td = table.splitFooterTable.querySelector('.' + targetColumnClass);
      td.text = sum.toString();
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
    val = int.parse(cell.text, onError: (_) => 0);
    
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
  String name;
  
  SuperTableCellUpdateHandler(String this.name){}
  
  // Override if you need to do something immediatly before an update attempt
  preUpdate(Element e) {}
  
  // Must define this action.  Will be called only if data changes
  update(Element e); 
  
  // Override if you need to do any cleanup after an update attempt
  postUpdate(Element e){}
}

// Not a really useful example of how to use this, but at least you can see it hapenning.
// Note that a preValue of the cell contents is saved here.  If you have two, or more, tables on your page,
// in order to prevent conflict on this variable, be sure to instantiate one of these for each table.
// Also, note that this is also called from the cloned split table editing.  Clone seems to copy ids too, 
// so an id on a table element may not be unique in your document.
class SuperTableCellUpdateHandlerLogChange extends SuperTableCellUpdateHandler {
  String preValue;
  SuperTableCellUpdateHandlerLogChange(String name) : super(name) {}
  
  @override
  preUpdate(Element e) {
    preValue = e.text;
  }
  update(Element e) {
    window.console.log("Data in cell changed from '" + preValue + "' to '" + e.text + "'");
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
  static const String CONTAINERCLASSNAME       = 'tablescroll_wrapper';
  static const String BODYTABLECLASS           = 'superTableBody';
  static const String HEADERTABLECLASS         = 'superTableHeader';
  static const String FOOTERTABLECLASS         = 'superTableFooter';
  
  static const String INITIALWIDTHATTRNAME     = 'initwidth';
  static const String INITIALDATAPOSATTRNAME   = 'initdatapos';
  static const String ROWIDATTRNAME            = 'RowId';
  static const String DATATYPEATTRNAME         = 'datatype';
  static const String SUPERTABLEPREFIX         = 'super';
  static const String COLUMNCLASSNAME          = 'ColumnClass';
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
  static const int    MINCOLUMNWIDTH           = 5;
  static const int    MINMAINWIDTH             = 100;
  static const int    SPLITGRABBERWIDTH        = 5;
  static const int    GRABBERZINDEXOFFSET      = 10;
  static const String NECESSARYTABLESTYLE      = 'table-layout:fixed;';

  // Override these if you need to use different class names in your code
  String ContainerClassName = CONTAINERCLASSNAME;
  String BodyTableClass = BODYTABLECLASS;
  String HeaderTableClass = HEADERTABLECLASS;
  String FooterTableClass = FOOTERTABLECLASS;
  String InitialWidthAttrName = INITIALWIDTHATTRNAME;
  String InitialDataPosAttrName = INITIALDATAPOSATTRNAME;
  String RowIdAttrName = ROWIDATTRNAME;
  String DataTypeAttrName = DATATYPEATTRNAME;
  String SuperTablePrefix = SUPERTABLEPREFIX;
  String ColumnClassName = COLUMNCLASSNAME;
  String ColumnResizeGrabberClass = COLUMNRESIZEGRABBERCLASS;
  String ColumnMoverHolderClass = COLUMNMOVERHOLDERCLASS;
  String SplitGrabberClass = SPLITGRABBERCLASS;
  String SelectedRowClass = SELECTEDROWCLASS;
  String ShowStuffClass = SHOWSTUFFCLASS;
  String CellEditableClass = CELLEDITABLECLASS;
  String CellNotEditableClass = CELLNOTEDITABLECLASS;
  String CellEditedClass = CELLEDITEDCLASS;
  String CellEditingClass = CELLEDITINGCLASS;
  String CellUpdateHandlerAttrName = CELLUPDATEHANDLERATTRNAME;
  int    SplitGrabberWidth = SPLITGRABBERWIDTH;
  int    GrabberZIndexOffset = GRABBERZINDEXOFFSET;
  SuperTableRowSelectPolicy rowSelectPolicy;
  int MinColumnWidth = MINCOLUMNWIDTH; // If you change this, you may want to change the CSS too.
  int MinMainWidth = MINMAINWIDTH; // When you split the table, at least this much must be visible, but breaks if table smaller than 100
    
  int VScrollBarThick, HScrollBarThick; // need only be set once.  Someone else can make them static
  StreamSubscription<Event> scroller, splitScroller, splitter;
  StreamSubscription<Event> resizer; // attempt to make the resize get called by window resizing, but not yet!!
  List<SuperTableComputedField> computedFields;
  List<SuperTableCellUpdateHandler> cellUpdateHandlers;
  List<SuperTableSaveAs> saveAsCreators;
  
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
  Element showBackground, cellEdited;
  TextAreaElement cellEditor;
  SuperTableCellUpdateHandler cellUpdateHandler;
  // End showStuff
  
  SuperTable.presizedContainer(String this.id) {
    computedFields = new List<SuperTableComputedField>();
    cellUpdateHandlers = new List<SuperTableCellUpdateHandler>();
    saveAsCreators = new List<SuperTableSaveAs>();
    saveAsCreators.add(new SuperTableSaveAsCSV()); // We'll force in a CSV saver, but user can remove before calling init.
    table = document.querySelector('#' + id);
    table.classes.add(id);
  }
        
  void init() {
    firsttime();
    prepareMain();
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
      tfoot = table.querySelector('tfoot');
      footerTable.insertAdjacentElement('afterBegin', tfoot);
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
    mainHolder_3.classes.add('mainHolder');
    
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
    
//    resizer = document.onResize.listen(null);
//    resizer.onData((Event) { reShape(); }); 

    // Now reshape pieces that can change when columns or table are resized or split changed
    resize();

//    resizer = window.onResize.listen(null);
//    resizer.onData((Event) { Debug("resizing on event"); resize(); });
    
    //wrapper_0.on
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
      col.setAttribute(ColumnClassName,colClass);
      col.setAttribute(InitialDataPosAttrName, columnPos.toString());  //If columns are reordered, this will allow finding data refreshed.
            
      swidth = col.getAttribute(InitialWidthAttrName);
      rule = '.' + colClass + ' { max-width:' + swidth + 'px; min-width:' + swidth + 'px;}';
      sheet.insertRule(rule,columnPos - 1);
      
      dataType = col.getAttribute(DataTypeAttrName);
      th = table.querySelector('th:nth-of-type(' + columnPos.toString() + ')');
      th.classes.add(colClass); th.classes.add(dataType);
      th.setAttribute(ColumnClassName, colClass);
      headerContent = th.innerHtml;
      th.innerHtml = '';
      
      resizerGrabberDiv = new Element.div();
      resizerGrabberDiv
        ..style.position = 'absolute'
        ..style.height = '100%'
        ..style.top = '0px'
        ..classes.add(ColumnResizeGrabberClass)
        ..setAttribute(ColumnClassName, colClass)
        ..setAttribute(InitialDataPosAttrName, columnPos.toString())
        ..style.zIndex = (int.parse(th.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset).toString();
      
      resizerHolderDiv = new Element.div();
      resizerHolderDiv
        ..style.position = 'relative'
        ..style.height = '100%'
        ..style.width = '100%'
        ..classes.add(ColumnMoverHolderClass)
        ..setAttribute(ColumnClassName, colClass)
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
         td.setAttribute(ColumnClassName, colClass);
         // Theoretically, we could add resizers to the footer too.
      }
          
      columnPos++;
    }
    
    // Set up row selection events
    if (rowSelectPolicy == null) rowSelectPolicy = new SuperTableRowSelectPolicyNormal(this);
    table.onClick.listen(rowSelectPolicy.rowSelect);
    table.onClick.listen(cellSelect);
    // This goes through the data rows.  If the data are later updated, then recall refreshBody.
    refreshBody();
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
    Debug('columnSort target=' + target.text + ' classname=' + target.getAttribute(ColumnClassName).toString());
    // Need to find movingColumn
    String columnClassName = target.getAttribute(ColumnClassName);
    List<String> classNames;
    classNames = new List<String>();
    classNames.add(columnClassName + ':' + ((lastSortAscending) ? 'D' : 'A'));
    lastSortAscending = ! lastSortAscending;
    SuperTableSort sorter;
    sorter = new SuperTableSort(this,classNames, debug: true);
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
    Debug('startSplitColumnMove target=' + target.text + ' classname=' + target.getAttribute(ColumnClassName).toString());
    // Need to find movingColumn
    String columnClassName = target.getAttribute(ColumnClassName);
    List<Element> cols;
    Element col;
    cols = splitColGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(ColumnClassName) == columnClassName) {
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
    Debug('startColumnMove target=' + target.text + ' classname=' + target.getAttribute(ColumnClassName).toString());
    // Need to find movingColumn
    String columnClassName = target.getAttribute(ColumnClassName);
    List<Element> cols;
    Element col;
    cols = colGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(ColumnClassName) == columnClassName) {
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
      if ((pos.y > wrapper_0.offsetTop) && (pos.y < wrapper_0.offsetTop + wrapper_0.offsetHeight)) {
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
      }
       
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
    int movingColumnPos = getColumnPositionByColumnClassName(movingColumn.getAttribute(ColumnClassName));
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
    columnClassName = movingColumn.getAttribute(ColumnClassName);
    colPosition = getColumnPositionByColumnClassName(columnClassName);
    // First the header
    th = headerTable.querySelector('th:nth-of-type(' + colPosition.toString() + ')');
    // BUT, we don't want the resizing/moving divs
    td = th.querySelector('.' + ColumnMoverHolderClass);
    Debug('startColumnMove header text=' + td.text);
    Debug('startColumnMove colClass=' + columnClassName);
    tablestuff = '<thead><tr><th class="' + columnClassName + '">' + td.text + '</th></tr></thead>';
    tablestuff += '<tbody>';
    
    rows = table.querySelectorAll('tr');
    for (row in rows) {
      cell = row.querySelector('td:nth-of-type(' + colPosition.toString() + ')');
      tablestuff += '<row><td class="' + columnClassName + '">' + cell.text + '</td></tr>';
      if (rowcount > 5) break; // Just do the first 5 rows for now.  Later we will figure out the number of rows in the scroll area
      rowcount++;
    }
    tablestuff += '</tbody>';
    
    docx = th.offsetLeft;
    draggingView = new Element.table();
    draggingView
      ..classes.add(BodyTableClass)
      ..classes.add('movingColumnTable')
      ..insertAdjacentHtml('afterBegin', tablestuff)
      ..style.tableLayout = 'fixed'
      ..style.whiteSpace = "nowrap"
      ..style.position = "absolute"
      ..style.left = docx.toString() + 'px'
      ..style.top = th.documentOffset.y.toString() + 'px'
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
    Debug('colclass=' + p.getAttribute(ColumnClassName).toString());
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
    resizingClass = p.getAttribute(ColumnClassName);
    List<Element> cols = colGroup.querySelectorAll('col');
    Element col;
    for (col in cols) {
      if (col.getAttribute(ColumnClassName) == resizingClass) {
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
    Debug("Enter cellSelect.hashCode=" + cellEdited.hashCode.toString() + ' e.target.hashCode=' + e.target.hashCode.toString());
    if (cellEdited.hashCode == e.target.hashCode) {
      String cellUpdateHandlerName;
      cellUpdateHandlerName = cellEdited.getAttribute(CellUpdateHandlerAttrName);
      if (cellUpdateHandlerName != null) {
        // OK, a handler is named, let's find it.  Linear search should be good enough.
        for (cellUpdateHandler in cellUpdateHandlers) {
          if (cellUpdateHandler.name == cellUpdateHandlerName) break;
        }
        if (cellUpdateHandler != null) cellUpdateHandler.preUpdate(cellEdited);
      }
      // OK, now get the main table row and pass it in
      openCell(cellEdited, true);
      
      // Now need to register an event to 
      StreamSubscription<Event> undo = showBackground.onClick.listen(null);
      undo.onData(endSplitCellEdit); 
    } else {
      cellEdited = e.target;
    }
  }
  
  void endSplitCellEdit(MouseEvent e) {
    // If the cell was editable, need to put the new data in place.
    if (e.target != cellEditor) {
      Debug("cellEditor.isContentEditable=" + cellEditor.isContentEditable.toString());
      if (cellEditor.isContentEditable) {
        Debug("cellEditor.text=" + cellEditor.value);
        if (cellEdited.text != cellEditor.value) {
          if (validateEdit(cellEdited,cellEditor.value)) {
            cellEdited.text = cellEditor.value;
            cellEdited.classes.add(CellEditedClass);
            if (cellUpdateHandler != null) cellUpdateHandler.update(cellEdited);
            tableEditCount++;
            if (isSplit) {
              setMainTdEditedFromSplit(cellEdited);
            }  
            showBackground.remove();
          } else {
            showBackground.remove();
            Element msg;
            msg = new Element.div();
            msg.text = 'Changed value is not valid.  Change Ignored.';
            showStuff(msg);
          }        
        } else showBackground.remove();
      } else showBackground.remove();
    }
    if (cellUpdateHandler != null) cellUpdateHandler.postUpdate(cellEdited);
  }
  
  void cellSelect(MouseEvent e) {   
    Debug("Enter cellSelect.hashCode=" + cellEdited.hashCode.toString() + ' e.target.hashCode=' + e.target.hashCode.toString());
    if (cellEdited.hashCode == e.target.hashCode) {
      // If there is a CellEditUpdateAttrName then need to look for an update handler
      String cellUpdateHandlerName;
      cellUpdateHandlerName = cellEdited.getAttribute(CellUpdateHandlerAttrName);
      if (cellUpdateHandlerName != null) {
        // OK, a handler is named, let's find it.  Linear search should be good enough.
        for (cellUpdateHandler in cellUpdateHandlers) {
          if (cellUpdateHandler.name == cellUpdateHandlerName) break;
        }
        if (cellUpdateHandler != null) cellUpdateHandler.preUpdate(cellEdited);
      }
      // OK, now get the main table row and pass it in
      openCell(cellEdited, false);
      
      // Now need to register an event to 
      StreamSubscription<Event> undo = showBackground.onClick.listen(null);
      undo.onData(endCellEdit); 
    } else {
      cellEdited = e.target;
    }
  }

  void endCellEdit(MouseEvent e) {
    // If the cell was editable, need to put the new data in place.
    if (e.target != cellEditor) {
      Debug("cellEditor.isContentEditable=" + cellEditor.isContentEditable.toString());
      if (cellEditor.isContentEditable) {
        Debug("cellEditor.text=" + cellEditor.value);
        if (cellEdited.text != cellEditor.value) {
          if (validateEdit(cellEdited,cellEditor.value)) {
            cellEdited.text = cellEditor.value;
            cellEdited.classes.add(CellEditedClass);
            if (cellUpdateHandler != null) cellUpdateHandler.update(cellEdited);
            tableEditCount++;
            if (isSplit) {
              setSplitTdEditedFromMain(cellEdited);
            }  
            showBackground.remove();
          } else {
            showBackground.remove();
            Element msg;
            msg = new Element.div();
            msg.text = 'Changed value is not valid.  Change Ignored.';
            showStuff(msg);
          }        
        } else showBackground.remove();
      } else showBackground.remove();
      
      if (cellUpdateHandler != null) cellUpdateHandler.postUpdate(cellEdited);
    }
  }
  
  TextAreaElement getEditArea(int x, int y, int h, int w) {
    TextAreaElement ta;

    // Let's keep the text area inside the table wrapper (at least horizontally)
    if (x < 0) {
      w += x;
      x = 0;
    }
    
    if (x + w > wrapper_0.clientWidth) {
      w -= (x + w - wrapper_0.clientWidth);
    }
    
    ta = new TextAreaElement();
    
    ta.style
      ..position = 'absolute'
      ..left = x.toString() + 'px'
      ..top = y.toString() + 'px'
      ..height = h.toString() + 'px'
      ..maxHeight = h.toString() + 'px'
      ..width = w.toString() + 'px'
      ..maxWidth = w.toString() + 'px'
    ;
    
    return ta;
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
    cellEditor.text = td.text;
    
    if (td.classes.contains(CellEditableClass)) {
      cellEditor.contentEditable = "true";
      cellEditor.readOnly = false;
    } else if (td.classes.contains(CellNotEditableClass)) {
      cellEditor.contentEditable = "false";
      cellEditor.readOnly = true;
    } else if (defaultCellEditable) {
      cellEditor.contentEditable = "true";
      cellEditor.readOnly = false;
    } else {
      cellEditor.contentEditable = "false";
      //cellEditor.setAttribute('readonly','true');
      cellEditor.readOnly = true;
    }
    showBackground.insertAdjacentElement('afterBegin', cellEditor);
    wrapper_0.insertAdjacentElement('afterBegin', showBackground);
  }
   
  Element getShowBackground() {
    Element background;
    background = new Element.div();
    
    background.style
      ..position = 'absolute'
      ..left = '0px'
      ..top = '0px'
      ..height = wrapper_0.clientHeight.toString() + 'px'
      ..width = wrapper_0.clientWidth.toString() + 'px'
      ..zIndex = (int.parse(wrapper_0.style.zIndex,onError: (_) => 0) + GrabberZIndexOffset + GrabberZIndexOffset).toString()
    ;    
    return background;
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
    String initdatapos, mainrowid;
    
    mainTr = mainTd.parent;
    mainrowid = mainTr.getAttribute(RowIdAttrName);
    initdatapos = mainTd.getAttribute(InitialDataPosAttrName);
    splitTr = splitBodyTable.querySelector('[' + RowIdAttrName + '="' + mainrowid + '"]');
    splitTd = splitTr.querySelector('[' + InitialDataPosAttrName + '="' + initdatapos + '"]');
    splitTd.text = mainTd.text;
    splitTd.classes.add(CellEditedClass);
  }
  
  void setMainTdEditedFromSplit(Element splitTd) {
    // First find the row and column of the mainCell
    Element mainTr, splitTr, mainTd;
    String initdatapos, splitrowid;
    
    splitTr = splitTd.parent;
    splitrowid = splitTr.getAttribute(RowIdAttrName);
    initdatapos = splitTd.getAttribute(InitialDataPosAttrName);    
    mainTr = table.querySelector('[' + RowIdAttrName + '="' + splitrowid + '"]');    
    mainTd = mainTr.querySelector('[' + InitialDataPosAttrName + '="' + initdatapos + '"]');    
    mainTd.text = splitTd.text;
    mainTd.classes.add(CellEditedClass);
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
    SuperTableComputedField computedField;
    for (computedField in computedFields) {
      computedField.selectedRowFlippedTo(tr, selected);
    }
  }
  
  void computedFieldsSelectionChanged() {
    SuperTableComputedField computedField;
    for (computedField in computedFields) {
      computedField.selectionChanged();
    }    
  }
  
  void computedFieldsRefresh() {
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
 
  int getColumnPositionByColumnClassName (String columnClassName) {
    List<Element> cols;
    Element col;
    int i = 1;  // First column is 1
    cols = colGroup.querySelectorAll('col');
    for (col in cols) {
      if (col.getAttribute(ColumnClassName) == columnClassName)
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
  
  // Call refreshBody after the cells are filled or refilled.
  void refreshBody() {
    List<Element> rows, cells, columns;
    int colpos, rowId = 1, cellPos;
    Element row, cell;
    Element column;
    
    columns = colGroup.querySelectorAll('col');
    
    // They must be in the order columns currently are when we start this    
    rows = table.querySelectorAll('tbody > tr');
    for (Element row in rows) {
      row.setAttribute(RowIdAttrName, rowId.toString());
      cells = row.querySelectorAll('td');
      colpos = 0;
      for (column in columns) {
        colpos = int.parse(column.getAttribute(InitialDataPosAttrName));
        cell = cells[colpos - 1];
        cell.setAttribute(InitialDataPosAttrName, colpos.toString());
        cell.classes.add(column.getAttribute(DataTypeAttrName)); 
        cell.classes.add(column.getAttribute(ColumnClassName));
        colpos++; // For now we will not check the data for missing cells
      }
      rowId++;
    }
    
    // We may need to reorder data to match columns when data are refreshed after 
    // the user has spent some time with moving columns around 
    if (rows.length > 0) { // If there are no data rows, just skip this entirely
      bool outoforder = true;
      int pos, i;
      while (outoforder) {
        outoforder = false; // Now let's see if we get through the loop
        pos = 0;
        cells = rows[0].querySelectorAll('td'); // use this ae a prototype, get the newest since the last iteration
        for (column in columns) {
          colpos = int.parse(column.getAttribute(InitialDataPosAttrName));
          cellPos = int.parse(cells[pos].getAttribute(InitialDataPosAttrName));
          Debug('colpos=' + colpos.toString() + ' cellPos=' + cellPos.toString());
          if (cellPos != colpos) {
            // They're not in the correct order
            // gotta find the correct data that should be here
            for (i = pos; i < columns.length; i++) {
              cellPos = int.parse(cells[i].getAttribute(InitialDataPosAttrName));
              if (cellPos == colpos) {
                // This is the one that shoud go in pos
                break;
              }
            }
            columnMoveMoveData(i, pos);
            outoforder = true;
            break;
          }
          pos++;
        }
      }
    }
    
    // Reset all the computed fields
    computedFieldsRefresh();
    
    if (isSplit) {
      // Need to clone the body and put in split
      splitBodyTable = table.clone(true);
    }

  }
  
  void columnMoveMoveData(int movingColumnPos, int follows) {
    List<Element> rows;
    Element row, columnToMove, columnToFollow;
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
    if (debug) window.console.debug('SuperTable ' + s);
  }
}

