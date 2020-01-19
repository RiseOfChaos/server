import 'dart:math';

import 'package:data/data.dart';
import 'package:server/models/city.dart';

class CityGenerator {
  final _rand = Random(DateTime.now().millisecondsSinceEpoch);

  Map<String, Plot> plots = <String, Plot>{};

  bool isBlobEmpty(Rectangle<int> rect) {
    for (int xpos = 0; xpos < rect.width; xpos++) {
      for (int ypos = 0; ypos < rect.height; ypos++) {
        final pos = Pos(x: xpos + rect.left, y: ypos + rect.top);
        final pos1d = pos.oneDForm;

        if (plots.containsKey(pos1d)) return false;

        if (C.ccPosMap.containsKey(pos1d)) return false;

        // TODO return false if coast

        // TODO return false if water
      }
    }

    return true;
  }

  Point<int> getRandomEmptyBlock(Point<int> shape) {
    final watch = Stopwatch();
    watch.start();
    while (true) {
      final xpos = _rand.nextInt(C.numCols - 6 - shape.x) + 3;
      final ypos = _rand.nextInt(C.numRows - 6 - shape.y) + 3;

      final rect = Rectangle<int>(xpos, ypos, shape.x, shape.y);

      if (isBlobEmpty(rect)) return Point<int>(xpos, ypos);
      if (watch.elapsed > Duration(milliseconds: 10)) {
        watch.stop();
        return null;
      }
    }
  }

  int _placeBlock(
      final int type, final Point<int> base, final Point<int> size) {
    final holes = List<bool>.generate(
        size.x * size.y, (i) => _rand.nextDouble() < 0.80,
        growable: false);

    for (int x = 0; x < size.x; x++) {
      for (int y = 0; y < size.y; y++) {
        final localPos = y * size.y + x;
        if (holes.contains(localPos)) continue;

        final pos = Pos(x: base.x + x, y: base.y + y);
        plots[pos.oneDForm.toString()] =
            Plot(pos: pos.oneDForm, type: type, level: 0);
      }
    }
  }

  void fillBlocks(final int count, final int type) {
    int remaining = count;

    while (remaining > 0) {
      final shape = shapes[_rand.nextInt(shapes.length)];
      final pos = getRandomEmptyBlock(shape);
      if (pos == null) continue;
      remaining -= _placeBlock(type, pos, shape);
    }
  }

  /// Generates city map with given number of [forests], [mountains] and [swamps]
  /// at random positions.
  static Map<String, Plot> generate(int forests, int mountains, int swamps) {
    final cityGenerator = CityGenerator();

    cityGenerator.fillBlocks(citySwamp.id, forests);
    cityGenerator.fillBlocks(cityMountain.id, mountains);
    cityGenerator.fillBlocks(citySwamp.id, swamps);
  }

  static const shapes = [
    Point<int>(1, 2),
    Point<int>(2, 1),
    Point<int>(2, 2),
    Point<int>(1, 3),
    Point<int>(3, 1),
    Point<int>(2, 3),
    Point<int>(3, 2),
    Point<int>(3, 3),
    Point<int>(2, 4),
    Point<int>(4, 2),
  ];
}
