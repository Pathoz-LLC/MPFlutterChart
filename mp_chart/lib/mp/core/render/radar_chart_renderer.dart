import 'package:flutter/painting.dart';
import 'package:mp_chart/mp/core/adapter_android_mp.dart';
import 'package:mp_chart/mp/core/animator.dart';
import 'package:mp_chart/mp/core/data/radar_data.dart';
import 'package:mp_chart/mp/core/data_interfaces/i_radar_data_set.dart';
import 'package:mp_chart/mp/core/entry/radar_entry.dart';
import 'package:mp_chart/mp/core/highlight/highlight.dart';
import 'package:mp_chart/mp/core/render/line_radar_renderer.dart';
import 'package:mp_chart/mp/core/utils/canvas_utils.dart';
import 'package:mp_chart/mp/core/utils/color_utils.dart';
import 'package:mp_chart/mp/core/utils/painter_utils.dart';
import 'package:mp_chart/mp/core/value_formatter/value_formatter.dart';
import 'package:mp_chart/mp/core/view_port.dart';
import 'package:mp_chart/mp/painter/radar_chart_painter.dart';
import 'package:mp_chart/mp/core/poolable/point.dart';
import 'package:mp_chart/mp/core/utils/utils.dart';

class RadarChartRenderer extends LineRadarRenderer {
  RadarChartPainter _chartPainter;

  /// paint for drawing the web
  late Paint _webPaint;
  late Paint _highlightCirclePaint;

  RadarChartRenderer(
      this._chartPainter, Animator animator, ViewPortHandler viewPortHandler)
      : super(animator, viewPortHandler) {
    // _chartPainter = chart;

    _highlightCirclePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = Utils.convertDpToPixel(2)
      ..color = Color.fromARGB(255, 255, 187, 115);

    _webPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    _highlightCirclePaint = Paint()
      ..isAntiAlias = true
      ..style;
  }

  Paint get webPaint => _webPaint;

  RadarChartPainter get painter => _chartPainter;

  @override
  void initBuffers() {}

  @override
  void drawData(Canvas c) {
    RadarData radarData = _chartPainter.getData() as RadarData;

    int mostEntries = radarData.getMaxEntryCountSet()?.getEntryCount() ?? 0;

    for (IRadarDataSet set in radarData.dataSets) {
      if (set.isVisible()) {
        drawDataSet(c, set, mostEntries);
      }
    }
  }

  Path mDrawDataSetSurfacePathBuffer = new Path();

  /// Draws the RadarDataSet
  ///
  /// @param c
  /// @param dataSet
  /// @param mostEntries the entry count of the dataset with the most entries
  void drawDataSet(Canvas c, IRadarDataSet dataSet, int mostEntries) {
    double phaseX = animator.getPhaseX();
    double phaseY = animator.getPhaseY();

    double sliceangle = _chartPainter.getSliceAngle();

    // calculate the factor that is needed for transforming the value to
    // pixels
    double factor = _chartPainter.getFactor();

    MPPointF center = _chartPainter.getCenterOffsets();
    MPPointF pOut = MPPointF.getInstance1(0, 0);
    Path surface = mDrawDataSetSurfacePathBuffer;
    surface.reset();

    bool hasMovedToPoint = false;

    for (int j = 0; j < dataSet.getEntryCount(); j++) {
      renderPaint.color = dataSet.getColor2(j);

      RadarEntry e = dataSet.getEntryForIndex(j);

      Utils.getPosition(
          center,
          (e.y - _chartPainter.getYChartMin()) * factor * phaseY,
          sliceangle * j * phaseX + _chartPainter.getRotationAngle(),
          pOut);

      if (pOut.x.isNaN) continue;

      if (!hasMovedToPoint) {
        surface.moveTo(pOut.x, pOut.y);
        hasMovedToPoint = true;
      } else
        surface.lineTo(pOut.x, pOut.y);
    }

    if (dataSet.getEntryCount() > mostEntries) {
      // if this is not the largest set, draw a line to the center before closing
      surface.lineTo(center.x, center.y);
    }

    surface.close();

    if (dataSet.isDrawFilledEnabled()) {
//      final Drawable drawable = dataSet.getFillDrawable();
//      if (drawable != null) {
//
//        drawFilledPath(c, surface, drawable);
//      } else {

      if (dataSet.isGradientEnabled()) {
        var gcl = dataSet.getGradientColor1();
        drawFilledPath3(
          c,
          surface,
          gcl?.startColor.value ?? 0,
          gcl?.endColor.value ?? 0,
          dataSet.getFillAlpha(),
        );
      } else {
        drawFilledPath2(
            c, surface, dataSet.getFillColor().value, dataSet.getFillAlpha());
      }
//      }
    }

    renderPaint
      ..strokeWidth = dataSet.getLineWidth()
      ..style = PaintingStyle.stroke;

    // draw the line (only if filled is disabled or alpha is below 255)
    if (!dataSet.isDrawFilledEnabled() || dataSet.getFillAlpha() < 255)
      c.drawPath(surface, renderPaint);

    MPPointF.recycleInstance(center);
    MPPointF.recycleInstance(pOut);
  }

  @override
  void drawValues(Canvas c) {
    double phaseX = animator.getPhaseX();
    double phaseY = animator.getPhaseY();

    double sliceangle = _chartPainter.getSliceAngle();

    // calculate the factor that is needed for transforming the value to
    // pixels
    double factor = _chartPainter.getFactor();

    MPPointF center = _chartPainter.getCenterOffsets();
    MPPointF pOut = MPPointF.getInstance1(0, 0);
    MPPointF pIcon = MPPointF.getInstance1(0, 0);

    double yoffset = Utils.convertDpToPixel(5);

    for (int i = 0; i < _chartPainter.getData().getDataSetCount(); i++) {
      IRadarDataSet? dataSet =
          _chartPainter.getData().getDataSetByIndex(i) as IRadarDataSet;

      if (!shouldDrawValues(dataSet)) continue;

      // apply the text-styling defined by the DataSet
      applyValueTextStyle(dataSet);

      ValueFormatter formatter = dataSet.getValueFormatter();

      MPPointF iconsOffset = MPPointF.getInstance3(dataSet.getIconsOffset());
      iconsOffset.x = Utils.convertDpToPixel(iconsOffset.x);
      iconsOffset.y = Utils.convertDpToPixel(iconsOffset.y);

      for (int j = 0; j < dataSet.getEntryCount(); j++) {
        RadarEntry entry = dataSet.getEntryForIndex(j);

        Utils.getPosition(
            center,
            (entry.y - _chartPainter.getYChartMin()) * factor * phaseY,
            sliceangle * j * phaseX + _chartPainter.getRotationAngle(),
            pOut);

        if (dataSet.isDrawValuesEnabled()) {
          drawValue(
              c,
              formatter.getRadarLabel(entry),
              pOut.x,
              pOut.y - yoffset,
              dataSet.getValueTextColor2(j),
              dataSet.getValueTextSize(),
              dataSet.getValueTypeface());
        }

        if (entry.mIcon != null && dataSet.isDrawIconsEnabled()) {
          Utils.getPosition(
              center,
              entry.y * factor * phaseY + iconsOffset.y,
              sliceangle * j * phaseX + _chartPainter.getRotationAngle(),
              pIcon);

          //noinspection SuspiciousNameCombination
          pIcon.y += iconsOffset.x;

          CanvasUtils.drawImage(c, Offset(pIcon.x, pIcon.y), entry.mIcon,
              Size(15, 15), drawPaint);
        }
      }

      MPPointF.recycleInstance(iconsOffset);
    }

    MPPointF.recycleInstance(center);
    MPPointF.recycleInstance(pOut);
    MPPointF.recycleInstance(pIcon);
  }

  @override
  void drawValue(Canvas c, String valueText, double x, double y, Color color,
      double textSize, TypeFace typeFace) {
    valuePaint = PainterUtils.create(
      valuePaint,
      valueText,
      color,
      textSize,
      fontFamily: typeFace.fontFamily,
      fontWeight: typeFace.fontWeight,
    );
    valuePaint.layout();
    valuePaint.paint(
        c, Offset(x - valuePaint.width / 2, y - valuePaint.height));
  }

  @override
  void drawExtras(Canvas c) {
    drawWeb(c);
  }

  void drawWeb(Canvas c) {
    double sliceangle = _chartPainter.getSliceAngle();

    // calculate the factor that is needed for transforming the value to
    // pixels
    double factor = _chartPainter.getFactor();
    double rotationangle = _chartPainter.getRotationAngle();

    MPPointF center = _chartPainter.getCenterOffsets();

    // draw the web lines that come from the center
    var color = _chartPainter.webColor;
    _webPaint
      ..strokeWidth = _chartPainter.webLineWidth
      ..color = Color.fromARGB(
          _chartPainter.webAlpha, color.red, color.green, color.blue);

    final int xIncrements = 1 + _chartPainter.skipWebLineCount;
    int maxEntryCount =
        _chartPainter.getData().getMaxEntryCountSet()?.getEntryCount() ?? 0;

    MPPointF p = MPPointF.getInstance1(0, 0);
    for (int i = 0; i < maxEntryCount; i += xIncrements) {
      Utils.getPosition(center, _chartPainter.yAxis.axisRange * factor,
          sliceangle * i + rotationangle, p);

      c.drawLine(Offset(center.x, center.y), Offset(p.x, p.y), _webPaint);
    }
    MPPointF.recycleInstance(p);

    // draw the inner-web
    color = _chartPainter.webColorInner;
    _webPaint
      ..strokeWidth = _chartPainter.innerWebLineWidth
      ..color = Color.fromARGB(
          _chartPainter.webAlpha, color.red, color.green, color.blue);

    int labelCount = _chartPainter.yAxis.entryCount;

    MPPointF p1out = MPPointF.getInstance1(0, 0);
    MPPointF p2out = MPPointF.getInstance1(0, 0);
    for (int j = 0; j < labelCount; j++) {
      for (int i = 0; i < _chartPainter.getData().getEntryCount(); i++) {
        double r =
            (_chartPainter.yAxis.entries[j] - _chartPainter.getYChartMin()) *
                factor;

        Utils.getPosition(center, r, sliceangle * i + rotationangle, p1out);
        Utils.getPosition(
            center, r, sliceangle * (i + 1) + rotationangle, p2out);

        c.drawLine(
            Offset(p1out.x, p1out.y), Offset(p2out.x, p2out.y), _webPaint);
      }
    }
    MPPointF.recycleInstance(p1out);
    MPPointF.recycleInstance(p2out);
  }

  @override
  void drawHighlighted(Canvas c, List<Highlight> indices) {
    double sliceangle = _chartPainter.getSliceAngle();

    // calculate the factor that is needed for transforming the value to
    // pixels
    double factor = _chartPainter.getFactor();

    MPPointF center = _chartPainter.getCenterOffsets();
    MPPointF pOut = MPPointF.getInstance1(0, 0);

    RadarData radarData = _chartPainter.getData() as RadarData;

    for (Highlight high in indices) {
      IRadarDataSet set =
          radarData.getDataSetByIndex(high.dataSetIndex) as IRadarDataSet;

      if (set == null || !set.isHighlightEnabled()) continue;

      RadarEntry e = set.getEntryForIndex(high.x.toInt());

      if (!isInBoundsX(e, set)) continue;

      double y = (e.y - _chartPainter.getYChartMin());

      Utils.getPosition(
          center,
          y * factor * animator.getPhaseY(),
          sliceangle * high.x * animator.getPhaseX() +
              _chartPainter.getRotationAngle(),
          pOut);

      high.setDraw(pOut.x, pOut.y);

      // draw the lines
      drawHighlightLines(c, pOut.x, pOut.y, set);

      if (set.isDrawHighlightCircleEnabled()) {
        if (!pOut.x.isNaN && !pOut.y.isNaN) {
          Color strokeColor = set.getHighlightCircleStrokeColor();
          if (strokeColor == ColorUtils.COLOR_NONE) {
            strokeColor = set.getColor2(0);
          }

          if (set.getHighlightCircleStrokeAlpha() < 255) {
            strokeColor = ColorUtils.colorWithAlpha(
              strokeColor,
              set.getHighlightCircleStrokeAlpha(),
            );
          }

          drawHighlightCircle(
              c,
              pOut,
              set.getHighlightCircleInnerRadius(),
              set.getHighlightCircleOuterRadius(),
              set.getHighlightCircleFillColor(),
              strokeColor,
              set.getHighlightCircleStrokeWidth());
        }
      }
    }

    MPPointF.recycleInstance(center);
    MPPointF.recycleInstance(pOut);
  }

  Path mDrawHighlightCirclePathBuffer = new Path();

  void drawHighlightCircle(
      Canvas c,
      MPPointF point,
      double innerRadius,
      double outerRadius,
      Color fillColor,
      Color strokeColor,
      double strokeWidth) {
    c.save();

    outerRadius = Utils.convertDpToPixel(outerRadius);
    innerRadius = Utils.convertDpToPixel(innerRadius);

    if (fillColor != ColorUtils.COLOR_NONE) {
      Path p = mDrawHighlightCirclePathBuffer;
      p.reset();
      p.addOval(Rect.fromLTRB(point.x - outerRadius, point.y - outerRadius,
          point.x + outerRadius, point.y + outerRadius));
//      p.addCircle(point.x, point.y, outerRadius, Path.Direction.CW);
      if (innerRadius > 0.0) {
        p.addOval(Rect.fromLTRB(point.x - innerRadius, point.y - innerRadius,
            point.x + innerRadius, point.y + innerRadius));
//        p.addCircle(point.x, point.y, innerRadius, Path.Direction.CCW);
      }
      _highlightCirclePaint
        ..color = fillColor
        ..style = PaintingStyle.fill;
      c.drawPath(p, _highlightCirclePaint);
    }

    if (strokeColor != ColorUtils.COLOR_NONE) {
      _highlightCirclePaint
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = Utils.convertDpToPixel(strokeWidth);
      c.drawCircle(
          Offset(point.x, point.y), outerRadius, _highlightCirclePaint);
    }

    c.restore();
  }
}
