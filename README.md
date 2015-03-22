# dart
Some dart functions for the browser to make HTML tables much more "toollike"

If you want to see the current state, go to http://normcf.com/supertabledemo/examples/example.html

The functions made so far:
 1. scroll vertically and horizontally with the body, header and footer staying together
 2. grab the right edge of any header and resize the column without affecting other column widths
 3. reorder columns by grabbing and dragging a header
 4. sort columns by double clicking on the header
 5. split the table into two views by grabbing the left edge of the table and dragging right
 6. select rows by clicking, shift clicking, or control clicking
 7. create computed values of selected rows which change as rows are un/selected
 8. resizing the wrapper will recalculate the need for scroll bars.
 9. caller can create a SaveAs button create a saved copy of the data.  The programmer can prompt the user if they want to include all rows, or just the selected rows.
    The programmer can prompt for the type of file to generate.  Currently CSV and FODS are supported, but the programmer can subclass and generate any format they need.
    The SaveAs creates the file locally and generates a URL for download.  No need to pass the file back to the server.
 10. click a cell twice to open editing, if editable, and full text selection.  Changed values are validated according to their data type.

Developer features:
 1.  can subclass the row selection class and have your own handler of clicks
 2.  Set up your own data types for setting a sort order
 3.  Add computed fields and subclass to generate as you need
 4.  All classes and attibute names have defaults but can be changed if you have name collisions
 5.  The sort function can be called with multiple rows in ascending, or decending order if simple single clicks are not sufficient.
 6.  Can subclass the cell datatypes to create your own datatypes, which are used by SaveAs. 

Some other dart functions are supplied.
 1. a tabview.  Lot's of these out there, but this one can scroll through tabs if there are more than the space allows.  It is also resizable.
 2. a layout program for laying out text and label fields.  This does all the calculations for positioning and sizing. 

Work in progress.  More clarity to be added later.


