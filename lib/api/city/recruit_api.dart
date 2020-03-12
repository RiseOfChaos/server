import 'dart:async';

import 'package:data/city/city.dart';
import 'package:jaguar/jaguar.dart';
import 'package:server/models/city.dart';
import 'package:server/db/db.dart';

Future<Response> recruit(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  int type = context.query.getInt('type');
  int amount = context.query.getInt('amount');

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(RecruitErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in construction queue
  if (city.recruitments.length >= city.maxRecruitmentsAllowed) {
    return Response(RecruitErrors422.queueFull, statusCode: 422);
  }

  // Check if units are recuitable
  if (!city.buildingCache.recruitable.containsKey(type)) {
    return Response(RecruitErrors422.notResearched, statusCode: 422);
  }

  // Check if there is troopspace left
  int troopspace = units[type].space * amount;
  if (troopspace > city.buildingCache.troopSpace) {
    // TODO also take into account the troop space in queue
    return Response(RecruitErrors422.notEnoughTroopSpace, statusCode: 422);
  }

  // Check if there are enough resources
  Resources cost = units[type].cost * amount;
  Resources resAvailable = city.resources.amount(now);
  if (cost > resAvailable) {
    return Response(RecruitErrors422.notEnoughResources, statusCode: 422);
  }

  int incAmount = 10;
  if (incAmount > amount) incAmount = amount;
  Recruitment recruitment = Recruitment(
    id: now.microsecondsSinceEpoch.toString(),
    type: type,
    amount: amount,
    resources: cost,
    duration:
        city.recruitmentTime(incAmount * units[type].recruitmentSpeed, type),
  );
  // If the construction queue empty, start recruitment immediately!
  if (city.recruitments.isEmpty) {
    recruitment.startedAt = now;
    recruitment.finishesAt =
        recruitment.startedAt.add(Duration(seconds: recruitment.duration));
  }
  city.recruitments.add(recruitment);

  await storage.updateRecruitmentQueue(city.id, city.recruitments, null,
      city.resources.clone.subtract(cost, now));

  // TODO trigger ministers

  // TODO return model
}

Future<Response> discharge(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  int type = context.query.getInt('type');
  Troops troops; // TODO
  // int amount = context.query.getInt('amount');

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(DischargeErrors422.cityNotYours, statusCode: 422);
  }

  if (troops > city.troopsHome) {
    return Response(DischargeErrors422.notEnoughTroops, statusCode: 422);
  }

  city.troopsHome.subtract(troops);

  // TODO refund
  await storage.updateTroopsHome(city.id, city.troopsHome);

  // TODO trigger minister recruit

  // TODO return response
}
