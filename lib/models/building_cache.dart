import 'package:data/data.dart';
import 'city.dart';

export 'package:data/data.dart';

class BuildingCache {
  int hitpoints = 0;

  int numBuildings = 0;

  int score = 0;

  bool castled = false;

  Map<String, Map<String, void>> buildingsByType = {};

  int troopSpace = 0;

  int constructionSpeed = 100;

  int carts = 0;

  Map<String, void> recruitable = {};

  int meleeRecruitmentSpeed = 100;

  int rangeRecruitmentSpeed = 100;

  int siegeRecruitmentSpeed = 100;

  void addBuilding(Plot plot) {
    Map<String, void> forType = buildingsByType[plot.type.toString()];
    if (forType == null) {
      buildingsByType[plot.type.toString()] = forType = {};
    }

    forType[plot.pos.toString()] = null;
  }

  void updateRates(Plot plot, City city, DateTime now) {
    Resources newRate;
    Resources newStorage;
    switch (plot.type) {
      case CityNodeIds.cityCenter:
        newStorage = _calculateStorage(city);
        break;
      case CityNodeIds.quarry:
        newRate = Resources(adamantium: 0, magnetite: 0, uranium: 0);
        newRate.adamantium = _calculateAdamantiumRate(city);
        break;
      case CityNodeIds.magnetiteMine:
        newRate = Resources(adamantium: 0, magnetite: 0, uranium: 0);
        newRate.magnetite = _calculateMagnetiteRate(city);
        break;
      case CityNodeIds.house:
        newRate = Resources(adamantium: 0, magnetite: 0, uranium: 0);
        newRate.adamantium = _calculateAdamantiumRate(city);
        newRate.magnetite = _calculateMagnetiteRate(city);
        newRate.uranium = _calculateUraniumRate(city);

        _updateConstructionSpeed(city);
        break;
      case CityNodeIds.warehouse:
        newStorage = _calculateStorage(city);
        _updateCarts(city);
        break;
      case CityNodeIds.refinery:
        _calculateAdamantiumRate(city);
        _calculateMagnetiteRate(city);
        newStorage = _calculateStorage(city);
        break;
      case CityNodeIds.uraniumMine:
        newRate = Resources(adamantium: 0, magnetite: 0, uranium: 0);
        newRate.uranium = _calculateUraniumRate(city);
        break;
      case CityNodeIds.enrichmentPlant:
        _calculateUraniumRate(city);
        newStorage = _calculateStorage(city);
        break;
      case CityNodeIds.garrison:
        _updateTroopSpace(city);
        _updateMeleeRecruitmentSpeed(city);
        _updateRangeRecruitmentSpeed(city);
        _updateSiegeRecruitmentSpeed(city);
        break;
      case CityNodeIds.barrack:
        _updateTroopSpace(city);
        _updateMeleeRecruitmentSpeed(city);
        _updateMeleeRecruitable(city);
        break;
      case CityNodeIds.plasmaRange:
        _updateTroopSpace(city);
        _updateRangeRecruitmentSpeed(city);
        _updateRangeRecruitable(city);
        break;
      case CityNodeIds.artilleryYard:
        _updateTroopSpace(city);
        _updateSiegeRecruitmentSpeed(city);
        _updateSiegeRecruitable(city);
        break;
      case CityNodeIds.commandCenter:
        _updateTroopSpace(city);
        break;
      case CityNodeIds.forest:
        _calculateAdamantiumRate(city);
        break;
      case CityNodeIds.mountain:
        _calculateMagnetiteRate(city);
        break;
      case CityNodeIds.marsh:
        _calculateUraniumRate(city);
        break;
    }
    // Update resource rate and storage
    if (newRate != null || newStorage != null) {
      final old = city.resources;
      if (newRate != null) {
        newRate.adamantium ??= old.rate.adamantium;
        newRate.magnetite ??= old.rate.magnetite;
        newRate.uranium ??= old.rate.uranium;
      }
      newStorage ??= old.max;

      final amount = old.amount(now);
      city.resources =
          TimedResources(was: amount, rate: newRate, max: newStorage, at: now);
    }
  }

  int _calculateAdamantiumRate(City city) {
    final quarryMap = buildingsByType[CityNodeIds.quarry];

    int res = 300;

    if (quarryMap != null) {
      for (String pos in quarryMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.quarry) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final boosterBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(boosterBuildingPos)) continue;

            Plot boosterBuilding =
                city.plots[boosterBuildingPos.oneDForm.toString()];
            if (boosterBuilding == null) continue;

            switch (boosterBuilding.type) {
              case CityNodeIds.forest:
                perc += 40;
                break;
              case CityNodeIds.house:
                perc += house.production1[boosterBuilding.level - 1];
                break;
              case CityNodeIds.refinery:
                perc += refinery.production1[boosterBuilding.level - 1];
                break;
            }
          }
        }

        int current = quarry.production1[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    return res;
  }

  int _calculateMagnetiteRate(City city) {
    final magnetiteMineMap = buildingsByType[CityNodeIds.magnetiteMine];

    int res = 300;

    if (magnetiteMineMap != null) {
      for (String pos in magnetiteMineMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.magnetiteMine) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final boosterBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(boosterBuildingPos)) continue;

            Plot boosterBuilding =
                city.plots[boosterBuildingPos.oneDForm.toString()];
            if (boosterBuilding == null) continue;

            switch (boosterBuilding.type) {
              case CityNodeIds.mountain:
                perc += 40;
                break;
              case CityNodeIds.house:
                perc += house.production1[boosterBuilding.level - 1];
                break;
              case CityNodeIds.refinery:
                perc += refinery.production1[boosterBuilding.level - 1];
                break;
            }
          }
        }

        int current = magnetiteMine.production1[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    return res;
  }

  int _calculateUraniumRate(City city) {
    final uraniumMineMap = buildingsByType[CityNodeIds.uraniumMine];

    int res = 300;

    if (uraniumMineMap != null) {
      for (String pos in uraniumMineMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.uraniumMine) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final boosterBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(boosterBuildingPos)) continue;

            Plot boosterBuilding =
                city.plots[boosterBuildingPos.oneDForm.toString()];
            if (boosterBuilding == null) continue;

            switch (boosterBuilding.type) {
              case CityNodeIds.marsh:
                perc += 40;
                break;
              case CityNodeIds.house:
                perc += house.production1[boosterBuilding.level - 1];
                break;
              case CityNodeIds.enrichmentPlant:
                perc += enrichmentPlant.production1[boosterBuilding.level - 1];
                break;
            }
          }
        }

        int current = uraniumMine.production1[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    return res;
  }

  Resources _calculateStorage(City city) {
    final warehouseMap = buildingsByType[CityNodeIds.warehouse];

    Resources res = Resources.same(cityCenter.production1[city.level - 1]);

    if (warehouseMap != null) {
      for (String pos in warehouseMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.warehouse) {
          // TODO this can't be. log!
          continue;
        }

        Resources perc = Resources.same(100);

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final boosterBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(boosterBuildingPos)) continue;

            Plot boosterBuilding =
                city.plots[boosterBuildingPos.oneDForm.toString()];
            if (boosterBuilding == null) continue;

            switch (boosterBuilding.type) {
              case CityNodeIds.refinery:
                perc.adamantium +=
                    refinery.production2[boosterBuilding.level - 1];
                perc.magnetite +=
                    refinery.production2[boosterBuilding.level - 1];
                break;
              case CityNodeIds.enrichmentPlant:
                perc.uranium +=
                    enrichmentPlant.production2[boosterBuilding.level - 1];
                break;
            }
          }
        }

        int current = warehouse.production1[plot.level - 1];

        res.adamantium += current * perc.adamantium ~/ 100;
        res.magnetite += current * perc.magnetite ~/ 100;
        res.uranium += current * perc.uranium ~/ 100;
      }
    }

    return res;
  }

  void _updateCarts(City city) {
    final warehouseMap = buildingsByType[CityNodeIds.warehouse];

    int res = 0;

    if (warehouseMap != null) {
      for (String pos in warehouseMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.warehouse) {
          // TODO this can't be. log!
          continue;
        }

        int current = warehouse.production2[plot.level - 1];
        res += current;
      }
    }

    carts = res;
  }

  void _updateConstructionSpeed(City city) {
    final houseMap = buildingsByType[CityNodeIds.house];

    int res = 100;

    if (houseMap != null) {
      for (String pos in houseMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.house) {
          // TODO this can't be. log!
          continue;
        }

        res += house.production2[plot.level - 1];
      }
    }

    constructionSpeed = res;
  }

  void _updateMeleeRecruitmentSpeed(City city) {
    final barrackMap = buildingsByType[CityNodeIds.barrack];

    int res = 100;

    if (barrackMap != null) {
      for (String pos in barrackMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.barrack) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final militaryBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(militaryBuildingPos)) continue;

            Plot militaryBuilding =
                city.plots[militaryBuildingPos.oneDForm.toString()];
            if (militaryBuilding == null) continue;

            switch (militaryBuilding.type) {
              case CityNodeIds.garrison:
                perc += garrison.production1[militaryBuilding.level - 1];
                break;
            }
          }
        }

        int current = barrack.production1[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    meleeRecruitmentSpeed = res;
  }

  void _updateRangeRecruitmentSpeed(City city) {
    final plasmaRangeMap = buildingsByType[CityNodeIds.plasmaRange];

    int res = 100;

    if (plasmaRangeMap != null) {
      for (String pos in plasmaRangeMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.plasmaRange) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final militaryBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(militaryBuildingPos)) continue;

            Plot militaryBuilding =
                city.plots[militaryBuildingPos.oneDForm.toString()];
            if (militaryBuilding == null) continue;

            switch (militaryBuilding.type) {
              case CityNodeIds.garrison:
                perc += garrison.production1[militaryBuilding.level - 1];
                break;
            }
          }
        }

        int current = plasmaRange.production1[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    rangeRecruitmentSpeed = res;
  }

  void _updateSiegeRecruitmentSpeed(City city) {
    final artilleryYardMap = buildingsByType[CityNodeIds.artilleryYard];

    int res = 100;

    if (artilleryYardMap != null) {
      for (String pos in artilleryYardMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.artilleryYard) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final militaryBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(militaryBuildingPos)) continue;

            Plot militaryBuilding =
                city.plots[militaryBuildingPos.oneDForm.toString()];
            if (militaryBuilding == null) continue;

            switch (militaryBuilding.type) {
              case CityNodeIds.garrison:
                perc += garrison.production1[militaryBuilding.level - 1];
                break;
            }
          }
        }

        int current = artilleryYard.production1[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    siegeRecruitmentSpeed = res;
  }

  void _updateTroopSpace(City city) {
    final garrisonMap = buildingsByType[CityNodeIds.garrison];

    int res = city.level * 10;

    if (garrisonMap != null) {
      for (String pos in garrisonMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.garrison) {
          // TODO this can't be. log!
          continue;
        }

        int perc = 100;

        final intPos = Pos.fromString(pos);
        for (int x = intPos.x - 1; x <= intPos.x + 1; x++) {
          if (x < 0 || x >= C.numCols) continue;

          for (int y = intPos.y - 1; y <= intPos.y + 1; y++) {
            if (y < 0 || y >= C.numRows) continue;

            final militaryBuildingPos = Pos(x: x, y: y);
            if (intPos.isSame(militaryBuildingPos)) continue;

            Plot militaryBuilding =
                city.plots[militaryBuildingPos.oneDForm.toString()];
            if (militaryBuilding == null) continue;

            switch (militaryBuilding.type) {
              case CityNodeIds.barrack:
                perc += barrack.production2[militaryBuilding.level - 1];
                break;
              case CityNodeIds.plasmaRange:
                perc += plasmaRange.production2[militaryBuilding.level - 1];
                break;
              case CityNodeIds.artilleryYard:
                perc += artilleryYard.production2[militaryBuilding.level - 1];
                break;
            }
          }
        }

        int current = garrison.production2[plot.level - 1];
        current = current * perc ~/ 100;

        res += current;
      }
    }

    if (buildingsByType[CityNodeIds.commandCenter] != null) {
      final plot =
          city.plots[buildingsByType[CityNodeIds.commandCenter].keys.first];

      if (plot == null) {
        // TODO this can't be. log!
      } else if (plot.type != CityNodeIds.commandCenter) {
        // TODO this can't be. log!
      } else {
        res = res * commandCenter.production1[plot.level - 1] ~/ 100;
      }
    }

    troopSpace = res;
  }

  void _updateMeleeRecruitable(City city) {
    final barrackMap = buildingsByType[CityNodeIds.barrack];

    final res = <String, void>{};

    if (barrackMap != null) {
      for (String pos in barrackMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.barrack) {
          // TODO this can't be. log!
          continue;
        }

        for (final unitStat in meleeUnits) {
          if (plot.level >= unitStat.minBuildingLevelRequired) {
            res[unitStat.id.toString()] = null;
          }
        }

        if (plot.level == 10) break;
      }
    }

    for (final unitStat in meleeUnits) {
      recruitable.remove(unitStat.id.toString());
    }

    recruitable.addAll(res);
  }

  void _updateRangeRecruitable(City city) {
    final plasmaRangeMap = buildingsByType[CityNodeIds.plasmaRange];

    final res = <String, void>{};

    if (plasmaRangeMap != null) {
      for (String pos in plasmaRangeMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.plasmaRange) {
          // TODO this can't be. log!
          continue;
        }

        for (final unitStat in rangedUnits) {
          if (plot.level >= unitStat.minBuildingLevelRequired) {
            res[unitStat.id.toString()] = null;
          }
        }

        if (plot.level == 10) break;
      }
    }

    for (final unitStat in rangedUnits) {
      recruitable.remove(unitStat.id.toString());
    }

    recruitable.addAll(res);
  }

  void _updateSiegeRecruitable(City city) {
    final artilleryYardMap = buildingsByType[CityNodeIds.artilleryYard];

    final res = <String, void>{};

    if (artilleryYardMap != null) {
      for (String pos in artilleryYardMap.keys) {
        final plot = city.plots[pos];

        if (plot == null) {
          // TODO this can't be. log!
          continue;
        }

        if (plot.type != CityNodeIds.artilleryYard) {
          // TODO this can't be. log!
          continue;
        }

        for (final unitStat in siegeUnits) {
          if (plot.level >= unitStat.minBuildingLevelRequired) {
            res[unitStat.id.toString()] = null;
          }
        }

        if (plot.level == 10) break;
      }
    }

    for (final unitStat in siegeUnits) {
      recruitable.remove(unitStat.id.toString());
    }

    recruitable.addAll(res);
  }
}
