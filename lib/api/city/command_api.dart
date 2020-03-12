import 'dart:async';

import 'package:data/city/city.dart';
import 'package:jaguar/jaguar.dart';
import 'package:server/db/db.dart';
import 'package:server/models/city.dart';

Future<Response> assault(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  AssaultReq req = await context.bodyAsJson<AssaultReq, Map>(); // parse it

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(AssaultErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in command queue
  if (city.commands.length >= city.maxCommandsAllowed) {
    return Response(AssaultErrors422.queueFull, statusCode: 422);
  }

  // Check that the city is castled
  if (!city.buildingCache.castled) {
    return Response(AssaultErrors422.notCastled, statusCode: 422);
  }

  // Check that there are enough troops
  if (city.troopsHome < req.troops) {
    return Response(AssaultErrors422.notEnoughTroop, statusCode: 422);
  }

  City toCity = await storage.fetchByID(req.toId);
  if (toCity == null) {
    return Response(AssaultErrors422.toCityNotFound, statusCode: 422);
  }

  // Checks that toCity is castled
  if (!toCity.buildingCache.castled) {
    return Response(AssaultErrors422.toCityNotCastled, statusCode: 422);
  }

  // Check that toCity does not belong to same player or alliance
  if (toCity.ownerId != null) {
    if (toCity.ownerId == city.ownerId) {
      return Response(AssaultErrors422.cannotAttackOwnAlliance,
          statusCode: 422);
    }

    // TODO check that toCity does not belong to same alliance
  }

  // Check that city is reachable
  if (city.continent != toCity.continent) {
    return Response(AssaultErrors422.notReachable, statusCode: 422);
  }

  // TODO check minimum number of troops are sent

  final distance = city.pos.distance(toCity.pos);
  final speed = 1.0; // TODO calculate movement speed
  final duration = Duration(seconds: (distance * speed * 60).toInt());
  final finishesAt = now.add(duration);
  final command = Command(
    id: now.microsecondsSinceEpoch.toString(),
    type: CommandType.assault,
    fromId: city.id,
    toId: city.id,
    troops: req.troops,
    state: CommandState.going,
    startedAt: now,
    finishesAt: finishesAt,
  );
  city.troopsHome.subtract(req.troops);
  city.commands.add(command);

  final incomingAttack = IncomingAttack(
    id: command.id,
    fromId: city.id,
    hitsAt: finishesAt,
  );
  city.incomingAttacks.add(incomingAttack);

  await storage.updateCommand(city.id, city.commands, city.troopsHome, null);
  await storage.updateIncomingAttack(
      toCity.id, toCity.incomingAttacks, null, null);

  // TODO
}

Future<Response> siege(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  AssaultReq req = await context.bodyAsJson<AssaultReq, Map>(); // parse it

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(AssaultErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in command queue
  if (city.commands.length >= city.maxCommandsAllowed) {
    return Response(AssaultErrors422.queueFull, statusCode: 422);
  }

  // Check that the city is castled
  if (!city.buildingCache.castled) {
    return Response(AssaultErrors422.notCastled, statusCode: 422);
  }

  // Check that there are enough troops
  if (city.troopsHome < req.troops) {
    return Response(AssaultErrors422.notEnoughTroop, statusCode: 422);
  }

  City toCity = await storage.fetchByID(req.toId);
  if (toCity == null) {
    return Response(AssaultErrors422.toCityNotFound, statusCode: 422);
  }

  // Checks that toCity is castled
  if (!toCity.buildingCache.castled) {
    return Response(AssaultErrors422.toCityNotCastled, statusCode: 422);
  }

  // Check that toCity does not belong to same player or alliance
  if (toCity.ownerId != null) {
    if (toCity.ownerId == city.ownerId) {
      return Response(AssaultErrors422.cannotAttackOwnAlliance,
          statusCode: 422);
    }

    // TODO check that toCity does not belong to same alliance
  }

  // Check that city is reachable
  if (city.continent != toCity.continent) {
    return Response(AssaultErrors422.notReachable, statusCode: 422);
  }

  // TODO check minimum number of troops are sent

  final distance = city.pos.distance(toCity.pos);
  final speed = 1.0; // TODO calculate movement speed
  final duration = Duration(seconds: (distance * speed * 60).toInt());
  final finishesAt = now.add(duration);
  final command = Command(
    id: now.microsecondsSinceEpoch.toString(),
    type: CommandType.siege,
    fromId: city.id,
    toId: city.id,
    troops: req.troops,
    state: CommandState.going,
    startedAt: now,
    finishesAt: finishesAt,
  );
  city.troopsHome.subtract(req.troops);
  city.commands.add(command);

  final incomingAttack = IncomingAttack(
    id: command.id,
    fromId: city.id,
    hitsAt: finishesAt,
  );
  city.incomingAttacks.add(incomingAttack);

  await storage.updateCommand(city.id, city.commands, city.troopsHome, null);
  await storage.updateIncomingAttack(
      toCity.id, toCity.incomingAttacks, null, null);

  // TODO
}

Future<Response> raid(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  AssaultReq req = await context.bodyAsJson<AssaultReq, Map>(); // parse it

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(AssaultErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in command queue
  if (city.commands.length >= city.maxCommandsAllowed) {
    return Response(AssaultErrors422.queueFull, statusCode: 422);
  }

  // Check that there are enough troops
  if (city.troopsHome < req.troops) {
    return Response(AssaultErrors422.notEnoughTroop, statusCode: 422);
  }

  City toCity = await storage.fetchByID(req.toId);
  if (toCity == null) {
    return Response(AssaultErrors422.toCityNotFound, statusCode: 422);
  }

  // Check that toCity does not belong to same player or alliance
  if (toCity.ownerId != null) {
    if (toCity.ownerId == city.ownerId) {
      return Response(AssaultErrors422.cannotAttackOwnAlliance,
          statusCode: 422);
    }

    // TODO check that toCity does not belong to same alliance
  }

  // Check that city is reachable
  if (city.continent != toCity.continent) {
    return Response(AssaultErrors422.notReachable, statusCode: 422);
  }

  // TODO check minimum number of troops are sent

  final distance = city.pos.distance(toCity.pos);
  final speed = 1.0; // TODO calculate movement speed
  final duration = Duration(seconds: (distance * speed * 60).toInt());
  final finishesAt = now.add(duration);
  final command = Command(
    id: now.microsecondsSinceEpoch.toString(),
    type: CommandType.plunder,
    fromId: city.id,
    toId: city.id,
    troops: req.troops,
    state: CommandState.going,
    startedAt: now,
    finishesAt: finishesAt,
  );
  city.troopsHome.subtract(req.troops);
  city.commands.add(command);

  final incomingAttack = IncomingAttack(
    id: command.id,
    fromId: city.id,
    hitsAt: finishesAt,
  );
  city.incomingAttacks.add(incomingAttack);

  await storage.updateCommand(city.id, city.commands, city.troopsHome, null);
  await storage.updateIncomingAttack(
      toCity.id, toCity.incomingAttacks, null, null);

  // TODO
}

Future<Response> support(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  AssaultReq req = await context.bodyAsJson<AssaultReq, Map>(); // parse it

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(AssaultErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in command queue
  if (city.commands.length >= city.maxCommandsAllowed) {
    return Response(AssaultErrors422.queueFull, statusCode: 422);
  }

  // Check that there are enough troops
  if (city.troopsHome < req.troops) {
    return Response(AssaultErrors422.notEnoughTroop, statusCode: 422);
  }

  City toCity = await storage.fetchByID(req.toId);
  if (toCity == null) {
    return Response(AssaultErrors422.toCityNotFound, statusCode: 422);
  }

  // Check that city is reachable
  if (city.continent != toCity.continent) {
    return Response(AssaultErrors422.notReachable, statusCode: 422);
  }

  // TODO check minimum number of troops are sent

  final distance = city.pos.distance(toCity.pos);
  final speed = 1.0; // TODO calculate movement speed
  final duration = Duration(seconds: (distance * speed * 60).toInt());
  final finishesAt = now.add(duration);
  final command = Command(
    id: now.microsecondsSinceEpoch.toString(),
    type: CommandType.support,
    fromId: city.id,
    toId: city.id,
    troops: req.troops,
    state: CommandState.going,
    startedAt: now,
    finishesAt: finishesAt,
  );
  city.troopsHome.subtract(req.troops);
  city.commands.add(command);

  final support = OnSupport(
    id: command.id,
    fromId: city.id,
    arrivesAt: finishesAt,
  );
  city.onSupports.add(support);

  await storage.updateCommand(city.id, city.commands, city.troopsHome, null);
  await storage.updateSupport(toCity.id, toCity.onSupports, null);

  // TODO
}

Future<dynamic> cancelCommand(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  String cmdId = context.query['command'];

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(CancelCmdErrors422.cityNotYours, statusCode: 422);
  }

  final cmd =
      city.commands.firstWhere((c) => c.id == cmdId, orElse: () => null);
  if (cmd == null) {
    return Response(CancelCmdErrors422.cmdNotFound, statusCode: 422);
  }

  if (cmd.type == CommandType.support || cmd.type == CommandType.loot) {
    return Response(CancelCmdErrors422.cannotBeSupportOrLoot, statusCode: 422);
  }

  if (cmd.state == CommandState.returning) {
    return Response(CancelCmdErrors422.alreadyReturning, statusCode: 422);
  }

  if (cmd.state == CommandState.going) {
    if (now.isAfter(cmd.startedAt.add(maxCommandCancelDuration))) {
      return Response(CancelCmdErrors422.tooLateToCancel, statusCode: 422);
    }
  }

  cmd.state = CommandState.returning;
  final duration = now.difference(cmd.startedAt); // TODO
  cmd.finishesAt = now.add(duration);
  cmd.startedAt = now;

  final toCity = await storage.fetchByID(cmd.toId);
  if (toCity != null) {
    final attack = toCity.incomingAttacks.firstWhere((a) => a.id == cmd.id);
    if (attack != null) {
      toCity.incomingAttacks.remove(attack);
      await storage.updateIncomingAttack(
          toCity.id, toCity.incomingAttacks, null, null);
    } else {
      // TODO log
    }
  } else {
    // TODO log
  }

  await storage.updateCommand(city.id, city.commands, null, null);

  // TODO
}

Future<dynamic> cancelSupport(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  String cmdId = context.query['command'];

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);
  if (city == null) {
    // TODO
  }

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(AssaultErrors422.cityNotYours, statusCode: 422);
  }

  final cmd =
      city.commands.firstWhere((c) => c.id == cmdId, orElse: () => null);
  if (cmd == null) {
    return Response(CancelCmdErrors422.cmdNotFound, statusCode: 422);
  }

  if (cmd.state == CommandState.returning) {
    return Response(CancelCmdErrors422.alreadyReturning, statusCode: 422);
  }

  cmd.state = CommandState.returning;
  final duration = now.difference(cmd.startedAt); // TODO
  cmd.finishesAt = now.add(duration);
  cmd.startedAt = now;

  final toCity = await storage.fetchByID(cmd.toId);
  if (toCity != null) {
    final attack = toCity.onSupports.firstWhere((a) => a.id == cmd.id);
    if (attack != null) {
      toCity.onSupports.remove(attack);
      await storage.updateSupport(toCity.id, toCity.onSupports, null);
    } else {
      // TODO log
    }
  } else {
    // TODO log
  }

  await storage.updateCommand(city.id, city.commands, null, null);

  // TODO
}

Future<dynamic> sendBackSupport(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  String cmdId = context.query['command'];

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityDb storage = context.getVariable<CityDb>(id: "cityStorage");

  City city = await storage.fetchByID(id);
  if (city == null) {
    // TODO
  }

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(SendBackSupportErrors422.cityNotYours, statusCode: 422);
  }

  final onSup =
      city.onSupports.firstWhere((s) => s.id == cmdId, orElse: () => null);
  if (onSup == null) {
    return Response(SendBackSupportErrors422.cmdNotFound, statusCode: 422);
  }

  city.onSupports.remove(onSup);

  final fromCity = await storage.fetchByID(onSup.fromId);
  if (fromCity != null) {
    final sup =
        fromCity.commands.firstWhere((s) => s.id == cmdId, orElse: () => null);
    if (sup != null && sup.state != CommandState.returning) {
      sup.state = CommandState.returning;
      final duration = now.difference(sup.startedAt); // TODO
      sup.finishesAt = now.add(duration);
      sup.startedAt = now;

      await storage.updateCommand(fromCity.id, fromCity.commands, null, null);
    } else {
      // TODO log
    }
  } else {
    // TODO log
  }

  await storage.updateSupport(city.id, city.onSupports, null);

  // TODO
}
