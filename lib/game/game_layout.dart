import 'package:flutter/painting.dart';

abstract final class GameLayout {
  static const width = 420.0;
  static const height = 780.0;
  static const gutter = 24.0;
  static const contentWidth = width - gutter * 2;
  static const panelRadius = 12.0;
  static const dialogRadius = 18.0;

  static const statsBounds = Rect.fromLTWH(gutter, 92, contentWidth, 74);
  static const statCenters = [86.0, 210.0, 334.0];
  static const codeBounds = Rect.fromLTWH(gutter, 184, contentWidth, 124);
  static const codeInset = 16.0;
  static const codeTop = 218.0;
  static const codeWidth = contentWidth - codeInset * 2;
  static const codeHeight = 80.0;

  static const laneCenters = [75.0, 210.0, 345.0];
  static const spawnY = 330.0;
  static const paddleY = 694.0;
  static const floorY = 720.0;
  static const despawnY = 740.0;
  static const footerY = 760.0;
  static const paddleMinX = 52.0;
  static const paddleMaxX = 368.0;

  static const gameOverBounds = Rect.fromLTWH(gutter, 370, contentWidth, 208);
  static const restartButtonBounds = Rect.fromLTWH(32, 108, 308, 48);
}
