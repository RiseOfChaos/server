import 'package:server/models/city.dart';
import 'package:server/models/player/player.dart';

abstract class CityStorage {
  Future<City> fetchByID(String id);

  Future<void> updateConstructionQueue(
    List<Construction> constructions,
    TimedResources resources,
    BuildingCache cache,
    Map<int, Plot> plots,
    /* TODO others */
  );

  /*Future<void> constructSlot(
      List<Construction> constructions, Plot plot, BuildingCache cache);*/

  Future<void> updateRecruitmentQueue(List<Recruitment> recruitments,
      Troops troopsHome, TimedResources resources);

  Future<void> updateTroops(Troops total);

  Future<void> updateCommand(
      List<Command> commands, Troops troopsHome, TimedResources resources);

  Future<void> updateIncomingAttack(
      List<IncomingAttack> attacks, Troops troops, TimedResources resources);

  Future<void> updateSupport(
      List<OnSupport> supports, TimedResources resources);

  Future<void> updateTrade(List<Trade> trades, TimedResources resources);

  Future<void> updateTradeIn(List<TradeIn> trades, TimedResources resources);
}

abstract class PlayerStorage {
  Future<Player> fetchByID(String id);
}
