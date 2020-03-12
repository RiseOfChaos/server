import 'package:server/generate_city.dart';
import 'package:server/models/city.dart';

String plotToString(Map<String, Plot> map) {
  final sb = StringBuffer();

  for (int x = 0; x < C.numCols; x++) {
    for (int y = 0; y < C.numRows; y++) {
      final pos = Pos(x: x, y: y);
      final plot = map[pos.oneDForm.toString()];
      if (C.ccPosMap.containsKey(pos.oneDForm)) {
        if (plot != null) throw Exception('Plot found on CC position');
        sb.write('^');
        continue;
      }
      if (plot == null) {
        sb.write('-');
      } else {
        final type = plot.type;
        if (type < 100) {
          final building = buildings[type];
          if (building == null) throw Exception('Unknown building');
          sb.write(building.info.name[0].toUpperCase());
        } else {
          final resource = cityResources[type - 100];
          if (resource == null) throw Exception('Unknown resource');
          sb.write(resource.name[0].toUpperCase());
        }
      }
    }
    sb.writeln();
  }

  return sb.toString();
}

main() {
  final map = CityGenerator.generate(20, 16, 20);
  print(plotToString(map));
}
