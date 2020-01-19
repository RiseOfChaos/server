import 'package:data/data.dart';

import 'building_cache.dart';

export 'package:data/data.dart';

export 'building_cache.dart';

class Plot {
  int type;

  int level;

  int pos;

  Plot({this.type, this.pos, this.level});
}

class City {
  // Unique ID of the city
  String id;

  WorldPos pos;

  String continent;

  // Player ID of the owner of the city
  String ownerId;

  // Current level of city
  int level;

  Map<int, Plot> plots;

  List<Construction> constructions;

  List<Trade> trades;

  List<TradeIn> tradeIns;

  List<Recruitment> recruitments;

  List<Command> commands;

  List<OnSupport> onSupports;

  List<IncomingAttack> incomingAttacks;

  TimedResources resources;

  int totalCS;

  BuildingCache buildingCache;

  Troops troopsHome;
}

extension ConstructionUtils on City {
  int get maxBuildingsAllowed => level * 10;

  int get maxConstructionsAllowed => 5;

  Plot getPlotAfterConstructions(int pos) {
    Plot ret = Plot();

    {
      final plot = plots[pos];
      if (pos == null) {
        ret.level = 0;
      } else {
        // TODO check if it is a building

        ret.type = plot.type;
        ret.level = plot.level;
      }
    }

    for (final construction in constructions) {
      if (construction.pos == pos) {
        switch (construction.constructionType) {
          case ConstructionType.construct:
            ret.type = construction.buildingType;
            ret.level++;
            break;
          case ConstructionType.upgrade:
            ret.level++;
            break;
          case ConstructionType.downgrade:
            ret.level--;
            if (ret.level == 0) return null;
            break;
          case ConstructionType.demolish:
            return null;
        }
      }
    }

    return ret;
  }

  int buildTime(int seconds) {
    int cs = totalCS;
    // TODO CS bonus

    int newTime = ((seconds * 100) / cs).ceil();

    if (newTime < 5) newTime = 5;
    return newTime;
  }

  bool canDowngradePlot(int pos) => !constructions.any(
      (c) => c.pos == pos && c.constructionType != ConstructionType.downgrade);

  bool canDemolishPlot(int pos) => !constructions.any((c) => c.pos == pos);
}

extension RecruitmentUtils on City {
  int get maxRecruitmentsAllowed => 5;

  int recruitmentTime(int seconds, int type) {
    // TODO
  }

  Troops get troopsAway {
    final ret = Troops();
    for (final cmd in commands) {
      ret.add(cmd.troops);
    }
    return ret;
  }

  Troops get troopsTotal => troopsHome + troopsAway;
}

extension CommandUtils on City {
  int get maxCommandsAllowed => 5;
}

extension TradeUtils on City {
  int get maxTradesAllowed => 5;

  int get takenCarts {
    int res = 0;

    for (Trade trade in trades) {
      res += trade.carts;
    }

    return res;
  }

  int get freeCarts => buildingCache.carts - takenCarts;
}
