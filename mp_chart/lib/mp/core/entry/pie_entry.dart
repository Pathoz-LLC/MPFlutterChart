import 'package:mp_chart/mp/core/entry/entry.dart';
import 'dart:ui' as ui;

import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';

class PieEntry extends Entry {
  late String _label;
  late double _labelTextSize;
  late ui.Color _labelColor;

  PieEntry({
    double value = 0,
    String label = '',
    ui.Image? icon,
    required Object data,
    double labelTextSize = 0,
    ui.Color? labelColor,
  }) : super(x: 0, y: value, icon: icon, data: data) {
    this._label = label;
    this._labelTextSize = labelTextSize ?? Utils.convertDpToPixel(10);
    this._labelColor = labelColor ?? ColorUtils.WHITE;
  }

  double getValue() {
    return y;
  }

  PieEntry copy() {
    PieEntry e = PieEntry(value: getValue(), label: _label, data: mData);
    return e;
  }

  // ignore: unnecessary_getters_setters
  String get label => _label;

  double get labelTextSize => _labelTextSize;

  ui.Color get labelColor => _labelColor;

  // ignore: unnecessary_getters_setters
  set label(String value) {
    _label = value;
  }
}
