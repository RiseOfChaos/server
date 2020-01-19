import 'package:data/city/city.dart';
import 'package:server/logic/combat/combat.dart';
import 'package:server/models/city.dart';
import 'package:server/models/player/player.dart';
import 'package:server/storage/storage.dart';

Future<List<Army>> getSupportArmy(DateTime now, City city,
    CityStorage cityStorage, PlayerStorage playerStorage) async {
  final ret = <Army>[];

  final cities = <String, City>{};
  final players = <String, Player>{};

  for (final sup in city.onSupports) {
    if (now.isBefore(sup.arrivesAt)) continue;

    // Fetch city
    City fromCity;
    if (!cities.containsKey(sup.fromId)) {
      fromCity = await cityStorage.fetchByID(sup.fromId);
      cities[sup.fromId] = fromCity;
    } else {
      fromCity = cities[sup.fromId];
    }

    if (fromCity == null) continue;

    // Find command
    final cmd =
    fromCity.commands.firstWhere((c) => c.id == sup.id, orElse: () => null);
    if (cmd == null) continue;

    if (cmd.state != CommandState.staying) continue;

    // Fetch player
    Player player;
    if (!players.containsKey(fromCity.ownerId)) {
      player = await playerStorage.fetchByID(fromCity.ownerId);
      players[fromCity.ownerId] = player;
    } else {
      player = players[fromCity.ownerId];
    }

    ret.add(Army(
        troops: cmd.troops.clone,
        city: fromCity,
        player: player,
        command: cmd));
  }

  return ret;
}

Future<Army> getDefender(DateTime now, City toCity, CityStorage cityStorage,
    PlayerStorage playerStorage) async {
  // Fetch player
  Player player = await playerStorage.fetchByID(toCity.ownerId);

  return Army(troops: toCity.troopsHome, city: toCity, player: player);
}