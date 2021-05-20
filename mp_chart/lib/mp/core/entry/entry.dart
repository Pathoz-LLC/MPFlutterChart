import 'package:mp_chart/mp/core/entry/base_entry.dart';
import 'dart:ui' as ui;

// const DFLT_ICON = const ui.Image();

class Entry extends BaseEntry {
  double _x = 0;

  Entry({
    double x = 0,
    double y = 0,
    ui.Image? icon,
    required Object data,
  })  : this._x = x,
        super(y: y, icon: icon, data: data);

  Entry copy() {
    Entry e = Entry(x: _x, y: y, data: mData);
    return e;
  }

  // ignore: unnecessary_getters_setters
  double get x => _x;

  // ignore: unnecessary_getters_setters
  set x(double value) {
    _x = value;
  }
}
