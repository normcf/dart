// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a LGPL-style license that can be found in the LICENSE file.

library ChunkFitLayout;

import 'dart:html';
import 'dart:math';

abstract class ChunkFitChange {
  static const int NONE = 0, SPACE = 1, SIZE = 2, ALIGN = 3, STRETCH = 4, CHUNK = 5;
  static const int CHANGEGROW = 10;
  List<Element> components;
  Element start;
  bool debug = true;
  int changeType = NONE;
  
  ChunkFitChange.element(Element this.start, int this.changeType) {
    this.components = new List<Element>();
  }
  ChunkFitChange.id(String id, int this.changeType) {
    this.components = new List<Element>();
    start = document.querySelector('#' + id);
  }
 
  ChunkFitChange addE(Element element) {components.add(element); return this; }
  ChunkFitChange addId(String id) { return addE(document.querySelector('#' + id)); }
  
  void alter();
    
  void Debug(String s) {
    if (debug) window.console.debug('ChunkFitChange ' + s);
  }
}

class ChunkFitSpace extends ChunkFitChange {
  static const int NONE = 0, DOWN = 1, UP = 2, LEFT = 3, RIGHT = 4;
  static const GAP = 5;
  int gap = GAP;
  int spaceDirection = DOWN;
  
  ChunkFitSpace.element(Element start, this.spaceDirection, [int this.gap = GAP]) : super.element(start,ChunkFitChange.SPACE) {}
  ChunkFitSpace.id     (String  start, this.spaceDirection, [int this.gap = GAP]) : super.id     (start,ChunkFitChange.SPACE) {}
    
  void alter() {
    int d0 = null;
    int p0 = null;
    Element component;
    
    Debug("Enter reSpace");
    switch (spaceDirection) {
      case DOWN:
      case UP:
        d0 = start.offsetHeight;
        p0 = start.offsetTop;
        break;
      case RIGHT:
      case LEFT:
        d0 = start.offsetWidth;
        p0 = start.offsetLeft;
        Debug('d0=' + d0.toString() + ' p0=' + p0.toString());
        Debug('clientWidth=' + start.clientWidth.toString() + ' clientLeft=' + start.clientLeft.toString() );
        break;
      case NONE:
        /* Do nothing */
        break;
      default:
      /* Maybe someday do an error */
    }
    
    for (component in components) {
      Debug('component.id=' + component.id + ' gap=' + gap.toString());
      switch (spaceDirection) {
        case DOWN:
          component.style.top = (p0 + d0 + gap).toString() + 'px';
          d0 = component.offsetHeight;
          p0 = component.offsetTop;
          break;
        case UP:
          component.style.top = (p0 - (component.offsetHeight + gap)).toString() + 'px';
          //d0 = component.offsetHeight; // not used
          p0 = component.offsetTop;
          break;
        case RIGHT:
          component.style.left = (p0 + d0 + gap).toString() + 'px';
          d0 = component.offsetWidth;
          p0 = component.offsetLeft;
          break;
        case LEFT:
          component.style.left = (p0 - (component.offsetWidth + gap)).toString() + 'px';
          //d0 = component.offsetHeight; // not used
          p0 = component.offsetLeft;
          break;
        case NONE:
          /* Do nothing */
          break;
        default:
        /* Maybe someday do an error */
      }
    }
    Debug("Exit reSpace");
  }
}

class ChunkFitSize extends ChunkFitChange {
  static const int NONE = 0, HORIZONTAL = 1, VERTICAL = 2, BOTH = 3;
  int resizeType = NONE;
  
  ChunkFitSize.element(Element start, int this.resizeType) : super.element(start,ChunkFitChange.SIZE) {}
  ChunkFitSize.id     (String  start, int this.resizeType) : super.id     (start,ChunkFitChange.SIZE) {}
  
  void alter() {
    Element component; 
    
    Debug("Enter reSize");
    for (component in components) {    
      switch (resizeType) {
        case HORIZONTAL:
          component.style.width = start.style.width;  
          component.style.minWidth = component.style.width;
          component.style.maxWidth = component.style.width;
          break;
        case VERTICAL:
          component.style.height = start.style.height;  
          component.style.minHeight = component.style.height;
          component.style.maxHeight = component.style.height;
          break;
        case BOTH:
          component.style.width = start.style.width;  
          component.style.minWidth = component.style.width;
          component.style.maxWidth = component.style.width;
          component.style.height = start.style.height;  
          component.style.minHeight = component.style.height;
          component.style.maxHeight = component.style.height;
          break;
        case NONE:
          /* do nothing, but don't complain */
          break;
        default:
          /* Maybe someday put out an error */
      }
    }
    
    Debug("Exit reSize");
  }
}

class ChunkFitAlign extends ChunkFitChange {
  static const int NONE = 0, LEFT = 1, RIGHT = 2, TOP = 3, BOTTOM = 4, VCENTER = 5, HCENTER = 6;
  int alignment = NONE;
  
  ChunkFitAlign.element(Element start, int this.alignment) : super.element(start,ChunkFitChange.ALIGN) {}
  ChunkFitAlign.id     (String  start, int this.alignment) : super.id     (start,ChunkFitChange.ALIGN) {}
  
  void alter() {
    int i;
    Element component; 
    
    Debug("Enter reAlign");
    
    for (component in components) {
      switch (alignment) {
        case LEFT:
          component.style.left = start.style.left; break;
        case RIGHT:
          component.style.left = (start.offsetLeft + start.offsetWidth - component.offsetWidth).toString() + 'px';
          break;
        case HCENTER:
          component.style.left = (start.offsetLeft + ((start.offsetWidth - component.offsetWidth) ~/ 2)).toString() + 'px';
          break;
        case TOP:
          component.style.top = start.style.top; break;
        case BOTTOM:
          component.style.top = (start.offsetTop + start.offsetHeight - component.offsetHeight).toString() + 'px';
          break;
        case VCENTER:
          component.style.top = (start.offsetTop + ((start.offsetHeight - component.offsetHeight) ~/ 2)).toString() + 'px';
          break;
        case NONE:
          break;
      }
    }
    
    Debug("Exit reAlign");
  }  
}

class ChunkFitStretch extends ChunkFitChange {
  static const int NONE = 0, RIGHT = 1, LEFT = 2, TOP = 3, BOTTOM = 4;
  int edge;
  
  ChunkFitStretch.element(Element start, int this.edge) : super.element(start,ChunkFitChange.STRETCH) {}
  ChunkFitStretch.id     (String  start, int this.edge) : super.id     (start,ChunkFitChange.STRETCH) {}
  
  void alter() {
    Element component; 
    
    Debug("Enter reStretch");         
    for (component in components) {
      switch (edge)
      {
        case LEFT:  
          component.style.width = (component.offsetWidth + (component.offsetLeft - start.offsetLeft)).toString() + 'px';
          component.style.minWidth = component.style.width;
          component.style.maxWidth = component.style.width;
          component.style.left = start.style.left;
          break;
        case RIGHT: 
          component.style.width = (start.offsetLeft + start.offsetWidth - (component.offsetLeft)).toString() + 'px';
          component.style.minWidth = component.style.width;
          component.style.maxWidth = component.style.width;
          break;
        case TOP:   
          component.style.height = (component.offsetHeight + (component.offsetTop - start.offsetTop)).toString() + 'px';
          component.style.minHeight = component.style.height;
          component.style.maxHeight = component.style.height;
          component.style.top = start.style.top;
          break;
        case BOTTOM:
          component.style.height = (start.offsetTop + start.offsetHeight - (component.offsetTop)).toString() + 'px';
          component.style.minHeight = component.style.height;
          component.style.maxHeight = component.style.height;
          break;
        case NONE: break;
      }
    }
    
    Debug("Exit reStretch");
  }
}

class ChunkFitChunk extends ChunkFitChange {
  static const int NONE = 0, LEFT = 1, RIGHT = 2, TOP = 3, BOTTOM = 4;
  static const SPACEBETWEENCHUNKS = 10;
  int direction = NONE;
  int spaceBetweenChunks = SPACEBETWEENCHUNKS;
  String name = 'none';
  
  ChunkFitChunk(int this.direction, [this.spaceBetweenChunks = SPACEBETWEENCHUNKS]) : super.element(null,ChunkFitChange.CHUNK) {}
  
  alter() {} // Dummy which is unused, but needed for compile
  
  void reMove(List<ChunkFitChange> allChunks) {
    ChunkFitChange vsChunk;
    
    Debug("Enter reMove - name=" + name);
    // Before we begin moving relative to other chunks, we need to move it
    // to the appropriate insets
    int farthest = 100000000; // would prefer to use int.MAX_VALUE; but don't know how yet
    Element component;
    switch (direction) {
      case RIGHT:
      case LEFT:
        Debug("reMove - First find the leftmost position of and part of any component in the chunk.");
        for (component in components) {
          Debug("reMove - farthest=" + farthest.toString() + " c.offsetLeft" + component.offsetLeft.toString());
          farthest = min(component.offsetLeft,farthest);
        }
        Debug("reMove - farthest=" + farthest.toString());
        moveChunk(-1 * farthest);
        break;
      case TOP:
      case BOTTOM:
        Debug("reMove - First find the ltopmost position of and part of any ccomponent in the chunk.");
        for (component in components) {
          farthest = min(component.offsetTop,farthest);
        }
        moveChunk(-1 * farthest);
        break;
    }
    
    for (vsChunk in allChunks) {
      if (vsChunk == this) break;
      if (vsChunk.changeType == ChunkFitChange.CHUNK) {
        Debug("reMove - call placeChunk");
        placeChunk(vsChunk);
      }
    }
    Debug("Exit reMove");
  }
  
  void placeChunk(ChunkFitChunk vsChunk) {
    Element component;
    int moveNeeded = 0;
    //for each component in the current chunk, check against each component in the passed chunk.
    // If a change needs to be made, move this chunk
    Debug("Enter placeChunk 1");
    for (component in components) {
      moveNeeded = max(moveNeeded,vsChunk.checkChunk(component,this.direction));
    }
    if (moveNeeded != 0) {
      Debug("Before moveChunk moveNeeded=" + moveNeeded.toString() + " name=" + ((name == null) ? "Unknown" : name));
      this.moveChunk(moveNeeded);          
    }
    Debug("Exit placeChunk 1");
  }
  
  int checkChunk(Element r0, int direction) {
    Rectangle r;
    Element component;
    int moveDistance = 0, rightpos, leftpos;
    bool firstMove = true;
    
    Debug("Enter checkChunk 1 - r0=" + r0.toString());
    // this is the vsChunk
    // Want to know how far to move r0 (if any)
    for (component in components) {
      Debug("checkChunk 1 - r=" + r.toString());
      switch (direction) {
        case RIGHT:
          // First see if they could overlap
          if (
            ((r0.offsetTop                   >= component.offsetTop) && (r0.offsetTop                   <  component.offsetTop + component.offsetHeight)) || // check top left corner
            ((r0.offsetTop + r0.offsetHeight >  component.offsetTop) && (r0.offsetTop + r0.offsetHeight <= component.offsetTop + component.offsetHeight)) || // check bottom left corner
            ((r0.offsetTop                   <  component.offsetTop) && (r0.offsetTop + r0.offsetHeight >  component.offsetTop + component.offsetHeight)) // check for r0 overlap
            ) {
            rightpos = component.offsetLeft + component.offsetWidth + this.spaceBetweenChunks;
            if (r0.offsetLeft < rightpos) {
              moveDistance = max(moveDistance,rightpos - r0.offsetLeft);
              firstMove = false;
            } else if ((r0.offsetLeft > rightpos) && (firstMove)) {
              moveDistance = rightpos - r0.offsetLeft;
              firstMove = false; 
            }
          }
          break;
        case LEFT:
          if (
            ((r0.offsetTop                   >= component.offsetTop) && (r0.offsetTop                   <  component.offsetTop + component.offsetHeight)) ||
            ((r0.offsetTop + r0.offsetHeight >  component.offsetTop) && (r0.offsetTop + r0.offsetHeight <= component.offsetTop + component.offsetHeight)) ||
            ((r0.offsetTop                   <  component.offsetTop) && (r0.offsetTop + r0.offsetHeight >  component.offsetTop + component.offsetHeight))
            ) {
            leftpos = component.offsetLeft - this.spaceBetweenChunks;
            if (r0.offsetLeft + r0.offsetWidth > leftpos) {
              moveDistance = min(moveDistance,leftpos - (r0.offsetLeft + r0.offsetWidth));
              firstMove = false;
            } else if ((r0.offsetLeft + r0.offsetWidth < leftpos) && (firstMove)) {
              moveDistance = leftpos - (r0.offsetLeft + r0.offsetWidth);
              firstMove = false; 
            }
          }
          break;
          
      }
    }
    Debug("Exit checkChunk 1 moveDistance=" + moveDistance.toString());
    return moveDistance;
  }
    
  void moveChunk(int offset) {
    Element component;
    // for each component in this chunk, move it the offset given
    Debug("Enter moveChunk xoffset=" + offset.toString());
    for (component in components) {
      switch (direction) {
        case   LEFT:  component.style.left = (component.offsetLeft - offset).toString() + 'px'; break;
        case  RIGHT:  component.style.left = (component.offsetLeft + offset).toString() + 'px'; break;
        case    TOP:  component.style.top  = (component.offsetTop  - offset).toString() + 'px'; break;
        case BOTTOM:  component.style.top  = (component.offsetTop  + offset).toString() + 'px'; break;
      }
    }
    Debug("Exit moveChunk xoffset=" + offset.toString());
  }
}


class ChunkFitLayout {
  static const String CHUNKFITLAYOUTDEBUG = null; //  "ChunkFitLayout"; // null; //  
  static const int HORIZONTALSPACE = 5;
  static const int VERTICALSPACE = 5;
  static const int INTERCHUNKSPACE = 10;
  static const int LEFTINSET = 8;
  static const int TOPINSET = 8;
  bool debug = true;
  String name = "UnNamed";
  int horizontalSpace = HORIZONTALSPACE;
  int verticalSpace = VERTICALSPACE;
  int interChunkSpace = INTERCHUNKSPACE;
  int leftInset = LEFTINSET;
  int topInset = TOPINSET;
  int h = 0, w = 0;
  double hmult = 1.0, vmult = 1.0;
  List<ChunkFitChange> changes; //private int changeCount = 0;
  bool firstTime = true;
  List<Element> components;

  ChunkFitLayout([String this.name]) { init(); }
  void init() {
    changes    = new List<ChunkFitChange>();
    components = new List<Element>();
  }
  
  ChunkFitLayout addE(Element component) {
    int h, w;
    component.style.position = 'absolute';
    Debug('id=' + component.id + ' clientWidth=' + component.clientWidth.toString() + ' clientHeight=' + component.clientHeight.toString() );
    Debug('id=' + component.id + ' offsetWidth=' + component.offsetWidth.toString() + ' offsetHeight=' + component.offsetHeight.toString() );
    h = component.offsetHeight;
    w = component.offsetWidth;
    component.style.width = w.toString() + 'px';
    component.style.minWidth = component.style.width;
    component.style.maxWidth = component.style.width;
    component.style.height = h.toString() + 'px';
    component.style.minHeight = component.style.height;
    component.style.maxHeight = component.style.height;
    Debug('id=' + component.id + ' clientWidth=' + component.clientWidth.toString() + ' clientHeight=' + component.clientHeight.toString() );
    Debug('id=' + component.id + ' offsetWidth=' + component.offsetWidth.toString() + ' offsetHeight=' + component.offsetHeight.toString() );
    
    components.add(component);
    return this;
  }
  ChunkFitLayout addId(String id) { return addE(document.querySelector('#' + id)); }
  
//  ChunkFitLayout addChange(Change change) {    
//    changes.add(change);
//    return this;
//  }
//  
  Debug(String s) { if (debug) window.console.debug('ChunkFit ' + s);}


  void layout() {
    Element component;
    ChunkFitChange change;
    int movex, movey;
    
    Debug("Enter setSizes " + name);
    
    if ( ! firstTime ) return;
    firstTime = false;
    
    Debug("Work setSizes " + name);
        
    for (change in changes) {
      // Need to process each of the changes
      switch (change.changeType)
      {
        case ChunkFitChange.NONE   :                 break;
        case ChunkFitChange.SIZE   : change.alter(); break;
        case ChunkFitChange.ALIGN  : change.alter(); break;
        case ChunkFitChange.SPACE  : change.alter(); break;
        case ChunkFitChange.STRETCH: change.alter(); break;
        case ChunkFitChange.CHUNK  : (change as ChunkFitChunk).reMove (this.changes); break;
        default:
          // Do we need to do an error here?
      }
    }
    
//    Debug("Make sure all components have size " + name);
//    for (change in changes)
//    {
//      if (change.changeType == Change.CHUNK)
//      {
//        for (component in components)
//        {
//          if ((component.offsetWidth <= 0) || (component.offsetHeight <= 0))
//          {
//            // Do we need this any more????
//          }
//        } 
//      }
//    }


    Debug("Now we need to look and see if the whole thing needs to be moved to the insets " + name);
    int minx = 100000000; // would prefer to use int.MAX_VALUE; but don't know how yet
    int miny = 100000000; // would prefer to use int.MAX_VALUE; but don't know how yet
    for (component in components) {
      minx = min(minx,component.offsetLeft);
      miny = min(miny,component.offsetTop);
    }
    
    Debug("How far do we need to move everything?");
    Debug("leftInset=" + leftInset.toString() + ' minx=' + minx.toString());
    movex = leftInset - minx;
    movey = topInset  - miny;
    
    offsetAll(movex, movey);
  }
  void offsetAll(int offsetx, offsety) {
    Element component;
    // for each component in this chunk, move it the offset given
    Debug("Enter offsetAll offsetx=" + offsetx.toString() + ' offsety=' + offsety.toString());
    for (component in components) {
      component.style.left = (component.offsetLeft + offsetx).toString() + 'px';
      component.style.top  = (component.offsetTop  + offsety).toString() + 'px';
    }
  }
  
  // Call these afterwards if you want to size your contailer to fit
  int getWidth() {
    int w = 0, right;
    Element component;
    for (component in components) {
      right = component.offsetLeft + component.offsetWidth;
      if (right > w) w = right;
    }
    
    return w + leftInset; /* add right inset to get whole picture */
  }

  int getHeight() {
    int h = 0, bot;
    Element component;
    for (component in components) {
      bot = component.offsetTop + component.offsetHeight;
      if (bot > h) h = bot;
    }
    
    return h + topInset; /* add bottom inset to get whole picture */
  }
}
