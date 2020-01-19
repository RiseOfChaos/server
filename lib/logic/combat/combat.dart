import 'package:server/models/models.dart';
import 'package:server/models/player/player.dart';

class Army {
  Troops troops;

  City city;

  Player player;

  Command command;

  // TODO bonuses

  CombatArmyResult result;

  Army({this.troops, this.city, this.player, this.command});
}

class CombatArmyResult {
  Troops died;

  Troops remaining;

  Resources loot;
}

void assault(
  Army attacker,
  Army defender,
  List<Army> supports,
) {
  // TODO
}

void siege(
  Army attacker,
  Army defender,
  List<Army> supports,
) {
  // TODO
}
