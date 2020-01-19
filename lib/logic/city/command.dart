import 'package:data/city/city.dart';
import 'package:server/logic/combat/combat.dart';
import 'package:server/models/city.dart';
import 'package:server/storage/storage.dart';

import 'command_helper.dart';

Future<void> doCommand(
    CityStorage cityStorage, PlayerStorage playerStorage, String cityId) async {
  final now = DateTime.now();

  final city = await cityStorage.fetchByID(cityId);
  if (city == null) {
    // TODO log
    return;
  }

  if (city.commands.isEmpty) {
    // TODO we should never be here
    return;
  }

  final command = city.commands
      .firstWhere((t) => t.finishesAt != null && now.isAfter(t.finishesAt));

  if (command.state == CommandState.returning) {
    city.commands.remove(command);
    TimedResources res;
    if (!command.loot.isZero) {
      res = city.resources.add(command.loot, now);
    }
    city.troopsHome.add(command.troops);
    await cityStorage.updateCommand(city.commands, city.troopsHome, res);
  } else if (command.state == CommandState.going ||
      command.state == CommandState.staying) {
    switch (command.type) {
      case CommandType.plunder:
      case CommandType.assault:
        await _doAssault(now, cityStorage, playerStorage, city, command);
        break;
      case CommandType.siege:
        await _doSiege(now, cityStorage, playerStorage, city, command);
        break;
      case CommandType.support:
        await _doSupport(now, cityStorage, city, command);
        break;
      case CommandType.loot:
        await _doLoot(now, cityStorage, city, command);
        break;
    }
    // TODO
  }
  // TODO
}

Future<void> _doAssault(DateTime now, CityStorage cityStorage,
    PlayerStorage playerStorage, City city, Command command) async {
  final toCity = await cityStorage.fetchByID(command.toId);
  if (toCity == null) {
    // TODO return command
    // TODO log?
    return;
  }

  final attacker = Army(
    troops: command.troops,
    player: null, // TODO
    city: city,
    command: null,
  );
  final defender = await getDefender(now, toCity, cityStorage, playerStorage);
  final supports =
      await getSupportArmy(now, toCity, cityStorage, playerStorage);
  assault(attacker, defender, supports);

  command.state = CommandState.returning;
  command.startedAt = now;
  command.finishesAt; // TODO
  command.troops = attacker.result.remaining;
  command.loot = attacker.result.loot;

  await cityStorage.updateCommand(attacker.city.commands, null, null);

  for (final sup in supports) {
    if (sup.result.remaining.isZero) {
      toCity.onSupports.removeWhere((s) => s.id == sup.command.id);

      sup.city.commands.remove(sup.command);
      await cityStorage.updateCommand(sup.city.commands, null, null);
    } else {
      sup.command.troops = sup.result.remaining;
      await cityStorage.updateCommand(sup.city.commands, null, null);
    }
  }

  city.incomingAttacks.removeWhere((ia) => ia.id == command.id);
  city.troopsHome = defender.result.remaining;
  final res = city.resources.subtract(defender.result.loot, now);
  await cityStorage.updateIncomingAttack(
      city.incomingAttacks, city.troopsHome, res);
}

Future<void> _doSupport(
    DateTime now, CityStorage storage, City city, Command command) async {
  command.state = CommandState.staying;
  command.startedAt = now;
  command.finishesAt = null;

  await storage.updateCommand(city.commands, null, null);
}

Future<void> _doSiege(DateTime now, CityStorage cityStorage,
    PlayerStorage playerStorage, City city, Command command) async {
  final toCity = await cityStorage.fetchByID(command.toId);
  if (toCity == null) {
    // TODO return command
    // TODO log?
    return;
  }

  final attacker = Army(
    troops: command.troops,
    player: null, // TODO
    city: city,
    command: null,
  );
  final defender = await getDefender(now, toCity, cityStorage, playerStorage);
  final supports =
      await getSupportArmy(now, toCity, cityStorage, playerStorage);
  siege(attacker, defender, supports);

  command.state = CommandState.returning;
  command.startedAt = now;
  command.finishesAt; // TODO
  command.troops = attacker.result.remaining;
  command.loot = attacker.result.loot;

  await cityStorage.updateCommand(attacker.city.commands, null, null);

  for (final sup in supports) {
    if (sup.result.remaining.isZero) {
      toCity.onSupports.removeWhere((s) => s.id == sup.command.id);

      sup.city.commands.remove(sup.command);
      await cityStorage.updateCommand(sup.city.commands, null, null);
    } else {
      sup.command.troops = sup.result.remaining;
      await cityStorage.updateCommand(sup.city.commands, null, null);
    }
  }

  city.incomingAttacks.removeWhere((ia) => ia.id == command.id);
  city.troopsHome = defender.result.remaining;
  final res = city.resources.subtract(defender.result.loot, now);
  await cityStorage.updateIncomingAttack(
      city.incomingAttacks, city.troopsHome, res);
}

Future<void> _doLoot(
    DateTime now, CityStorage storage, City city, Command command) async {
  // TODO
}
