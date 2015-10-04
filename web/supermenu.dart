//
// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a LGPL-style license that can be found in the LICENSE file.
//

library SuperMenu;

import 'dart:html';
import 'resizable.dart';

abstract class SuperMenuAction {
  SuperMenu superMenu;
  void action();
//  setResizeable(Resizable resizable) {
//    superMenu.resizableModalChild = resizable;
//  }
}

class SuperMenuItem {
  String id; // From the DOM.  We'll add it to the new ones in case it's needed
  String menuId; // Unique within this menu
  String text;
  int width; // For creating the submenu 
  int xOffset = 0, yOffset = 0; // From normal position
  List<SuperMenuItem> subMenuItems;
  SuperMenuItem parent;
  Element menuItemDisplay = null;
  Element subMenuDisplay = null;
  
  SuperMenuAction action = null;
  
  SuperMenuItem() { subMenuItems = new List<SuperMenuItem>(); }
}

class SuperMenu implements Resizable, Resizer {
  static const String ATTRNAMEPREFIX = 'data-'; // So the attributes become application specific
  String SuperMenuMenuClass          = 'superMenuMenu';
  String SuperMenuItemClass          = 'superMenuItem';
  String SuperMenuTopItemClass       = 'superMenuTopItem';
  String SuperMenuWidthAttrName      = ATTRNAMEPREFIX + 'superMenuWidth';
  String SuperMenuDispayTextAttrName = ATTRNAMEPREFIX + 'superMenuText';
  String SuperMenuActiveItemClass    = 'superMenuItemActive';
  String SuperMenuIdAttrName         = ATTRNAMEPREFIX + 'superMenuId';
  String SuperMenuXOffsetAttrName    = ATTRNAMEPREFIX + 'superMenuXOffset';
  String SuperMenuYOffsetAttrName    = ATTRNAMEPREFIX + 'superMenuYOffset';
  int DefaultMenuItemWidth = 50;
  bool debug = true;
  int zIndexOffset = 5;
  Resizable resizableModalChild2 = null; // Must fill this in when a modal child must resize too.
  
  SuperMenuItem menuItems;
  Element menu;
  
  int TopMenuSpace = 5;
  String id;
  int height = 20;
  
  SuperMenu(String this.id) {
    menuItems = new SuperMenuItem();
    menuItems.id = id;
    menuItems.text = 'Main';
    menuItems.width = 0;
    menuItems.menuId = '0';
    menuItems.xOffset = 0;
    menuItems.yOffset = 0;
  }
  
  void init() {
    // Get the menu and remove it from the class
    int width;
    //Element menu;
    var listener;
    
    menuItems.subMenuDisplay = new Element.div();
    
    menu = document.querySelector('#' + id);
    if (menu == null) return; // Just exit if it's not found.
    
    menu.insertAdjacentElement('beforeBegin', menuItems.subMenuDisplay);
    
    menuItems.subMenuDisplay.classes.add(SuperMenuMenuClass);
    menuItems.subMenuDisplay.style
      ..position = 'relative'
      ..height = height.toString() + 'px'
      ..minHeight = height.toString() + 'px'
      ..width = '100%'
    ;
    
    buildMenuItems(menuItems,menu);
    
    // Now display the top menu line
    
    SuperMenuItem topMenuItem;
    int xpos = 0;
    for (topMenuItem in menuItems.subMenuItems) {
      topMenuItem.menuItemDisplay = new Element.div();
      topMenuItem.menuItemDisplay.setAttribute(SuperMenuIdAttrName,topMenuItem.menuId);
      topMenuItem.menuItemDisplay.classes.add(SuperMenuItemClass);
      topMenuItem.menuItemDisplay.classes.add(SuperMenuTopItemClass);
      topMenuItem.menuItemDisplay.style
        ..position = 'absolute'
        ..height = height.toString() + 'px'
        ..width = width.toString() + 'px'
        ..minWidth = width.toString() + 'px'
        ..maxWidth = width.toString() + 'px'
        ..top = '0' + 'px'
        ..left = xpos.toString() + 'px'
      ;
      topMenuItem.menuItemDisplay.insertAdjacentText('afterBegin', topMenuItem.text);
      listener = topMenuItem.menuItemDisplay.onMouseEnter.listen(null);
      listener.onData(showMenu);
      listener = topMenuItem.menuItemDisplay.onClick.listen(null);
      listener.onData(runAction);  
      
      menuItems.subMenuDisplay.insertAdjacentElement('beforeEnd', topMenuItem.menuItemDisplay);
      xpos += topMenuItem.width + TopMenuSpace;
    }
    
    listener = menuItems.subMenuDisplay.onMouseEnter.listen(null);
    listener.onData(clearMenu);
    
    menu.remove(); // Remove the old menu from the DOM   
    menuItems.subMenuDisplay.id = id;
  }
  
  void buildMenuItems(SuperMenuItem parent, Element ol) {
    List<Element> lis, ols;
    Element li, subol;
    Node subNodeLi, subNodeOl;
    SuperMenuItem smi;
    int n = 0;
    String attr;
    
    Debug('Enter buildMenuItems - ol=' + ol.toString());
    
    lis = ol.childNodes;
    for (subNodeLi in lis) {
      if (! (subNodeLi is Element)) continue;
      li = subNodeLi;
      smi = new SuperMenuItem();
      smi.parent = parent;
      smi.id = li.id;
      smi.menuId = parent.menuId + '.' + n.toString(); n++;
      attr = li.getAttribute(SuperMenuWidthAttrName);
      if (attr == null) smi.width = DefaultMenuItemWidth;
      else smi.width = int.parse(attr,onError: (_) => DefaultMenuItemWidth);
      smi.text = li.getAttribute(SuperMenuDispayTextAttrName);
      // Now let's see if there are any sub menus
      ols = li.childNodes;
      for (subNodeOl in ols) {
        if (! (subNodeOl is Element)) continue;
        subol = subNodeOl;
        Debug('buildMenuItems - working on subs for text=' + smi.text + ' tagName=' + subol.tagName);
        // Note: There should only ever be one OL in here.  More that one make no sense.
        if (subol.tagName == 'OL') {
          // Need to see if there are x or y offsets
          attr = subol.getAttribute(SuperMenuXOffsetAttrName);
          Debug("attr='" + attr.toString() + "' x");
          if (attr != null) smi.xOffset = int.parse(attr,onError: (_) => 0);
          attr = subol.getAttribute(SuperMenuYOffsetAttrName);
          if (attr != null) smi.yOffset = int.parse(attr,onError: (_) => 0);
          buildMenuItems(smi,subol);
        }        
      }
      parent.subMenuItems.add(smi);     
    }
  }
  
  void removeSubMenu(SuperMenuItem menuItem) {
    Debug('Enter removeSubMenu - menuId=' + menuItem.menuId);
    menuItem.subMenuDisplay.remove();
    menuItem.subMenuDisplay = null;
  }
  
  void removeChildSubMenus(SuperMenuItem menuItem) {
    SuperMenuItem current;
    for (current in menuItem.subMenuItems) {
      current.menuItemDisplay.classes.remove(SuperMenuActiveItemClass);
      if (current.subMenuDisplay != null) {
        removeChildSubMenus(current);
        removeSubMenu(current);
      }
    }
  }
  
  void removeSelection(SuperMenuItem menuItem) {
    SuperMenuItem current;
    for (current in menuItem.subMenuItems) {
      
      current.menuItemDisplay.classes.remove(SuperMenuActiveItemClass);
    }
  }
  
  void clearMenu(MouseEvent me) {
    removeChildSubMenus(menuItems);
    me.preventDefault();
    me.stopPropagation();
  }
  
  void showMenu(MouseEvent me) {
    Element target;
    String menuId;
    SuperMenuItem current;
    
    Debug('Enter showMenu');
    target = me.target;
    target.classes.add(SuperMenuActiveItemClass); // Just for testing
    menuId = target.getAttribute(SuperMenuIdAttrName);
    Debug('showMenu look for menuId=\'' + menuId.toString() + '\'');
    current = findMenuItem(menuItems.subMenuItems, menuId);
    
    Debug('showMenu current=' + current.text);
    
    if (current != null) {
      Debug('showMenu - First let\'s see if it is already displaying a submenu');
      if (current.subMenuDisplay != null) {
        Debug('showMenu - Good, we don\'t need to create one, but if there is anything below this one, then they need to close');
        removeChildSubMenus(current);
        removeSelection(current.parent);
        current.menuItemDisplay.classes.add(SuperMenuActiveItemClass);
      } else if (current.subMenuItems.length > 0) {
        // Need to create this submenu
        Debug('Need to open submenu');
        removeChildSubMenus(current.parent);
        createSubMenu(target,current);
        removeSelection(current.parent);
        current.menuItemDisplay.classes.add(SuperMenuActiveItemClass);
      } else {
        Debug('showMenu - This is an end item, but it needs to be highlighted');
        removeChildSubMenus(current.parent);
        removeSelection(current.parent);
        current.menuItemDisplay.classes.add(SuperMenuActiveItemClass);
      }     
    }
    
    me.preventDefault();
    me.stopPropagation();
  }
  
  // There could be one of these if there is a submenu, or not if this is an end node

  
  Element createSubMenu(Element target, SuperMenuItem menuSelected) {
    SuperMenuItem subs;
    int y = 0, subMenuWidth = 0;
    var listener;
    menuSelected.subMenuDisplay = new Element.div();
    
    // subMenuWidth will be the width of the widest list item
    for (subs in  menuSelected.subMenuItems) {
      if (subs.width > subMenuWidth) subMenuWidth = subs.width;
    }
    
    if (subs.width <= 0) subs.width = DefaultMenuItemWidth;
    // We need to know where to place it.  If topMenu then going down, otherwise left or right.
    // Let's make it simple for now, and go right or down only
    if (menuSelected.parent == menuItems) {
      menuSelected.subMenuDisplay.style
        ..left = (target.offsetLeft                      + menuSelected.xOffset).toString() + 'px'
        ..top  = (target.offsetTop + target.clientHeight + menuSelected.yOffset).toString() + 'px'
        ;
    } else {
      menuSelected.subMenuDisplay.style
        ..left = (target.offsetLeft + target.clientWidth + menuSelected.xOffset).toString() + 'px'
        ..top  = (target.offsetTop                       + menuSelected.yOffset).toString() + 'px'
        ;
    }
    
    menuSelected.subMenuDisplay.style
      ..position = 'absolute'
      ..width = subMenuWidth.toString() + 'px' // ..zIndex = '10'
      ..zIndex = (int.parse(menuSelected.parent.subMenuDisplay.style.zIndex,onError: (_) => 0) + this.zIndexOffset).toString()
    ;
    menuSelected.subMenuDisplay.classes.add(SuperMenuMenuClass);
    
    for (subs in  menuSelected.subMenuItems) {
      // Need to add this to the itemList and set the display
      subs.menuItemDisplay = new Element.div();
      subs.menuItemDisplay.setAttribute(SuperMenuIdAttrName, subs.menuId);
      subs.menuItemDisplay.style
        ..position = 'absolute'
        ..width = '100%'
        ..top = y.toString() + 'px'
        ..height = '15px'
      ;
      y += 15;
      listener = subs.menuItemDisplay.onMouseEnter.listen(null);
      listener.onData(showMenu);
      listener = subs.menuItemDisplay.onClick.listen(null);
      listener.onData(runAction);  

      subs.menuItemDisplay.insertAdjacentText('afterBegin',subs.text);
      menuSelected.subMenuDisplay.insertAdjacentElement('beforeEnd', subs.menuItemDisplay);
    }
    menuSelected.subMenuDisplay.style.height = y.toString() + 'px';
    
    // OK, do some smarts here to see if the height is too big for the screen and sho
    menuSelected.parent.subMenuDisplay.insertAdjacentElement('beforeEnd', menuSelected.subMenuDisplay);
    return menuSelected.subMenuDisplay;
  }
  
  SuperMenuItem findMenuItem(List<SuperMenuItem> head, String menuId) {
    SuperMenuItem temp = null, found;
    for (temp in head) {
      if (menuId == temp.menuId) {
        return temp;
      } else {
        found = findMenuItem(temp.subMenuItems, menuId);
        if (found != null) return found;
      }
    }
    return null;
  }
  
  SuperMenuItem findMenuItemById(List<SuperMenuItem> head, String id) {
    SuperMenuItem temp = null, found;
    for (temp in head) {
      if (id == temp.id) {
        return temp;
      } else {
        found = findMenuItemById(temp.subMenuItems, id);
        if (found != null) return found;
      }
    }
    return null;
  }
  
  void addAction(String id, SuperMenuAction action) {
    SuperMenuItem found;
    Debug('Enter addAction');
    found = findMenuItemById(menuItems.subMenuItems,id);
    if (found != null) {
      found.action = action;
      action.superMenu = this;
    }
    else Debug("addAction - Could not find id='" + id.toString() + "'");
  }
  
  void runAction(MouseEvent me) {
    Element target;
    String menuId;
    SuperMenuItem current;
    
    Debug('Enter runAction');
    target = me.target;
    menuId = target.getAttribute(SuperMenuIdAttrName);
    Debug('runAction look for menuId=\'' + menuId.toString() + '\'');
    current = findMenuItem(menuItems.subMenuItems, menuId);
    Debug('runAction - current=' + current.toString());
    if (current.action != null) {
      removeChildSubMenus(menuItems);
      Debug('runAction - before action');
      current.action.action();
      Debug('runAction - after action');
    } else Debug("action is null");
    
    Debug('runAction current=' + current.text);
    
  }
  
  void setResizable(Resizable resizable,bool active) {
    Debug("setResizable - resizableModalChild=" + resizableModalChild2.toString());
    resizableModalChild2 = (active) ? resizable : null;
  }
  
  void resize() {
    if (resizableModalChild2 != null) resizableModalChild2.resize();
  }
  
  void Debug(String s) {
    if (debug) print('SuperMenu ' + s);
  }
}