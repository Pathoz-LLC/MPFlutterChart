import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/highlight/i_highlighter.dart';
import 'package:mp_chart/mp/painter/pie_chart_painter.dart';
import 'package:mp_chart/mp/painter/pie_redar_chart_painter.dart';

abstract class PieRadarHighlighter<T extends PieRadarChartPainter>
    implements IHighlighter {
  T _painter;

  /// buffer for storing previously highlighted values
  List<Highlight> _highlightBuffer = [];

  PieRadarHighlighter(this._painter) {
    // this._painter = painter;
  }

  List<Highlight> get highlightBuffer => _highlightBuffer;

  T get painter => _painter;

  @override
  Highlight? getHighlight(double x, double y) {
    double touchDistanceToCenter = _painter.distanceToCenter(x, y);

    // check if a slice was touched
    if (touchDistanceToCenter > _painter.getRadius()) {
      // if no slice was touched, highlight nothing
      return null;
    } else {
      double angle = _painter.getAngleForPoint(x, y);

      if (_painter is PieChartPainter) {
        angle /= _painter.animator.getPhaseY();
      }

      int index = _painter.getIndexForAngle(angle);

      // check if the index could be found
      // TODO:  99999 is a hack ... need to review this code
      if (index < 0 ||
          index >=
              (_painter.getData().getMaxEntryCountSet()?.getEntryCount() ??
                  99999)) {
        return null;
      } else {
        return getClosestHighlight(index, x, y);
      }
    }
  }

  /// Returns the closest Highlight object of the given objects based on the touch position inside the chart.
  ///
  /// @param index
  /// @param x
  /// @param y
  /// @return
  Highlight? getClosestHighlight(int index, double x, double y);
}
