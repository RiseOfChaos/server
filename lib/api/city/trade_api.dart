import 'package:jaguar/jaguar.dart';
import 'package:server/models/city.dart';
import 'package:server/storage/storage.dart';

Future<Response> sendResources(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  TradeReq req = await context.bodyAsJson<TradeReq, Map>();

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(TradeErrors422.cityNotYours, statusCode: 422);
  }

  // Check if there is a spot left in trade queue
  if (city.trades.length >= city.maxTradesAllowed) {
    return Response(TradeErrors422.queueFull, statusCode: 422);
  }

  // Check that the city has enough carts
  int cartsNeeded = req.cartsNeeded;
  if (city.freeCarts < cartsNeeded) {
    return Response(TradeErrors422.notEnoughCarts, statusCode: 422);
  }

  // Check that the city has enough resources
  final resources = city.resources.amount(now);
  if (resources < req.resources) {
    // TODO force enqueue if city has minister
    return Response(TradeErrors422.notEnoughResources, statusCode: 422);
  }

  City toCity = await storage.fetchByID(req.toId);
  if (toCity == null) {
    return Response(AssaultErrors422.toCityNotFound, statusCode: 422);
  }

  // Check that cities is reachable
  if (city.continent != toCity.continent) {
    return Response(AssaultErrors422.notReachable, statusCode: 422);
  }

  final tradeId = now.microsecondsSinceEpoch.toString();
  final distance = city.pos.distance(toCity.pos);
  final speed = 1.0; // TODO calculate movement speed
  final duration = Duration(seconds: (distance * speed * 60).toInt());
  final finishesAt = now.add(duration);

  final trade = Trade(
    id: tradeId,
    fromId: city.id,
    toId: toCity.id,
    startedAt: now,
    finishesAt: finishesAt,
    carts: cartsNeeded,
    resources: req.resources,
    returning: false,
  );
  city.trades.add(trade);
  final tradeIn = TradeIn(
    id: tradeId,
    fromId: city.id,
    toId: toCity.id,
    resources: req.resources,
    arrivesAt: finishesAt,
  );
  toCity.tradeIns.add(tradeIn);

  await storage.updateTrade(
      city.trades, city.resources.clone.subtract(req.resources, now));
  await storage.updateTradeIn(toCity.tradeIns, null);

  // TODO
}

Future<Response> cancelTrade(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  String tradeId = context.query['trade'];

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
      context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(CancelTradeErrors422.cityNotYours, statusCode: 422);
  }

  int index = city.trades.indexWhere((t) => t.id == tradeId);
  if (index == -1) {
    return Response(CancelTradeErrors422.tradeNotFound, statusCode: 422);
  }

  final trade = city.trades[index];

  if (trade.returning) {
    return Response(CancelTradeErrors422.alreadyReturning, statusCode: 422);
  }

  City toCity = await storage.fetchByID(trade.toId);
  if (toCity != null) {
    toCity.tradeIns.removeWhere((t) => t.id == tradeId);
  }

  trade.returning = true;
  trade.finishesAt = now.add(now.difference(trade.startedAt));
  trade.startedAt = now;

  await storage.updateTrade(city.trades, null);
  await storage.updateTradeIn(toCity.tradeIns, null);

  // TODO
}

Future<Response> cancelTradeIn(Context context) async {
  String playerId = context.getVariable<String>(id: "playerId");
  String id = context.query['city'];
  String tradeId = context.query['trade'];

  // TODO validate parameters

  DateTime now = DateTime.now();

  final CityStorage storage =
  context.getVariable<CityStorage>(id: "cityStorage");

  City city = await storage.fetchByID(id);

  // Ensure that city belongs to player
  if (city.ownerId != playerId) {
    return Response(CancelTradeInErrors422.cityNotYours, statusCode: 422);
  }

  int index = city.tradeIns.indexWhere((t) => t.id == tradeId);
  if (index == -1) {
    return Response(CancelTradeInErrors422.tradeNotFound, statusCode: 422);
  }
  final tradeIn = city.tradeIns[index];
  city.tradeIns.removeAt(index);

  City fromCity = await storage.fetchByID(tradeIn.fromId);
  if (fromCity != null) {
    int index = fromCity.trades.indexWhere((t) => t.id == tradeId);
    if (index != -1) {
      final trade = city.trades[index];

      if (!trade.returning) {
        trade.returning = true;
        trade.finishesAt = now.add(now.difference(trade.startedAt));
        trade.startedAt = now;
      } else {
        // TODO log
      }
    } else {
      // TODO log
    }
  }

  await storage.updateTrade(fromCity.trades, null);
  await storage.updateTradeIn(city.tradeIns, null);

  // TODO
}
