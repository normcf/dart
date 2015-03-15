// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library SuperTabView;

import 'dart:html';
import 'dart:async';

import 'resizable.dart';
import 'supertable.dart';
//import 'dart:math';

abstract class TabHandler {
  static int TABWIDTH = 40;
  int tabWidth = TABWIDTH;

  bool unFormatted = true;
  bool fetched = false;
  bool autoRefresh = false; // Should the tab refresh data each time it is selected?
  SuperTabView tabView = null;
  Element source; // Probably an li
  Element content;
  Element tabHolder;
  //List<Resizable> resizables; // There may be more than one piece in this tab
  Resizable resizable = null; // When the inside space of the contents changes, you must call resizable.resize()
  
  TabHandler.element(SuperTabView this.tabView, Element this.source) {tabView.tabs.add(this);}
  TabHandler.id(SuperTabView this.tabView, String id) { this.source = document.querySelector('#' + id); tabView.tabs.add(this); }
  
  void init() {}
  void firstTime() {}
  void refresh();
  void chosen(MouseEvent me); // Needs to fill the tab contents
  
  void resize(){ if (resizable != null) resizable.resize(); } // Subclass may override or extend
  
}

class PlainContentTabHandler extends TabHandler {
  PlainContentTabHandler.id(SuperTabView tabView, String id) : super.id(tabView, id) {
    this.content = source.querySelector('div');
  }
  refresh() {}
  chosen(MouseEvent me) {
    tabView.Debug('clicked ' + source.id);
    tabView.currentTab.content.remove();
    tabView.currentTab.tabHolder.classes.remove(tabView.SelectedTabClass);
    tabView.currentTab = this;
    tabView.currentTab.tabHolder.classes.add(tabView.SelectedTabClass);
    tabView.tabContent.insertAdjacentElement('afterBegin', this.content);
    this.content.style
      ..width = tabView.tabContent.clientWidth.toString() + 'px'
      ..height = tabView.tabContent.clientHeight.toString() + 'px';
  }
  @override
  resize() {
    this.content.style
      ..width = tabView.tabContent.clientWidth.toString() + 'px'
      ..height = tabView.tabContent.clientHeight.toString() + 'px';
    super.resize();
  }
}

class SuperTableTabHandler extends TabHandler {
  SuperTable superTable;
  SuperTableTabHandler.id(SuperTabView tabView, String id, SuperTable this.superTable) : super.id(tabView, id) { 
    resizable = superTable;
    this.content = superTable.wrapper_0;
  }
  refresh() {}
  chosen(MouseEvent me) {
    tabView.Debug('clicked ' + source.id);
    tabView.currentTab.content.remove();
    tabView.currentTab.tabHolder.classes.remove(tabView.SelectedTabClass);
    tabView.currentTab = this;
    tabView.currentTab.tabHolder.classes.add(tabView.SelectedTabClass);
    this.content.style
      ..width = tabView.tabContent.clientWidth.toString() + 'px'
      ..height = tabView.tabContent.clientHeight.toString() + 'px';
    tabView.tabContent.insertAdjacentElement('afterBegin', this.content);
    resize();
  }
  @override
  resize() {
    tabView.Debug("in resize");
    superTable.wrapper_0.style
        ..width = tabView.tabContent.clientWidth.toString() + 'px'
        ..height = tabView.tabContent.clientHeight.toString() + 'px';   
    super.resize();
   }
}

class SuperTabView {
  static const TABROWHEIGHT              = 30;
  static const String CONTAINERCLASSNAME = 'tabview_wrapper';
  static const String TABDISPLAYATTRNAME = 'tabtext';
  static const String TABBUTTONCLASSNAME = 'tabButton';
  static const String SELECTEDTABCLASS   = 'selecteTabButton';
  
  String TabDisplayAttrName = TABDISPLAYATTRNAME;
  String ContainerClassName = CONTAINERCLASSNAME;
  String TabButtonClassName = TABBUTTONCLASSNAME;
  String SelectedTabClass = SELECTEDTABCLASS;
  int tabRowHeight = TABROWHEIGHT;
  int VScrollBarThick, HScrollBarThick; // need only be set once.  Someone else can make them static
  bool debug = true;  

  Element wrapper_0;
  Element    tabsWrapper; // The width of the wrapper
  Element        tabsHolder; // The combined width of the tabs
  Element    tabContent; 
  
  int tabHolderWidth;
  
  Element listHolder;
  String listId;
  List<TabHandler> tabs;
  TabHandler currentTab = null;
  
  
  
  SuperTabView.element (Element this.listHolder) {
    tabs= new List<TabHandler>();
    listId = listHolder.id;
    init();
  }
  
  SuperTabView.id (String this.listId) {
    tabs= new List<TabHandler>();
    listHolder = document.getElementById(listId);
    init();
  }
  
  void startTabId(String id) {
    
  }
  
  void init() {
    getScrollbarThicks();
        
    Element parent;
    parent = listHolder.parent;
    if ( ! parent.classes.contains(ContainerClassName)) {
      // Need to create a container div
      wrapper_0 = new Element.div();
      wrapper_0.classes.add(ContainerClassName);
      
      parent.insertAdjacentElement('afterBegin', wrapper_0);
      
      wrapper_0.style.width = '800px';
      wrapper_0.insertAdjacentElement('afterBegin',listHolder);
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
    
    // Now crete the two internal pieces
    tabsWrapper = new Element.div();
    tabsWrapper.style
      ..position = 'absolute'
      ..height = tabRowHeight.toString() + 'px'
      ..width = wrapper_0.clientWidth.toString() + 'px';
    wrapper_0.insertAdjacentElement('afterBegin', tabsWrapper);
    tabsHolder = new Element.div();
    tabsHolder.style
      ..position = 'absolute'
      ..height = tabsWrapper.clientHeight.toString() + 'px';
    tabsWrapper.insertAdjacentElement('afterBegin', tabsHolder);
    
    tabContent = new Element.div();
    tabContent.style
      ..position = 'absolute'
      ..left = '0px';
    wrapper_0.insertAdjacentElement('beforeEnd', tabContent);
  }
  
  void begin() {
    // Need to generate the tab holders
    int tabWidth, left = 0;
    StreamSubscription<MouseEvent> clicker;
    TabHandler tab;
    for (tab in tabs) {
      tab.tabHolder = new Element.html('<button class="tabButton">' + tab.source.getAttribute(TabDisplayAttrName) + '</button>');
      clicker = tab.tabHolder.onClick.listen(null);
      clicker.onData(tab.chosen);
      tab.tabHolder.style
        ..top = '0px'
        ..position = 'absolute'
        ..height = tabsHolder.clientHeight.toString() + 'px'
        ..textAlign = 'center'
        ..verticalAlign = 'middle'
        ..left = left.toString() + 'px';
      //tab.tabHolder.insertAdjacentHtml('afterBegin','<button>' + tab.source.getAttribute(TabDisplayAttrName) + '</button>');
      tabsHolder.insertAdjacentElement('beforeEnd', tab.tabHolder);
      Debug('tab=' + tab.source.id + ' text=' + tab.tabHolder.text);
      tabWidth = tab.tabHolder.offsetWidth;
      
      Debug('tab=' + tab.source.id + ' tabWidth=' + tabWidth.toString());
      tab.tabHolder.style.width = tabWidth.toString() + 'px';
      tab.tabHolder.style
        ..maxWidth = tab.tabHolder.style.width
        ..minWidth = tab.tabHolder.style.width;
      left += tabWidth;
    }

    tabHolderWidth = left;
    
    // Remove the list from the DOM which should take some work away from the browser   
    listHolder.remove();
    

    if (currentTab == null) {
      // Find the first tab
      currentTab = tabs[0]; // We aren't going to bother checking if there are no tabs.  No tabs are useless!!
      currentTab.chosen(null);
    }    
    
    resize();
  }
  
  void resize() {
    Debug('tabHolderWidth=' + tabHolderWidth.toString() + ' tabsWrapper.clientWidth=' + tabsWrapper.clientWidth.toString());
    tabsWrapper.style.width = wrapper_0.clientWidth.toString() + 'px';
    tabContent.style.width = tabsWrapper.style.width;
    
    if (tabHolderWidth > tabsWrapper.clientWidth) {
      // Need a scroll bar
      if (tabsWrapper.style.overflowX != 'scroll') {
        tabsWrapper.style.height = (tabRowHeight + HScrollBarThick).toString() + 'px';
        tabsWrapper.style.overflowX = 'scroll';
        tabContent.style.top = tabsWrapper.offsetHeight.toString() + 'px';
      }
      tabContent.style.height = (wrapper_0.clientHeight - tabsWrapper.offsetHeight).toString() + 'px';
    } else {
      if (tabsWrapper.style.overflowX != 'hidden') {
        tabsWrapper.style.height = tabRowHeight.toString() + 'px';
        tabsWrapper.style.overflowX = 'hidden';
        tabContent.style.top = tabsWrapper.offsetHeight.toString() + 'px';
      }
      tabContent.style.height = (wrapper_0.clientHeight - tabsWrapper.offsetHeight).toString() + 'px';
    }
    currentTab.resize();
  }
  
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
  
  void Debug(String s) {
    if (debug) window.console.debug('SuperTabView ' + s);
  }
}