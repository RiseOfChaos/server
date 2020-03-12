import 'package:server/models/city.dart';
import 'package:server/db/db.dart';

Future<void> scheduleNext(CityDb storage, String cityId) async {
  final now = DateTime.now();

  final city = await storage.fetchByID(cityId);
  if (city == null) {
    // TODO log
    return;
  }

  if (city.recruitments.isEmpty) return;

  final recruitment = city.recruitments.first;

  if (!recruitment.hasStarted) {
    recruitment.startedAt = now;
    recruitment.finishesAt =
        recruitment.startedAt.add(Duration(seconds: recruitment.duration));
  }

  await storage.updateRecruitmentQueue(city.id, city.recruitments, null, null);
}

Future<void> doRecruitment(CityDb storage, String cityId) async {
  final now = DateTime.now();

  final city = await storage.fetchByID(cityId);
  if (city == null) {
    // TODO log
    return;
  }

  if (city.recruitments.isEmpty) {
    // TODO we should never be here
    return;
  }

  final recruitment = city.recruitments.first;

  if (recruitment.hasStarted && now.isAfter(recruitment.finishesAt)) {
    int incAmount = 10;
    if (incAmount > recruitment.amount) incAmount = recruitment.amount;

    city.troopsHome[recruitment.type] += incAmount;

    recruitment.amount -= incAmount;

    if (recruitment.amount <= 0) {
      city.recruitments.removeAt(0);
    } else {
      incAmount = 10;
      if (incAmount > recruitment.amount) incAmount = recruitment.amount;
      recruitment.duration = city.recruitmentTime(
          incAmount * units[recruitment.type].recruitmentSpeed,
          recruitment.type);
      recruitment.finishesAt =
          recruitment.startedAt.add(Duration(seconds: recruitment.duration));
    }

    await storage.updateRecruitmentQueue(
        city.id, city.recruitments, city.troopsHome, null);
  } else {
    // TODO: we should never be here. log!
  }

  await scheduleNext(storage, cityId);
}
