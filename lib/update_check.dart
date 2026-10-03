import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Vérification des mises à jour (GitHub Releases de foclabroc/retro_jump_app)
// À chaque nouvelle version : changer kRetroJumpVersion ET « version: » du
// pubspec.yaml, puis AJOUTER l'APK à la release existante en le nommant
// « retro.jump.V<version>.apk » (ex. retro.jump.V1.0.1.apk).
// ═══════════════════════════════════════════════════════════════════════════

/// Version de l'application (identique au pubspec.yaml, sans le « +N »).
const kRetroJumpVersion = '1.0.1';

const _apiLatest = 'https://api.github.com/repos/foclabroc/retro_jump_app/releases/latest';
const _releasesPage = 'https://github.com/foclabroc/retro_jump_app/releases/latest';

class RetroJumpUpdate {
  final String latest;   // ex. « 1.1.0 »
  final String pageUrl;  // page de la release
  final String? apkUrl;  // lien direct de l'APK (s'il y en a un)
  const RetroJumpUpdate(this.latest, this.pageUrl, this.apkUrl);
}

/// Renvoie la mise à jour disponible, ou null (à jour, hors ligne, erreur…).
/// Tous les APK sont dans une seule release : la version est lue dans le NOM
/// du fichier, ex. « retro.jump.V1.0.1.apk » (le plus récent est retenu).
/// throwOnError : lève une exception si GitHub est injoignable (vérification manuelle).
Future<RetroJumpUpdate?> checkRetroJumpUpdate({bool throwOnError = false}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final req = await client.getUrl(Uri.parse(_apiLatest));
    req.headers.add('Accept', 'application/vnd.github+json');
    req.headers.add('User-Agent', 'retro-jump-update-check');
    final res = await req.close().timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      if (throwOnError) throw HttpException('HTTP ${res.statusCode}');
      return null;
    }
    final data = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final pattern = RegExp(r'V(\d+(?:\.\d+){1,3})\.apk$', caseSensitive: false);
    String? best, apk;
    for (final a in (data['assets'] as List? ?? const [])) {
      final m = a as Map<String, dynamic>;
      final match = pattern.firstMatch(m['name'] as String? ?? '');
      if (match == null) continue;
      final v = match.group(1)!;
      if (best == null || _compare(v, best) > 0) {
        best = v;
        apk = m['browser_download_url'] as String?;
      }
    }
    if (best == null || _compare(best, kRetroJumpVersion) <= 0) return null;
    return RetroJumpUpdate(best, data['html_url'] as String? ?? _releasesPage, apk);
  } catch (_) {
    if (throwOnError) rethrow;
    return null;
  } finally {
    client.close();
  }
}

/// Compare « 1.10.0 » et « 1.9.2 » segment par segment (> 0 si a > b).
int _compare(String a, String b) {
  final pa = a.split(RegExp(r'[.+-]')).map((p) => int.tryParse(p) ?? 0).toList();
  final pb = b.split(RegExp(r'[.+-]')).map((p) => int.tryParse(p) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

/// Accès à la vérification depuis les Réglages du jeu.
final updateGateKey = GlobalKey<UpdateGateState>();

/// Enveloppe l'écran d'accueil : vérifie une fois au lancement et propose la mise à jour.
class UpdateGate extends StatefulWidget {
  final Widget child;
  final bool french;
  const UpdateGate({super.key, required this.child, required this.french});

  @override
  State<UpdateGate> createState() => UpdateGateState();
}

class UpdateGateState extends State<UpdateGate> {
  @override
  void initState() {
    super.initState();
    // Laisse le jeu s'afficher (et la roue s'ouvrir) avant de vérifier
    Future.delayed(const Duration(seconds: 2), check);
  }

  /// 0 : à jour, 1 : mise à jour proposée, 2 : hors ligne (seulement si manual).
  Future<int> check({bool manual = false}) async {
    RetroJumpUpdate? u;
    try {
      u = await checkRetroJumpUpdate(throwOnError: manual);
    } catch (_) {
      return 2;
    }
    if (u == null || !mounted) return 0;
    final upd = u; // non nul (variable figée pour la fenêtre)
    final fr = widget.french;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2230),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: Color(0xFFE02020)),
          const SizedBox(width: 10),
          Expanded(child: Text(fr ? 'Mise à jour disponible' : 'Update available',
              style: const TextStyle(color: Colors.white, fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${fr ? 'Version actuelle' : 'Current version'} : $kRetroJumpVersion',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${fr ? 'Nouvelle version' : 'New version'} : ${upd.latest}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          Text(fr ? 'Télécharger la mise à jour maintenant ?' : 'Download the update now?',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(fr ? 'Plus tard' : 'Later')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUrl(Uri.parse(upd.apkUrl ?? upd.pageUrl), mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(fr ? 'Télécharger' : 'Download'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE02020)),
          ),
        ],
      ),
    );
    return 1;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
