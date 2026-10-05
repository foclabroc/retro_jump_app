import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Vérification des mises à jour (GitHub Releases de foclabroc/retro_jump_app)
// À chaque nouvelle version : changer kRetroJumpVersion ET « version: » du
// pubspec.yaml, puis AJOUTER l'APK à la release existante en le nommant
// « retro.jump.V<version>.apk » (ex. retro.jump.V1.0.1.apk).
// ═══════════════════════════════════════════════════════════════════════════

/// Version de l'application (identique au pubspec.yaml, sans le « +N »).
const kRetroJumpVersion = '1.0.5';

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
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(update: upd, french: fr),
    );
    return 1;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Fenêtre de mise à jour : téléchargement dans l'appli + installateur Android ───
class _UpdateDialog extends StatefulWidget {
  final RetroJumpUpdate update;
  final bool french;
  const _UpdateDialog({required this.update, required this.french});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  // 0 : question, 1 : téléchargement, 2 : prêt à installer, 3 : erreur
  int _step = 0;
  double _progress = 0;      // 0 à 1 (−1 = taille inconnue)
  String? _apkPath;
  String _info = '';
  HttpClient? _client;
  bool _cancelled = false;

  bool get fr => widget.french;

  @override
  void dispose() {
    _cancelled = true;
    _client?.close(force: true);
    super.dispose();
  }

  Future<void> _download() async {
    final url = widget.update.apkUrl;
    if (url == null) {
      _openPage();
      return;
    }
    setState(() {
      _step = 1;
      _progress = 0;
      _info = '';
    });
    final client = _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/retro_jump_update.apk');
      final req = await client.getUrl(Uri.parse(url)); // GitHub redirige : suivi automatique
      req.headers.add('User-Agent', 'retro-jump-updater');
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength;
      final sink = file.openWrite();
      var got = 0;
      await for (final chunk in res) {
        if (_cancelled) break;
        sink.add(chunk);
        got += chunk.length;
        if (mounted) setState(() => _progress = total > 0 ? got / total : -1);
      }
      await sink.close();
      if (_cancelled) return;
      if (total > 0 && got < total) throw const FileSystemException('incomplet');
      _apkPath = file.path;
      if (!mounted) return;
      setState(() => _step = 2);
      await _install();
    } catch (_) {
      if (!mounted || _cancelled) return;
      setState(() {
        _step = 3;
        _info = fr ? 'Téléchargement impossible. Essaie depuis la page GitHub.' : 'Download failed. Try from the GitHub page.';
      });
    } finally {
      client.close(force: true);
      _client = null;
    }
  }

  /// Ouvre l'installateur Android (le joueur confirme avec « Installer »).
  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) return;
    final r = await OpenFilex.open(path, type: 'application/vnd.android.package-archive');
    if (!mounted) return;
    if (r.type != ResultType.done) {
      // 1re fois : Android demande d'autoriser « Installer des applis inconnues »
      setState(() => _info = fr
          ? 'Autorise « Installer des applis inconnues » pour Rétro Jump, puis appuie sur Installer.'
          : 'Allow "Install unknown apps" for Retro Jump, then tap Install.');
    } else {
      setState(() => _info = '');
    }
  }

  void _openPage() {
    Navigator.of(context).pop();
    launchUrl(Uri.parse(widget.update.pageUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE02020);
    final pct = _progress < 0 ? null : _progress;
    return PopScope(
      canPop: _step != 1,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1C2230),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: red),
          const SizedBox(width: 10),
          Expanded(child: Text(fr ? 'Mise à jour disponible' : 'Update available',
              style: const TextStyle(color: Colors.white, fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${fr ? 'Version actuelle' : 'Current version'} : $kRetroJumpVersion',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${fr ? 'Nouvelle version' : 'New version'} : ${widget.update.latest}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 14),
          if (_step == 0)
            Text(fr ? 'Télécharger et installer maintenant ? Ta progression est conservée.'
                    : 'Download and install now? Your progress is kept.',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (_step == 1) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.white10, color: red),
            ),
            const SizedBox(height: 6),
            Text(pct == null
                    ? (fr ? 'Téléchargement…' : 'Downloading…')
                    : '${fr ? 'Téléchargement' : 'Downloading'} : ${(pct * 100).round()} %',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          if (_step == 2)
            Text(fr ? 'Téléchargé ! Confirme avec « Installer » dans la fenêtre d\'Android.'
                    : 'Downloaded! Confirm with "Install" in the Android window.',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
          if (_info.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_info, style: const TextStyle(color: Colors.amberAccent, fontSize: 12, height: 1.3)),
          ],
        ]),
        actions: [
          if (_step == 0) ...[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(fr ? 'Plus tard' : 'Later')),
            ElevatedButton.icon(
              onPressed: _download,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(fr ? 'Installer' : 'Install'),
              style: ElevatedButton.styleFrom(backgroundColor: red),
            ),
          ],
          if (_step == 1)
            TextButton(
              onPressed: () {
                _cancelled = true;
                _client?.close(force: true);
                Navigator.of(context).pop();
              },
              child: Text(fr ? 'Annuler' : 'Cancel'),
            ),
          if (_step == 2) ...[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(fr ? 'Fermer' : 'Close')),
            ElevatedButton.icon(
              onPressed: _install,
              icon: const Icon(Icons.install_mobile_rounded, size: 18),
              label: Text(fr ? 'Installer' : 'Install'),
              style: ElevatedButton.styleFrom(backgroundColor: red),
            ),
          ],
          if (_step == 3) ...[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(fr ? 'Fermer' : 'Close')),
            ElevatedButton.icon(
              onPressed: _openPage,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('GitHub'),
              style: ElevatedButton.styleFrom(backgroundColor: red),
            ),
          ],
        ],
      ),
    );
  }
}

