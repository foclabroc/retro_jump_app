import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'leaderboard_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Surveillance du classement (Rétro Jump seul) : environ toutes les 15 minutes,
// même appli fermée, Android lance une vérification. Si un joueur t'a dépassé
// (Solo ou défi du jour, quelle que soit ta place), une notification indique
// qui, son score, ton score et ta nouvelle place.
// ═══════════════════════════════════════════════════════════════════════════

const _kWatchKey = 'rjlb_rank_watch'; // derniers rangs connus (JSON)
const _kTask = 'rj_rank_watch';

/// Point d'entrée de la tâche de fond (isolat séparé).
@pragma('vm:entry-point')
void rankWatchDispatcher() {
  Workmanager().executeTask((task, input) async {
    DartPluginRegistrant.ensureInitialized();
    try {
      await RankWatch.check(notify: true);
    } catch (_) {}
    return true;
  });
}

class RankWatch {
  static final _notif = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _fr => PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'fr';

  /// Au lancement de l'appli : autorisation, tâche périodique, rangs de référence.
  static Future<void> start() async {
    try {
      await _init();
      await _notif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await Workmanager().initialize(rankWatchDispatcher);
      await Workmanager().registerPeriodicTask(
        _kTask,
        _kTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );
      await check(notify: false);
    } catch (_) {}
  }

  static Future<void> _init() async {
    if (_ready) return;
    await _notif.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
  }

  static String _num(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(_fr ? ' ' : ',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// Compare les rangs actuels aux derniers connus ; notifie si on a été dépassé.
  static Future<void> check({required bool notify}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // l'appli a pu écrire entre-temps
    Map<String, dynamic> old;
    try {
      old = Map<String, dynamic>.from(jsonDecode(prefs.getString(_kWatchKey) ?? '{}') as Map);
    } catch (_) {
      old = {};
    }
    final day = Leaderboard.today();
    final soloPrev = (old['solo'] as num?)?.toInt();
    // Défi du jour : nouveau classement chaque jour, pas de comparaison avec la veille
    final dailyPrev = old['day'] == day ? (old['daily'] as num?)?.toInt() : null;
    final st = await Leaderboard.rankWatch(soloPrev, dailyPrev);
    if (st == null) return;
    final out = <String, dynamic>{'day': day};
    for (final board in const ['solo', 'daily']) {
      final b = st[board];
      if (b is! Map) continue;
      final rank = (b['rank'] as num?)?.toInt();
      final score = (b['score'] as num?)?.toInt();
      final passers = [for (final p in (b['passers'] as List? ?? const [])) if (p is Map) p];
      if (notify && rank != null && score != null && passers.isNotEmpty) {
        await _show(board == 'solo', passers, rank, score);
      }
      out[board] = rank;
    }
    await prefs.setString(_kWatchKey, jsonEncode(out));
  }

  static Future<void> _show(bool solo, List<Map> passers, int rank, int score) async {
    await _init();
    final fr = _fr;
    final first = passers.first;
    final who = '${first['name'] ?? '?'} (${_num((first['score'] as num?)?.toInt() ?? 0)} pts)';
    final more = passers.length - 1;
    final title = solo
        ? (fr ? '🏆 Classement Solo' : '🏆 Solo leaderboard')
        : (fr ? '📅 Défi du jour' : '📅 Daily challenge');
    final body = fr
        ? '$who${more > 0 ? ' et $more autre${more > 1 ? 's' : ''} t’ont' : ' t’a'} dépassé — '
            'tu passes ${rank == 1 ? '1er' : '${rank}ᵉ'} avec ${_num(score)} pts'
        : '$who${more > 0 ? ' and $more other${more > 1 ? 's' : ''}' : ''} passed you — '
            'you are now #$rank with ${_num(score)} pts';
    await _notif.show(
      id: solo ? 1 : 2,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'rj_rank',
          fr ? 'Classement' : 'Leaderboard',
          channelDescription: fr ? 'Quand un joueur te dépasse au classement' : 'When a player passes you on the leaderboard',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }
}
