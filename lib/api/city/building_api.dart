import 'dart:async';

import 'package:data/city/city.dart';
import 'package:data/data.dart';
import 'package:jaguar/jaguar.dart';
import 'package:server/models/city.dart';
import 'package:server/storage/storage.dart';

Future<Response> constructBuilding(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  int pos = context.query.getInt('pos');
  int buildingType = context.query.getInt('building');

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(ConstructBuildingErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in construction queue
  if (city.constructions.length >= city.maxConstructionsAllowed) {
    return Response(ConstructBuildingErrors422.queueFull, statusCode: 422);
  }

  // Check that city is not maxed
  if (city.buildingCache.numBuildings >= city.maxBuildingsAllowed) {
    // TODO take into account buildings being demolished or destroyed
    return Response(ConstructBuildingErrors422.notEnoughBuildingSpace,
        statusCode: 422);
  }

  // TODO check if the plot is not city center

  // Check if the plot is empty
  if (city.plots.containsKey(pos)) {
    return Response(ConstructBuildingErrors422.notEmpty, statusCode: 422);
  }

  // Check that there is no on-going construction on this plot
  if (city.getPlotAfterConstructions(pos) != null) {
    return Response(ConstructBuildingErrors422.notEmpty, statusCode: 422);
  }

  // Check that the city has enough resources
  final resources = city.resources.amount(now);
  final buildingInfo = buildings[buildingType];
  final ResourceBase cost = buildingInfo.cost.level1;
  if (resources < cost) {
    // TODO force enqueue if city has minister
    return Response(ConstructBuildingErrors422.notEnoughResources,
        statusCode: 422);
  }

  final construction = Construction(
    id: now.microsecondsSinceEpoch.toString(),
    pos: pos,
    buildingType: buildingType,
    constructionType: ConstructionType.construct,
    duration: city.buildTime(buildingInfo.buildTime.level1),
  );
  // If the construction queue has only one item, start construction immediately!
  if (city.constructions.isEmpty) {
    construction.startedAt = now;
    construction.finishesAt =
        construction.startedAt.add(Duration(seconds: construction.duration));
  }
  city.constructions.add(construction);

  // Save to database
  await storage.updateConstructionQueue(
      city.constructions, city.resources.clone.subtract(cost, now), null, null);

  // TODO return model
}

Future<Response> upgradeBuilding(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  int pos = context.query.getInt('pos');

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(UpgradeBuildingErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in construction queue
  if (city.constructions.length >= city.maxConstructionsAllowed) {
    return Response(UpgradeBuildingErrors422.queueFull, statusCode: 422);
  }

  final plot = city.getPlotAfterConstructions(pos);
  // Check that there is a building
  if (plot == null) {
    return Response(UpgradeBuildingErrors422.empty, statusCode: 422);
  }

  // Check that the building has not reached max level
  if (plot.level >= 10) {
    return Response(UpgradeBuildingErrors422.atMaxLevel, statusCode: 422);
  }

  // Check that the city has enough resources
  final resources = city.resources.amount(now);
  final buildingInfo = buildings[plot.type];
  final ResourceBase cost = buildingInfo.cost[plot.level];
  if (resources < cost) {
    // TODO force enqueue if city has minister
    return Response(UpgradeBuildingErrors422.notEnoughResources,
        statusCode: 422);
  }

  final construction = Construction(
      id: now.microsecondsSinceEpoch.toString(),
      pos: pos,
      buildingType: plot.type,
      constructionType: ConstructionType.upgrade,
      duration: city.buildTime(buildingInfo.buildTime[plot.level]));
  // If the construction queue has only one item, start construction immediately!
  if (city.constructions.isEmpty) {
    construction.startedAt = now;
    construction.finishesAt =
        construction.startedAt.add(Duration(seconds: construction.duration));
  }
  city.constructions.add(construction);

  // Save to database
  await storage.updateConstructionQueue(
      city.constructions, city.resources.clone.subtract(cost, now), null, null);

  // TODO trigger ministers

  // TODO return model
}

Future<Response> downgradeBuilding(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  int pos = context.query.getInt('pos');

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(DowngradeBuildingErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in construction queue
  if (city.constructions.length >= city.maxConstructionsAllowed) {
    return Response(DowngradeBuildingErrors422.queueFull, statusCode: 422);
  }

  if (!city.canDowngradePlot(pos)) {
    return Response(DowngradeBuildingErrors422.cannotDowngradeConstructing,
        statusCode: 422);
  }

  var plot = city.plots[pos];
  if (plot == null) {
    return Response(DowngradeBuildingErrors422.empty, statusCode: 422);
  }
  // Check if plot is building
  if (!C.isBuilding(plot.type)) {
    return Response(DowngradeBuildingErrors422.notBuilding, statusCode: 422);
  }
  plot = city.getPlotAfterConstructions(pos);
  if (plot.level == null) {
    return Response(DowngradeBuildingErrors422.destroyed, statusCode: 422);
  }

  final buildingInfo = buildings[plot.type];

  final construction = Construction(
      id: now.microsecondsSinceEpoch.toString(),
      pos: pos,
      buildingType: plot.type,
      constructionType: ConstructionType.downgrade,
      duration: city.buildTime(buildingInfo.buildTime[plot.level - 1] ~/ 2));
  // If the construction queue has only one item, start construction immediately!
  if (city.constructions.isEmpty) {
    construction.startedAt = now;
    construction.finishesAt =
        construction.startedAt.add(Duration(seconds: construction.duration));
  }
  city.constructions.add(construction);

  // Save to database
  await storage.updateConstructionQueue(city.constructions, null, null, null);

  // TODO return model
}

Future<Response> demolishBuilding(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  int pos = context.query.getInt('pos');

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(DemolishBuildingErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in construction queue
  if (city.constructions.length >= city.maxConstructionsAllowed) {
    return Response(DemolishBuildingErrors422.queueFull, statusCode: 422);
  }

  if (!city.canDemolishPlot(pos)) {
    return Response(DemolishBuildingErrors422.cannotDemolishConstructing,
        statusCode: 422);
  }

  final plot = city.plots[pos];
  if (plot == null) {
    return Response(DemolishBuildingErrors422.empty, statusCode: 422);
  }
  // Check if plot is building
  if (!C.isBuilding(plot.type)) {
    return Response(DowngradeBuildingErrors422.notBuilding, statusCode: 422);
  }
  if (plot.level < 1) {
    return Response(DemolishBuildingErrors422.destroyed, statusCode: 422);
  }

  final buildingInfo = buildings[plot.type];

  final construction = Construction(
      id: now.microsecondsSinceEpoch.toString(),
      pos: pos,
      buildingType: plot.type,
      constructionType: ConstructionType.demolish,
      duration: city.buildTime(buildingInfo.buildTime[plot.level - 1] ~/ 2));
  // If the construction queue has only one item, start construction immediately!
  if (city.constructions.isEmpty) {
    construction.startedAt = now;
    construction.finishesAt =
        construction.startedAt.add(Duration(seconds: construction.duration));
  }
  city.constructions.add(construction);

  // Save to database
  await storage.updateConstructionQueue(city.constructions, null, null, null);

  // TODO return model
}

Future<Response> cancelConstruction(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  String constructionId = context.query['constructionId'];

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(CancelConstructionErrors422.cityNotYours, statusCode: 422);
  }

  final constructionIndex =
      city.constructions.indexWhere((c) => c.id == constructionId);
  if (constructionIndex == -1) {
    return Response(CancelConstructionErrors422.notFound, statusCode: 422);
  }

  final construction = city.constructions.removeAt(constructionIndex);

  TimedResources refund;
  if (construction.constructionType == ConstructionType.construct ||
      construction.constructionType == ConstructionType.upgrade) {
    final plot = city.getPlotAfterConstructions(construction.pos);
    final cost = buildings[plot.type].cost[plot.level - 1];
    refund = city.resources.clone.add(cost, now);
  }

  // Save to database
  await storage.updateConstructionQueue(city.constructions, refund, null, null);

  // TODO return model
}

// TODO move building
