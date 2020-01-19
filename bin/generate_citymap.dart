import 'package:server/generate_city.dart';
import 'package:server/models/city.dart';

String plotToString(Map<String, Plot> map) {
  final sb = StringBuffer();

  for(int x = 0; x < C.numCols; x++) {
    for(int y = 0; y < C.numRows; y++) {
      final pos = Pos(x: x, y: y);
      final plot = map[pos.oneDForm];
      if(plot == null) {
        sb.write(' ');
      } else {
        final type = plot.type;
        if(type < 100) {
          final building = buildings[type];
          if(building == null) throw null;
        } else {
          final resource = cityResources[type];
        }
      }
    }
  }
}

main() {
  final map = CityGenerator.generate(10, 12, 8);
}