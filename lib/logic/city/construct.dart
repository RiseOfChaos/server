import 'package:server/models/city.dart';
import 'package:server/storage/storage.dart';

Future<void> scheduleNext(CityStorage storage, String cityId) async {
  final now = DateTime.now();

  final city = await storage.fetchByID(cityId);
  if (city == null) {
    // TODO log
    return;
  }

  if (city.constructions.isEmpty) return;

  final construction = city.constructions.first;

  if (!construction.hasStarted) {
    construction.startedAt = now;
    construction.finishesAt =
        construction.startedAt.add(Duration(seconds: construction.duration));
  }

  await storage.updateConstructionQueue(city.constructions, null, null, null);
}

Future<void> doConstruct(CityStorage storage, String cityId) async {
  final now = DateTime.now();

  final city = await storage.fetchByID(cityId);
  if (city == null) {
    // TODO log
    return;
  }

  if (city.constructions.isEmpty) {
    // TODO we should never be here
    return;
  }

  final construction = city.constructions.first;

  bool success = false;
  if (construction.hasStarted && now.isAfter(construction.finishesAt)) {
    switch (construction.constructionType) {
      case ConstructionType.construct:
        success = await _executeConstruct(storage, city, construction, now);
        // TODO
        break;
      case ConstructionType.upgrade:
        success = await _executeUpgrade(storage, city, construction, now);
        // TODO
        break;
      case ConstructionType.downgrade:
        success = await _executeDowngrade(storage, city, construction, now);
        // TODO
        break;
      case ConstructionType.demolish:
        success = await _executeDemolish(storage, city, construction, now);
        // TODO
        break;
    }

    if (!success) {
      city.constructions.removeAt(0);
      await storage.updateConstructionQueue(
          city.constructions, null, null, null);
    }
  } else {
    // TODO we should never be here
  }

  await scheduleNext(storage, cityId);
}

Future<bool> _executeConstruct(CityStorage storage, City city,
    Construction construction, DateTime now) async {
  final buildingInfo = buildings[construction.buildingType];

  // Plot not empty?
  if (city.plots.containsKey(construction.pos)) {
    return false;
  }

  // Is there a building slot?
  if (city.buildingCache.numBuildings >= city.maxBuildingsAllowed) {
    return false;
  }

  // If castle, check if there is already a castle
  if (buildingInfo == commandCenter && city.buildingCache.castled) {
    return false;
  }

  Plot plot = Plot()
    ..type = construction.buildingType
    ..level = 1
    ..pos = construction.pos;
  city.plots[plot.pos] = plot;

  // TODO
  final buildingCache = city.buildingCache;
  buildingCache.score += buildingInfo.rankPoint.level1;
  // TODO city.buildingCache.hitpoints += buildingInfo.
  buildingCache.castled = buildingInfo == commandCenter;
  buildingCache.numBuildings++;
  buildingCache.addBuilding(plot);
  buildingCache.updateRates(plot, city, now);

  city.constructions.removeAt(0);

  await storage.updateConstructionQueue(
      city.constructions, city.resources, city.buildingCache, city.plots);

  // TODO

  return true;
}

Future<bool> _executeUpgrade(CityStorage storage, City city,
    Construction construction, DateTime now) async {
  final plot = city.plots[construction.pos];
  if (plot == null) {
    return false;
  }

  if (plot.type != construction.buildingType) {
    return false;
  }

  if (plot.level >= 10) {
    return false;
  }

  plot.level++;

  final buildingCache = city.buildingCache;
  buildingCache.score; // TODO
  // TODO buildingCache.hitpoints;
  buildingCache.updateRates(plot, city, now);

  city.constructions.removeAt(0);

  await storage.updateConstructionQueue(
      city.constructions, city.resources, city.buildingCache, city.plots);

  // TODO
}

Future<bool> _executeDowngrade(CityStorage storage, City city,
    Construction construction, DateTime now) async {
  final plot = city.plots[construction.pos];
  if (plot == null) {
    return false;
  }

  if (plot.type != construction.buildingType) {
    return false;
  }

  if (plot.level <= 0) {
    return false;
  } else if (plot.level == 1) {
    if (plot.type == CityNodeIds.commandCenter) {
      return false;
    }
    city.plots.remove(plot.pos);
  } else {
    plot.level--;
  }

  final buildingCache = city.buildingCache;
  buildingCache.score; // TODO
  // TODO buildingCache.hitpoints;
  buildingCache.updateRates(plot, city, now);

  city.constructions.removeAt(0);

  await storage.updateConstructionQueue(
      city.constructions, city.resources, city.buildingCache, city.plots);

  // TODO
}

Future<bool> _executeDemolish(CityStorage storage, City city,
    Construction construction, DateTime now) async {
  if (construction.buildingType == CityNodeIds.commandCenter) {
    return false;
  }
  final plot = city.plots[construction.pos];
  if (plot == null) {
    return false;
  }
  if (plot.type != construction.buildingType) {
    return false;
  }

  city.plots.remove(plot.pos);

  final buildingCache = city.buildingCache;
  buildingCache.score; // TODO
  // TODO buildingCache.hitpoints;
  buildingCache.updateRates(plot, city, now);

  city.constructions.removeAt(0);

  await storage.updateConstructionQueue(
      city.constructions, city.resources, city.buildingCache, city.plots);

  // TODO
}
