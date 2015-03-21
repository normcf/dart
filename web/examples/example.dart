// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a LGPL-style license that can be found in the LICENSE file.

import 'dart:html';

import '../supertable.dart';
import '../chunkfitlayout.dart';
import '../supertabview.dart';
import '../supertablesaveasfods.dart';

void main() {
  //t1 = new SuperTable.presizedContainer('testtable1');
  SuperTable t1, t2;
  
  t1 = new SuperTable.presizedContainer('testtable1'); t1.debug = true; t1.init();
  SuperTableCellUpdateHandlerLogChange l1;
  l1 = new SuperTableCellUpdateHandlerLogChange("Log"); // See the attribute on one of the editable fields
  t1.cellUpdateHandlers.add(l1); // Add this update handler to the list.  Note: instantiate one of these for each table you need it for.
  
  t2 = new SuperTable.presizedContainer('testtable2'); t2.init();
  
  SuperTableComputedField t2counter = new SuperTableComputedFieldCount(t2,t2.generateColClassName(1),SuperTableComputedField.MODESELECTED);
  t2.debug = true;
  t2.addComputedField(t2counter);
  
  SuperTableComputedField t2years = new SuperTableComputedFieldColumnIntSum(t2,t2.generateColClassName(2),SuperTableComputedField.MODESELECTED);
  t2.addComputedField(t2years);
  //t1.getScrollbarWidth();
  var clicker;
  Element button, test1;
  
  button = document.querySelector('#vplus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; t1.wrapper_0.style.height = (t1.wrapper_0.clientHeight + d).toString() + 'px'; t1.resize(); } );
  
  button = document.querySelector('#vminus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; t1.wrapper_0.style.height = (t1.wrapper_0.clientHeight - d).toString() + 'px'; t1.resize(); } );
  
  button = document.querySelector('#hplus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; t1.wrapper_0.style.width = (t1.wrapper_0.clientWidth + d).toString() + 'px'; t1.resize(); } );
  
  button = document.querySelector('#hminus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; t1.wrapper_0.style.width = (t1.wrapper_0.clientWidth - d).toString() + 'px'; t1.resize(); } );

  button = document.querySelector('#split');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent) { t1.createSplitView(); t1.changeSplitWidth(100); t1.reShape(); } );
  
  button = document.querySelector('#saveAs');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent) { AnchorElement link; SuperTableSaveAsCSV s = new SuperTableSaveAsCSV(); link = s.saveAs(t1); t1.showStuff(link) ;} );
  //SuperTableSaveAsCSV
  
  button = document.querySelector('#saveAsFods');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent) { AnchorElement link; SuperTableSaveAsFODS s = new SuperTableSaveAsFODS(); link = s.saveAs(t1); t1.showStuff(link) ;} );
  

  test1 = document.querySelector("#test1");
  window.console.debug('t1' +
      ' offsetTop=' + t1.mainHolder_3.offsetTop.toString() +
      ' offsetHeight=' + t1.mainHolder_3.offsetHeight.toString() +
      ' offsetLeft=' + t1.mainHolder_3.offsetLeft.toString() +
      ' offsetWidth=' + t1.mainHolder_3.offsetWidth.toString() + '');
      
  window.console.debug('t1' +
      ' clientTop=' + t1.mainHolder_3.clientTop.toString() +
      ' clientHeight=' + t1.mainHolder_3.clientHeight.toString() +
      ' clientLeft=' + t1.mainHolder_3.clientLeft.toString() +
      ' clientWidth=' + t1.mainHolder_3.clientWidth.toString() + '');

  window.console.debug('test1 ' +
      ' offsetLeft=' + test1.offsetLeft.toString() +
      ' offsetWidth=' + test1.offsetWidth.toString() +
      ' offsetTop=' + test1.offsetTop.toString() +
      ' offsetHeight=' + test1.offsetHeight.toString() +
      ' clientLeft=' + test1.clientLeft.toString() +
      ' clientWidth=' + test1.clientWidth.toString() +
      ' clientTop=' + test1.clientTop.toString() +
      ' clientHeight=' + test1.clientHeight.toString() );
  
  test1 = document.querySelector("#test2");
  window.console.debug('test2 ' +
      ' offsetLeft=' + test1.offsetLeft.toString() +
      ' offsetWidth=' + test1.offsetWidth.toString() +
      ' offsetTop=' + test1.offsetTop.toString() +
      ' offsetHeight=' + test1.offsetHeight.toString() +
      ' clientLeft=' + test1.clientLeft.toString() +
      ' clientWidth=' + test1.clientWidth.toString() +
      ' clientTop=' + test1.clientTop.toString() +
      ' clientHeight=' + test1.clientHeight.toString() );
 //querySelector('#output').text = 'Dart is running 3.';
  
  Element cflHolder = document.querySelector('#chunkFitTest');
  
  ChunkFitLayout cfl = new ChunkFitLayout('chunkFitTest');
  cfl.addId('label1').addId('text1')
     .addId('label2').addId('text2')
     .addId('label3').addId('text3');
  
  Size size0 = new Size.id("label1",Size.VERTICAL);
  size0.addId('label1').addId('text1')
    .addId('label2').addId('text2')
    .addId('label3').addId('text3'); 
  cfl.changes.add(size0);
  
  Align alignh1 = new Align.element(cflHolder.querySelector('#label1'),Align.TOP);
  alignh1.addId('text1');
  cfl.changes.add(alignh1);

  Space space1 = new Space.id('label1',Space.RIGHT);
  space1.addId('text1');
  cfl.changes.add(space1);

  Space space2 = new Space.id('text1',Space.DOWN);
  space2.addId('text2').addId('text3');
  cfl.changes.add(space2);

  Align align1 = new Align.id('label1',Align.RIGHT);
  align1.addId('label2').addId('label3');
  cfl.changes.add(align1);
  
  Align align2 = new Align.id('text1',Align.LEFT);
  align2.addId('text2').addId('text3');
  cfl.changes.add(align2);
  
  Align alignh2 = new Align.id('text2',Align.TOP);
  alignh2.addId('label2');
  cfl.changes.add(alignh2);
  
  Align alignh3 = new Align.id('text3',Align.TOP);
  alignh3.addId('label3');
  cfl.changes.add(alignh3);
  
  Chunk chunk1 = new Chunk(Chunk.NONE);
  chunk1.name = "chunk1";
  chunk1.addId('label1').addId('text1')
  .addId('label2').addId('text2')
  .addId('label3').addId('text3');
  cfl.changes.add(chunk1);

  // Now let's build chunk 2 and fit the two chunks together
  cfl.addId('labela1').addId('texta1') // Don't forget to add them to the layout.
    .addId('labela2').addId('texta2')
    .addId('labela3').addId('texta3')
    .addId('labela4').addId('texta4'); 
  
  size0.addId('labela1').addId('texta1')
    .addId('labela2').addId('texta2')
    .addId('labela3').addId('texta3')
    .addId('labela4').addId('texta4'); 
  
  Space spacea1 = new Space.id('labela1',Space.RIGHT); 
  spacea1.addId('texta1'); // Now texta1 comes immediately right of labela1 
  cfl.changes.add(spacea1);
  
  Align aligna1 = new Align.element(cflHolder.querySelector('#labela1'),Align.RIGHT);
  aligna1.addId('labela2').addId('labela3').addId('labela4');
  cfl.changes.add(aligna1);
  
  Align aligna2 = new Align.id('texta1',Align.LEFT);
  aligna2.addId('texta2').addId('texta3').addId('texta4');
  cfl.changes.add(aligna2);
 
  
  // We'll align the rest of the rows
  alignh1.addId('labela1').addId('texta1'); // Here we set the field in the second chunk in line with the first chunk, 
  alignh2.addId('labela2').addId('texta2'); // But we could have spaced then out, even if different from the first
  alignh3.addId('labela3').addId('texta3'); // chunk spacing.

  // Because there is nothing in the first chunk to align labela4 and texta4 to, we will need to space them down
  Space spacea2 = new Space.id('texta3',Space.DOWN); 
  spacea2.addId('texta4');
  cfl.changes.add(spacea2);
  
  // Now vertically align texta4 to labela4
  Align alignh4 = new Align.id('texta4',Align.TOP);
  alignh4.addId('labela4');
  cfl.changes.add(alignh4);
  
  Size size1 = new Size.id('texta2', Size.HORIZONTAL);
  size1.addId('texta3').addId('texta4');
  cfl.changes.add(size1);
  
  // No fit the chunks together
  Chunk chunk2 = new Chunk(Chunk.RIGHT);
  chunk2.name = "chunk2";
  chunk2.addId('labela1').addId('texta1') // Don't forget to add them to the layout.
  .addId('labela2').addId('texta2')
  .addId('labela3').addId('texta3')
  .addId('labela4').addId('texta4');
  cfl.changes.add(chunk2);
  
  cfl.layout();
 
  SuperTable t3;
  t3 = new SuperTable.presizedContainer('tabbedtable'); t3.init();
   
  SuperTabView tv1;
  tv1 = new SuperTabView.id("tabs1");
  PlainContentTabHandler tab;
  SuperTableTabHandler sttab;
  tab = new PlainContentTabHandler.id(tv1,'tab1'); 
  tab = new PlainContentTabHandler.id(tv1,'tab2');
  tab = new PlainContentTabHandler.id(tv1,'tab3'); 
  tab = new PlainContentTabHandler.id(tv1,'tab4'); 
  tab = new PlainContentTabHandler.id(tv1,'tab5'); 
  sttab = new SuperTableTabHandler.id(tv1,'tab6',t3); 
  tab = new PlainContentTabHandler.id(tv1,'tab7'); 
  tab = new PlainContentTabHandler.id(tv1,'tab8'); 
  
   
  //testtabview1
  button = document.querySelector('#tvplus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; tv1.wrapper_0.style.height = (tv1.wrapper_0.clientHeight + d).toString() + 'px'; tv1.resize(); } );
  
  button = document.querySelector('#tvminus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; tv1.wrapper_0.style.height = (tv1.wrapper_0.clientHeight - d).toString() + 'px'; tv1.resize(); } );
  
  button = document.querySelector('#thplus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; tv1.wrapper_0.style.width = (tv1.wrapper_0.clientWidth + d).toString() + 'px'; tv1.resize(); } );
  
  button = document.querySelector('#thminus');
  clicker = button.onClick.listen(null);
  clicker.onData((MouseEvent m) { int d = (m.shiftKey) ? 10 : 1; tv1.wrapper_0.style.width = (tv1.wrapper_0.clientWidth - d).toString() + 'px'; tv1.resize(); } );

  tv1.begin();
  
}
