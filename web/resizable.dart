// Copyright (c) 2015, John Yendt. All rights reserved. Use of this source code
// is governed by a LGPL-style license that can be found in the LICENSE file.

/*
 * This id just a class definition so that other pieces may be defined as resizable pieces.
 */
library Resizable;
 
abstract class Resizable {
  resize();
}
 
abstract class Resizer {
  // This may be implemented as a single value, or as a list if there are possible more than one child to consider
  setResizable(Resizable resizable,bool active);
}

class Lockable {
  bool locked = false; 
  bool lock(bool locked, [var control = null] ) => this.locked = locked;
}

