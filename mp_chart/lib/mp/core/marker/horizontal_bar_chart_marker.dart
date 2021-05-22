import 'dart:ui';

import 'package:mp_chart/mp/core/marker/line_chart_marker.dart';

class HorizontalBarChartMarker extends LineChartMarker {
  HorizontalBarChartMarker({
    required Color textColor,
    required Color backColor,
    required double fontSize,
  }) : super(textColor: textColor, backColor: backColor, fontSize: fontSize);
}
