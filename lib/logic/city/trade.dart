import 'package:server/models/city.dart';
import 'package:server/db/db.dart';

Future<void> doTrade(CityDb storage, String cityId) async {
  final now = DateTime.now();

  final city = await storage.fetchByID(cityId);
  if (city == null) {
    // TODO log
    return;
  }

  if (city.trades.isEmpty) {
    // TODO we should never be here
    return;
  }

  final trade = city.trades
      .firstWhere((t) => t.finishesAt != null && now.isAfter(t.finishesAt));

  if (trade.isReturning) {
    city.trades.remove(trade);
    TimedResources res;
    if (!trade.resources.isZero) {
      res = city.resources.add(trade.resources, now);
    }
    await storage.updateTrade(city.id, city.trades, res);
  } else {
    trade.isReturning = true;
    Duration duration =
        now.difference(trade.startedAt); // TODO compute from distance
    trade.finishesAt = now.add(duration);
    trade.startedAt = now;

    City toCity = await storage.fetchByID(trade.toId);
    if (toCity != null) {
      toCity.tradeIns.removeWhere((t) => t.id == trade.id);

      TimedResources res = toCity.resources.add(trade.resources, now);
      trade.resources = Resources();
      await storage.updateTradeIn(toCity.id, toCity.tradeIns, res);
    }

    await storage.updateTrade(city.id, city.trades, null);
  }
}
