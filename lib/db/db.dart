import 'package:server/models/city.dart';
import 'package:server/models/player/player.dart';

abstract class CityDb {
  Future<City> create(City city);

  Future<City> fetchByID(String id);

  Future<void> updateConstructionQueue(
    String id,
    List<Construction> constructions,
    TimedResources resources,
    BuildingCache cache,
    Map<int, Plot> plots,
    /* TODO others */
  );

  /*Future<void> constructSlot(
      List<Construction> constructions, Plot plot, BuildingCache cache);*/

  Future<void> updateRecruitmentQueue(String id, List<Recruitment> recruitments,
      Troops troopsHome, TimedResources resources);

  Future<void> updateTroopsHome(String id, Troops troopsHome);

  Future<void> updateCommand(String id, List<Command> commands,
      Troops troopsHome, TimedResources resources);

  Future<void> updateIncomingAttack(String id, List<IncomingAttack> incomingAttacks,
      Troops troops, TimedResources resources);

  Future<void> updateSupport(
      String id, List<OnSupport> onSupports, TimedResources resources);

  Future<void> updateTrade(
      String id, List<Trade> trades, TimedResources resources);

  Future<void> updateTradeIn(
      String id, List<TradeIn> tradeIns, TimedResources resources);
}

abstract class PlayerDb {
  Future<Player> fetchByID(String id);
}
