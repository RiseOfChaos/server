import 'package:libpg/libpg.dart';
import 'package:server/db/db.dart';
import 'package:server/models/city.dart';

class CityDbImpl implements CityDb {
  Future<City> create(City city) async {
    Querier db;

    final row = await db
        .query(substitute(r'''
       insert into city (
        pos, continent, ownerId, level, plots, constructions, recruitments, 
        trades, tradeIns, commands, onSupports, incomingAttacks, resources, 
        totalCS, buildingCache, troopsHome) 
       values (
        @{pos}, @{contient}, @{ownerId}, @{level}, @{plots}, @{constructions}, @{recruitments},
        @{trades}, @{tradeIns}, @{commands}, @{onSupports}, @{incomingAttacks}, @{resources},
        @{totalCS}, @{buildingCache}, @{troopsHome}
      ) returning id''', values: {
          'pos': city.pos,
          'continent': city.continent,
          'ownerId': city.ownerId,
          'level': city.level,
          'plots': city.plots,
          'constructions': city.constructions,
          'recruitments': city.recruitments,
          'trades': city.trades,
          'tradeIns': city.tradeIns,
          'commands': city.commands,
          'onSupports': city.onSupports,
          'incomingAttacks': city.incomingAttacks,
          'resources': city.resources,
          'totalCS': city.totalCS,
          'buildingCache': city.buildingCache,
          'troopsHome': city.troopsHome,
        }))
        .one();

    if(row == null) {
      throw Exception('Expected id');
    }

    return fetchByID(row[0]);
  }

  Future<City> fetchByID(String id) async {
    Querier db;

    final row = await db.query(substitute(r'''
      select 
        id, pos, continent, ownerId, level, plots, construction, trades, 
        tradeIns, recruitments, commands, onSupports, incommingAttacks, 
        timedResources, totalCS, buildingCache, troopsHome 
      from city where id = @{id}''', values: {'id': id})).one();
    if (row == null) {
      // TODO
    }
    // TODO
  }

  Future<void> updateConstructionQueue(
    String id,
    List<Construction> constructions,
    TimedResources resources,
    BuildingCache buildingCache,
    Map<int, Plot> plots,
    /* TODO others */
  ) async {
    Querier db;

    final tag = await db.execute(substitute(
        r'''
            UPDATE city SET ''' +
            '''constructions = @{constructions}''' +
            (plots != null ? ''', plots = @{plots} ''' : '') +
            (buildingCache != null
                ? ''', buildingCache = @{buildingCache} '''
                : '') +
            (resources != null ? ''', resources = @{resources} ''' : '') +
            ''' WHERE id = @{id}''',
        values: {
          'id': id,
          'plots': plots,
          'constructions': constructions,
          'resources': resources,
          'buildingCache': buildingCache,
        }));
    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  /*Future<void> constructSlot(
      List<Construction> constructions, Plot plot, BuildingCache cache);*/

  Future<void> updateRecruitmentQueue(String id, List<Recruitment> recruitments,
      Troops troopsHome, TimedResources resources) async {
    Querier db;

    final tag = await db.execute(substitute(
        r'''
            UPDATE city SET 
              recruitments = @{recruitments} ''' +
            (troopsHome != null ? ''', troopsHome = @{troopsHome} ''' : '') +
            (resources != null ? ''', resources = @{resources}''' : '') +
            ''' WHERE id = @{id}''',
        values: {
          'id': id,
          'recruitments': recruitments,
          'troopsHome': troopsHome,
          'resources': resources,
        }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  Future<void> updateTroopsHome(String id, Troops troopsHome) async {
    Querier db;

    final tag = await db.execute(substitute(r'''
            UPDATE city SET troopsHome = @{troopsHome}
            WHERE id = @{id}''', values: {
      'id': id,
      'troopsHome': troopsHome,
    }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  Future<void> updateCommand(String id, List<Command> commands,
      Troops troopsHome, TimedResources resources) async {
    Querier db;

    final tag = await db.execute(substitute(
        r'''
            UPDATE city SET 
              commands = @{commands}, 
              troopsHome = @{troopsHome} ''' +
            (resources != null ? r''', resources = @{resources} ''' : '') +
            r''' WHERE id = @{id}''',
        values: {
          'id': id,
          'commands': commands,
          'troopsHome': troopsHome,
          'resources': resources,
        }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  Future<void> updateIncomingAttack(
      String id,
      List<IncomingAttack> incomingAttacks,
      Troops troopsHome,
      TimedResources resources) async {
    Querier db;

    final tag = await db.execute(substitute(r'''
            UPDATE city SET 
              incomingAttacks = @{incomingAttacks}, 
              troopsHome = @{troopsHome}, 
              resources = @{resources} 
            WHERE id = @{id}''', values: {
      'id': id,
      'incomingAttacks': incomingAttacks,
      'troopsHome': troopsHome,
      'resources': resources,
    }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  Future<void> updateSupport(
      String id, List<OnSupport> onSupports, TimedResources resources) async {
    Querier db;

    final tag = await db.execute(substitute(r'''
            UPDATE city SET 
              onSupports = @{onSupports}, 
              resources = @{resources} 
            WHERE id = @{id}''', values: {
      'id': id,
      'onSupports': onSupports,
      'resources': resources,
    }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  Future<void> updateTrade(
      String id, List<Trade> trades, TimedResources resources) async {
    Querier db;

    final tag = await db.execute(substitute(r'''
            UPDATE city SET 
              trades = @{trades}, 
              resources = @{resources} 
            WHERE id = @{id}''', values: {
      'id': id,
      'trades': trades,
      'resources': resources,
    }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }

  Future<void> updateTradeIn(
      String id, List<TradeIn> tradeIns, TimedResources resources) async {
    Querier db;

    final tag = await db.execute(substitute(r'''
            UPDATE city SET 
              tradeIns = @{tradeIns}, 
              resources = @{resources} 
            WHERE id = @{id}''', values: {
      'id': id,
      'tradeIns': tradeIns,
      'resources': resources,
    }));

    if (tag.rowsAffected != 1) {
      if (tag.rowsAffected == 0) {
        throw Exception('No matching cities found in database to update!');
      } else {
        throw Exception('Updated more than one row: ${tag.rowsAffected}!');
      }
    }
  }
}
