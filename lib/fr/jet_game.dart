part of 'jump_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// RÉTRO JET — 2ᵉ jeu (façon Jetpack Joyride), en mode paysage.
// Partage les pièces, les héros (dorés compris), l'avatar et le pseudo de
// Rétro Jump ; classement à part (modes « jet » et « jetd » côté serveur).
// ═══════════════════════════════════════════════════════════════════════════

const _kJetBestKey  = 'jet_best';       // meilleure distance (m)
const _kJetDailyKey = 'jet_daily_best'; // « AAAA-MM-JJ|distance » du défi du jour
const _kJetRunsKey  = 'jet_runs';       // nombre de parties (aide affichée au début)
const _kJetStatsKey = 'jet_stats';      // statistiques à vie (JSON)

// Monde : hauteur logique 360 unités, 30 unités = 1 mètre
const double _jH = 360;
const double _jCeil = 30;
const double _jFloor = 322;
const double _jUnitsPerM = 30;

const _jCyan = Color(0xFF00E5FF);
const _jGold = Color(0xFFFFD740);

// ─── Objets du parcours ─────────────────────────────────────────────────────

/// Laser entre deux bornes (centre, longueur, angle ; [spin] rad/s s'il tourne).
class _JZap {
  double x, y, len, ang;
  final double spin;
  _JZap(this.x, this.y, this.len, this.ang, [this.spin = 0]);
  Offset get a => Offset(x - cos(ang) * len / 2, y - sin(ang) * len / 2);
  Offset get b => Offset(x + cos(ang) * len / 2, y + sin(ang) * len / 2);
}

/// Missile : annoncé au bord droit ([warn] s), il suit le joueur puis se verrouille et part.
class _JMissile {
  final double trig; // déclenché quand le bord droit de l'écran atteint ce x (monde)
  double x = 0, y = 0, warn = 1.35;
  bool active = false, fired = false, done = false;
  _JMissile(this.trig);
}

class _JBug {
  double x, y;
  final double y0, phase, amp;
  final int type; // 0 bug, 1 envahisseur « crabe », 2 envahisseur « calmar »
  bool dead = false;
  _JBug(this.x, this.y0, this.phase, this.amp, [this.type = 0]) : y = y0;
}

class _JCoin {
  final double x, y;
  double px = 0, py = 0; // position attirée par l'aimant
  bool taken = false, pulled = false;
  _JCoin(this.x, this.y);
}

/// Bonus : 0 bouclier, 1 aimant, 2 turbo, 3 caisse véhicule.
class _JItem {
  final double x, y;
  final int kind;
  bool taken = false;
  _JItem(this.x, this.y, this.kind);
}

class _JFx {
  double x, y, vx, vy, life;
  final double ttl, size, grav;
  final Color color;
  final bool glow;
  _JFx(this.x, this.y, this.vx, this.vy, this.ttl, this.size, this.color, {this.glow = false, this.grav = 0})
      : life = ttl;
}

// ─── Dessin (partagé par le jeu, le menu et la carte de choix) ──────────────

void _jText(Canvas c, String s, Offset center, double size, Color color,
    {FontWeight weight = FontWeight.w900, String? family, String? package}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: family, package: package),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

void _jIcon(Canvas c, IconData ic, Offset center, double size, Color color) =>
    _jText(c, String.fromCharCode(ic.codePoint), center, size, color, family: ic.fontFamily, package: ic.fontPackage);

// ─── Thèmes du décor (Boutique Rétro Jet) ───────────────────────────────────

class _JetTheme {
  final String name;
  final int price;
  final int decor; // 0 labo, 1 arcade, 2 station spatiale, 3 usine, 4 glacier
  final Color wallA, wallB, wallC; // dégradé du mur (haut, milieu, bas)
  final Color seam, pillar, pillarHi, pipe, ceil, stripe, floorA, floorB, floorLine, lamp;
  const _JetTheme(this.name, this.price, this.decor, this.wallA, this.wallB, this.wallC, this.seam, this.pillar,
      this.pillarHi, this.pipe, this.ceil, this.stripe, this.floorA, this.floorB, this.floorLine, this.lamp);
}

const _jetThemes = [
  _JetTheme('Labo', 0, 0, Color(0xFF0C1226), Color(0xFF17204A), Color(0xFF0B1022), Color(0xFF1D2852), Color(0xFF1A2348),
      Color(0xFF2E3B70), Color(0xFF25305C), Color(0xFF080B18), Color(0xFFFFCA28), Color(0xFF2B3550), Color(0xFF111628),
      Color(0xFF5C6B9C), Color(0xFFFFF59D)),
  _JetTheme('Arcade néon', 600, 1, Color(0xFF12041E), Color(0xFF2A0A44), Color(0xFF10031A), Color(0xFF3A1460),
      Color(0xFF2A0E46), Color(0xFF7B1FA2), Color(0xFF4A148C), Color(0xFF07020D), Color(0xFFFF4FD8), Color(0xFF2A1240),
      Color(0xFF12061E), Color(0xFFFF4FD8), Color(0xFFFF80EA)),
  _JetTheme('Station spatiale', 900, 2, Color(0xFF02030C), Color(0xFF0A1430), Color(0xFF02040E), Color(0xFF16224A),
      Color(0xFF1E2A50), Color(0xFF8899CC), Color(0xFF2A3660), Color(0xFF05070F), Color(0xFF00E5FF), Color(0xFF3A4566),
      Color(0xFF151A2C), Color(0xFFB0BEC5), Color(0xFFB3E5FC)),
  _JetTheme('Usine', 1200, 3, Color(0xFF1A0F08), Color(0xFF3A2414), Color(0xFF160C06), Color(0xFF4A2E18), Color(0xFF3E2A1A),
      Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF0E0804), Color(0xFFFF9100), Color(0xFF4E3B2C), Color(0xFF1E140C),
      Color(0xFFBF8F5F), Color(0xFFFFCC80)),
  _JetTheme('Glacier', 1500, 4, Color(0xFF0A2638), Color(0xFF17506A), Color(0xFF0A1E2E), Color(0xFF2B6A88),
      Color(0xFF1E5470), Color(0xFF9FE3FF), Color(0xFF3A7A98), Color(0xFF061824), Color(0xFFE1F5FE), Color(0xFF7FB8D4),
      Color(0xFF2C5E78), Color(0xFFFFFFFF), Color(0xFFE1F5FE)),
];

/// Roue dentée (décor Usine).
void _jGear(Canvas c, Offset o, double r, double ang, Color col) {
  const teeth = 10;
  final path = Path();
  for (int i = 0; i < teeth * 2; i++) {
    final a = ang + i * pi / teeth;
    final rr = i.isEven ? r : r * 0.8;
    final p = o + Offset(cos(a), sin(a)) * rr;
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  c.drawPath(path, Paint()..color = col);
  c.drawCircle(o, r * 0.35, Paint()..color = Colors.black.withOpacity(0.35));
}

/// Décor qui défile (coordonnées monde : hauteur [_jH], largeur [w]) selon le thème.
void _jetDrawLab(Canvas c, double w, double cam, double time, [int theme = 0]) {
  const h = _jH;
  final th = _jetThemes[theme.clamp(0, _jetThemes.length - 1)];
  c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()
    ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, h), [th.wallA, th.wallB, th.wallC], const [0, 0.55, 1]));

  // Plan lointain (×0,3)
  final f = cam * 0.3;
  const pw = 230.0;
  final i0 = (f / pw).floor();
  for (int i = i0; i <= i0 + (w / pw).ceil() + 1; i++) {
    final x = i * pw - f;
    c.drawRect(Rect.fromLTWH(x, _jCeil, 3, _jFloor - _jCeil), Paint()..color = th.seam);
    final k = _hash(i, 7);
    switch (th.decor) {
      case 1:
        _decorArcade(c, x, i, k, time);
        break;
      case 2:
        _decorSpace(c, x, i, k, time);
        break;
      case 3:
        _decorFactory(c, x, i, k, time);
        break;
      case 4:
        _decorIce(c, x, i, k, time);
        break;
      default:
        _decorLab(c, x, i, k, time);
    }
    // Lampe au plafond et halo
    final lx = x + pw / 2;
    c.drawPath(
        Path()
          ..moveTo(lx - 10, _jCeil + 10)
          ..lineTo(lx + 10, _jCeil + 10)
          ..lineTo(lx + 70, _jFloor)
          ..lineTo(lx - 70, _jFloor)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(const Offset(0, _jCeil), const Offset(0, _jFloor),
              [th.lamp.withOpacity(0.10), th.lamp.withOpacity(0)], const [0, 1]));
    c.drawRect(Rect.fromLTWH(lx - 14, _jCeil, 28, 10), Paint()..color = th.pillarHi.withOpacity(0.6));
    c.drawRect(Rect.fromLTWH(lx - 10, _jCeil + 8, 20, 3), Paint()..color = th.lamp);
  }

  // Plan moyen (×0,65) : piliers et gyrophares
  final m = cam * 0.65;
  const qw = 380.0;
  final j0 = (m / qw).floor();
  for (int j = j0; j <= j0 + (w / qw).ceil() + 1; j++) {
    final x = j * qw - m + 300;
    final r = Rect.fromLTWH(x, _jCeil, 26, _jFloor - _jCeil);
    c.drawRect(r, Paint()
      ..shader = ui.Gradient.linear(r.centerLeft, r.centerRight, [th.pillar, th.pillarHi, th.pillar], const [0, 0.5, 1]));
    final bolt = Paint()..color = Color.lerp(th.pillarHi, Colors.white, 0.2)!.withOpacity(0.6);
    for (double by = _jCeil + 20; by < _jFloor; by += 46) {
      c.drawCircle(Offset(x + 6, by), 2, bolt);
      c.drawCircle(Offset(x + 20, by), 2, bolt);
    }
    final on = ((time * 1.6 + j * 0.37) % 1) < 0.5;
    final lc = j.isEven ? const Color(0xFFFF5252) : th.stripe;
    c.drawCircle(Offset(x + 13, 110), 6, Paint()..color = on ? lc : lc.withOpacity(0.25));
    if (on) {
      c.drawCircle(Offset(x + 13, 110), 18, Paint()
        ..color = lc.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }
  // Tuyaux sous le plafond
  c.drawRect(Rect.fromLTWH(0, _jCeil + 12, w, 8), Paint()..color = th.pipe);
  c.drawRect(Rect.fromLTWH(0, _jCeil + 12, w, 2), Paint()..color = Color.lerp(th.pipe, Colors.white, 0.18)!);
  // Glacier : stalactites sous le plafond
  if (th.decor == 4) {
    final ic = Paint()..color = const Color(0xFFE1F5FE).withOpacity(0.85);
    final s0 = cam % 37;
    for (double x = -s0; x < w + 37; x += 37) {
      final l = 10 + _hash((x + cam).floor() ~/ 37, 5) * 22;
      c.drawPath(
          Path()
            ..moveTo(x, _jCeil)
            ..lineTo(x + 9, _jCeil)
            ..lineTo(x + 4.5, _jCeil + l)
            ..close(),
          ic);
    }
  }

  // Plafond (bandes de sécurité qui défilent avec le sol)
  c.drawRect(Rect.fromLTWH(0, 0, w, _jCeil), Paint()..color = th.ceil);
  final st = cam % 40;
  final stripe = Paint()..color = th.stripe;
  for (double x = -st - 40; x < w + 40; x += 40) {
    c.drawPath(
        Path()
          ..moveTo(x, _jCeil - 8)
          ..lineTo(x + 18, _jCeil - 8)
          ..lineTo(x + 26, _jCeil)
          ..lineTo(x + 8, _jCeil)
          ..close(),
        stripe);
  }
  // Sol
  c.drawRect(Rect.fromLTWH(0, _jFloor, w, h - _jFloor), Paint()
    ..shader = ui.Gradient.linear(const Offset(0, _jFloor), const Offset(0, h), [th.floorA, th.floorB], const [0, 1]));
  c.drawRect(Rect.fromLTWH(0, _jFloor, w, 3), Paint()..color = th.floorLine);
  final tl = cam % 60;
  final groove = Paint()
    ..color = Color.lerp(th.floorB, Colors.black, 0.35)!
    ..strokeWidth = 2;
  final rivet = Paint()..color = th.floorLine.withOpacity(0.45);
  for (double x = -tl; x < w + 60; x += 60) {
    c.drawLine(Offset(x, _jFloor + 3), Offset(x - 14, h), groove);
    c.drawCircle(Offset(x + 30, _jFloor + 14), 2.2, rivet);
  }
}

void _decorLab(Canvas c, double x, int i, double k, double time) {
  if (k < 0.4) {
    // Mur d'écrans CRT
    final hue = _hash(i, 3) * 360;
    final glow = HSVColor.fromAHSV(1, hue, 0.7, 1).toColor();
    for (int s = 0; s < 2; s++) {
      final r = Rect.fromLTWH(x + 34 + s * 82, 92, 70, 54);
      c.drawRRect(RRect.fromRectAndRadius(r.inflate(5), const Radius.circular(7)), Paint()..color = const Color(0xFF232D52));
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()
        ..shader = ui.Gradient.radial(r.center, r.width * 0.7, [glow.withOpacity(0.55), const Color(0xFF0A0F20)], const [0, 1]));
      final on = ((time * 2 + i + s) % 2) < 1.4;
      if (on) {
        final p = Paint()..color = Colors.white.withOpacity(0.85);
        const map = ['..X.X..', '.XXXXX.', 'XX.X.XX', 'XXXXXXX', '.X...X.'];
        for (int yy = 0; yy < map.length; yy++) {
          for (int xx = 0; xx < 7; xx++) {
            if (map[yy][xx] == 'X') c.drawRect(Rect.fromLTWH(r.center.dx - 14 + xx * 4, r.center.dy - 10 + yy * 4, 4, 4), p);
          }
        }
      }
      for (double yy = r.top; yy < r.bottom; yy += 3) {
        c.drawRect(Rect.fromLTWH(r.left, yy, r.width, 1), Paint()..color = Colors.black.withOpacity(0.18));
      }
    }
  } else if (k < 0.72) {
    // Étagères de consoles
    for (int s = 0; s < 2; s++) {
      final sy = 150.0 + s * 80;
      c.drawRect(Rect.fromLTWH(x + 20, sy, 190, 6), Paint()..color = const Color(0xFF2A3766));
      for (int b = 0; b < 3; b++) {
        final kk = _hash(i * 7 + s, b);
        final bx = x + 30 + b * 60;
        final bw = 34 + kk * 16, bh = 22 + kk * 18;
        final col = Color.lerp(const Color(0xFF3A4A80), const Color(0xFF5A3A80), kk)!;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, sy - bh, bw, bh), const Radius.circular(4)), Paint()..color = col);
        c.drawCircle(Offset(bx + bw - 8, sy - bh / 2), 3, Paint()..color = kk > 0.5 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE));
        c.drawRect(Rect.fromLTWH(bx + 5, sy - bh + 5, bw * 0.45, 4), Paint()..color = Colors.white.withOpacity(0.18));
      }
    }
  } else {
    // Baie vitrée sur la nuit étoilée
    final r = Rect.fromLTWH(x + 30, 80, 170, 150);
    c.drawRRect(RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(10)), Paint()..color = const Color(0xFF26315C));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()
      ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [Color(0xFF050818), Color(0xFF1A1450)], const [0, 1]));
    for (int s = 0; s < 14; s++) {
      final sx = r.left + _hash(i, s * 2) * r.width, sy = r.top + _hash(i, s * 2 + 1) * r.height;
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(time * 3 + s));
      c.drawCircle(Offset(sx, sy), 1.2, Paint()..color = Colors.white.withOpacity(tw));
    }
    c.drawCircle(Offset(r.right - 36, r.top + 36), 14, Paint()..color = const Color(0xFFF5F5DC).withOpacity(0.85));
    c.drawLine(r.topCenter, r.bottomCenter, Paint()
      ..color = const Color(0xFF26315C)
      ..strokeWidth = 5);
  }
}

void _decorArcade(Canvas c, double x, int i, double k, double time) {
  if (k < 0.55) {
    // Bornes d'arcade
    for (int s = 0; s < 2; s++) {
      final bx = x + 40 + s * 85;
      final hue = (_hash(i, s + 9) * 360);
      final neon = HSVColor.fromAHSV(1, hue, 0.8, 1).toColor();
      final body = Path()
        ..moveTo(bx, 300)
        ..lineTo(bx, 130)
        ..lineTo(bx + 10, 110)
        ..lineTo(bx + 60, 110)
        ..lineTo(bx + 60, 300)
        ..close();
      c.drawPath(body, Paint()..color = const Color(0xFF1C0B2E));
      c.drawPath(body, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = neon.withOpacity(0.8));
      c.drawRect(Rect.fromLTWH(bx + 8, 114, 46, 12), Paint()..color = neon.withOpacity(0.7));
      final scr = Rect.fromLTWH(bx + 8, 136, 46, 38);
      c.drawRect(scr, Paint()
        ..shader = ui.Gradient.radial(scr.center, 30, [neon.withOpacity(0.6), const Color(0xFF05010A)], const [0, 1]));
      final blink = ((time * 3 + i + s) % 1) < 0.5;
      if (blink) c.drawCircle(scr.center, 4, Paint()..color = Colors.white);
      c.drawRect(Rect.fromLTWH(bx + 4, 186, 54, 10), Paint()..color = const Color(0xFF2E1450));
      c.drawCircle(Offset(bx + 18, 184), 4, Paint()..color = const Color(0xFFFF5252));
      c.drawCircle(Offset(bx + 38, 188), 3, Paint()..color = const Color(0xFFFFEA00));
      c.drawCircle(Offset(bx + 46, 188), 3, Paint()..color = const Color(0xFF00E5FF));
    }
  } else {
    // Enseigne néon qui clignote
    final on = ((time * 1.3 + i) % 2) < 1.6;
    final r = Rect.fromLTWH(x + 40, 110, 150, 60);
    final col = i.isEven ? const Color(0xFFFF4FD8) : const Color(0xFF00E5FF);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = col.withOpacity(on ? 0.95 : 0.25));
    if (on) {
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = col.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    _jText(c, i % 3 == 0 ? 'HI-SCORE' : i % 3 == 1 ? 'INSERT COIN' : '1UP ★', r.center, 18, col.withOpacity(on ? 1 : 0.3));
  }
}

void _decorSpace(Canvas c, double x, int i, double k, double time) {
  if (k < 0.6) {
    // Hublot sur une planète
    final o = Offset(x + 115, 160);
    c.drawCircle(o, 72, Paint()..color = const Color(0xFF2A3660));
    c.drawCircle(o, 64, Paint()..color = const Color(0xFF02030A));
    for (int s = 0; s < 16; s++) {
      final a = _hash(i, s) * pi * 2, d = _hash(i, s + 30) * 60;
      c.drawCircle(o + Offset(cos(a), sin(a)) * d, 1.1, Paint()..color = Colors.white.withOpacity(0.4 + 0.6 * (0.5 + 0.5 * sin(time * 2 + s))));
    }
    final hue = _hash(i, 77) * 360;
    final pc = o + Offset(-12 + _hash(i, 2) * 24, 8);
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: 64)));
    c.drawCircle(pc, 30, Paint()
      ..shader = ui.Gradient.radial(pc + const Offset(-10, -10), 40,
          [HSVColor.fromAHSV(1, hue, 0.5, 1).toColor(), HSVColor.fromAHSV(1, hue, 0.8, 0.35).toColor()], const [0, 1]));
    c.drawOval(Rect.fromCenter(center: pc, width: 90, height: 18), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withOpacity(0.45));
    c.restore();
    for (int b = 0; b < 8; b++) {
      final a = b * pi / 4;
      c.drawCircle(o + Offset(cos(a), sin(a)) * 68, 3, Paint()..color = const Color(0xFF8899CC));
    }
  } else {
    // Pupitre de commande
    final r = Rect.fromLTWH(x + 30, 150, 170, 90);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = const Color(0xFF1A2448));
    for (int yy = 0; yy < 3; yy++) {
      for (int xx = 0; xx < 8; xx++) {
        final on = ((time * 2 + _hash(i * 13 + yy, xx) * 4) % 2) < 1;
        final col = [const Color(0xFF00E5FF), const Color(0xFF69F0AE), const Color(0xFFFFEA00)][(xx + yy) % 3];
        c.drawRect(Rect.fromLTWH(r.left + 14 + xx * 19, r.top + 14 + yy * 22, 10, 8), Paint()..color = on ? col : col.withOpacity(0.15));
      }
    }
  }
}

void _decorFactory(Canvas c, double x, int i, double k, double time) {
  if (k < 0.55) {
    // Engrenages qui tournent
    final dir = i.isEven ? 1.0 : -1.0;
    _jGear(c, Offset(x + 80, 150), 46, time * 0.8 * dir, const Color(0xFF6D4C41));
    _jGear(c, Offset(x + 152, 200), 30, -time * 1.25 * dir, const Color(0xFF8D6E63));
    _jGear(c, Offset(x + 60, 236), 22, -time * 1.7 * dir, const Color(0xFF5D4037));
  } else {
    // Caisses empilées
    for (int b = 0; b < 3; b++) {
      for (int lv = 0; lv < (b == 1 ? 3 : 2); lv++) {
        final r = Rect.fromLTWH(x + 30 + b * 56, 270 - lv * 50, 50, 50);
        c.drawRect(r, Paint()..color = const Color(0xFF6D4C2E));
        c.drawRect(r, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF3E2A18));
        c.drawLine(r.topLeft, r.bottomRight, Paint()
          ..strokeWidth = 3
          ..color = const Color(0xFF3E2A18));
      }
    }
    // Panneau « danger »
    c.drawPath(
        Path()
          ..moveTo(x + 150, 100)
          ..lineTo(x + 180, 150)
          ..lineTo(x + 120, 150)
          ..close(),
        Paint()..color = const Color(0xFFFFB300));
    _jText(c, '!', Offset(x + 150, 134), 22, Colors.black);
  }
}

void _decorIce(Canvas c, double x, int i, double k, double time) {
  if (k < 0.5) {
    // Cristaux de glace
    for (int s = 0; s < 3; s++) {
      final bx = x + 40 + s * 60, hh = 60 + _hash(i, s) * 90;
      c.drawPath(
          Path()
            ..moveTo(bx, _jFloor)
            ..lineTo(bx + 14, _jFloor - hh)
            ..lineTo(bx + 28, _jFloor)
            ..close(),
          Paint()
            ..shader = ui.Gradient.linear(Offset(bx, _jFloor - hh), Offset(bx + 28, _jFloor),
                [const Color(0xFFE1F5FE).withOpacity(0.7), const Color(0xFF4FC3F7).withOpacity(0.25)], const [0, 1]));
    }
  } else {
    // Flocon géant qui scintille
    final o = Offset(x + 115, 150);
    final a = 0.35 + 0.35 * (0.5 + 0.5 * sin(time * 2 + i));
    final p = Paint()
      ..color = Colors.white.withOpacity(a)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int b = 0; b < 6; b++) {
      final an = b * pi / 3 + time * 0.2;
      final e = o + Offset(cos(an), sin(an)) * 46;
      c.drawLine(o, e, p);
      final m = o + Offset(cos(an), sin(an)) * 28;
      c.drawLine(m, m + Offset(cos(an + 0.7), sin(an + 0.7)) * 12, p);
      c.drawLine(m, m + Offset(cos(an - 0.7), sin(an - 0.7)) * 12, p);
    }
  }
}

/// Aperçu d'un thème (boutique).
class _JetThemeSwatch extends CustomPainter {
  final int theme;
  _JetThemeSwatch(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = size.height / _jH;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
    canvas.scale(s, s);
    _jetDrawLab(canvas, size.width / s, 260.0 * theme, 1.0, theme);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JetThemeSwatch old) => old.theme != theme;
}

/// Héros avec son jetpack ; [feet] = pieds (monde).
void _jetDrawPlayer(Canvas c, Offset feet, int hero, double time,
    {bool thrust = false, bool onFloor = false, double rot = 0, double flash = 0, double scale = 1, int pack = 0}) {
  final pk = _jetPacks[pack.clamp(0, _jetPacks.length - 1)];
  final rainbow = pack == _jetPackRainbow;
  c.save();
  c.translate(feet.dx, feet.dy);
  c.scale(scale, scale);
  if (rot != 0) {
    c.translate(0, -20);
    c.rotate(rot);
    c.translate(0, 20);
  }
  final bob = onFloor ? -(sin(time * 18).abs() * 3) : sin(time * 5) * 1.2;
  c.translate(0, bob);
  // Flamme du jetpack
  if (thrust) {
    final fl = 20 + sin(time * 47) * 4 + sin(time * 31) * 3;
    final path = Path()
      ..moveTo(-29, -12)
      ..quadraticBezierTo(-23, -12 + fl * 0.55, -23, -12 + fl)
      ..quadraticBezierTo(-23, -12 + fl * 0.55, -17, -12)
      ..close();
    c.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(const Offset(0, -12), Offset(0, -12 + fl), [
          rainbow ? HSVColor.fromAHSV(1, (time * 300) % 360, 0.6, 1).toColor() : pk.flameA,
          rainbow ? HSVColor.fromAHSV(1, (time * 300 + 120) % 360, 1, 1).toColor() : pk.flameB,
          pk.flameB.withOpacity(0),
        ], const [0, 0.45, 1]));
    c.drawCircle(const Offset(-23, -8), 9, Paint()
      ..color = pk.flameB.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }
  // Jetpack (dans le dos : le héros regarde à droite)
  final tank = RRect.fromRectAndRadius(const Rect.fromLTWH(-32, -38, 17, 27), const Radius.circular(6));
  c.drawRRect(tank, Paint()..shader = ui.Gradient.linear(const Offset(-32, 0), const Offset(-15, 0), [pk.a, pk.b], const [0, 1]));
  c.drawRRect(tank, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..color = const Color(0xFF37474F));
  c.drawRect(const Rect.fromLTWH(-29, -33, 11, 4), Paint()..color = const Color(0xFFE53935));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-29, -13, 12, 5), const Radius.circular(2)),
      Paint()..color = const Color(0xFF263238));
  c.save();
  c.scale(0.9, 0.9);
  _drawHero(c, hero, true, time);
  c.restore();
  if (flash > 0) {
    c.drawCircle(const Offset(0, -20), 30, Paint()
      ..color = _jCyan.withOpacity(0.6 * flash)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }
  c.restore();
}

void _jetDrawZap(Canvas c, Offset a, Offset b, double time, int seed) {
  c.drawLine(a, b, Paint()
    ..color = _jCyan.withOpacity(0.45)
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  final d = b - a;
  final len = d.distance;
  if (len > 1) {
    final nrm = Offset(-d.dy, d.dx) / len;
    for (int arc = 0; arc < 2; arc++) {
      final r = Random(seed * 31 + arc * 7 + (time * 22).floor());
      final path = Path()..moveTo(a.dx, a.dy);
      const n = 10;
      for (int i = 1; i < n; i++) {
        final p = a + d * (i / n) + nrm * ((r.nextDouble() - 0.5) * 7);
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(b.dx, b.dy);
      c.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arc == 0 ? 2 : 1.1
        ..strokeJoin = StrokeJoin.round
        ..color = arc == 0 ? const Color(0xFFB2FFFF) : Colors.white.withOpacity(0.8));
    }
  }
  c.drawLine(a, b, Paint()
    ..strokeWidth = 1.4
    ..color = Colors.white);
  for (final p in [a, b]) {
    c.drawCircle(p, 9, Paint()..color = const Color(0xFF1C262B));
    c.drawCircle(p, 9, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF90A4AE));
    c.drawCircle(p, 4, Paint()..color = _jCyan);
    c.drawCircle(p, 7, Paint()
      ..color = _jCyan.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }
}

void _jetDrawCoin(Canvas c, Offset p, double time) {
  final sx = cos(time * 5 + p.dx * 0.02).abs().clamp(0.22, 1.0);
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(sx, 1);
  c.drawCircle(Offset.zero, 8, Paint()..color = _jGold);
  c.drawCircle(Offset.zero, 8, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFFE6A800));
  c.drawRect(const Rect.fromLTWH(-1.6, -4.5, 3.2, 9), Paint()..color = const Color(0xFFFFF8E1));
  c.restore();
}

// Envahisseurs façon Space Invaders (2 images d'animation chacun)
const _jInvCrab = [
  ['..X.....X..', '...X...X...', '..XXXXXXX..', '.XX.XXX.XX.', 'XXXXXXXXXXX', 'X.XXXXXXX.X', 'X.X.....X.X', '...XX.XX...'],
  ['..X.....X..', 'X..X...X..X', 'X.XXXXXXX.X', 'XXX.XXX.XXX', 'XXXXXXXXXXX', '.XXXXXXXXX.', '..X.....X..', '.X.......X.'],
];
const _jInvSquid = [
  ['...XX...', '..XXXX..', '.XXXXXX.', 'XX.XX.XX', 'XXXXXXXX', '..X..X..', '.X.XX.X.', 'X.X..X.X'],
  ['...XX...', '..XXXX..', '.XXXXXX.', 'XX.XX.XX', 'XXXXXXXX', '.X.XX.X.', 'X......X', '.X....X.'],
];

/// Dessin pixel : X = corps, W = blanc, autre lettre = foncé, « . » = vide.
void _jPixels(Canvas c, List<String> rows, Offset center, double px, Color body, Color dark) {
  final cols = rows.first.length;
  final ox = center.dx - cols * px / 2, oy = center.dy - rows.length * px / 2;
  final paint = Paint();
  for (int r = 0; r < rows.length; r++) {
    for (int k = 0; k < cols; k++) {
      final ch = rows[r][k];
      if (ch == '.') continue;
      paint.color = ch == 'X' ? body : ch == 'W' ? Colors.white : dark;
      c.drawRect(Rect.fromLTWH(ox + k * px, oy + r * px, px + 0.3, px + 0.3), paint);
    }
  }
}

/// Ennemi : bug pixel (comme dans Rétro Jump) ou envahisseur.
void _jetDrawBug(Canvas c, Offset p, double time, [int type = 0]) {
  final frame = (time * 4).floor().isEven ? 0 : 1;
  const bodies = [Color(0xFF76FF03), Color(0xFF00E5FF), Color(0xFFFF4FD8)];
  const darks = [Color(0xFF33691E), Color(0xFF006064), Color(0xFF880E4F)];
  final body = bodies[type.clamp(0, 2)], dark = darks[type.clamp(0, 2)];
  c.drawCircle(p, 18, Paint()
    ..color = body.withOpacity(0.28)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  switch (type) {
    case 1:
      _jPixels(c, _jInvCrab[frame], p, 3.0, body, dark);
      break;
    case 2:
      _jPixels(c, _jInvSquid[frame], p, 3.6, body, dark);
      break;
    default:
      _jPixels(c, _bugFrames[frame], p, 3.6, body, dark);
  }
}

void _jetDrawMissile(Canvas c, Offset p, double time) {
  // Flamme (à droite : le missile file vers la gauche)
  final fl = 18 + sin(time * 50) * 5;
  c.drawPath(
      Path()
        ..moveTo(p.dx + 16, p.dy - 5)
        ..lineTo(p.dx + 16 + fl, p.dy)
        ..lineTo(p.dx + 16, p.dy + 5)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(Offset(p.dx + 16, 0), Offset(p.dx + 16 + fl, 0),
            const [Color(0xFFFFF59D), Color(0x00FF6D00)], const [0, 1]));
  final body = RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 14, p.dy - 6, 30, 12), const Radius.circular(4));
  c.drawRRect(body, Paint()
    ..shader = ui.Gradient.linear(Offset(0, p.dy - 6), Offset(0, p.dy + 6),
        const [Color(0xFFECEFF1), Color(0xFF78909C)], const [0, 1]));
  c.drawPath(
      Path()
        ..moveTo(p.dx - 14, p.dy - 6)
        ..lineTo(p.dx - 26, p.dy)
        ..lineTo(p.dx - 14, p.dy + 6)
        ..close(),
      Paint()..color = const Color(0xFFE53935));
  c.drawPath(
      Path()
        ..moveTo(p.dx + 8, p.dy - 6)
        ..lineTo(p.dx + 16, p.dy - 12)
        ..lineTo(p.dx + 16, p.dy - 6)
        ..close(),
      Paint()..color = const Color(0xFFE53935));
  c.drawPath(
      Path()
        ..moveTo(p.dx + 8, p.dy + 6)
        ..lineTo(p.dx + 16, p.dy + 12)
        ..lineTo(p.dx + 16, p.dy + 6)
        ..close(),
      Paint()..color = const Color(0xFFE53935));
  c.drawRect(Rect.fromLTWH(p.dx - 4, p.dy - 6, 3, 12), Paint()..color = const Color(0xFFFFCA28));
}

/// Lot du jackpot (pièces chance, tirées après un crash).
class _JPrize {
  final String label;
  final IconData? icon;
  final Color color;
  final int meters, coins;
  final bool life;
  const _JPrize(this.label, this.icon, this.color, {this.meters = 0, this.coins = 0, this.life = false});
}

const _jetPrizes = [
  _JPrize('+150 m', Icons.trending_up_rounded, Color(0xFF29B6F6), meters: 150),
  _JPrize('+250 m', Icons.rocket_launch_rounded, Color(0xFF7C4DFF), meters: 250),
  _JPrize('VIE', Icons.favorite_rounded, Color(0xFFFF1744), life: true),
  _JPrize('50', null, Color(0xFFFFD740), coins: 50),
  _JPrize('75', null, Color(0xFFFFD740), coins: 75),
  _JPrize('100', null, Color(0xFFFFD740), coins: 100),
  _JPrize('RIEN', Icons.close_rounded, Color(0xFF90A4AE)),
];
// Chances de chaque lot (défi du jour : pas de mètres en bonus, pour rester équitable)
const _jetPrizeWeights = [14, 8, 10, 16, 12, 8, 32];
const _jetPrizeWeightsDaily = [0, 0, 20, 0, 0, 0, 80]; // défi du jour : ni mètres ni pièces

/// Pièce chance (violette, trèfle) : donne un tour de jackpot après un crash.
void _jetDrawChance(Canvas c, Offset p, double time) {
  final pulse = 1 + sin(time * 6) * 0.1;
  c.drawCircle(p, 20 * pulse, Paint()
    ..color = const Color(0xFFE040FB).withOpacity(0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
  final sx = cos(time * 3 + p.dx * 0.01).abs().clamp(0.3, 1.0);
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(sx, 1);
  c.drawCircle(Offset.zero, 13, Paint()
    ..shader = ui.Gradient.radial(const Offset(-4, -4), 16, const [Color(0xFFF3E5F5), Color(0xFF8E24AA)], const [0, 1]));
  c.drawCircle(Offset.zero, 13, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFFFFD740));
  // Trèfle à quatre feuilles
  final leaf = Paint()..color = const Color(0xFF00E676);
  for (int k = 0; k < 4; k++) {
    final a = k * pi / 2 + pi / 4;
    c.drawCircle(Offset(cos(a), sin(a)) * 3.6, 3.4, leaf);
  }
  c.drawLine(const Offset(0, 1), const Offset(2.5, 7), Paint()
    ..color = const Color(0xFF00C853)
    ..strokeWidth = 1.6);
  c.restore();
  // Éclat
  final g = (sin(time * 4 + p.dx) + 1) / 2;
  final sp = Paint()..color = Colors.white.withOpacity(0.4 + 0.6 * g);
  c.drawCircle(p + const Offset(9, -10), 1.5 + g * 1.5, sp);
}

/// Boss : envahisseur géant (Space Invaders) avec un canon à missiles.
void _jetDrawBoss(Canvas c, Offset p, double time, bool charging, double hurt) {
  const px = 11.0;
  final frame = (time * 2.5).floor().isEven ? 0 : 1;
  final body = Color.lerp(const Color(0xFFE040FB), const Color(0xFFFF1744), hurt)!;
  // Halo
  c.drawCircle(p, 90, Paint()
    ..color = body.withOpacity(0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
  // Yeux lumineux derrière les trous du sprite
  final eye = charging ? const Color(0xFFFFEA00) : const Color(0xFFFF1744);
  for (final e in const [Offset(-22, -5.5), Offset(22, -5.5)]) {
    c.drawCircle(p + e, 13, Paint()
      ..color = eye.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }
  _jPixels(c, _jInvCrab[frame], p, px, body, Color.lerp(body, Colors.black, 0.5)!);
  // Reflets « écran CRT »
  final scan = Paint()..color = Colors.black.withOpacity(0.18);
  for (double y = p.dy - 44; y < p.dy + 44; y += 4) {
    c.drawRect(Rect.fromLTWH(p.dx - 61, y, 122, 1.5), scan);
  }
  // Canon (vise à gauche, sous le corps)
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 86, p.dy + 30, 40, 16), const Radius.circular(4)),
      Paint()..color = const Color(0xFF37474F));
  c.drawRect(Rect.fromLTWH(p.dx - 92, p.dy + 32, 8, 12), Paint()..color = const Color(0xFF263238));
  if (charging) {
    final g = (sin(time * 30) + 1) / 2;
    c.drawCircle(Offset(p.dx - 92, p.dy + 38), 8 + g * 6, Paint()
      ..color = const Color(0xFFFF6D00).withOpacity(0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }
  // Réacteurs à l'arrière
  for (final dy in const [-20.0, 20.0]) {
    final fl = 22 + sin(time * 40 + dy) * 6;
    c.drawPath(
        Path()
          ..moveTo(p.dx + 62, p.dy + dy - 6)
          ..lineTo(p.dx + 62 + fl, p.dy + dy)
          ..lineTo(p.dx + 62, p.dy + dy + 6)
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(Offset(p.dx + 62, 0), Offset(p.dx + 62 + fl, 0),
              const [Color(0xFFFFF59D), Color(0x00FF6D00)], const [0, 1]));
  }
}

const _jDragon = [
  [
    '......DD..........',
    '.....DXXD.........',
    '....DXXXXD....DDD.',
    '...DXXXXXXD..DXXXD',
    '....DDXXXXXDDXXWXD',
    'D.....DXXXXXXXXXXD',
    'XD...DXXXXXXXXXXD.',
    '.XDDDXXXXXXXXXDD..',
    '..XXXXXXXXXXXD....',
    '....DXD...DXD.....',
    '....DD....DD......',
  ],
  [
    '..................',
    '..................',
    '..............DDD.',
    '.............DXXXD',
    '......DDDDDDDXXWXD',
    'D....DXXXXXXXXXXXD',
    'XD..DXXXXXXXXXXXD.',
    '.XDDXXXXDDDXXXDD..',
    '..XXXXXDXXXD.D....',
    '....DXDDXXD.XD....',
    '....DD.DXD..DD....',
  ],
];

/// Dragon pixel : vole comme le jetpack, crache du feu, le héros sur son dos.
void _jetDrawDragon(Canvas c, Offset feet, int hero, double time, double left) {
  final center = feet + const Offset(0, -26);
  final frame = (time * 6).floor().isEven ? 0 : 1;
  // Clignote les 2 dernières secondes
  if (left < 2 && (time * 8).floor().isEven) return;
  c.drawCircle(center, 34, Paint()
    ..color = const Color(0xFFFF6D00).withOpacity(0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  c.save();
  c.translate(feet.dx - 6, feet.dy - 40);
  c.scale(0.5, 0.5);
  _drawHero(c, hero, true, time);
  c.restore();
  _jPixels(c, _jDragon[frame], center, 4.0, const Color(0xFF66BB6A), const Color(0xFF1B5E20));
}

/// Mecha Manette : grosse manette sur deux jambes, le héros aux commandes.
void _jetDrawMecha(Canvas c, Offset feet, int hero, double time, bool onFloor) {
  c.save();
  c.translate(feet.dx, feet.dy);
  final step = onFloor ? sin(time * 12) : 0.6;
  final leg = Paint()
    ..color = const Color(0xFF37474F)
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;
  final l1 = Offset(-16 + step * 10, -2), l2 = Offset(16 - step * 10, -2);
  c.drawLine(const Offset(-14, -36), l1, leg);
  c.drawLine(const Offset(14, -36), l2, leg);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: l1, width: 22, height: 7), const Radius.circular(3)),
      Paint()..color = const Color(0xFF263238));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: l2, width: 22, height: 7), const Radius.circular(3)),
      Paint()..color = const Color(0xFF263238));
  // Corps
  final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-46, -74, 92, 42), const Radius.circular(21));
  c.drawRRect(body, Paint()
    ..shader = ui.Gradient.linear(const Offset(0, -74), const Offset(0, -32),
        const [Color(0xFF90A4AE), Color(0xFF455A64)], const [0, 1]));
  c.drawRRect(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFF263238));
  c.drawRect(const Rect.fromLTWH(-34, -58, 18, 6), Paint()..color = const Color(0xFF263238));
  c.drawRect(const Rect.fromLTWH(-28, -64, 6, 18), Paint()..color = const Color(0xFF263238));
  c.drawCircle(const Offset(26, -62), 5, Paint()..color = const Color(0xFFE53935));
  c.drawCircle(const Offset(35, -53), 5, Paint()..color = const Color(0xFF1E88E5));
  c.drawCircle(const Offset(17, -53), 5, Paint()..color = const Color(0xFF43A047));
  c.drawCircle(const Offset(26, -44), 5, Paint()..color = const Color(0xFFFDD835));
  c.save();
  c.translate(0, -72);
  c.scale(0.62, 0.62);
  _drawHero(c, hero, true, time);
  c.restore();
  c.restore();
}

/// Game Boy à gravité : on touche pour passer du sol au plafond.
void _jetDrawGameBoy(Canvas c, Offset feet, int hero, double time, bool up) {
  c.save();
  c.translate(feet.dx, feet.dy);
  if (up) {
    c.translate(0, -24);
    c.scale(1, -1);
    c.translate(0, 24);
  }
  final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -50, 48, 50), const Radius.circular(6));
  c.drawRRect(body, Paint()
    ..shader = ui.Gradient.linear(const Offset(-24, 0), const Offset(24, 0),
        const [Color(0xFFE0E0E0), Color(0xFFB0B0B0)], const [0, 1]));
  c.drawRRect(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFF616161));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -45, 36, 24), const Radius.circular(3)),
      Paint()..color = const Color(0xFF424242));
  c.drawRect(const Rect.fromLTWH(-14, -42, 28, 18), Paint()..color = const Color(0xFF9BBC0F));
  c.save();
  c.translate(0, -24);
  c.scale(0.36, 0.36);
  _drawHero(c, hero, true, time);
  c.restore();
  c.drawRect(const Rect.fromLTWH(-17, -15, 12, 4), Paint()..color = const Color(0xFF212121));
  c.drawRect(const Rect.fromLTWH(-13, -19, 4, 12), Paint()..color = const Color(0xFF212121));
  c.drawCircle(const Offset(10, -12), 3.5, Paint()..color = const Color(0xFF8E24AA));
  c.drawCircle(const Offset(17, -16), 3.5, Paint()..color = const Color(0xFF8E24AA));
  // Roulettes
  final wh = Paint()..color = const Color(0xFF263238);
  c.drawCircle(Offset(-14, 2 + sin(time * 30) * 0.5), 5, wh);
  c.drawCircle(Offset(14, 2 + cos(time * 30) * 0.5), 5, wh);
  c.restore();
}

void _jetDrawItem(Canvas c, Offset p, int kind, double time) {
  final pulse = 1 + sin(time * 5) * 0.08;
  const cols = [Color(0xFF00E5FF), Color(0xFFFF5252), Color(0xFFFF9100), Color(0xFFFFD740)];
  final col = cols[kind.clamp(0, 3)];
  c.drawCircle(p, 22 * pulse, Paint()
    ..color = col.withOpacity(0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  c.drawCircle(p, 16 * pulse, Paint()..color = const Color(0xFF101830).withOpacity(0.85));
  c.drawCircle(p, 16 * pulse, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = col);
  switch (kind) {
    case 0:
      _jIcon(c, Icons.shield_rounded, p, 18, col);
      break;
    case 1:
      // Aimant en U
      final m = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = col;
      c.drawArc(Rect.fromCenter(center: p + const Offset(0, -1), width: 16, height: 16), 0, pi, false, m);
      c.drawLine(p + const Offset(-8, -1), p + const Offset(-8, -7), m);
      c.drawLine(p + const Offset(8, -1), p + const Offset(8, -7), m);
      c.drawRect(Rect.fromLTWH(p.dx - 10.5, p.dy - 10, 5, 4), Paint()..color = Colors.white);
      c.drawRect(Rect.fromLTWH(p.dx + 5.5, p.dy - 10, 5, 4), Paint()..color = Colors.white);
      break;
    case 2:
      _jIcon(c, Icons.rocket_launch_rounded, p, 17, col);
      break;
    default:
      _jIcon(c, Icons.sports_esports_rounded, p, 18, col);
  }
}

// ─── Boutique Rétro Jet : jetpacks et améliorations ─────────────────────────

const _kJetPackKey       = 'jet_pack';          // jetpack choisi
const _kJetPackUnlockKey = 'jet_pack_unlocked'; // jetpacks achetés
const _kJetUpKey         = 'jet_upgrades';      // niveaux « aimant,turbo,bouclier »
const _kJetCoinsKey      = 'jet_coins';         // pièces de Rétro Jet (indépendantes de Rétro Jump)
const _kJetHeroKey       = 'jet_hero';          // héros choisi
const _kJetHeroesKey     = 'jet_heroes';        // héros débloqués
const _kJetThemeKey      = 'jet_theme';         // décor choisi
const _kJetThemeUnlockKey = 'jet_theme_unlocked'; // décors achetés
const _kJetMusicKey      = 'jet_music';         // musique de Rétro Jet
const _kJetMusicUnlockKey = 'jet_music_unlocked'; // musiques achetées

class _JetPack {
  final String name;
  final int price;
  final Color a, b;           // dégradé du réservoir
  final Color flameA, flameB; // dégradé de la flamme
  const _JetPack(this.name, this.price, this.a, this.b, this.flameA, this.flameB);
}

const _jetPackRainbow = 5; // flamme arc-en-ciel (couleur qui tourne)
const _jetPacks = [
  _JetPack('Classique', 0, Color(0xFFCFD8DC), Color(0xFF607D8B), Color(0xFFFFF59D), Color(0xFFFF9100)),
  _JetPack('Fusée rouge', 300, Color(0xFFFF8A80), Color(0xFFC62828), Color(0xFFFFF59D), Color(0xFFFF3D00)),
  _JetPack('Néon', 600, Color(0xFF84FFFF), Color(0xFF00838F), Color(0xFFE0F7FA), Color(0xFF00E5FF)),
  _JetPack('Toxique', 900, Color(0xFFCCFF90), Color(0xFF558B2F), Color(0xFFF4FF81), Color(0xFF76FF03)),
  _JetPack('Plasma', 1300, Color(0xFFEA80FC), Color(0xFF6A1B9A), Color(0xFFF3E5F5), Color(0xFFD500F9)),
  _JetPack('Arc-en-ciel', 1800, Color(0xFFFFFFFF), Color(0xFF90CAF9), Color(0xFFFF1744), Color(0xFF2979FF)),
  _JetPack('Fantôme', 2400, Color(0xFFECEFF1), Color(0xFF78909C), Color(0xFFFFFFFF), Color(0xFFB0BEC5)),
  _JetPack('Or', 3000, Color(0xFFFFF59D), Color(0xFFFFA000), Color(0xFFFFFDE7), Color(0xFFFFD740)),
];

/// Améliorations permanentes : aimant (3 niveaux), turbo (3 niveaux), bouclier au départ (1 niveau).
const _jetUpNames = ['Aimant', 'Turbo', 'Bouclier au départ'];
const _jetUpMax = [3, 3, 1];
const _jetUpPrices = [
  [600, 1500, 3500],
  [600, 1500, 3500],
  [2500],
];
String _jetUpDesc(int k, int lvl) => switch (k) {
      0 => 'Durée ${9 + 2 * lvl} s',
      1 => 'Durée ${(3.2 + 0.8 * lvl).toStringAsFixed(1).replaceAll('.', ',')} s',
      _ => lvl > 0 ? 'Chaque partie commence avec un bouclier' : 'Commence chaque partie avec un bouclier',
    };

/// Pouvoirs des héros dans Rétro Jet (les autres n'en ont pas ici).
const _jetPowers = {
  5: 'Bonus : durée +50 %',
  6: 'Attire les pièces proches',
  7: '1 pièce sur 4 compte double',
  8: 'Commence avec un bouclier',
  11: 'Turbo 60 % plus long',
  12: 'Bug écrasé = 10 pièces',
  14: '2ᵉ chance gratuite (hors défi du jour)',
};

// ═══════════════════════════════════════════════════════════════════════════
// Écran Rétro Jet : démarrage, menu, boutique, parties (paysage)
// ═══════════════════════════════════════════════════════════════════════════

// ─── Quêtes Rétro Jet : défis par partie (en séries) et trophées (à vie) ────

const _kJetChalKey    = 'jet_challenges';      // défis réussis de la série en cours
const _kJetChalLvlKey = 'jet_challenge_level'; // série en cours (0 = 1re)
const _kJetTrophyKey  = 'jet_trophies';        // trophées débloqués

class _JetChal {
  final String id, label;
  final int reward, target;
  final IconData icon;
  const _JetChal(this.id, this.label, this.reward, this.icon, this.target);
}

/// Défis de la série [lvl] : quand tous sont réussis, une nouvelle série commence,
/// plus difficile et mieux payée.
List<_JetChal> _jetChallengesFor(int lvl) {
  final f = 1 + lvl * 0.5;
  int m(int base) => ((base * f) / 50).round() * 50;
  int rw(int base) => (base * f).round();
  final boss = 1 + lvl ~/ 2, coins = 80 + 30 * lvl, turbos = 2 + lvl ~/ 2;
  final veh = 1 + lvl ~/ 2, jack = 1 + lvl ~/ 3;
  return [
    _JetChal('m1', 'Voler ${_fmtNum(m(300))} m', rw(20), Icons.flag_rounded, m(300)),
    _JetChal('m2', 'Voler ${_fmtNum(m(1000))} m', rw(50), Icons.flag_rounded, m(1000)),
    _JetChal('m3', 'Voler ${_fmtNum(m(2000))} m', rw(100), Icons.emoji_events_rounded, m(2000)),
    _JetChal('noitem', '${_fmtNum(m(500))} m sans ramasser de bonus', rw(60), Icons.block_rounded, m(500)),
    _JetChal('boss', 'Vaincre $boss boss en une partie', rw(60), Icons.smart_toy_rounded, boss),
    _JetChal('coins', '$coins pièces en une partie', rw(50), Icons.monetization_on_rounded, coins),
    _JetChal('turbo', '$turbos turbos en une partie', rw(40), Icons.rocket_launch_rounded, turbos),
    _JetChal('veh', 'Monter dans $veh véhicules en une partie', rw(40), Icons.precision_manufacturing_rounded, veh),
    _JetChal('jack', 'Gagner $jack lots au jackpot en une partie', rw(50), Icons.casino_rounded, jack),
  ];
}

/// Bonus versé quand toute une série est terminée.
int _jetSeriesBonus(int lvl) => 150 * (lvl + 1);

bool _jetChalMet(_JetChal c, int meters, int coins, Map<String, int> st) {
  int v(String k) => st[k] ?? 0;
  return switch (c.id) {
    'm1' || 'm2' || 'm3' => meters >= c.target,
    'noitem' => meters >= c.target && v('items') == 0,
    'boss' => v('bosses') >= c.target,
    'coins' => coins >= c.target,
    'turbo' => v('turbos') >= c.target,
    'veh' => v('vehicles') >= c.target,
    'jack' => v('jackpots') >= c.target,
    _ => false,
  };
}

final _jetTrophies = <_Trophy>[
  _Trophy('g10', 0, Icons.sports_esports_rounded, 'games', 10, 'Pilote d’essai', 'Jouer 10 parties'),
  _Trophy('g100', 1, Icons.sports_esports_rounded, 'games', 100, 'Pilote confirmé', 'Jouer 100 parties'),
  _Trophy('g500', 2, Icons.sports_esports_rounded, 'games', 500, 'As du jetpack', 'Jouer 500 parties'),
  _Trophy('b1000', 0, Icons.emoji_events_rounded, 'best', 1000, 'Décollage', 'Record de 1 000 m'),
  _Trophy('b3000', 1, Icons.emoji_events_rounded, 'best', 3000, 'Longue portée', 'Record de 3 000 m'),
  _Trophy('b6000', 2, Icons.emoji_events_rounded, 'best', 6000, 'Hors de portée', 'Record de 6 000 m'),
  _Trophy('b10000', 2, Icons.emoji_events_rounded, 'best', 10000, 'Vol infini', 'Record de 10 000 m'),
  _Trophy('d20k', 0, Icons.straighten_rounded, 'dist', 20000, 'Globe-trotter', '20 000 m cumulés'),
  _Trophy('d200k', 1, Icons.straighten_rounded, 'dist', 200000, 'Grand voyageur', '200 000 m cumulés'),
  _Trophy('d1m', 2, Icons.straighten_rounded, 'dist', 1000000, 'Tour du monde', '1 000 000 m cumulés'),
  _Trophy('bo1', 0, Icons.smart_toy_rounded, 'bosses', 1, 'Tueur de géant', 'Vaincre un boss'),
  _Trophy('bo25', 1, Icons.smart_toy_rounded, 'bosses', 25, 'Chasseur de boss', 'Vaincre 25 boss'),
  _Trophy('bo100', 2, Icons.smart_toy_rounded, 'bosses', 100, 'Fléau des envahisseurs', 'Vaincre 100 boss'),
  _Trophy('e50', 0, Icons.pest_control_rounded, 'bugs', 50, 'Écraseur', 'Écraser 50 ennemis'),
  _Trophy('e500', 1, Icons.pest_control_rounded, 'bugs', 500, 'Rouleau compresseur', 'Écraser 500 ennemis'),
  _Trophy('e2000', 2, Icons.pest_control_rounded, 'bugs', 2000, 'Exterminateur', 'Écraser 2 000 ennemis'),
  _Trophy('o1k', 0, Icons.monetization_on_rounded, 'coins', 1000, 'Tirelire', 'Gagner 1 000 pièces'),
  _Trophy('o10k', 1, Icons.monetization_on_rounded, 'coins', 10000, 'Coffre-fort', 'Gagner 10 000 pièces'),
  _Trophy('o50k', 2, Icons.monetization_on_rounded, 'coins', 50000, 'Trésor royal', 'Gagner 50 000 pièces'),
  _Trophy('jp10', 0, Icons.casino_rounded, 'jackpots', 10, 'Veinard', 'Gagner 10 lots au jackpot'),
  _Trophy('jp100', 1, Icons.casino_rounded, 'jackpots', 100, 'Roi du casino', 'Gagner 100 lots au jackpot'),
  _Trophy('lv1', 0, Icons.favorite_rounded, 'lives', 1, 'Miraculé', 'Gagner une vie au jackpot'),
  _Trophy('lv10', 1, Icons.favorite_rounded, 'lives', 10, 'Increvable', 'Gagner 10 vies au jackpot'),
  _Trophy('vh10', 0, Icons.precision_manufacturing_rounded, 'vehicles', 10, 'Pilote', 'Monter dans 10 véhicules'),
  _Trophy('vh100', 1, Icons.precision_manufacturing_rounded, 'vehicles', 100, 'Mécano', 'Monter dans 100 véhicules'),
  _Trophy('t25', 0, Icons.rocket_launch_rounded, 'turbos', 25, 'Pied au plancher', 'Utiliser 25 turbos'),
  _Trophy('t250', 1, Icons.rocket_launch_rounded, 'turbos', 250, 'Supersonique', 'Utiliser 250 turbos'),
  _Trophy('h1', 0, Icons.timer_rounded, 'time', 3600, 'Une heure', 'Jouer 1 h au total'),
  _Trophy('h10', 1, Icons.timer_rounded, 'time', 36000, 'Passionné', 'Jouer 10 h au total'),
  _Trophy('dy10', 0, Icons.today_rounded, 'dailies', 10, 'Quotidien', 'Jouer 10 défis du jour'),
  _Trophy('dy50', 1, Icons.today_rounded, 'dailies', 50, 'Rituel', 'Jouer 50 défis du jour'),
  _Trophy('se1', 0, Icons.workspace_premium_rounded, 'series', 1, 'Défi relevé', 'Terminer 1 série de défis'),
  _Trophy('se5', 1, Icons.workspace_premium_rounded, 'series', 5, 'Persévérant', 'Terminer 5 séries de défis'),
  _Trophy('se10', 2, Icons.workspace_premium_rounded, 'series', 10, 'Maître des défis', 'Terminer 10 séries de défis'),
  _Trophy('he5', 0, Icons.person_rounded, 'heroes', 5, 'Petite équipe', 'Débloquer 5 héros'),
  _Trophy('heAll', 2, Icons.person_rounded, 'heroes', _heroCount, 'Toute la bande', 'Débloquer tous les héros'),
  _Trophy('pkAll', 1, Icons.rocket_rounded, 'packs', _jetPacks.length, 'Garage complet', 'Débloquer tous les jetpacks'),
  _Trophy('thAll', 1, Icons.landscape_rounded, 'themes', _jetThemes.length, 'Explorateur', 'Débloquer tous les décors'),
  _Trophy('muAll', 1, Icons.music_note_rounded, 'musics', _musicNames.length, 'Mélomane', 'Débloquer toutes les musiques'),
  _Trophy('upAll', 2, Icons.upgrade_rounded, 'ups', 7, 'Au maximum', 'Toutes les améliorations au max'),
  _Trophy('zap100', 0, Icons.electric_bolt_rounded, 'zaps', 100, 'Électrisé', 'Être électrocuté 100 fois'),
  _Trophy('boom100', 0, Icons.local_fire_department_rounded, 'booms', 100, 'Boum !', 'Exploser 100 fois'),
];

class _JetScreen extends StatefulWidget {
  final bool haptics;
  final int hapticLvl;
  final Future<void> Function() onSave, onLoad; // sauvegarde commune (Rétro Jump + Rétro Jet)
  const _JetScreen({required this.haptics, required this.hapticLvl, required this.onSave, required this.onLoad});

  @override
  State<_JetScreen> createState() => _JetScreenState();
}

class _JetScreenState extends State<_JetScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bg =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  int _view = 0; // 0 écran de démarrage, 1 menu, 2 partie
  int _best = 0, _dailyBest = 0, _coins = 0, _runs = 0;
  String? _daily; // défi du jour en cours
  int _runId = 0;
  // Héros (partagés avec Rétro Jump) et boutique Rétro Jet
  int _hero = 0;
  Set<int> _unlocked = {0};
  int _pack = 0;
  int _theme = 0;
  Set<int> _themes = {0};
  late bool _haptics = widget.haptics;
  late int _hapticLvl = widget.hapticLvl;
  Set<int> _packs = {0};
  List<int> _ups = [0, 0, 0];
  // Classement et boutique (fenêtres par-dessus le menu)
  bool _lbOpen = false, _lbLoading = false, _shopOpen = false, _optOpen = false;
  bool _dailyOpen = false, _dLoading = false; // fenêtre du défi du jour
  bool _statsOpen = false; // fenêtre des statistiques
  bool _questOpen = false; // fenêtre des quêtes
  int _questTab = 0; // 0 défis, 1 trophées
  int _chLvl = 0; // série de défis en cours
  Set<String> _chDone = {}; // défis réussis de la série
  Set<String> _trHave = {}; // trophées débloqués
  Map<String, dynamic> _stats = {}; // statistiques à vie
  LbBoard? _dBoard;
  LbGhost? _ghost; // fantôme du meilleur joueur du jour
  int _lbTab = 0, _shopTab = 0;
  LbBoard? _board;
  List<LbEntry> _podium = const [];
  String _myPid = '';
  String? _myName; // pseudo (commun avec Rétro Jump)

  int get _heroCode => _hero; // pas de héros dorés dans Rétro Jet

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
    Leaderboard.publicId().then((id) {
      if (mounted) setState(() => _myPid = id);
    }).catchError((_) {});
    Leaderboard.name().then((n) {
      if (mounted) setState(() => _myName = n);
    }).catchError((_) {});
    _loadPodium();
    _startMusic();
  }

  // ── Musique (choix propre à Rétro Jet) ───────────────────────────────────
  int _music = 0;

  Set<int> _musics = {0};

  Future<void> _startMusic() async {
    final prefs = await SharedPreferences.getInstance();
    await QuizAudio.loadPrefs();
    _musics = {0, ..._ids(prefs, _kJetMusicUnlockKey, _musicNames.length)};
    _music = (prefs.getInt(_kJetMusicKey) ?? 0).clamp(0, _musicNames.length - 1);
    if (!_musics.contains(_music)) _music = 0;
    if (mounted) setState(() {});
    await QuizAudio.musicStart(_music);
  }

  Future<void> _tapMusic(int i) async {
    if (!_musics.contains(i)) {
      if (!await _confirmBuy('la musique ${_musicNames[i]}', _musicPrices[i],
          const Icon(Icons.music_note_rounded, color: Color(0xFFCE93D8), size: 40))) {
        return;
      }
      await _spend(_musicPrices[i]);
      _musics.add(i);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kJetMusicUnlockKey, _musics.map((e) => '$e').toList());
    }
    await _pickMusic(i);
    await _afterBuy();
  }

  Future<void> _pickMusic(int i) async {
    setState(() => _music = i);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kJetMusicKey, i);
    if (!QuizAudio.musicEnabled) await QuizAudio.setMusicEnabled(true);
    await QuizAudio.musicStart(i);
  }

  List<LbEntry> _topAll = const [], _topDaily = const []; // repères des autres joueurs en jeu

  Future<void> _loadPodium() async {
    final b = await Leaderboard.fetch('jet', lbAllDay);
    if (b != null && mounted) {
      setState(() {
        _podium = b.top.where((e) => e.score > 0).take(3).toList();
        _topAll = b.top.where((e) => e.score > 0).take(15).toList();
      });
    }
    final d = await Leaderboard.fetch('jetd', Leaderboard.today());
    if (d != null && mounted) setState(() => _topDaily = d.top.where((e) => e.score > 0).take(15).toList());
  }

  /// Distances des autres joueurs (traits dans le décor).
  List<(String, int)> get _markers => [
        for (final e in (_daily != null ? _topDaily : _topAll))
          if (e.pid != _myPid) (e.name, e.score),
      ];

  @override
  void dispose() {
    _bg.dispose();
    // Retour à la musique choisie dans Rétro Jump
    SharedPreferences.getInstance().then((p) => QuizAudio.musicStart((p.getInt(_kMusicKey) ?? 0).clamp(0, _musicNames.length - 1)));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Set<int> _ids(SharedPreferences prefs, String k, int n) => {
        for (final x in prefs.getStringList(k) ?? const <String>[])
          if (int.tryParse(x) case final v? when v >= 0 && v < n) v
      };

  Map<String, dynamic> _readStats(SharedPreferences prefs) {
    try {
      return Map<String, dynamic>.from(jsonDecode(prefs.getString(_kJetStatsKey) ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  int _sv(String k) => (_stats[k] as num?)?.toInt() ?? 0;

  /// Statistiques publiques (fiche joueur) : stats à vie + collection.
  Map<String, int> _publicStats() => {
        for (final e in _stats.entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
        'games': max(_sv('games'), _runs),
        'best': max(_sv('best'), _best),
        'heroes': _unlocked.length,
        'heroes_n': _heroCount,
        'packs': _packs.length,
        'packs_n': _jetPacks.length,
        'themes': _themes.length,
        'themes_n': _jetThemes.length,
        'musics': _musics.length,
        'musics_n': _musicNames.length,
        'ups': _ups.fold(0, (a, b) => a + b),
        'ups_n': _jetUpMax.fold(0, (a, b) => a + b),
        'series': _chLvl,
        'trophies': _trHave.length,
        'trophies_n': _jetTrophies.length,
      };

  /// Débloque les trophées atteints (pièces versées) ; renvoie les nouveaux.
  Future<List<_Trophy>> _checkTrophies() async {
    final prefs = await SharedPreferences.getInstance();
    final have = (prefs.getStringList(_kJetTrophyKey) ?? const <String>[]).toSet();
    final snap = _publicStats();
    final news = [for (final t in _jetTrophies) if (!have.contains(t.id) && (snap[t.key] ?? 0) >= t.goal) t];
    if (news.isEmpty) return news;
    have.addAll(news.map((t) => t.id));
    await prefs.setStringList(_kJetTrophyKey, have.toList());
    final total = (prefs.getInt(_kJetCoinsKey) ?? 0) + news.fold<int>(0, (a, t) => a + _tierReward[t.tier]);
    await prefs.setInt(_kJetCoinsKey, total);
    if (mounted) {
      setState(() {
        _trHave = have;
        _coins = total;
      });
    }
    return news;
  }

  /// Après un achat : trophées de collection éventuels.
  Future<void> _afterBuy() async {
    final news = await _checkTrophies();
    if (news.isEmpty || !mounted) return;
    QuizAudio.win();
    _snack(news.length == 1
        ? 'Trophée débloqué : ${news.first.name} (+${_tierReward[news.first.tier]} pièces)'
        : '${news.length} trophées débloqués !');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final d = (prefs.getString(_kJetDailyKey) ?? '').split('|');
    final ups = (prefs.getString(_kJetUpKey) ?? '').split(',');
    if (!mounted) return;
    setState(() {
      _best = prefs.getInt(_kJetBestKey) ?? 0;
      _dailyBest = d.length >= 2 && d[0] == Leaderboard.today() ? int.tryParse(d[1]) ?? 0 : 0;
      _coins = prefs.getInt(_kJetCoinsKey) ?? 0;
      _runs = prefs.getInt(_kJetRunsKey) ?? 0;
      _unlocked = {0, ..._ids(prefs, _kJetHeroesKey, _heroCount)};
      _hero = (prefs.getInt(_kJetHeroKey) ?? 0).clamp(0, _heroCount - 1);
      if (!_unlocked.contains(_hero)) _hero = 0;
      _themes = {0, ..._ids(prefs, _kJetThemeUnlockKey, _jetThemes.length)};
      _theme = (prefs.getInt(_kJetThemeKey) ?? 0).clamp(0, _jetThemes.length - 1);
      if (!_themes.contains(_theme)) _theme = 0;
      _packs = {0, ..._ids(prefs, _kJetPackUnlockKey, _jetPacks.length)};
      _pack = (prefs.getInt(_kJetPackKey) ?? 0).clamp(0, _jetPacks.length - 1);
      if (!_packs.contains(_pack)) _pack = 0;
      _ups = [
        for (int k = 0; k < 3; k++) (k < ups.length ? int.tryParse(ups[k]) ?? 0 : 0).clamp(0, _jetUpMax[k]),
      ];
      _stats = _readStats(prefs);
      _chLvl = prefs.getInt(_kJetChalLvlKey) ?? 0;
      _chDone = (prefs.getStringList(_kJetChalKey) ?? const <String>[]).toSet();
      _trHave = (prefs.getStringList(_kJetTrophyKey) ?? const <String>[]).toSet();
    });
    Leaderboard.setJetStats(_publicStats());
  }

  Future<void> _openDaily() async {
    setState(() {
      _dailyOpen = true;
      _lbOpen = false;
      _shopOpen = false;
      _optOpen = false;
      _dLoading = true;
      _dBoard = null;
    });
    final b = await Leaderboard.fetch('jetd', Leaderboard.today());
    if (!mounted) return;
    setState(() {
      _dBoard = b;
      _dLoading = false;
    });
    final gh = await Leaderboard.topJetGhost(Leaderboard.today());
    if (mounted) setState(() => _ghost = gh);
  }

  void _play({bool daily = false}) {
    setState(() {
      _daily = daily ? Leaderboard.today() : null;
      _view = 2;
      _lbOpen = false;
      _shopOpen = false;
      _dailyOpen = false;
      _runId++;
    });
  }

  /// Fin de partie : pièces, records, envoi au classement.
  Future<(bool, LbRank?, String?, List<(IconData, String, int)>)> _finish(
      int meters, int coins, int seconds, Map<String, int> runStats, String ghost) async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_kJetCoinsKey) ?? 0) + coins;
    await prefs.setInt(_kJetCoinsKey, total);
    await prefs.setInt(_kJetRunsKey, _runs + 1);
    final daily = _daily;
    // Statistiques à vie
    final st = _readStats(prefs);
    void add(String k, int n) => st[k] = ((st[k] as num?)?.toInt() ?? 0) + n;
    if (!st.containsKey('games')) st['games'] = _runs; // parties jouées avant les stats
    add('games', 1);
    if (daily != null) add('dailies', 1);
    add('dist', meters);
    add('time', seconds);
    add('coins', coins);
    for (final e in runStats.entries) {
      add(e.key, e.value);
    }
    st['best'] = max(max((st['best'] as num?)?.toInt() ?? 0, _best), meters);
    await prefs.setString(_kJetStatsKey, jsonEncode(st));
    _stats = st;
    // Défis de la série en cours
    final rewards = <(IconData, String, int)>[];
    final chals = _jetChallengesFor(_chLvl);
    for (final c in chals) {
      if (!_chDone.contains(c.id) && _jetChalMet(c, meters, coins, runStats)) {
        _chDone.add(c.id);
        rewards.add((Icons.check_circle_rounded, c.label, c.reward));
      }
    }
    if (chals.every((c) => _chDone.contains(c.id))) {
      rewards.add((Icons.workspace_premium_rounded, 'Série ${_chLvl + 1} terminée !', _jetSeriesBonus(_chLvl)));
      _chLvl++;
      _chDone = {};
    }
    await prefs.setInt(_kJetChalLvlKey, _chLvl);
    await prefs.setStringList(_kJetChalKey, _chDone.toList());
    final gain = rewards.fold<int>(0, (a, r) => a + r.$3);
    if (gain > 0) await prefs.setInt(_kJetCoinsKey, (prefs.getInt(_kJetCoinsKey) ?? 0) + gain);
    // Trophées (pièces versées par _checkTrophies)
    _best = max(_best, meters);
    for (final t in await _checkTrophies()) {
      rewards.add((t.icon, 'Trophée ${t.name}', _tierReward[t.tier]));
    }
    final coinsNow = prefs.getInt(_kJetCoinsKey) ?? 0;
    if (mounted) setState(() => _coins = coinsNow);
    var record = false;
    if (daily != null) {
      final d = (prefs.getString(_kJetDailyKey) ?? '').split('|');
      final old = d.length >= 2 && d[0] == daily ? int.tryParse(d[1]) ?? 0 : 0;
      if (meters > old) {
        record = true;
        await prefs.setString(_kJetDailyKey, '$daily|$meters');
      }
    }
    if (meters > (prefs.getInt(_kJetBestKey) ?? 0)) {
      if (daily == null) record = true;
      await prefs.setInt(_kJetBestKey, meters);
    }
    if (mounted) {
      setState(() {
        _coins = max(total, _coins);
        _runs++;
        _best = max(_best, meters);
        if (daily != null) _dailyBest = max(_dailyBest, meters);
      });
    }
    Leaderboard.setJetStats(_publicStats());
    final name = await Leaderboard.name();
    if (name == null) return (record, null, 'Choisis un pseudo dans le classement pour être classé.', rewards);
    final r = await Leaderboard.submitJet(daily: daily != null, score: meters, hero: _heroCode, time: max(1, seconds), name: name);
    _loadPodium(); // podium et repères des autres joueurs à jour dès la fin de partie
    // Nouveau meilleur score du jour : on envoie son fantôme
    if (daily != null && record && r != null && ghost.isNotEmpty) {
      Leaderboard.uploadJetGhost(daily, meters, ghost).then((_) async {
        final gh = await Leaderboard.topJetGhost(daily);
        if (mounted) setState(() => _ghost = gh);
      });
    }
    return (record, r, r == null ? 'Hors ligne : score non envoyé.' : null, rewards);
  }

  void _menu() {
    setState(() => _view = 1);
    _load();
    _loadPodium();
  }

  Future<void> _openLb([int tab = 0]) async {
    setState(() {
      _lbOpen = true;
      _shopOpen = false;
      _lbTab = tab;
      _lbLoading = true;
      _board = null;
    });
    final b = await switch (tab) {
      0 => Leaderboard.fetch('jetd', Leaderboard.today()), // défi du jour
      1 => Leaderboard.fetchJetWeek(), // défi semaine : médailles de la semaine
      2 => Leaderboard.fetchJetGeneral(), // défi général : coupes et médailles
      _ => Leaderboard.fetch('jet', lbAllDay), // solo
    };
    if (!mounted || _lbTab != tab) return;
    setState(() {
      _board = b;
      _lbLoading = false;
    });
  }

  // ── Pseudo (commun avec Rétro Jump) ───────────────────────────────────────
  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _myName ?? '');
    final n = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _uiStyle.panel,
        title: const Text('Ton pseudo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 16,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Pseudo…', hintStyle: TextStyle(color: Colors.white38)),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Valider')),
        ],
      ),
    );
    ctrl.dispose();
    if (n == null || Leaderboard.clean(n).isEmpty) return;
    final res = await Leaderboard.rename(n);
    if (!mounted) return;
    if (res == Leaderboard.renameTaken) {
      _snack('« ${Leaderboard.clean(n)} » est déjà pris, choisis-en un autre');
      return;
    }
    if (res == Leaderboard.renameInvalid) {
      _snack('Pseudo refusé');
      return;
    }
    setState(() => _myName = Leaderboard.clean(n));
    _snack(res == Leaderboard.renameOk ? 'Pseudo enregistré' : 'Pseudo enregistré (envoyé au prochain score)');
    if (_lbOpen) _openLb(_lbTab);
  }

  // ── Remise à zéro (Rétro Jet seulement) ──────────────────────────────────
  Future<void> _resetJet() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _uiStyle.panel,
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
          SizedBox(width: 8),
          Expanded(child: Text('Réinitialiser Rétro Jet ?', style: TextStyle(color: Colors.white))),
        ]),
        content: const Text(
            'Pièces, héros, jetpacks, décors, musiques, améliorations, record, stats et quêtes de Rétro Jet seront effacés. '
            'Rétro Jump n’est pas touché. Pense à sauvegarder avant !',
            style: TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().toList()) {
      if (k.startsWith('jet_')) await prefs.remove(k);
    }
    await _load();
    await _startMusic();
    if (mounted) _snack('Rétro Jet réinitialisé');
  }

  // ── Achats ───────────────────────────────────────────────────────────────
  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: _uiStyle.panel,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<bool> _confirmBuy(String what, int price, Widget preview) async {
    if (_coins < price) {
      _snack('Il te manque ${_fmtNum(price - _coins)} pièces.');
      return false;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _uiStyle.panel,
        title: Text('Débloquer $what ?'),
        content: Row(children: [
          SizedBox(width: 60, height: 50, child: preview),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Prix : ${_fmtNum(price)} pièces\nTu en as ${_fmtNum(_coins)}.',
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Débloquer')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _spend(int price) async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_kJetCoinsKey) ?? 0) - price;
    await prefs.setInt(_kJetCoinsKey, total);
    if (mounted) setState(() => _coins = total);
    QuizAudio.sfx('powerup');
  }

  Future<void> _tapHero(int i) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_unlocked.contains(i)) {
      if (!await _confirmBuy(_heroNames[i], _heroPrices[i], CustomPaint(painter: _HeroPreviewPainter(i)))) return;
      await _spend(_heroPrices[i]);
      _unlocked.add(i);
      await prefs.setStringList(_kJetHeroesKey, _unlocked.map((e) => '$e').toList());
    }
    await prefs.setInt(_kJetHeroKey, i);
    if (mounted) setState(() => _hero = i);
    await _afterBuy();
  }

  Future<void> _tapPack(int i) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_packs.contains(i)) {
      final p = _jetPacks[i];
      if (!await _confirmBuy('le jetpack ${p.name}', p.price, CustomPaint(painter: _JetPackSwatch(i)))) return;
      await _spend(p.price);
      _packs.add(i);
      await prefs.setStringList(_kJetPackUnlockKey, _packs.map((e) => '$e').toList());
    }
    await prefs.setInt(_kJetPackKey, i);
    if (mounted) setState(() => _pack = i);
    await _afterBuy();
  }

  Future<void> _tapTheme(int i) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_themes.contains(i)) {
      final t = _jetThemes[i];
      if (!await _confirmBuy('le décor ${t.name}', t.price, CustomPaint(painter: _JetThemeSwatch(i)))) return;
      await _spend(t.price);
      _themes.add(i);
      await prefs.setStringList(_kJetThemeUnlockKey, _themes.map((e) => '$e').toList());
    }
    await prefs.setInt(_kJetThemeKey, i);
    if (mounted) setState(() => _theme = i);
    await _afterBuy();
  }

  // ── Options ──────────────────────────────────────────────────────────────
  Future<void> _setSound(bool v) async {
    QuizAudio.enabled = v;
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, v);
  }

  Future<void> _setMusic(bool v) async {
    await QuizAudio.setMusicEnabled(v);
    if (mounted) setState(() {});
  }

  Future<void> _setHaptics(bool v) async {
    setState(() => _haptics = v);
    if (v) HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticsKey, v);
  }

  Future<void> _setHapticLvl(int v) async {
    setState(() => _hapticLvl = v);
    _hapticAt(v, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHapticLvlKey, v);
  }

  Future<void> _saveLoad(bool load) async {
    if (load) {
      await widget.onLoad();
      if (!mounted) return;
      await _load();
    } else {
      await widget.onSave();
    }
  }

  Future<void> _tapUpgrade(int k) async {
    final lvl = _ups[k];
    if (lvl >= _jetUpMax[k]) return;
    final price = _jetUpPrices[k][lvl];
    if (!await _confirmBuy('${_jetUpNames[k]} (niveau ${lvl + 1})', price, Icon(_upIcon(k), color: _upColor(k), size: 40))) return;
    await _spend(price);
    final prefs = await SharedPreferences.getInstance();
    _ups[k] = lvl + 1;
    await prefs.setString(_kJetUpKey, _ups.join(','));
    if (mounted) setState(() {});
    await _afterBuy();
  }

  IconData _upIcon(int k) => k == 0 ? Icons.bolt_rounded : k == 1 ? Icons.rocket_launch_rounded : Icons.shield_rounded;
  Color _upColor(int k) => k == 0 ? const Color(0xFFFF5252) : k == 1 ? const Color(0xFFFF9100) : _jCyan;

  // ── Affichage ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _view == 0 || (_view == 1 && !_lbOpen && !_shopOpen && !_optOpen && !_dailyOpen && !_statsOpen && !_questOpen),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_lbOpen || _shopOpen || _optOpen || _dailyOpen || _statsOpen || _questOpen) {
          setState(() {
            _statsOpen = false;
            _questOpen = false;
            _lbOpen = false;
            _shopOpen = false;
            _optOpen = false;
            _dailyOpen = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070A14),
        body: switch (_view) {
          2 => _JetGame(
              key: ValueKey(_runId),
              hero: _heroCode,
              pack: _pack,
              theme: _theme,
              haptics: _haptics,
              hapticLvl: _hapticLvl,
              daily: _daily,
              best: _daily != null ? _dailyBest : _best,
              showHelp: _runs < 3,
              markers: _markers,
              ghost: _daily != null ? _ghost : null,
              magnetTime: _daily != null ? 9.0 : 9.0 + 2 * _ups[0], // améliorations sans effet en défi du jour
              turboTime: _daily != null ? 3.2 : 3.2 + 0.8 * _ups[1],
              startShield: _ups[2] > 0 && _daily == null, // aucun bonus en défi du jour
              onFinish: _finish,
              onRetry: () => _play(daily: _daily != null),
              onMenu: _menu,
            ),
          1 => _menuView(),
          _ => _splashView(),
        },
      ),
    );
  }

  Widget _bgLayer({bool dark = false}) => Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bg,
            builder: (_, __) => CustomPaint(painter: _JetMenuPainter(_bg.value * 30, _heroCode, _pack, _theme, hideHero: dark)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: dark
                  ? RadialGradient(colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.7)], radius: 1.1)
                  : LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      stops: const [0.35, 1],
                    ),
            ),
          ),
        ),
      ]);

  // Écran de démarrage du jeu
  Widget _splashView() {
    return GestureDetector(
      onTap: () {
        QuizAudio.sfx('powerup');
        setState(() => _view = 1);
      },
      child: Stack(children: [
        Positioned.fill(child: _bgLayer(dark: true)),
        Positioned.fill(
          child: SafeArea(
          child: AnimatedBuilder(
            animation: _bg,
            builder: (_, __) {
              final t = _bg.value * 30;
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Héros en vol
                Expanded(
                  flex: 4,
                  child: SizedBox.expand(child: CustomPaint(painter: _JetSplashHeroPainter(t, _heroCode, _pack))),
                ),
                Expanded(
                  flex: 5,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(
                      flex: 5,
                      child: FittedBox(
                      child: ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFDE7), Color(0xFFFFB300)],
                        ).createShader(r),
                        child: const Column(children: [
                          Text('RÉTRO',
                              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1,
                                  letterSpacing: 8, shadows: [Shadow(color: Color(0xFF0D0F14), offset: Offset(0, 4))])),
                          Text('JET',
                              style: TextStyle(color: Colors.white, fontSize: 110, fontWeight: FontWeight.w900, height: 0.95,
                                  letterSpacing: 10, shadows: [Shadow(color: Color(0xFF0D0F14), offset: Offset(0, 7))])),
                        ]),
                      ),
                    ),
                    ),
                    const Text('by foclabroc',
                        style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    const SizedBox(height: 14),
                    Flexible(flex: 4, child: SizedBox(height: 120, child: FittedBox(child: _jetPodium()))),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 5)),
                      child: const Text('Touche pour jouer',
                          style: TextStyle(color: Color(0xFFFFD54F), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                  ]),
                ),
              ]);
            },
          ),
          ),
        ),
      ]),
    );
  }

  /// Podium : 2ᵉ à gauche, 1ᵉʳ au centre (plus haut), 3ᵉ à droite ; places libres si personne.
  Widget _jetPodium() {
    const cols = [Color(0xFFFFD54F), Color(0xFFCFD8DC), Color(0xFFFFAB91)];
    const heights = [46.0, 34.0, 26.0];
    Widget place(int i) {
      final e = i < _podium.length ? _podium[i] : null;
      return SizedBox(
        width: 92,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (e != null)
            _Avatar(code: e.avatar, hero: e.hero, size: 34)
          else
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
              child: const Text('?', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900)),
            ),
          const SizedBox(height: 3),
          Text(e?.name ?? 'Libre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: e != null ? Colors.white : Colors.white38, fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text(e != null ? '${_fmtNum(e.score)} m' : '—',
              style: TextStyle(color: cols[i], fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Container(
            width: 80,
            height: heights[i],
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cols[i].withOpacity(0.85), cols[i].withOpacity(0.35)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text('${i + 1}',
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ]),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('MEILLEURS PILOTES',
          style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
      const SizedBox(height: 4),
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [place(1), place(0), place(2)]),
    ]);
  }

  Widget _menuView() {
    return Stack(children: [
      Positioned.fill(child: _bgLayer()),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            // Titre
            Expanded(
              flex: 5,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _JetPill(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  color: const Color(0xFFFF9100),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                Flexible(
                  flex: 6,
                  child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFDE7), Color(0xFFFFB300)],
                    ).createShader(r),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RÉTRO',
                          style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1,
                              letterSpacing: 6, shadows: [Shadow(color: Color(0xFF0D0F14), offset: Offset(0, 4))])),
                      Text('JET',
                          style: TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.w900, height: 0.95,
                              letterSpacing: 8, shadows: [Shadow(color: Color(0xFF0D0F14), offset: Offset(0, 6))])),
                    ]),
                  ),
                ),
                ),
                const SizedBox(height: 6),
                // Héros et jetpack choisis (touche = boutique)
                GestureDetector(
                  onTap: () => setState(() {
                    _shopOpen = true;
                    _shopTab = 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 24, height: 24, child: CustomPaint(painter: _HeroPreviewPainter(_heroCode))),
                      const SizedBox(width: 6),
                      Text(_heroNames[_hero], style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      SizedBox(width: 20, height: 24, child: CustomPaint(painter: _JetPackSwatch(_pack))),
                      const SizedBox(width: 6),
                      Text(_jetPacks[_pack].name,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded, color: Colors.white38, size: 14),
                    ]),
                  ),
                ),
                if (_jetPowers[_hero] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: Text('⚡ ${_jetPowers[_hero]}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                const Spacer(),
                // Podium des 3 meilleurs (classement général)
                SizedBox(
                  height: 96,
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.bottomLeft, child: _jetPodium()),
                ),
              ]),
            ),
            // Actions
            Expanded(
              flex: 4,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _JetCoins(coins: _coins),
                  const SizedBox(width: 8),
                  _JetPill(
                    icon: Icons.bar_chart_rounded,
                    label: 'Stats',
                    color: const Color(0xFF26A69A),
                    onTap: () => setState(() {
                      _statsOpen = true;
                      _optOpen = false;
                      _shopOpen = false;
                      _lbOpen = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _JetPill(
                    icon: Icons.settings_rounded,
                    label: 'Options',
                    color: const Color(0xFF29B6F6),
                    onTap: () => setState(() {
                      _optOpen = true;
                      _shopOpen = false;
                      _lbOpen = false;
                    }),
                  ),
                ]),
                const Spacer(),
                Row(children: [
                  Expanded(child: _JetStat(label: 'RECORD', value: '${_fmtNum(_best)} m', color: _jGold)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _JetStat(
                          label: 'DÉFI DU JOUR',
                          value: _dailyBest > 0 ? '${_fmtNum(_dailyBest)} m' : '—',
                          color: Colors.lightBlueAccent)),
                ]),
                const SizedBox(height: 8),
                _JetButton(
                  label: 'JOUER',
                  icon: Icons.play_arrow_rounded,
                  colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
                  big: true,
                  onTap: () => _play(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _JetButton(
                      label: 'DÉFI DU JOUR',
                      icon: Icons.today_rounded,
                      colors: const [Color(0xFF29B6F6), Color(0xFF1565C0)],
                      onTap: _openDaily,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JetButton(
                      label: 'CLASSEMENT',
                      icon: Icons.leaderboard_rounded,
                      colors: const [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                      onTap: () => _openLb(),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _JetButton(
                      label: 'QUÊTES ${_chDone.length}/${_jetChallengesFor(_chLvl).length}',
                      icon: Icons.military_tech_rounded,
                      colors: const [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                      onTap: () => setState(() {
                        _questOpen = true;
                        _shopOpen = false;
                        _lbOpen = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JetButton(
                      label: 'BOUTIQUE',
                      icon: Icons.storefront_rounded,
                      colors: const [Color(0xFFEC407A), Color(0xFFAD1457)],
                      onTap: () => setState(() {
                        _shopOpen = true;
                        _lbOpen = false;
                      }),
                    ),
                  ),
                ]),
                const Spacer(),
              ]),
            ),
          ]),
        ),
      ),
      if (_lbOpen) Positioned.fill(child: _lbView()),
      if (_shopOpen) Positioned.fill(child: _shopView()),
      if (_optOpen) Positioned.fill(child: _optView()),
      if (_dailyOpen) Positioned.fill(child: _dailyView()),
      if (_statsOpen) Positioned.fill(child: _statsView()),
      if (_questOpen) Positioned.fill(child: _questView()),
    ]);
  }

  // ── Fenêtres ──────────────────────────────────────────────────────────────
  Widget _window({required IconData icon, required Color color, required String title, required List<Widget> tabs,
      required Widget body, Widget? footer, required VoidCallback onClose, double widthFactor = 0.8}) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: 0.92,
            child: Container(
              decoration: BoxDecoration(
                color: _uiStyle.dialog,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
              ),
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
              child: Column(children: [
                Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(children: tabs),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54), onPressed: onClose),
                ]),
                const Divider(color: Colors.white10, height: 8),
                Expanded(child: body),
                if (footer != null) footer,
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(bool sel, String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: sel ? LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.35)!]) : null,
            color: sel ? null : color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? Colors.white54 : color.withOpacity(0.6)),
            boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 10)] : null,
          ),
          child: Text(label,
              style: TextStyle(color: sel ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      );

  Widget _lbView() {
    final b = _board;
    return _window(
      icon: Icons.leaderboard_rounded,
      color: Colors.amberAccent,
      title: 'Classement Rétro Jet',
      onClose: () => setState(() => _lbOpen = false),
      tabs: [
        _tabBtn(_lbTab == 0, 'Défi du jour', Colors.lightBlueAccent, () => _openLb(0)),
        _tabBtn(_lbTab == 1, 'Défi semaine', Colors.tealAccent, () => _openLb(1)),
        _tabBtn(_lbTab == 2, 'Défi général', Colors.amberAccent, () => _openLb(2)),
        _tabBtn(_lbTab == 3, 'Solo', Colors.pinkAccent, () => _openLb(3)),
      ],
      body: Column(children: [
        // Pseudo (touche pour le modifier), fixe en haut
        GestureDetector(
          onTap: _editName,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6, right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.person_rounded, size: 16, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_myName == null ? 'Choisis ton pseudo pour être classé' : 'Pseudo : $_myName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              const Icon(Icons.edit_rounded, size: 15, color: Colors.white54),
            ]),
          ),
        ),
        // Temps restant (fixe) : seule la liste des joueurs défile
        if (_lbTab < 3)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6, right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(_lbTab == 0 ? Icons.timer_rounded : Icons.emoji_events_rounded,
                  size: 15, color: _lbTab == 0 ? Colors.lightBlueAccent : Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: _lbTab == 0
                    ? const _DailyCountdown(color: Colors.lightBlueAccent, prefix: 'Fin du défi du jour dans ')
                    : const _DailyCountdown(color: Colors.amberAccent, prefix: 'Remise des coupes dans ', weekly: true),
              ),
            ]),
          ),
        Expanded(
          child: _lbLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
              : b == null
                  ? const Center(
                      child: Text('Classement indisponible (hors ligne ?)', style: TextStyle(color: Colors.white54)))
                  : b.top.isEmpty
                      ? const Center(
                          child: Text('Personne pour l’instant : à toi de jouer !', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(itemCount: b.top.length, itemBuilder: (_, i) => _lbRow(i, b.top[i])),
        ),
      ]),
      footer: b != null && b.me.rank != null
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Ton rang : ${b.me.rank} / ${b.me.total}  ·  ${_fmtNum(b.me.score ?? 0)} m',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  /// Élément possédé suivant / précédent.
  static int _cycle(Set<int> owned, int cur, int dir) {
    final l = owned.toList()..sort();
    final i = max(0, l.indexOf(cur));
    return l[(i + dir + l.length) % l.length];
  }

  Widget _cycler(String label, Widget preview, String name, Color color, ValueChanged<int> onStep) {
    Widget arrow(IconData ic, int dir) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onStep(dir),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: Icon(ic, color: color, size: 22)),
        );
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(children: [
        arrow(Icons.chevron_left_rounded, -1),
        SizedBox(width: 30, height: 26, child: preview),
        const SizedBox(width: 6),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
        arrow(Icons.chevron_right_rounded, 1),
      ]),
    );
  }

  Widget _dailyPicks() => Padding(
        padding: const EdgeInsets.only(top: 8, right: 6),
        child: Row(children: [
          Expanded(
            child: _cycler('HÉROS', CustomPaint(painter: _HeroPreviewPainter(_heroCode)), _heroNames[_hero], Colors.pinkAccent,
                (d) => _tapHero(_cycle(_unlocked, _hero, d))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _cycler(
                'DÉCOR',
                ClipRRect(borderRadius: BorderRadius.circular(5), child: CustomPaint(painter: _JetThemeSwatch(_theme))),
                _jetThemes[_theme].name,
                Colors.purpleAccent,
                (d) => _tapTheme(_cycle(_themes, _theme, d))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _cycler('MUSIQUE', const Icon(Icons.music_note_rounded, color: Color(0xFFCE93D8), size: 22),
                _musicNames[_music], Colors.greenAccent, (d) => _pickMusic(_cycle(_musics, _music, d))),
          ),
        ]),
      );

  Widget _dailyView() {
    final b = _dBoard;
    return _window(
      icon: Icons.today_rounded,
      color: Colors.lightBlueAccent,
      title: 'Défi du jour',
      onClose: () => setState(() => _dailyOpen = false),
      tabs: const [
        SizedBox(width: 150, child: _DailyCountdown(color: Colors.lightBlueAccent, prefix: 'Fin dans ')),
      ],
      body: _dLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
          : b == null
              ? const Center(child: Text('Classement indisponible (hors ligne ?)', style: TextStyle(color: Colors.white54)))
              : b.top.isEmpty
                  ? const Center(
                      child: Text('Personne n’a encore joué aujourd’hui : sois le premier !',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(itemCount: b.top.length, itemBuilder: (_, i) => _lbRow(i, b.top[i])),
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        _dailyPicks(),
        Padding(
        padding: const EdgeInsets.only(top: 8, right: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(
                  _dailyBest > 0
                      ? 'Ton meilleur aujourd’hui : ${_fmtNum(_dailyBest)} m${b != null && b.me.rank != null ? '  ·  ${b.me.rank}ᵉ / ${b.me.total}' : ''}'
                      : 'Pas encore joué aujourd’hui',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w800)),
              if (_ghost != null)
                Text('👻 Fantôme : ${_ghost!.name} (${_fmtNum(_ghost!.score)} m) vole avec toi',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700)),
              const Text('Même parcours pour tous, sans pièces ni jackpot · essais illimités',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          SizedBox(
            width: 190,
            child: _JetButton(
              label: 'JOUER',
              icon: Icons.play_arrow_rounded,
              colors: const [Color(0xFF29B6F6), Color(0xFF1565C0)],
              onTap: () => _play(daily: true),
            ),
          ),
        ]),
      ),
      ]),
    );
  }

  Widget _lbRow(int i, LbEntry e) {
    final me = e.pid == _myPid;
    const medals = [Color(0xFFFFD54F), Color(0xFFCFD8DC), Color(0xFFFFAB91)];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openCard(e),
      child: Container(
      margin: const EdgeInsets.only(bottom: 4, right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: me ? Colors.amberAccent.withOpacity(0.12) : _uiStyle.panel,
        borderRadius: BorderRadius.circular(12),
        border: me ? Border.all(color: Colors.amberAccent.withOpacity(0.6)) : null,
      ),
      child: Row(children: [
        SizedBox(
          width: 30,
          child: Text('${i + 1}',
              style: TextStyle(color: i < 3 ? medals[i] : Colors.white54, fontSize: 15, fontWeight: FontWeight.w900)),
        ),
        _Avatar(code: e.avatar, hero: e.hero, size: 30),
        const SizedBox(width: 8),
        // Héros utilisé (à côté de l'avatar s'il y en a un)
        if (e.avatar != null && e.avatar!.isNotEmpty) ...[
          SizedBox(width: 26, height: 26, child: CustomPaint(painter: _HeroPreviewPainter(_heroSafe(e.hero)))),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Flexible(
              child: Text(e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: me ? Colors.amberAccent : Colors.white, fontWeight: FontWeight.w700)),
            ),
            // Coupes gagnées au défi semaine de Rétro Jet
            if ((e.cups ?? 0) > 0) ...[
              const SizedBox(width: 5),
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 15),
              Text('${e.cups}', style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ]),
          // Heure de la dernière partie de Rétro Jet
          if (e.lastPlayed != null)
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 11, color: Colors.white38),
              const SizedBox(width: 3),
              Text(_when(e.lastPlayed!),
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        if (e.mGold != null)
          // Défi semaine / général : récompenses, meilleure distance du défi en petit
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              _Cups(
                  gold: e.gold ?? 0,
                  silver: e.silver ?? 0,
                  bronze: e.bronze ?? 0,
                  medals: e.medals ?? 0,
                  mGold: e.mGold ?? 0,
                  mSilver: e.mSilver ?? 0,
                  mBronze: e.mBronze ?? 0,
                  size: 13),
              Text('${_fmtNum(e.score)} m',
                  style: const TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ]),
          )
        else
          Text('${_fmtNum(e.score)} m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ]),
      ),
    );
  }

  // ── Fiche joueur Rétro Jet ─────────────────────────────────────────────────
  Widget _sTile(IconData icon, Color color, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _uiStyle.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
            ]),
          ),
        ]),
      );

  Widget _sGrid(List<Widget> tiles, {int cols = 3}) => GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 3.1,
        children: tiles,
      );

  Widget _sHead(String txt) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
        child: Text(txt,
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  static String _dur(int secs) =>
      secs >= 3600 ? '${secs ~/ 3600} h ${(secs % 3600) ~/ 60} min' : '${secs ~/ 60} min ${secs % 60} s';

  static String _when(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final hm = '${two(d.hour)}:${two(d.minute)}';
    if (d.year == now.year && d.month == now.month && d.day == now.day) return hm;
    final y = now.subtract(const Duration(days: 1));
    if (d.year == y.year && d.month == y.month && d.day == y.day) return 'hier $hm';
    return '${two(d.day)}/${two(d.month)} $hm';
  }

  Future<void> _openCard(LbEntry e) async {
    final f = Leaderboard.jetPlayerCard(e.pid);
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _uiStyle.dialog,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: f,
            builder: (_, snap) {
              final c = snap.data;
              final loading = snap.connectionState != ConnectionState.done;
              final h = (c?['hero'] as num?)?.toInt() ?? e.hero;
              final av = (c?['avatar'] as String?) ?? e.avatar;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    _Avatar(code: av, hero: h, size: 44),
                    const SizedBox(width: 8),
                    SizedBox(width: 30, height: 30, child: CustomPaint(painter: _HeroPreviewPainter(_heroSafe(h)))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text((c?['name'] as String?) ?? e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ]),
                  if (loading)
                    const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Colors.amberAccent))
                  else if (c == null)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Fiche indisponible (hors ligne ?)', style: TextStyle(color: Colors.white54)),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(padding: const EdgeInsets.only(right: 8), child: _cardBody(c)),
                    ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cardBody(Map<String, dynamic> c) {
    final st = c['stats'] is Map ? Map<String, dynamic>.from(c['stats'] as Map) : <String, dynamic>{};
    int? n(String k) => (c[k] as num?)?.toInt();
    int? v(String k) => (st[k] as num?)?.toInt();
    String fmt(int? x, [String unit = '']) => x == null ? '—' : '${_fmtNum(x)}$unit';
    String rank(int? r, [int? total]) => r == null ? '' : (total == null ? '  #$r' : '  #$r/$total');
    String own(String k) => v(k) == null ? '—' : '${v(k)}/${v('${k}_n') ?? '?'}';
    final games = v('games');
    final since = DateTime.tryParse(c['since'] as String? ?? '')?.toLocal();
    final last = DateTime.tryParse(c['last_played'] as String? ?? '')?.toLocal();
    final cups = (n('gold') ?? 0) + (n('silver') ?? 0) + (n('bronze') ?? 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (cups + (n('medals') ?? 0) + (n('mgold') ?? 0) + (n('msilver') ?? 0) + (n('mbronze') ?? 0) > 0) ...[
        _sHead('PALMARÈS'),
        _Cups(
            gold: n('gold') ?? 0,
            silver: n('silver') ?? 0,
            bronze: n('bronze') ?? 0,
            medals: n('medals') ?? 0,
            mGold: n('mgold') ?? 0,
            mSilver: n('msilver') ?? 0,
            mBronze: n('mbronze') ?? 0,
            size: 18),
      ],
      _sHead('DÉFI DU JOUR'),
      _sGrid([
        _sTile(Icons.today_rounded, Colors.cyanAccent, 'Défi du jour${rank(n('rank_today'))}', fmt(n('today'), ' m')),
        _sTile(Icons.date_range_rounded, Colors.tealAccent, 'Défi semaine${rank(n('rank_wch'), n('total_wch'))}',
            n('rank_wch') == null ? '—' : '🥇${n('wg') ?? 0} 🥈${n('ws') ?? 0} 🥉${n('wb') ?? 0} ✅${n('wp') ?? 0}'),
        _sTile(Icons.emoji_events_rounded, Colors.amberAccent, 'Défi général${rank(n('rank_gen'), n('total_gen'))}',
            n('rank_gen') == null ? '—' : '🏆 $cups'),
        _sTile(Icons.workspace_premium_rounded, Colors.orangeAccent, 'Défis gagnés', fmt(n('daily_wins'))),
        _sTile(Icons.event_repeat_rounded, Colors.lightBlueAccent, 'Défis joués', fmt(n('dailies'))),
        _sTile(Icons.star_rounded, Colors.yellowAccent, 'Meilleur défi', fmt(n('daily_best'), ' m')),
      ]),
      _sHead('SOLO'),
      _sGrid([
        _sTile(Icons.person_rounded, Colors.pinkAccent, 'Record Solo${rank(n('rank_all'), n('total_all'))}',
            fmt(n('best') ?? v('best'), ' m')),
        _sTile(Icons.sports_esports_rounded, Colors.cyanAccent, 'Parties jouées', fmt(games)),
        _sTile(Icons.timer_rounded, Colors.tealAccent, 'Temps de jeu', v('time') == null ? '—' : _dur(v('time')!)),
        _sTile(Icons.straighten_rounded, Colors.purpleAccent, 'Distance cumulée', fmt(v('dist'), ' m')),
        _sTile(Icons.show_chart_rounded, Colors.lightBlueAccent, 'Moyenne / partie',
            games == null || games == 0 || v('dist') == null ? '—' : '${_fmtNum(v('dist')! ~/ games)} m'),
        _sTile(Icons.monetization_on_rounded, Colors.amberAccent, 'Pièces gagnées', fmt(v('coins'))),
        _sTile(Icons.pest_control_rounded, Colors.lightGreenAccent, 'Ennemis écrasés', fmt(v('bugs'))),
        _sTile(Icons.smart_toy_rounded, const Color(0xFFE040FB), 'Boss vaincus', fmt(v('bosses'))),
        _sTile(Icons.casino_rounded, const Color(0xFFCE93D8), 'Jackpots gagnés', fmt(v('jackpots'))),
      ]),
      _sHead('COLLECTION'),
      _sGrid([
        _sTile(Icons.person_rounded, Colors.pinkAccent, 'Héros', own('heroes')),
        _sTile(Icons.rocket_rounded, Colors.orangeAccent, 'Jetpacks', own('packs')),
        _sTile(Icons.landscape_rounded, Colors.purpleAccent, 'Décors', own('themes')),
        _sTile(Icons.music_note_rounded, Colors.greenAccent, 'Musiques', own('musics')),
        _sTile(Icons.upgrade_rounded, Colors.cyanAccent, 'Améliorations', own('ups')),
        _sTile(Icons.emoji_events_rounded, const Color(0xFFFFD54F), 'Trophées', own('trophies')),
        _sTile(Icons.workspace_premium_rounded, Colors.amberAccent, 'Séries de défis', fmt(v('series'))),
      ]),
      if (st.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Stats détaillées visibles quand ce joueur aura mis à jour son jeu.',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      const SizedBox(height: 10),
      Text(
        [
          if (last != null) 'Dernière partie : ${_when(last)}',
          if (since != null)
            'Joueur depuis le ${since.day.toString().padLeft(2, '0')}/${since.month.toString().padLeft(2, '0')}/${since.year}',
        ].join('  ·  '),
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    ]);
  }

  // ── Quêtes : défis et trophées ─────────────────────────────────────────────
  Widget _questView() {
    final chals = _jetChallengesFor(_chLvl);
    final snap = _publicStats();
    final got = _jetTrophies.where((t) => _trHave.contains(t.id)).length;
    Widget head(List<Widget> children) => Container(
          margin: const EdgeInsets.only(bottom: 8, right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Row(children: children),
        );
    final Widget body = _questTab == 0
        ? Column(children: [
            head([
              Text('Série ${_chLvl + 1}',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Text('${_chDone.length}/${chals.length} réussis',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 4),
              Text('Série complète : +${_fmtNum(_jetSeriesBonus(_chLvl))}',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12.5, fontWeight: FontWeight.w800)),
            ]),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.only(right: 6),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 5.2,
                children: [
                  for (final c in chals)
                    Builder(builder: (_) {
                      final done = _chDone.contains(c.id);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: done ? Colors.greenAccent.withOpacity(0.08) : _uiStyle.panel,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: done ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(children: [
                          Icon(done ? Icons.check_circle_rounded : c.icon,
                              color: done ? Colors.greenAccent : Colors.white54, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(c.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: done ? Colors.white54 : Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    decoration: done ? TextDecoration.lineThrough : null)),
                          ),
                          const _CoinIcon(size: 11),
                          const SizedBox(width: 4),
                          Text('+${c.reward}',
                              style: TextStyle(
                                  color: done ? Colors.white24 : Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w800)),
                        ]),
                      );
                    }),
                ],
              ),
            ),
          ])
        : Column(children: [
            head([
              Text('$got / ${_jetTrophies.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: got / _jetTrophies.length,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      color: const Color(0xFFFFD54F)),
                ),
              ),
              const SizedBox(width: 10),
              for (int k = 0; k < 3; k++) ...[
                Icon(Icons.emoji_events_rounded, size: 15, color: _tierColors[k]),
                Text('${_jetTrophies.where((t) => t.tier == k && _trHave.contains(t.id)).length} ',
                    style: TextStyle(color: _tierColors[k], fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ]),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.only(right: 6),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.5,
                children: [
                  for (final t in [
                    ..._jetTrophies.where((t) => _trHave.contains(t.id)),
                    ..._jetTrophies.where((t) => !_trHave.contains(t.id)),
                  ])
                    _trophyTile(t, _trHave.contains(t.id), snap[t.key] ?? 0),
                ],
              ),
            ),
          ]);
    return _window(
      icon: Icons.military_tech_rounded,
      color: Colors.greenAccent,
      title: 'Quêtes',
      onClose: () => setState(() => _questOpen = false),
      tabs: [
        _tabBtn(_questTab == 0, 'Défis ${_chDone.length}/${chals.length}', Colors.lightGreenAccent,
            () => setState(() => _questTab = 0)),
        _tabBtn(_questTab == 1, 'Trophées $got/${_jetTrophies.length}', const Color(0xFFFFD54F),
            () => setState(() => _questTab = 1)),
      ],
      body: body,
      footer: const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text('Défis : à réussir en une partie, une nouvelle série plus dure suit. Trophées : bronze 25, argent 75, or 200 pièces.',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white38, fontSize: 11)),
      ),
    );
  }

  Widget _trophyTile(_Trophy x, bool got, int value) {
    final c = _tierColors[x.tier];
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: got ? c.withOpacity(0.10) : _uiStyle.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: got ? c.withOpacity(0.6) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: got ? c.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            border: Border.all(color: got ? c : Colors.white24, width: 1.5),
          ),
          child: Icon(got ? x.icon : Icons.lock_rounded, size: 15, color: got ? c : Colors.white24),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(x.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: got ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w800)),
            Text(x.desc,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
            const SizedBox(height: 3),
            if (got)
              Text('${_tierNames[x.tier]} · +${_tierReward[x.tier]}',
                  style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700))
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                    value: (value / x.goal).clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: Colors.white10,
                    color: c.withOpacity(0.7)),
              ),
          ]),
        ),
      ]),
    );
  }

  // ── Statistiques à vie ─────────────────────────────────────────────────────
  Widget _statsView() {
    final games = max(_sv('games'), _runs);
    final dist = _sv('dist');
    return _window(
      icon: Icons.bar_chart_rounded,
      color: Colors.tealAccent,
      title: 'Statistiques',
      onClose: () => setState(() => _statsOpen = false),
      tabs: const [],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sHead('PARTIES'),
          _sGrid([
            _sTile(Icons.sports_esports_rounded, Colors.cyanAccent, 'Parties jouées', _fmtNum(games)),
            _sTile(Icons.emoji_events_rounded, Colors.amberAccent, 'Record', '${_fmtNum(max(_best, _sv('best')))} m'),
            _sTile(Icons.today_rounded, Colors.lightBlueAccent, 'Défis du jour joués', _fmtNum(_sv('dailies'))),
            _sTile(Icons.straighten_rounded, Colors.purpleAccent, 'Distance cumulée', '${_fmtNum(dist)} m'),
            _sTile(Icons.show_chart_rounded, Colors.lightBlueAccent, 'Moyenne / partie',
                _sv('games') == 0 ? '—' : '${_fmtNum(dist ~/ _sv('games'))} m'),
            _sTile(Icons.timer_rounded, Colors.tealAccent, 'Temps de jeu', _dur(_sv('time'))),
          ]),
          _sHead('EXPLOITS'),
          _sGrid([
            _sTile(Icons.monetization_on_rounded, Colors.amberAccent, 'Pièces gagnées', _fmtNum(_sv('coins'))),
            _sTile(Icons.pest_control_rounded, Colors.lightGreenAccent, 'Ennemis écrasés', _fmtNum(_sv('bugs'))),
            _sTile(Icons.smart_toy_rounded, const Color(0xFFE040FB), 'Boss vaincus', _fmtNum(_sv('bosses'))),
            _sTile(Icons.rocket_launch_rounded, Colors.orangeAccent, 'Turbos', _fmtNum(_sv('turbos'))),
            _sTile(Icons.precision_manufacturing_rounded, const Color(0xFF90A4AE), 'Véhicules', _fmtNum(_sv('vehicles'))),
            _sTile(Icons.shield_rounded, _jCyan, 'Boucliers brisés', _fmtNum(_sv('shields'))),
          ]),
          _sHead('JACKPOT'),
          _sGrid([
            _sTile(Icons.toll_rounded, const Color(0xFFCE93D8), 'Pièces chance', _fmtNum(_sv('chances'))),
            _sTile(Icons.casino_rounded, const Color(0xFFE040FB), 'Tours de jackpot', _fmtNum(_sv('spins'))),
            _sTile(Icons.redeem_rounded, Colors.amberAccent, 'Lots gagnés', _fmtNum(_sv('jackpots'))),
            _sTile(Icons.favorite_rounded, Colors.redAccent, 'Vies gagnées', _fmtNum(_sv('lives'))),
          ]),
          _sHead('CRASHS'),
          _sGrid([
            _sTile(Icons.electric_bolt_rounded, Colors.cyanAccent, 'Électrocuté', _fmtNum(_sv('zaps'))),
            _sTile(Icons.local_fire_department_rounded, Colors.deepOrangeAccent, 'Explosé', _fmtNum(_sv('booms'))),
          ]),
        ]),
      ),
    );
  }

  Widget _shopView() {
    const pink = Color(0xFFFF4081);
    final Widget body = switch (_shopTab) {
      1 => _shopGrid(_jetPacks.length, (i) => _packTile(i)),
      2 => _shopGrid(_jetThemes.length, (i) => _themeTile(i), aspect: 1.3),
      3 => ListView(children: [for (int k = 0; k < 3; k++) _upRow(k)]),
      4 => _shopGrid(_musicNames.length, (i) => _musicTile(i)),
      _ => _shopGrid(_heroCount, (i) => _heroTile(i)),
    };
    return _window(
      icon: Icons.storefront_rounded,
      color: pink,
      title: 'Boutique',
      onClose: () => setState(() => _shopOpen = false),
      widthFactor: 0.96, // plus large : tous les onglets visibles sans défiler
      tabs: [
        _tabBtn(_shopTab == 0, 'Héros', const Color(0xFFFF5252), () => setState(() => _shopTab = 0)),
        _tabBtn(_shopTab == 1, 'Jetpacks', const Color(0xFFFF9100), () => setState(() => _shopTab = 1)),
        _tabBtn(_shopTab == 2, 'Décors', const Color(0xFF00B8D4), () => setState(() => _shopTab = 2)),
        _tabBtn(_shopTab == 4, 'Musiques', const Color(0xFFAB47BC), () => setState(() => _shopTab = 4)),
        _tabBtn(_shopTab == 3, 'Améliorations', const Color(0xFF00C853), () => setState(() => _shopTab = 3)),
      ],
      body: body,
      // Pièces en bas à droite (la barre d'onglets tient sans défiler)
      footer: Padding(
        padding: const EdgeInsets.only(top: 6, right: 6),
        child: Row(children: [
          Expanded(
            child: _shopTab == 0
                ? const Text('Héros propres à Rétro Jet (indépendants de Rétro Jump)',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white38, fontSize: 11.5))
                : const SizedBox.shrink(),
          ),
          _JetCoins(coins: _coins),
        ]),
      ),
    );
  }

  Widget _shopGrid(int n, Widget Function(int i) tile, {double aspect = 0.92}) => LayoutBuilder(builder: (_, c) {
        final cols = max(aspect > 1 ? 3 : 4, (c.maxWidth / (aspect > 1 ? 170 : 112)).floor());
        return GridView.builder(
          padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: aspect,
          ),
          itemCount: n,
          itemBuilder: (_, i) => tile(i),
        );
      });

  Widget _tile({required bool selected, required bool locked, required Widget preview, required String name,
      required int price, String? sub, required VoidCallback onTap}) {
    const pink = Color(0xFFFF4081);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        decoration: BoxDecoration(
          color: selected ? pink.withOpacity(0.14) : _uiStyle.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? pink : Colors.white.withOpacity(0.08), width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              Opacity(opacity: locked ? 0.35 : 1, child: preview),
              if (locked) const Icon(Icons.lock_rounded, color: Colors.white70, size: 20),
            ]),
          ),
          const SizedBox(height: 4),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: locked ? Colors.white38 : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
          if (locked)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const _CoinIcon(size: 11),
              const SizedBox(width: 3),
              Text(_fmtNum(price), style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w800)),
            ])
          else
            Text(sub ?? (selected ? 'Choisi' : 'Choisir'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: selected ? pink : Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _heroTile(int i) {
    return _tile(
      selected: _hero == i,
      locked: !_unlocked.contains(i),
      preview: SizedBox(width: 52, height: 46, child: CustomPaint(painter: _HeroPreviewPainter(i))),
      name: _heroNames[i],
      price: _heroPrices[i],
      sub: _jetPowers[i] != null && _hero != i ? '⚡ pouvoir' : null,
      onTap: () => _tapHero(i),
    );
  }

  Widget _packTile(int i) => _tile(
        selected: _pack == i,
        locked: !_packs.contains(i),
        preview: SizedBox(width: 40, height: 48, child: CustomPaint(painter: _JetPackSwatch(i))),
        name: _jetPacks[i].name,
        price: _jetPacks[i].price,
        onTap: () => _tapPack(i),
      );

  Widget _musicTile(int i) => _tile(
        selected: _music == i,
        locked: !_musics.contains(i),
        preview: Icon(Icons.music_note_rounded, color: _music == i ? const Color(0xFFE1BEE7) : const Color(0xFFAB47BC), size: 34),
        name: _musicNames[i],
        price: _musicPrices[i],
        sub: _music == i ? 'En cours' : null,
        onTap: () => _tapMusic(i),
      );

  Widget _themeTile(int i) => _tile(
        selected: _theme == i,
        locked: !_themes.contains(i),
        preview: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.expand(child: CustomPaint(painter: _JetThemeSwatch(i))),
        ),
        name: _jetThemes[i].name,
        price: _jetThemes[i].price,
        onTap: () => _tapTheme(i),
      );

  Widget _optRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) => Container(
        margin: const EdgeInsets.only(bottom: 6, right: 6),
        padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
        decoration: BoxDecoration(color: _uiStyle.panel, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: value ? Colors.lightBlueAccent : Colors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          Switch(value: value, onChanged: onChanged),
        ]),
      );

  Widget _optView() {
    const lvls = ['Faible', 'Normale', 'Forte'];
    return _window(
      icon: Icons.settings_rounded,
      color: Colors.lightBlueAccent,
      title: 'Options',
      onClose: () => setState(() => _optOpen = false),
      tabs: const [],
      body: ListView(children: [
        _optRow(QuizAudio.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, 'Son', QuizAudio.enabled, _setSound),
        _optRow(Icons.music_note_rounded, 'Musique', QuizAudio.musicEnabled, _setMusic),
        _optRow(Icons.vibration_rounded, 'Vibrations', _haptics, _setHaptics),
        if (_haptics)
          Container(
            margin: const EdgeInsets.only(bottom: 6, right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _uiStyle.panel, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('Intensité', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              const Spacer(),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _tabBtn(_hapticLvl == i, lvls[i], Colors.lightBlueAccent, () => _setHapticLvl(i)),
                ),
            ]),
          ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text('SAUVEGARDE (Rétro Jump + Rétro Jet)',
              style: TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        Row(children: [
          Expanded(
            child: _JetButton(
              label: 'SAUVEGARDER',
              icon: Icons.save_rounded,
              colors: const [Color(0xFF26A69A), Color(0xFF00695C)],
              onTap: () => _saveLoad(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _JetButton(
              label: 'CHARGER',
              icon: Icons.upload_file_rounded,
              colors: const [Color(0xFF5C6BC0), Color(0xFF283593)],
              onTap: () => _saveLoad(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _JetButton(
              label: 'RESET',
              icon: Icons.restart_alt_rounded,
              colors: const [Color(0xFFEF5350), Color(0xFFB71C1C)],
              onTap: _resetJet,
            ),
          ),
          const SizedBox(width: 6),
        ]),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.only(left: 4, right: 8),
          child: Text(
              'Règles : maintiens pour voler, lâche pour descendre. Évite lasers, missiles et bugs. '
              'Bonus : bouclier, aimant, turbo et véhicules (Mecha Manette : touche pour sauter ; '
              'Game Boy à gravité : touche pour passer du sol au plafond ; Dragon pixel : son feu détruit lasers et ennemis pendant 12 s). '
              'Un 2ᵉ bouclier part en réserve : touche la bulle en bas à droite pour l’activer. '
              'Pièces, héros, jetpacks et décors '
              'sont propres à Rétro Jet.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
        ),
      ]),
    );
  }

  Widget _upRow(int k) {
    final lvl = _ups[k];
    final maxed = lvl >= _jetUpMax[k];
    final col = _upColor(k);
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _uiStyle.panel, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: col.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: col)),
          child: Icon(_upIcon(k), color: col, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_jetUpNames[k], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(maxed || lvl > 0 ? _jetUpDesc(k, lvl) : _jetUpDesc(k, 0),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              for (int j = 0; j < _jetUpMax[k]; j++)
                Container(
                  width: 26,
                  height: 6,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: j < lvl ? col : Colors.white12, borderRadius: BorderRadius.circular(3)),
                ),
            ]),
          ]),
        ),
        if (maxed)
          const Text('MAX', style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w900))
        else
          ElevatedButton(
            onPressed: () => _tapUpgrade(k),
            style: ElevatedButton.styleFrom(backgroundColor: col.withOpacity(0.85)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const _CoinIcon(size: 14),
              const SizedBox(width: 5),
              Text(_fmtNum(_jetUpPrices[k][lvl]), style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          ),
      ]),
    );
  }
}

/// Jetpack seul (boutique).
class _JetPackSwatch extends CustomPainter {
  final int pack;
  _JetPackSwatch(this.pack);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final p = _jetPacks[pack.clamp(0, _jetPacks.length - 1)];
    final s = size.height / 48;
    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.scale(s, s);
    final flame = Path()
      ..moveTo(-7, 30)
      ..quadraticBezierTo(0, 40, 0, 47)
      ..quadraticBezierTo(0, 40, 7, 30)
      ..close();
    canvas.drawPath(flame, Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 30), const Offset(0, 47), [p.flameA, p.flameB], const [0, 1]));
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-10, 2, 20, 28), const Radius.circular(7));
    canvas.drawRRect(body, Paint()..shader = ui.Gradient.linear(const Offset(-10, 0), const Offset(10, 0), [p.a, p.b], const [0, 1]));
    canvas.drawRRect(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF37474F));
    canvas.drawRect(const Rect.fromLTWH(-6, 7, 12, 4), Paint()..color = Colors.white.withOpacity(0.5));
    canvas.drawRect(const Rect.fromLTWH(-7, 26, 14, 5), Paint()..color = const Color(0xFF263238));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JetPackSwatch old) => old.pack != pack;
}

/// Écran de démarrage : héros qui vole en boucle avec une traînée de flammes.
class _JetSplashHeroPainter extends CustomPainter {
  final double t;
  final int hero, pack;
  _JetSplashHeroPainter(this.t, this.hero, this.pack);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;
    final s = size.height / _jH;
    canvas.save();
    canvas.scale(s, s);
    final w = size.width / s;
    final c = Offset(w * 0.55 + sin(t * 1.3) * 14, 210 + sin(t * 2.1) * 26);
    final pk = _jetPacks[pack.clamp(0, _jetPacks.length - 1)];
    for (int i = 1; i < 16; i++) {
      final q = Offset(c.dx - 38 - i * 13.0, c.dy + 6 + i * 2.5 + sin(t * 9 + i) * 3);
      final col = pack == _jetPackRainbow
          ? HSVColor.fromAHSV(1, (t * 200 + i * 25) % 360, 0.9, 1).toColor()
          : (i.isEven ? pk.flameB : pk.flameA);
      canvas.drawCircle(q, 7.5 * (1 - i / 17), Paint()
        ..color = col.withOpacity(0.75 * (1 - i / 16))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    _jetDrawPlayer(canvas, c, hero, t, thrust: true, scale: 2.2, pack: pack, rot: -0.12);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JetSplashHeroPainter old) => true;
}

/// Fond animé du menu : labo qui défile + héros en vol stationnaire.
class _JetMenuPainter extends CustomPainter {
  final double t;
  final int hero, pack, theme;
  final bool hideHero;
  _JetMenuPainter(this.t, this.hero, this.pack, this.theme, {this.hideHero = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;
    final s = size.height / _jH;
    final w = size.width / s;
    canvas.save();
    canvas.scale(s, s);
    _jetDrawLab(canvas, w, t * 120, t, theme);
    // Pièces qui défilent
    for (int i = 0; i < 10; i++) {
      final x = (w + 40) - ((t * 120 + i * 34) % (w + 80));
      _jetDrawCoin(canvas, Offset(x, 250 + sin(i * 0.6) * 26), t);
    }
    if (!hideHero) {
      _jetDrawPlayer(canvas, Offset(w * 0.3, 214 + sin(t * 2) * 12), hero, t, thrust: true, scale: 1.7, pack: pack);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JetMenuPainter old) =>
      old.t != t || old.hero != hero || old.pack != pack || old.theme != theme;
}

class _JetPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color; // pilule colorée (ex. bouton Accueil)
  const _JetPill({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: color != null ? LinearGradient(colors: [color!, Color.lerp(color!, Colors.black, 0.35)!]) : null,
            color: color == null ? Colors.black.withOpacity(0.45) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color != null ? Colors.white38 : Colors.white24),
            boxShadow: color != null ? [BoxShadow(color: color!.withOpacity(0.4), blurRadius: 10)] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _JetCoins extends StatelessWidget {
  final int coins;
  const _JetCoins({required this.coins});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _jGold.withOpacity(0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const _CoinIcon(size: 16),
          const SizedBox(width: 6),
          Text(_fmtNum(coins), style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _JetStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _JetStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ]),
      );
}

class _JetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool big;
  final VoidCallback onTap;
  const _JetButton({required this.label, required this.icon, required this.colors, required this.onTap, this.big = false});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            height: big ? 58 : 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: colors.last.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: big ? 30 : 20),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: TextStyle(color: Colors.white, fontSize: big ? 22 : 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ]),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Partie
// ═══════════════════════════════════════════════════════════════════════════

class _JetGame extends StatefulWidget {
  final int hero; // code héros (+32 si doré)
  final int pack; // jetpack
  final int theme; // décor
  final double magnetTime, turboTime; // améliorations
  final bool startShield;
  final bool haptics;
  final int hapticLvl;
  final String? daily;
  final int best;
  final bool showHelp;
  final List<(String, int)> markers; // autres joueurs : (pseudo, distance)
  final LbGhost? ghost; // fantôme du meilleur joueur du jour (défi du jour)
  final Future<(bool, LbRank?, String?, List<(IconData, String, int)>)> Function(
      int meters, int coins, int seconds, Map<String, int> stats, String ghost) onFinish;
  final VoidCallback onRetry, onMenu;
  const _JetGame({
    super.key,
    required this.hero,
    required this.pack,
    required this.theme,
    required this.magnetTime,
    required this.turboTime,
    required this.startShield,
    required this.haptics,
    required this.hapticLvl,
    required this.daily,
    required this.best,
    required this.showHelp,
    this.markers = const [],
    this.ghost,
    required this.onFinish,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  State<_JetGame> createState() => _JetGameState();
}

class _JetGameState extends State<_JetGame> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Statistiques de la partie (ajoutées aux stats à vie à la fin)
  final _st = <String, int>{};
  void _stat(String k, [int n = 1]) => _st[k] = (_st[k] ?? 0) + n;
  // Jackpot : pièces chance ramassées, tirées après un crash
  int _chances = 0, _bonusM = 0;
  bool _jackpot = false, _spinning = false, _lifeWon = false;
  double _reelFrom = 0, _reelTo = 0, _reelT = 0, _reelPos = 6;
  int? _prize; // dernier lot tiré
  int _lastReelTick = 0;
  double _nextChance = 2600;
  // Boss tous les 500 m : 3 attaques de missiles
  int _bossState = 0; // 0 aucun, 1 arrivée, 2 combat, 3 vaincu
  double _bossT = 0, _bossY = (_jCeil + _jFloor) / 2, _bossShotT = 0;
  int _bossNext = 500, _bossShots = 0, _bossLevel = 0;

  late final Random _gen; // parcours (graine commune pour le défi du jour)
  final _fxRng = Random();
  Ticker? _ticker;
  Duration _last = Duration.zero;

  double _scale = 1, _w = 0; // échelle écran / monde, largeur du monde visible
  double _cam = 0, _speed = 430, _dist = 0;
  double _py = _jFloor, _vy = 0;
  bool _hold = false, _onFloor = true;
  bool _paused = false, _dead = false, _over = false;
  double _time = 0, _deadT = 0, _playTime = 0;
  double _inv = 0, _magnet = 0, _turbo = 0, _shake = 0, _flash = 0, _deadRot = 0;
  bool _shield = false;
  bool _shieldReserve = false; // 2ᵉ bouclier ramassé : en réserve (bulle en bas à droite)
  bool _lifeUsed = false; // Fantôme : 2ᵉ chance déjà utilisée
  int _vehicle = -1; // 0 Mecha Manette, 1 Game Boy à gravité, 2 Dragon pixel
  double _dragonT = 0; // temps restant du dragon
  double _fireSfxT = 0;
  // Fantôme du jour : enregistrement (distance, hauteur) toutes les 0,1 s
  final _ghostRec = <int>[];
  double _ghostT = 0;
  late final ByteData? _ghostData =
      widget.ghost == null ? null : ByteData.sublistView(widget.ghost!.data);
  bool _gbUp = false;
  int _coins = 0;
  double _nextX = 700, _nextItem = 1800, _nextMissile = 2600;
  bool _recordShown = false;
  String? _banner;
  double _bannerT = 0;
  double _shellT = 0;
  final _zaps = <_JZap>[];
  final _missiles = <_JMissile>[];
  final _bugs = <_JBug>[];
  final _coinsL = <_JCoin>[];
  final _items = <_JItem>[];
  final _fx = <_JFx>[];
  // Résultat
  bool _record = false;
  LbRank? _rank;
  String? _note;
  List<(IconData, String, int)> _rewards = const []; // défis, série, trophées
  bool _saving = false;

  double get _px => _cam + _w * 0.24; // x monde du joueur
  int get _power => widget.daily != null ? -1 : widget.hero % 32; // pouvoir du héros (aucun en défi du jour)
  double get _bonusMul => _power == 5 ? 1.5 : 1.0; // Disquette
  int get _meters => (_dist / _jUnitsPerM).floor() + _bonusM;
  Offset get _hitC {
    if (_vehicle == 0) return Offset(_px, _py - 48);
    if (_vehicle == 1) return Offset(_px, _py - 24);
    if (_vehicle == 2) return Offset(_px, _py - 28);
    return Offset(_px, _py - 21);
  }

  double get _hitR => _vehicle == 0 ? 34 : _vehicle == 1 ? 25 : _vehicle == 2 ? 24 : 14;

  /// Position du fantôme (monde) à l'instant de jeu actuel ; null s'il est fini ou absent.
  Offset? get _ghostPos {
    final d = _ghostData;
    if (d == null) return null;
    final n = d.lengthInBytes ~/ 6;
    if (n < 2) return null;
    final f = _playTime / 0.1;
    final i = f.floor();
    if (i >= n - 1) return null;
    final k = f - i;
    double gx(int j) => d.getInt32(j * 6, Endian.little).toDouble();
    double gy(int j) => d.getInt16(j * 6 + 4, Endian.little).toDouble();
    return Offset(gx(i) + (gx(i + 1) - gx(i)) * k + _w * 0.24, gy(i) + (gy(i + 1) - gy(i)) * k);
  }

  /// Fantôme enregistré (base64) pour le défi du jour.
  String _ghostEncode() {
    if (_ghostRec.isEmpty) return '';
    final b = ByteData(_ghostRec.length ~/ 2 * 6);
    for (int j = 0; j < _ghostRec.length ~/ 2; j++) {
      b.setInt32(j * 6, _ghostRec[j * 2], Endian.little);
      b.setInt16(j * 6 + 4, _ghostRec[j * 2 + 1], Endian.little);
    }
    return base64Encode(b.buffer.asUint8List());
  }

  /// Dragon : son souffle détruit les lasers et les ennemis devant lui.
  void _updateDragon(double dt) {
    _dragonT -= dt;
    if (_dragonT <= 0) {
      _burst(_hitC, const Color(0xFF66BB6A), 20);
      _vehicle = -1;
      _inv = max(_inv, 1.2);
      _showBanner('LE DRAGON S’ENVOLE');
      return;
    }
    final mouth = Offset(_px + 34, _py - 40);
    for (int i = 0; i < 2; i++) {
      _fx.add(_JFx(mouth.dx, mouth.dy + (_fxRng.nextDouble() - 0.5) * 10, _speed + 520 + _fxRng.nextDouble() * 200,
          (_fxRng.nextDouble() - 0.5) * 160, 0.28, 6 + _fxRng.nextDouble() * 4,
          i == 0 ? const Color(0xFFFF9100) : const Color(0xFFFFEB3B),
          glow: true));
    }
    final fire = Offset(_px + 120, _py - 36);
    var burnt = false;
    _zaps.removeWhere((z) {
      if (z.x < _px || _segDist(fire, z.a, z.b) > 80) return false;
      _burst(Offset(z.x, z.y), const Color(0xFFFF6D00), 18, speed: 300);
      burnt = true;
      return true;
    });
    for (final b in _bugs) {
      if (b.dead || b.x < _px) continue;
      if ((Offset(b.x, b.y) - fire).distance < 85) {
        b.dead = true;
        _coins += 5;
        _stat('bugs');
        _burst(Offset(b.x, b.y), const Color(0xFFFF9100), 14);
        burnt = true;
      }
    }
    _fireSfxT -= dt;
    if (burnt && _fireSfxT <= 0) {
      _fireSfxT = 0.25;
      QuizAudio.sfx('explode');
      _haptic(1);
    }
  }

  @override
  void initState() {
    super.initState();
    final d = widget.daily;
    _gen = d != null ? Random(Leaderboard.seedFor('jet-$d')) : Random();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
    _shield = widget.startShield || _power == 8; // amélioration ou Télé
    if (widget.showHelp) _showBanner('Maintiens pour voler !', 3);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    super.dispose();
  }

  void _setPaused(bool v) {
    setState(() {
      _paused = v;
      _hold = false;
    });
    if (v) {
      QuizAudio.musicPause();
    } else {
      QuizAudio.musicResume();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_dead && !_paused && mounted) {
      _setPaused(true);
    }
  }

  void _haptic(int strength) {
    if (widget.haptics) _hapticAt(widget.hapticLvl, strength);
  }

  void _showBanner(String s, [double t = 1.6]) {
    _banner = s;
    _bannerT = t;
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    if (!mounted || (_paused && !_jackpot) || _over || _w == 0) return;
    setState(() => _update(dt));
  }

  // ── Génération du parcours ────────────────────────────────────────────────
  void _generate() {
    if (_bossState != 0) return; // pas d'obstacles pendant le boss
    while (_nextX < _cam + _w + 160) {
      final d = (_nextX / _jUnitsPerM / 2500).clamp(0.0, 1.0);
      final r = _gen.nextDouble();
      double len;
      if (_nextX < 1300) {
        len = _patCoins(_nextX);
      } else if (r < 0.28) {
        len = _patCoins(_nextX);
      } else if (r < 0.58) {
        len = _patZap(_nextX);
      } else if (r < 0.74) {
        len = _patZapDuo(_nextX, d);
      } else if (r < 0.86) {
        len = d > 0.12 ? _patZapSpin(_nextX, d) : _patZap(_nextX);
      } else {
        len = _patBugs(_nextX, d);
      }
      _nextX += len + 170 - 80 * d + _gen.nextDouble() * 90;
      // Défi du jour : ni pièces ni pièces chance (le parcours reste identique pour tous)
      if (widget.daily != null) {
        _coinsL.clear();
        _items.removeWhere((it) => it.kind == 4);
      }
      if (_nextX > _nextChance) {
        _items.add(_JItem(_nextX - 40, 80 + _gen.nextDouble() * 190, 4));
        _nextChance += 3800 + _gen.nextDouble() * 3400;
      }
      if (_nextX > _nextItem) {
        final k = _gen.nextDouble();
        final kind = k < 0.3 ? 0 : k < 0.55 ? 1 : k < 0.7 ? 2 : 3;
        _items.add(_JItem(_nextX - 80, 90 + _gen.nextDouble() * 170, kind));
        _nextItem += 2400 + _gen.nextDouble() * 1800;
      }
      if (_nextX > _nextMissile) {
        _missiles.add(_JMissile(_nextX));
        if (d > 0.45 && _gen.nextBool()) _missiles.add(_JMissile(_nextX + 140));
        _nextMissile += 2600 - 1300 * d + _gen.nextDouble() * 1500;
      }
    }
  }

  double _patCoins(double x) {
    final kind = _gen.nextInt(4);
    final cy = 90 + _gen.nextDouble() * 170;
    switch (kind) {
      case 0: // vague
        final n = 12 + _gen.nextInt(8);
        for (int i = 0; i < n; i++) {
          _coinsL.add(_JCoin(x + i * 24, cy + sin(i * 0.55) * 42));
        }
        return n * 24.0;
      case 1: // bloc
        final cols = 6 + _gen.nextInt(4);
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < cols; c++) {
            _coinsL.add(_JCoin(x + c * 22, cy - 22 + r * 22));
          }
        }
        return cols * 22.0;
      case 2: // diagonale
        final n = 10 + _gen.nextInt(6);
        final up = _gen.nextBool();
        for (int i = 0; i < n; i++) {
          _coinsL.add(_JCoin(x + i * 22, (up ? 270 - i * 15.0 : 80 + i * 15.0).clamp(70.0, 290.0)));
        }
        return n * 22.0;
      default: // cœur
        const map = ['.XX.XX.', 'XXXXXXX', 'XXXXXXX', '.XXXXX.', '..XXX..', '...X...'];
        for (int r = 0; r < map.length; r++) {
          for (int c = 0; c < 7; c++) {
            if (map[r][c] == 'X') _coinsL.add(_JCoin(x + c * 22, cy - 55 + r * 22));
          }
        }
        return 7 * 22.0;
    }
  }

  double _patZap(double x) {
    final len = 70 + _gen.nextDouble() * 60;
    const angs = [0.0, pi / 2, pi / 4, -pi / 4];
    final ang = angs[_gen.nextInt(4)];
    final ext = (sin(ang).abs() * len / 2) + 16;
    final y = _jCeil + ext + _gen.nextDouble() * (_jFloor - _jCeil - 2 * ext);
    _zaps.add(_JZap(x + cos(ang).abs() * len / 2, y, len, ang));
    // Quelques pièces pour récompenser le passage au ras
    if (_gen.nextDouble() < 0.5) {
      final cy = y < _jH / 2 ? y + ext + 30 : y - ext - 30;
      for (int i = 0; i < 5; i++) {
        _coinsL.add(_JCoin(x + i * 22, cy.clamp(60.0, 300.0)));
      }
    }
    return cos(ang).abs() * len + 30;
  }

  double _patZapDuo(double x, double d) {
    // Slalom : un laser accroché en haut, l'autre en bas
    final len = 95 + d * 30;
    final topFirst = _gen.nextBool();
    final gap = 200 + d * 80; // plus d'espace quand ça va vite
    final yTop = _jCeil + len / 2 + 6, yBot = _jFloor - len / 2 - 6;
    _zaps.add(_JZap(x + 10, topFirst ? yTop : yBot, len, pi / 2));
    _zaps.add(_JZap(x + 10 + gap, topFirst ? yBot : yTop, len, pi / 2));
    return gap + 30;
  }

  double _patZapSpin(double x, double d) {
    final len = 85 + _gen.nextDouble() * 35;
    final y = (_jCeil + _jFloor) / 2 + (_gen.nextDouble() - 0.5) * 60;
    final spin = (1.1 + d * 1.3) * (_gen.nextBool() ? 1 : -1);
    _zaps.add(_JZap(x + len / 2, y, len, _gen.nextDouble() * pi, spin));
    return len + 20;
  }

  double _patBugs(double x, double d) {
    // Un seul ennemi à la fois, type au hasard (bug, crabe ou calmar)
    _bugs.add(_JBug(x, 70 + _gen.nextDouble() * 220, _gen.nextDouble() * pi * 2, 18 + _gen.nextDouble() * 40,
        _gen.nextInt(3)));
    return 60.0;
  }

  // ── Boucle de jeu ─────────────────────────────────────────────────────────
  void _update(double dt) {
    _time += dt;
    if (_bannerT > 0) _bannerT -= dt;
    if (_shake > 0) _shake = max(0.0, _shake - dt * 2.5);
    if (_flash > 0) _flash = max(0.0, _flash - dt * 2.5);
    _updateFx(dt);
    if (_jackpot) {
      _updateReel(dt);
      return;
    }
    if (_dead) {
      _updateDead(dt);
      return;
    }
    _playTime += dt;
    final m = _dist / _jUnitsPerM;
    final base = 430 + min(m, 2000.0) / 2000 * 440;
    final target = _turbo > 0 ? base * 2.2 : base;
    _speed += (target - _speed) * min(1.0, dt * 4);
    _cam += _speed * dt;
    _dist += _speed * dt;
    if (_inv > 0) _inv -= dt;
    if (_magnet > 0) _magnet -= dt;
    if (_turbo > 0) {
      _turbo -= dt;
      if (_turbo <= 0) _inv = max(_inv, 1.2);
    }
    if (!_recordShown && widget.best > 0 && _meters > widget.best) {
      _recordShown = true;
      _showBanner('NOUVEAU RECORD !');
      QuizAudio.sfx('tier');
      _haptic(2);
    }
    _updateBoss(dt);
    _generate();
    if (_vehicle == 2) _updateDragon(dt);
    _movePlayer(dt);
    // Fantôme du défi du jour (≈ 30 min max)
    if (widget.daily != null && _ghostRec.length < 36000) {
      _ghostT += dt;
      while (_ghostT >= 0.1) {
        _ghostT -= 0.1;
        _ghostRec
          ..add(_dist.round())
          ..add(_py.round());
      }
    }
    _moveThings(dt);
    _collide();
    _cleanup();
  }

  void _movePlayer(double dt) {
    final wasFloor = _onFloor;
    if (_vehicle == 0 && _turbo <= 0) {
      _vy += 2900 * dt;
      _py += _vy * dt;
      if (_py >= _jFloor) {
        if (!wasFloor && _vy > 500) {
          _shake = 0.5;
          _dust(10);
          QuizAudio.sfx('stomp');
          _haptic(1);
        }
        _py = _jFloor;
        _vy = 0;
        _onFloor = true;
      } else {
        _onFloor = false;
      }
      if (_py < _jCeil + 80) {
        _py = _jCeil + 80;
        _vy = max(_vy, 0.0);
      }
      return;
    }
    if (_vehicle == 2 && _turbo <= 0) {
      // Dragon : battements d'ailes, plus lourd que le jetpack
      _vy += (_hold ? -2500.0 : 1500.0) * dt;
      _vy = _vy.clamp(-420.0, 560.0);
      _py += _vy * dt;
      const topD = _jCeil + 62;
      if (_py < topD) {
        _py = topD;
        if (_vy < 0) _vy = 0;
      }
      if (_py >= _jFloor) {
        _py = _jFloor;
        _vy = 0;
        _onFloor = true;
      } else {
        _onFloor = false;
      }
      return;
    }
    if (_vehicle == 1 && _turbo <= 0) {
      _vy += (_gbUp ? -3400.0 : 3400.0) * dt;
      _vy = _vy.clamp(-1100.0, 1100.0);
      _py += _vy * dt;
      const topG = _jCeil + 48;
      if (_py <= topG) {
        _py = topG;
        _vy = 0;
      }
      if (_py >= _jFloor) {
        _py = _jFloor;
        _vy = 0;
      }
      _onFloor = _py >= _jFloor || _py <= topG;
      return;
    }
    // Jetpack
    // Jetpack nerveux : poussée forte, chute rapide, vitesse verticale plafonnée
    _vy += (_hold ? (_vy > 0 ? -3900.0 : -2800.0) : 1900.0) * dt;
    _vy = _vy.clamp(-490.0, 680.0);
    _py += _vy * dt;
    const top = _jCeil + 46;
    if (_py < top) {
      _py = top;
      if (_vy < 0) _vy = 0;
    }
    if (_py >= _jFloor) {
      if (!wasFloor && _vy > 300) _dust(6);
      _py = _jFloor;
      _vy = 0;
      _onFloor = true;
    } else {
      _onFloor = false;
    }
    if (_turbo > 0) {
      _emitFlame(big: true); // turbo : on monte et on descend librement
    } else if (_hold) {
      _emitFlame();
      _shellT -= dt;
      if (_shellT <= 0) {
        _shellT = 0.09;
        // Douilles « rétro » éjectées sous le jetpack
        _fx.add(_JFx(_px - 22, _py - 6, -_speed * 0.15 + (_fxRng.nextDouble() - 0.5) * 60,
            200 + _fxRng.nextDouble() * 80, 0.6, 3, const Color(0xFFFFCA28), grav: 900));
      }
    } else if (_onFloor && _fxRng.nextDouble() < dt * 10) {
      _dust(1);
    }
  }

  // ── Boss ─────────────────────────────────────────────────────────────────
  void _startBoss() {
    _bossState = 1;
    _bossT = 0;
    _bossLevel++;
    _bossShots = 0;
    _bossY = (_jCeil + _jFloor) / 2;
    // Le terrain se dégage devant le joueur
    _zaps.removeWhere((z) => z.x > _px + 60);
    _bugs.removeWhere((b) => b.x > _px + 60);
    _missiles.clear();
    if (_vehicle >= 0) {
      _burst(_hitC, const Color(0xFF90A4AE), 16);
      _vehicle = -1;
      _inv = max(_inv, 1.5);
    }
    _showBanner('⚠ ALERTE BOSS !', 2.4);
    QuizAudio.sfx('alarm');
    _shake = 0.6;
    _haptic(2);
  }

  void _endBoss() {
    _bossState = 0;
    _bossNext = ((_dist / _jUnitsPerM) ~/ 500 + 1) * 500;
    _nextX = max(_nextX, _cam + _w + 250);
  }

  void _updateBoss(double dt) {
    if (_bossState == 0) {
      if (_dist / _jUnitsPerM >= _bossNext) _startBoss();
      return;
    }
    _bossT += dt;
    final c = _hitC;
    switch (_bossState) {
      case 1: // arrivée
        _bossY += (c.dy - _bossY) * min(1.0, dt * 2);
        if (_bossT > 2.0) {
          _bossState = 2;
          _bossT = 0;
          _bossShotT = 2.6;
        }
        break;
      case 2: // combat
        final aim = _missiles.where((m) => m.active && !m.fired);
        final ty = aim.isNotEmpty ? aim.last.y : c.dy;
        _bossY += (ty - 38 - _bossY) * min(1.0, dt * 3); // le canon vise le joueur
        _bossShotT -= dt;
        if (_bossShotT <= 0 && _bossShots < 3) {
          _bossShots++;
          _missiles.add(_JMissile(0)
            ..active = true
            ..y = c.dy
            ..warn = 1.2);
          if (_bossShots == 3) {
            // Dernière attaque : deux missiles à la suite
            _missiles.add(_JMissile(0)
              ..active = true
              ..y = c.dy
              ..warn = 2.0);
          }
          QuizAudio.sfx('alarm');
          _bossShotT = 3.1;
        }
        if (_bossShots >= 3 && _missiles.isEmpty) {
          // Les 3 attaques esquivées : boss vaincu
          _bossState = 3;
          _bossT = 0;
          _coins += 50;
          _stat('bosses');
          if (widget.daily == null) {
            _chances++; // pas de jackpot en défi du jour
            _stat('chances');
          }
          final bp = Offset(_cam + _w - 80, _bossY);
          _burst(bp, const Color(0xFFFF6D00), 40, speed: 420);
          _burst(bp, const Color(0xFFE040FB), 24, speed: 300);
          _shake = 1;
          _showBanner(widget.daily != null ? 'BOSS VAINCU !' : 'BOSS VAINCU ! +50 pièces 🍀', 2.4);
          QuizAudio.sfx('explode');
          QuizAudio.win();
          _haptic(3);
        }
        break;
      default: // vaincu : il tombe en fumant
        _bossY += 160 * dt;
        if (_fxRng.nextDouble() < 0.6) {
          _fx.add(_JFx(_cam + _w - 80 + (_fxRng.nextDouble() - 0.5) * 60, _bossY, -60, -40, 0.8, 8, Colors.white24));
        }
        if (_bossT > 1.8) _endBoss();
    }
  }

  void _emitFlame({bool big = false}) {
    final n = big ? 3 : 1;
    for (int i = 0; i < n; i++) {
      _fx.add(_JFx(
        _px - 24 + (_fxRng.nextDouble() - 0.5) * 5,
        _py - (big ? 21 : 4),
        -_speed * 0.6 - _fxRng.nextDouble() * 80,
        (big ? 0 : 160) + (_fxRng.nextDouble() - 0.5) * 60,
        0.35 + _fxRng.nextDouble() * 0.2,
        big ? 7 : 4.5,
        widget.pack == _jetPackRainbow
            ? HSVColor.fromAHSV(1, (_time * 300 + _fxRng.nextDouble() * 60) % 360, 0.9, 1).toColor()
            : (_fxRng.nextBool() ? _jetPacks[widget.pack].flameB : _jetPacks[widget.pack].flameA),
        glow: true,
      ));
    }
  }

  void _dust(int n) {
    for (int i = 0; i < n; i++) {
      _fx.add(_JFx(_px - 6 + (_fxRng.nextDouble() - 0.5) * 20, _jFloor - 2, -_speed * 0.4 - _fxRng.nextDouble() * 60,
          -30 - _fxRng.nextDouble() * 60, 0.5, 4 + _fxRng.nextDouble() * 3, Colors.white24));
    }
  }

  void _burst(Offset at, Color color, int n, {double speed = 260}) {
    for (int i = 0; i < n; i++) {
      final a = _fxRng.nextDouble() * pi * 2;
      final v = speed * (0.3 + _fxRng.nextDouble() * 0.7);
      _fx.add(_JFx(at.dx, at.dy, cos(a) * v, sin(a) * v, 0.5 + _fxRng.nextDouble() * 0.3, 3 + _fxRng.nextDouble() * 3, color,
          glow: true, grav: 300));
    }
  }

  void _updateFx(double dt) {
    for (final f in _fx) {
      f.life -= dt;
      f.vy += f.grav * dt;
      f.x += f.vx * dt;
      f.y += f.vy * dt;
    }
    _fx.removeWhere((f) => f.life <= 0);
    if (_fx.length > 400) _fx.removeRange(0, _fx.length - 400);
  }

  void _moveThings(double dt) {
    for (final z in _zaps) {
      if (z.spin != 0) z.ang += z.spin * dt;
    }
    for (final b in _bugs) {
      if (b.dead) continue;
      b.x -= 120 * dt;
      b.y = b.y0 + sin(_time * 3 + b.phase) * b.amp;
    }
    final c = _hitC;
    for (final m in _missiles) {
      if (m.done) continue;
      if (!m.active) {
        if (_cam + _w >= m.trig) {
          m.active = true;
          m.y = c.dy;
          QuizAudio.sfx('alarm');
        }
        continue;
      }
      if (!m.fired) {
        m.warn -= dt;
        if (m.warn > 0.5) m.y += (c.dy - m.y) * min(1.0, dt * 3.5);
        if (m.warn <= 0) {
          m.fired = true;
          m.x = _bossState == 2 ? _cam + _w - 160 : _cam + _w + 40;
          QuizAudio.sfx('missile');
        }
      } else {
        m.x -= 700 * dt;
        if (_fxRng.nextDouble() < 0.7) {
          _fx.add(_JFx(m.x + 24, m.y + (_fxRng.nextDouble() - 0.5) * 4, 40, (_fxRng.nextDouble() - 0.5) * 30, 0.45,
              4 + _fxRng.nextDouble() * 3, Colors.white30));
        }
        if (m.x < _cam - 80) m.done = true;
      }
    }
    // Aimant : les pièces proches filent vers le joueur (CD : petit aimant permanent)
    final magR = _magnet > 0 ? 260.0 : (_power == 6 ? 90.0 : 0.0);
    if (magR > 0) {
      for (final k in _coinsL) {
        if (k.taken) continue;
        final p = k.pulled ? Offset(k.px, k.py) : Offset(k.x, k.y);
        if ((p - c).distance < magR) {
          if (!k.pulled) {
            k.pulled = true;
            k.px = k.x;
            k.py = k.y;
          }
          final dv = c - Offset(k.px, k.py);
          final step = min(1.0, dt * 9);
          k.px += dv.dx * step + _speed * dt * 0.2;
          k.py += dv.dy * step;
        }
      }
    }
  }

  static double _segDist(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (l2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / l2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  void _collide() {
    final c = _hitC;
    final r = _hitR;
    // Pièces
    for (final k in _coinsL) {
      if (k.taken) continue;
      final p = k.pulled ? Offset(k.px, k.py) : Offset(k.x, k.y);
      if ((p - c).distance < r + 10) {
        k.taken = true;
        _coins += _power == 7 && _fxRng.nextInt(4) == 0 ? 2 : 1; // Cassette
        if (_coins % 3 == 0) QuizAudio.sfx('coin');
        _fx.add(_JFx(p.dx, p.dy, 0, -40, 0.3, 6, _jGold, glow: true));
      }
    }
    // Bonus
    for (final it in _items) {
      if (it.taken) continue;
      if ((Offset(it.x, it.y) - c).distance < r + 18) {
        it.taken = true;
        _pickup(it.kind, Offset(it.x, it.y));
      }
    }
    final safe = _inv > 0 || _turbo > 0;
    // Bugs (le Mecha les écrase)
    for (final b in _bugs) {
      if (b.dead) continue;
      final bp = Offset(b.x, b.y);
      if ((bp - c).distance < r + 13) {
        if (_vehicle == 0 || _turbo > 0) {
          b.dead = true;
          _stat('bugs');
          _coins += _power == 12 ? 10 : 5; // Manette
          _burst(bp, const Color(0xFF8BC34A), 14);
          QuizAudio.sfx('stomp');
          _haptic(1);
        } else if (!safe) {
          b.dead = true;
          _burst(bp, const Color(0xFF8BC34A), 10);
          _hit(false);
          return;
        }
      }
    }
    if (safe) return;
    for (final z in _zaps) {
      if (_segDist(c, z.a, z.b) < r + 4) {
        _hit(true);
        return;
      }
    }
    for (final m in _missiles) {
      if (!m.fired || m.done) continue;
      if ((Offset(m.x, m.y) - c).distance < r + 9) {
        m.done = true;
        _burst(Offset(m.x, m.y), const Color(0xFFFF6D00), 24, speed: 340);
        _hit(false);
        return;
      }
    }
  }

  void _pickup(int kind, Offset at) {
    if (kind != 4) _stat('items');
    _burst(at, kind == 4 ? const Color(0xFFE040FB) : Colors.white, 12);
    _haptic(1);
    switch (kind) {
      case 4:
        _chances++;
        _stat('chances');
        _showBanner('PIÈCE CHANCE !');
        QuizAudio.sfx('logo');
        break;
      case 0:
        if (_shield) {
          // Déjà protégé : le bouclier part en réserve (1 au maximum)
          _showBanner(_shieldReserve ? 'BOUCLIER' : 'BOUCLIER EN RÉSERVE');
          _shieldReserve = true;
          QuizAudio.sfx('shield');
          break;
        }
        _shield = true;
        _showBanner('BOUCLIER');
        QuizAudio.sfx('shield');
        break;
      case 1:
        _magnet = widget.magnetTime * _bonusMul;
        _showBanner('AIMANT');
        QuizAudio.sfx('powerup');
        break;
      case 2:
        _stat('turbos');
        _turbo = widget.turboTime * _bonusMul * (_power == 11 ? 1.6 : 1.0); // Fusée
        _showBanner('TURBO !');
        QuizAudio.sfx('boost');
        break;
      default:
        if (_vehicle >= 0) {
          _coins += 25;
          if (widget.daily == null) _showBanner('+25 pièces');
          QuizAudio.sfx('coin');
        } else {
          _stat('vehicles');
          _vehicle = _fxRng.nextInt(3); // pas _gen : le parcours du défi doit rester identique
          _gbUp = false;
          _vy = 0;
          _dragonT = 12;
          _showBanner(
              switch (_vehicle) { 0 => 'MECHA MANETTE !', 1 => 'GAME BOY À GRAVITÉ !', _ => 'DRAGON PIXEL !' }, 2);
          QuizAudio.sfx('powerup');
        }
    }
  }

  void _hit(bool zap) {
    if (_inv > 0 || _turbo > 0) return;
    if (_vehicle >= 0) {
      // Le véhicule encaisse le choc et explose
      _burst(_hitC, const Color(0xFFFF6D00), 30, speed: 360);
      _burst(_hitC, const Color(0xFF90A4AE), 16, speed: 260);
      _vehicle = -1;
      _inv = 1.6;
      _vy = -520;
      _onFloor = false;
      _shake = 0.8;
      QuizAudio.sfx('explode');
      _haptic(3);
      return;
    }
    if (_shield) {
      _shield = false;
      _stat('shields');
      _inv = 1.2;
      _burst(_hitC, _jCyan, 20);
      _shake = 0.4;
      QuizAudio.sfx('hurt');
      _haptic(2);
      return;
    }
    _die(zap);
  }

  void _die(bool zap) {
    if (_power == 14 && !_lifeUsed && widget.daily == null) {
      // Fantôme : 2ᵉ chance (hors défi du jour)
      _lifeUsed = true;
      _inv = 2;
      _vy = -420;
      _onFloor = false;
      _burst(_hitC, Colors.white, 24);
      _showBanner('2ᵉ CHANCE !');
      QuizAudio.sfx('continue');
      _haptic(2);
      return;
    }
    _dead = true;
    _hold = false;
    _stat(zap ? 'zaps' : 'booms');
    _flash = zap ? 1 : 0;
    _vy = -380;
    _shake = 1;
    _burst(_hitC, zap ? _jCyan : const Color(0xFFFF6D00), 26, speed: 320);
    QuizAudio.sfx(zap ? 'zap' : 'explode');
    QuizAudio.lose();
    _haptic(3);
  }

  void _updateDead(double dt) {
    // Glissade sur le sol, comme un vrai crash de jetpack
    _speed = max(0.0, _speed - (_onFloor ? 520 : 140) * dt);
    _cam += _speed * dt;
    _dist += _speed * dt;
    _deadRot += dt * (_speed / 60) * (_onFloor ? 0.4 : 1);
    _vy += 1800 * dt;
    _py += _vy * dt;
    if (_py >= _jFloor) {
      _py = _jFloor;
      if (_vy > 120) {
        _vy = -_vy * 0.4;
        _dust(6);
        _haptic(1);
      } else {
        _vy = 0;
      }
      _onFloor = true;
    } else {
      _onFloor = false;
    }
    if (_speed <= 0 && _vy == 0) {
      _deadT += dt;
      if (_deadT > 0.6 && !_saving && !_jackpot) {
        if (_chances > 0) {
          // Pièces chance en poche : tours de jackpot avant le résultat
          _jackpot = true;
          _prize = null;
          _lifeWon = false;
          QuizAudio.sfx('tier');
        } else {
          _endRun();
        }
      }
    }
  }

  void _endRun() {
    _jackpot = false;
    _saving = true;
    _over = true;
    scheduleMicrotask(_finish); // hors du setState de la boucle
  }

  // ── Jackpot ──────────────────────────────────────────────────────────────
  void _spin() {
    if (_spinning || _chances <= 0 || _lifeWon) return;
    final weights = widget.daily != null ? _jetPrizeWeightsDaily : _jetPrizeWeights;
    final total = weights.fold<int>(0, (a, b) => a + b);
    var r = _fxRng.nextInt(total);
    var idx = 0;
    while (r >= weights[idx]) {
      r -= weights[idx];
      idx++;
    }
    final n = _jetPrizes.length;
    final from = _reelPos;
    final cur = from.round() % n;
    setState(() {
      _chances--;
      _stat('spins');
      _spinning = true;
      _prize = null;
      _reelFrom = from;
      _reelTo = from + n * 4 + ((idx - cur) % n + n) % n;
      _reelT = 0;
      _lastReelTick = from.floor();
    });
    _haptic(0);
  }

  void _updateReel(double dt) {
    if (!_spinning) return;
    _reelT += dt;
    const dur = 2.2;
    final k = Curves.easeOutCubic.transform((_reelT / dur).clamp(0.0, 1.0));
    _reelPos = _reelFrom + (_reelTo - _reelFrom) * k;
    if (_reelPos.floor() != _lastReelTick) {
      _lastReelTick = _reelPos.floor();
      QuizAudio.sfx('jump');
    }
    if (_reelT >= dur) {
      _reelPos = _reelTo;
      _spinning = false;
      final idx = _reelTo.round() % _jetPrizes.length;
      final pz = _jetPrizes[idx];
      _prize = idx;
      if (pz.life || pz.meters > 0 || pz.coins > 0) _stat('jackpots');
      if (pz.life) {
        _lifeWon = true;
        _stat('lives');
        QuizAudio.win();
        _haptic(3);
      } else if (pz.meters > 0 || pz.coins > 0) {
        _bonusM += pz.meters;
        _coins += pz.coins;
        QuizAudio.sfx(pz.coins > 0 ? 'coin' : 'powerup');
        _haptic(2);
      } else {
        QuizAudio.sfx('hurt');
      }
    }
  }

  /// Vie supplémentaire : la partie reprend tout de suite, obstacles proches retirés.
  void _revive() {
    setState(() {
      _jackpot = false;
      _lifeWon = false;
      _prize = null;
      _dead = false;
      _deadT = 0;
      _deadRot = 0;
      _flash = 0;
      _speed = 430 + min(_dist / _jUnitsPerM, 2000.0) / 2000 * 440;
      _py = (_jCeil + _jFloor) / 2;
      _vy = -250;
      _onFloor = false;
      _inv = 2.5;
      _zaps.removeWhere((z) => z.x < _cam + _w + 60);
      _bugs.removeWhere((b) => b.x < _cam + _w + 60);
      _missiles.removeWhere((m) => m.active);
      if (_bossState != 0) _endBoss();
      _showBanner('VIE SUPPLÉMENTAIRE !', 2);
    });
    QuizAudio.sfx('continue');
    _haptic(2);
  }

  Widget _jackpotView() {
    const itemH = 62.0;
    final n = _jetPrizes.length;
    final base = _reelPos.floor();
    final frac = _reelPos - base;
    final pz = _prize == null ? null : _jetPrizes[_prize!];
    Widget cell(int i) {
      final p = _jetPrizes[((i % n) + n) % n];
      return SizedBox(
        height: itemH,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (p.icon != null) Icon(p.icon, color: p.color, size: 30) else const _CoinIcon(size: 26),
          const SizedBox(width: 8),
          Text(p.label, style: TextStyle(color: p.color, fontSize: 26, fontWeight: FontWeight.w900)),
        ]),
      );
    }

    return _panel(width: 400, children: [
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.casino_rounded, color: Color(0xFFE040FB), size: 26),
        SizedBox(width: 8),
        Text('JACKPOT', style: TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < min(_chances, 8); i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFAB47BC)),
          ),
        const SizedBox(width: 6),
        Text(_chances > 1 ? '$_chances pièces chance' : _chances == 1 ? '1 pièce chance' : 'Plus de pièce chance',
            style: const TextStyle(color: Colors.white60, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 10),
      // Rouleau
      Container(
        width: 250,
        height: itemH * 3,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD740), width: 3),
          boxShadow: [BoxShadow(color: const Color(0xFFE040FB).withOpacity(0.35), blurRadius: 18)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: -frac * itemH,
              child: Column(children: [for (int k = -1; k <= 3; k++) cell(base + k)]),
            ),
            // Bande centrale + voiles haut / bas
            Positioned(
              left: 0,
              right: 0,
              top: itemH,
              height: itemH,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.symmetric(horizontal: BorderSide(color: Colors.amberAccent.withOpacity(0.7), width: 2)),
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.75), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.75)],
                      stops: const [0, 0.3, 0.7, 1],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 22,
        child: pz == null
            ? null
            : Text(
                pz.life
                    ? 'VIE SUPPLÉMENTAIRE !'
                    : pz.meters > 0
                        ? '+${pz.meters} m ajoutés à ta distance !'
                        : pz.coins > 0
                            ? '+${pz.coins} pièces !'
                            : 'Rien cette fois…',
                style: TextStyle(color: pz.color, fontSize: 16, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(height: 10),
      if (_lifeWon)
        _JetButton(
          label: 'REPRENDRE',
          icon: Icons.favorite_rounded,
          colors: const [Color(0xFFFF5252), Color(0xFFB71C1C)],
          onTap: _revive,
        )
      else if (_chances > 0 || _spinning)
        _JetButton(
          label: _spinning ? '…' : 'TOURNER',
          icon: Icons.casino_rounded,
          colors: const [Color(0xFFE040FB), Color(0xFF6A1B9A)],
          onTap: _spinning ? () {} : _spin,
        )
      else
        _JetButton(
          label: 'CONTINUER',
          icon: Icons.arrow_forward_rounded,
          colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
          onTap: () => setState(_endRun),
        ),
    ]);
  }

  Future<void> _finish() async {
    final res = await widget.onFinish(
        _meters, widget.daily != null ? 0 : _coins, _playTime.round(), Map.of(_st), widget.daily != null ? _ghostEncode() : '');
    if (!mounted) return;
    setState(() {
      _record = res.$1;
      _rank = res.$2;
      _note = res.$3;
      _rewards = res.$4;
      _saving = false;
    });
    if (_record) QuizAudio.win();
  }

  void _cleanup() {
    final left = _cam - 120;
    _zaps.removeWhere((z) => z.x + z.len < left);
    _bugs.removeWhere((b) => b.x < left || (b.dead && b.x < _cam + _w));
    _coinsL.removeWhere((k) => (k.pulled ? k.px : k.x) < left || k.taken);
    _items.removeWhere((i) => i.x < left || i.taken);
    _missiles.removeWhere((m) => m.done);
  }

  // ── Commandes ─────────────────────────────────────────────────────────────
  void _down() {
    if (_paused || _dead) return;
    _hold = true;
    if (_vehicle == 0 && _onFloor) {
      _vy = -930;
      _onFloor = false;
      QuizAudio.sfx('jump');
      _haptic(0);
    } else if (_vehicle == 1) {
      _gbUp = !_gbUp;
      QuizAudio.sfx('spring');
      _haptic(0);
    }
  }

  void _up() => _hold = false;

  /// Active le bouclier en réserve (si on n'est pas déjà protégé).
  void _useReserve() {
    if (!_shieldReserve || _shield || _dead || _paused) return;
    setState(() {
      _shield = true;
      _shieldReserve = false;
    });
    _burst(_hitC, _jCyan, 16);
    QuizAudio.sfx('shield');
    _haptic(2);
  }

  // ── Affichage ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_over) {
          widget.onMenu();
        } else if (!_dead) {
          _setPaused(!_paused);
        }
      },
      child: LayoutBuilder(builder: (_, cons) {
        if (cons.maxHeight > 0 && cons.maxWidth > 0) {
          _scale = cons.maxHeight / _jH;
          _w = cons.maxWidth / _scale;
        }
        final pad = MediaQuery.of(context).padding;
        return Stack(children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _down(),
              onPointerUp: (_) => _up(),
              onPointerCancel: (_) => _up(),
              child: CustomPaint(painter: _JetPainter(this)),
            ),
          ),
          // HUD
          Positioned(
            left: 14 + pad.left,
            top: 8,
            child: IgnorePointer(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_fmtNum(_meters)} m',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1,
                        shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
                Text(
                    widget.daily != null
                        ? 'Défi du jour · meilleur ${_fmtNum(widget.best)} m'
                        : 'Record ${_fmtNum(max(widget.best, _meters))} m',
                    style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          if (widget.daily == null)
            Positioned(
              right: 64 + pad.right,
              top: 10,
              child: IgnorePointer(child: _JetCoins(coins: _coins)),
            ),
          Positioned(
            right: 12 + pad.right,
            top: 6,
            child: IconButton(
              onPressed: _dead ? null : () => _setPaused(true),
              icon: const Icon(Icons.pause_circle_rounded, color: Colors.white70, size: 34),
            ),
          ),
          // Bonus actifs
          Positioned(
            left: 14 + pad.left,
            bottom: 10,
            child: IgnorePointer(
              child: Row(children: [
                if (_shield) _chip(Icons.shield_rounded, _jCyan, null),
                if (_magnet > 0) _chip(Icons.bolt_rounded, const Color(0xFFFF5252), _magnet),
                if (_turbo > 0) _chip(Icons.rocket_launch_rounded, const Color(0xFFFF9100), _turbo),
                if (_vehicle >= 0) _chip(Icons.sports_esports_rounded, _jGold, null),
                if (_chances > 0) _chip(Icons.casino_rounded, const Color(0xFFE040FB), null, count: _chances),
                if (_bossState == 2) _chip(Icons.warning_amber_rounded, const Color(0xFFFF1744), null, count: 3 - _bossShots),
              ]),
            ),
          ),
          // Bouclier en réserve : bulle à toucher (grisée tant qu'un bouclier est actif)
          if (_shieldReserve && !_dead)
            Positioned(
              right: 18 + pad.right,
              bottom: 14,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _useReserve(),
                child: Opacity(
                  opacity: _shield ? 0.45 : 1,
                  child: Transform.scale(
                    scale: _shield ? 1.0 : 1.0 + 0.07 * sin(_time * 6),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [_jCyan.withOpacity(0.55), const Color(0xFF006064).withOpacity(0.85)]),
                        border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                        boxShadow: [BoxShadow(color: _jCyan.withOpacity(_shield ? 0.2 : 0.6), blurRadius: 16)],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          if (_bannerT > 0 && _banner != null)
            Positioned(
              top: 54,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: _bannerT.clamp(0.0, 1.0),
                    child: Text(_banner!,
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 26, fontWeight: FontWeight.w900,
                            letterSpacing: 2, shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
                  ),
                ),
              ),
            ),
          if (_paused && !_over) Positioned.fill(child: _pauseView()),
          if (_jackpot) Positioned.fill(child: _jackpotView()),
          if (_over) Positioned.fill(child: _resultView()),
        ]);
      }),
    );
  }

  Widget _chip(IconData icon, Color color, double? left, {int? count}) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.7)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          if (left != null) ...[
            const SizedBox(width: 4),
            Text('${left.ceil()} s', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
          if (count != null) ...[
            const SizedBox(width: 4),
            Text('×$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ]),
      );

  Widget _panel({required List<Widget> children, double width = 380}) => Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            decoration: BoxDecoration(
              color: _uiStyle.dialog,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      );

  Widget _pauseView() => _panel(width: 320, children: [
        const Text('PAUSE', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 14),
        _JetButton(
          label: 'REPRENDRE',
          icon: Icons.play_arrow_rounded,
          colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
          onTap: () => _setPaused(false),
        ),
        const SizedBox(height: 8),
        _JetButton(
          label: 'QUITTER',
          icon: Icons.close_rounded,
          colors: const [Color(0xFF546E7A), Color(0xFF37474F)],
          onTap: widget.onMenu,
        ),
      ]);

  Widget _resultView() {
    final r = _rank;
    return _panel(children: [
      Text(_record ? 'NOUVEAU RECORD !' : 'CRASH !',
          style: TextStyle(
              color: _record ? Colors.amberAccent : Colors.white70, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
      const SizedBox(height: 4),
      Text('${_fmtNum(_meters)} m',
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1)),
      if (_bonusM > 0)
        Text('dont +${_fmtNum(_bonusM)} m de jackpot',
            style: const TextStyle(color: Color(0xFFE040FB), fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      if (widget.daily == null)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _CoinIcon(size: 18),
          const SizedBox(width: 6),
          Text('+${_fmtNum(_coins)} pièces',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      const SizedBox(height: 8),
      if (_saving)
        const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54))
      else if (r != null && r.rank != null)
        Text('${widget.daily != null ? 'Défi du jour' : 'Classement'} : ${r.rank}ᵉ sur ${r.total}',
            style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 14, fontWeight: FontWeight.w800))
      else if (_note != null)
        Text(_note!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
      // Défis réussis, série terminée, trophées débloqués
      if (_rewards.isNotEmpty) ...[
        const SizedBox(height: 10),
        for (final (icon, label, reward) in _rewards.take(4))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Icon(icon, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
              const _CoinIcon(size: 11),
              const SizedBox(width: 4),
              Text('+$reward', style: const TextStyle(color: Colors.amberAccent, fontSize: 12.5, fontWeight: FontWeight.w800)),
            ]),
          ),
        if (_rewards.length > 4)
          Text('+ ${_rewards.length - 4} autres récompenses',
              style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _JetButton(
            label: 'MENU',
            icon: Icons.home_rounded,
            colors: const [Color(0xFF546E7A), Color(0xFF37474F)],
            onTap: _saving ? () {} : widget.onMenu,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _JetButton(
            label: 'REJOUER',
            icon: Icons.replay_rounded,
            colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
            onTap: _saving ? () {} : widget.onRetry,
          ),
        ),
      ]),
    ]);
  }
}

class _JetPainter extends CustomPainter {
  final _JetGameState g;
  _JetPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    if (g._scale <= 0 || g._w <= 0 || !g._w.isFinite) return;
    final s = g._scale;
    canvas.save();
    if (g._shake > 0) {
      final r = g._fxRng;
      canvas.translate((r.nextDouble() - 0.5) * 10 * g._shake, (r.nextDouble() - 0.5) * 10 * g._shake);
    }
    canvas.scale(s, s);
    final w = g._w;
    final cam = g._cam;
    _jetDrawLab(canvas, w, cam, g._time, g.widget.theme);
    canvas.save();
    canvas.translate(-cam, 0);

    // Repères des autres joueurs (trait + pseudo)
    final mk = g.widget.markers;
    for (int i = 0; i < mk.length; i++) {
      final mx = mk[i].$2 * _jUnitsPerM + g._w * 0.24;
      if (mx < cam - 20 || mx > cam + w + 60) continue;
      final p = Paint()
        ..color = const Color(0xFF80D8FF).withOpacity(0.55)
        ..strokeWidth = 1.6;
      for (double y = _jCeil + 34; y < _jFloor; y += 14) {
        canvas.drawLine(Offset(mx, y), Offset(mx, y + 6), p);
      }
      final ly = _jCeil + 14 + (i % 2) * 14.0;
      _jText(canvas, mk[i].$1, Offset(mx, ly), 10, const Color(0xFF80D8FF), weight: FontWeight.w800);
    }
    // Repère du record
    final best = g.widget.best;
    if (best > 0) {
      final bx = best * _jUnitsPerM + g._w * 0.24;
      if (bx > cam - 20 && bx < cam + w + 20) {
        final p = Paint()
          ..color = Colors.amberAccent.withOpacity(0.7)
          ..strokeWidth = 2;
        for (double y = _jCeil; y < _jFloor; y += 16) {
          canvas.drawLine(Offset(bx, y), Offset(bx, y + 8), p);
        }
        _jText(canvas, 'RECORD', Offset(bx, _jCeil + 14), 11, Colors.amberAccent);
      }
    }
    // Pièces
    for (final k in g._coinsL) {
      if (k.taken) continue;
      final p = k.pulled ? Offset(k.px, k.py) : Offset(k.x, k.y);
      if (p.dx < cam - 20 || p.dx > cam + w + 20) continue;
      _jetDrawCoin(canvas, p, g._time);
    }
    for (final it in g._items) {
      if (it.taken || it.x > cam + w + 40) continue;
      final ip = Offset(it.x, it.y + sin(g._time * 3 + it.x) * 6);
      if (it.kind == 4) {
        _jetDrawChance(canvas, ip, g._time);
      } else {
        _jetDrawItem(canvas, ip, it.kind, g._time);
      }
    }
    if (g._bossState != 0) {
      final slide = g._bossState == 1 ? (1 - min(1.0, g._bossT / 1.5)) * 220 : 0.0;
      final charging = g._missiles.any((m) => m.active && !m.fired);
      _jetDrawBoss(canvas, Offset(cam + w - 80 + slide, g._bossY), g._time, charging, g._bossState == 3 ? 1.0 : 0.0);
    }
    for (int i = 0; i < g._zaps.length; i++) {
      final z = g._zaps[i];
      if (z.x - z.len > cam + w + 40) continue;
      _jetDrawZap(canvas, z.a, z.b, g._time, z.x.floor());
    }
    for (final b in g._bugs) {
      if (b.dead || b.x > cam + w + 40) continue;
      _jetDrawBug(canvas, Offset(b.x, b.y), g._time + b.phase, b.type);
    }
    for (final m in g._missiles) {
      if (m.fired && !m.done) _jetDrawMissile(canvas, Offset(m.x, m.y), g._time);
    }
    // Particules (traînées, étincelles)
    for (final f in g._fx) {
      final a = (f.life / f.ttl).clamp(0.0, 1.0);
      final p = Paint()..color = f.color.withOpacity(f.color.opacity * a);
      if (f.glow) p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(f.x, f.y), f.size * (0.4 + 0.6 * a), p);
    }
    // Fantôme du meilleur joueur du jour (transparent, pseudo au-dessus)
    final gp = g._ghostPos;
    final gh = g.widget.ghost;
    if (gp != null && gh != null && gp.dx > cam - 40 && gp.dx < cam + w + 40) {
      canvas.saveLayer(null, Paint()..color = Colors.white.withOpacity(0.38));
      _jetDrawPlayer(canvas, gp, _heroSafe(gh.hero), g._time, thrust: gp.dy < _jFloor - 1, scale: 1.05);
      canvas.restore();
      _jText(canvas, '👻 ${gh.name}', gp + const Offset(0, -62), 11, Colors.white70);
    }
    // Joueur
    final feet = Offset(g._px, g._py);
    final blink = g._inv > 0 && !g._dead && ((g._time * 12).floor() % 2 == 0);
    if (!blink) {
      if (g._vehicle == 0) {
        _jetDrawMecha(canvas, feet, g.widget.hero, g._time, g._onFloor);
      } else if (g._vehicle == 1) {
        _jetDrawGameBoy(canvas, feet, g.widget.hero, g._time, g._gbUp);
      } else if (g._vehicle == 2) {
        _jetDrawDragon(canvas, feet, g.widget.hero, g._time, g._dragonT);
      } else {
        _jetDrawPlayer(canvas, feet, g.widget.hero, g._time,
            thrust: (g._hold && !g._dead) || g._turbo > 0,
            onFloor: g._onFloor && !g._dead,
            rot: g._dead ? g._deadRot : (g._onFloor ? 0 : (g._vy / 680) * 0.2),
            flash: g._flash,
            scale: 1.05,
            pack: g.widget.pack);
      }
    }
    final c = g._hitC;
    if (g._shield && !g._dead) {
      final r = g._hitR + 12 + sin(g._time * 6) * 1.5;
      canvas.drawCircle(c, r, Paint()..color = _jCyan.withOpacity(0.12));
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = _jCyan.withOpacity(0.8));
    }
    if (g._magnet > 0 && !g._dead) {
      final ph = (g._time * 1.5) % 1;
      canvas.drawCircle(c, 30 + ph * 60, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFF5252).withOpacity(0.5 * (1 - ph)));
    }
    canvas.restore();

    // Turbo : lignes de vitesse
    if (g._turbo > 0) {
      final r = Random((g._time * 30).floor());
      final p = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 2;
      for (int i = 0; i < 14; i++) {
        final y = _jCeil + r.nextDouble() * (_jFloor - _jCeil);
        final x = r.nextDouble() * w;
        canvas.drawLine(Offset(x, y), Offset(x + 60 + r.nextDouble() * 80, y), p);
      }
    }
    // Alertes missiles (bord droit)
    for (final m in g._missiles) {
      if (!m.active || m.fired) continue;
      final locked = m.warn <= 0.5;
      final on = ((g._time * (locked ? 16 : 7)).floor() % 2) == 0;
      if (g._bossState == 2) {
        // Visée laser du boss
        final sight = Paint()
          ..color = const Color(0xFFFF1744).withOpacity(locked ? (on ? 0.9 : 0.4) : 0.35)
          ..strokeWidth = locked ? 2.5 : 1.5;
        for (double x = 0; x < w - 160; x += 18) {
          canvas.drawLine(Offset(x, m.y), Offset(x + 10, m.y), sight);
        }
        continue;
      }
      final p = Offset(w - 30, m.y);
      canvas.drawCircle(p, 17, Paint()..color = const Color(0xFFFF1744).withOpacity(on ? 0.35 : 0.15));
      canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - 13)
            ..lineTo(p.dx + 12, p.dy + 9)
            ..lineTo(p.dx - 12, p.dy + 9)
            ..close(),
          Paint()..color = on || locked ? const Color(0xFFFF1744) : const Color(0xFFFF8A80));
      _jText(canvas, '!', p.translate(0, 2), 13, Colors.white);
    }
    canvas.restore();
    // Éclair de l'électrocution
    if (g._flash > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = _jCyan.withOpacity(0.25 * g._flash));
    }
  }

  @override
  bool shouldRepaint(covariant _JetPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Carte de choix du jeu (au lancement, et via le bouton « Jeux » de l'accueil)
// ═══════════════════════════════════════════════════════════════════════════

class _GameChooser extends StatefulWidget {
  final int hero;
  final int coins, jetCoins; // porte-monnaie de chaque jeu
  final int jumpBest, jetBest;
  final bool canClose;
  final VoidCallback onJump, onJet, onClose;
  const _GameChooser({
    required this.hero,
    required this.coins,
    required this.jetCoins,
    required this.jumpBest,
    required this.jetBest,
    required this.canClose,
    required this.onJump,
    required this.onJet,
    required this.onClose,
  });

  @override
  State<_GameChooser> createState() => _GameChooserState();
}

class _GameChooserState extends State<_GameChooser> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.canClose,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1030), Color(0xFF1A1145), Color(0xFF0D0F14)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = _c.value * 20;
            return CustomPaint(
              painter: _SplashSkyPainter((t * 1000).round()),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(children: [
                    Row(children: [
                      if (widget.canClose)
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                    ]),
                    const SizedBox(height: 6),
                    const Text('CHOISIS TON JEU',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    const SizedBox(height: 4),
                    const Text('RÉTRO GAME · by foclabroc',
                        style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _card(
                        title: 'RÉTRO JUMP',
                        sub: 'Grimpe le plus haut possible',
                        best: 'Record ${_fmtNum(widget.jumpBest)} pts  ·  ${_fmtNum(widget.coins)} pièces',
                        colors: const [Color(0xFFFF5252), Color(0xFFFF4081)],
                        painter: _ChooserJumpPainter(t, widget.hero),
                        onTap: widget.onJump,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _card(
                        title: 'RÉTRO JET',
                        sub: 'Vole le plus loin possible',
                        best: widget.jetBest > 0
                            ? 'Record ${_fmtNum(widget.jetBest)} m  ·  ${_fmtNum(widget.jetCoins)} pièces'
                            : 'Nouveau jeu !',
                        colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
                        painter: _ChooserJetPainter(t, widget.hero),
                        onTap: widget.onJet,
                        isNew: widget.jetBest == 0,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String sub,
    required String best,
    required List<Color> colors,
    required CustomPainter painter,
    required VoidCallback onTap,
    bool isNew = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: painter)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
            ),
            if (isNew)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFF1744), borderRadius: BorderRadius.circular(10)),
                  child: const Text('NOUVEAU',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2,
                              shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
                    ),
                    Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(best, style: const TextStyle(color: Colors.amberAccent, fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('JOUER', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    SizedBox(width: 2),
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Aperçu Rétro Jump : plateformes, bugs et héros qui rebondit.
class _ChooserJumpPainter extends CustomPainter {
  final double t;
  final int hero;
  _ChooserJumpPainter(this.t, this.hero);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h),
          const [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF880E4F)], const [0, 0.6, 1]));
    final r = Random(5);
    for (int i = 0; i < 40; i++) {
      final a = 0.3 + 0.5 * (0.5 + 0.5 * sin(t * 2 + i));
      canvas.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * h * 0.7), 0.6 + r.nextDouble() * 1.2,
          Paint()..color = Colors.white.withOpacity(a));
    }
    // Plateformes qui descendent doucement (on grimpe)
    final scroll = (t * 26) % 70;
    for (int i = -1; i < (h / 70).ceil() + 1; i++) {
      final y = i * 70.0 + scroll;
      final k = _hash(i - (t * 26 / 70).floor(), 3);
      final x = 20 + k * (w - 120);
      final col = k < 0.2 ? const Color(0xFF29B6F6) : k < 0.35 ? const Color(0xFFFFA726) : const Color(0xFF66BB6A);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 84, 12), const Radius.circular(6)), Paint()..color = col);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 4, y + 2, 76, 3), const Radius.circular(2)),
          Paint()..color = Colors.white.withOpacity(0.35));
    }
    // Héros qui rebondit
    final s = h / 190;
    final hop = sin(t * 3).abs();
    canvas.save();
    canvas.translate(w * 0.5, h * 0.62 - hop * 46 * s);
    canvas.scale(1.4 * s, 1.4 * s);
    _drawHero(canvas, hero, true, t);
    canvas.restore();
    _jetDrawBug(canvas, Offset(w * 0.82, h * 0.3 + sin(t * 2) * 8), t);
    _jetDrawCoin(canvas, Offset(w * 0.2, h * 0.28), t);
    _jetDrawCoin(canvas, Offset(w * 0.27, h * 0.22), t + 0.3);
  }

  @override
  bool shouldRepaint(covariant _ChooserJumpPainter old) => old.t != t || old.hero != hero;
}

/// Aperçu Rétro Jet : labo, laser, pièces et héros au jetpack.
class _ChooserJetPainter extends CustomPainter {
  final double t;
  final int hero;
  _ChooserJetPainter(this.t, this.hero);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;
    final s = size.height / _jH;
    final w = size.width / s;
    canvas.save();
    canvas.scale(s, s);
    final cam = t * 160;
    _jetDrawLab(canvas, w, cam, t);
    final zx = w + 120 - ((t * 160) % (w + 300));
    _jetDrawZap(canvas, Offset(zx - 50, 110), Offset(zx + 50, 200), t, 3);
    for (int i = 0; i < 12; i++) {
      final x = (w + 40) - ((t * 160 + i * 26) % (w + 80));
      _jetDrawCoin(canvas, Offset(x, 240 + sin(i * 0.55) * 30), t);
    }
    _jetDrawPlayer(canvas, Offset(w * 0.28, 170 + sin(t * 2.2) * 22), hero, t, thrust: true, scale: 1.4);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChooserJetPainter old) => old.t != t || old.hero != hero;
}
