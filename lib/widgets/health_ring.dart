import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme.dart';

/// Widget affichant un anneau circulaire animé pour représenter le score de santé
class HealthRing extends StatefulWidget {
  final double percent; // Pourcentage à afficher (0 à 100)
  final double size; // Diamètre du widget
  final double strokeWidth; // Épaisseur de l'anneau
  final bool showLabel; // Affiche ou masque le texte à l'intérieur de l'anneau

  const HealthRing({
    super.key,
    required this.percent,
    this.size = 100,
    this.strokeWidth = 8,
    this.showLabel = true,
  });

  @override
  State<HealthRing> createState() => _HealthRingState();
}

class _HealthRingState extends State<HealthRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Contrôleur pour gérer la durée de l'animation
  late Animation<double> _animation; // Valeur interpolée de l'animation

  @override
  void initState() {
    super.initState();
    // Initialisation du contrôleur avec une durée de 1.2 secondes
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    // Définition de l'animation de 0 jusqu'au pourcentage cible (transformé en valeur de 0 à 1)
    // avec une courbe "easeOutCubic" pour un effet décélérant fluide
    _animation = Tween<double>(begin: 0, end: widget.percent / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    // Démarrage immédiat de l'animation
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la valeur du pourcentage a changé (ex: mise à jour des données de capteur)
    // on relance l'animation depuis la valeur actuelle vers la nouvelle valeur
    if (oldWidget.percent != widget.percent) {
      _animation = Tween<double>(begin: _animation.value, end: widget.percent / 100)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Récupération de la couleur dynamique (vert, bleu, rouge...) selon le score
    final color = AppTheme.healthColor(widget.percent);
    
    // Le widget est reconstruit à chaque 'tick' de l'animation
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              color: color,
              strokeWidth: widget.strokeWidth,
            ),
            child: widget.showLabel
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(widget.percent * _animation.value / (widget.percent / 100)).toInt()}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: widget.size * 0.22,
                          ),
                        ),
                        if (widget.size > 80) ...[
                          Text(
                            'Santé',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: widget.size * 0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Dessinateur personnalisé (CustomPainter) pour tracer physiquement l'anneau
class _RingPainter extends CustomPainter {
  final double progress; // Avancement visuel de 0.0 à 1.0
  final Color color; // Couleur de progression
  final double strokeWidth; // Épaisseur du trait

  _RingPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    // Calcul du point central et du rayon
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Tracé de l'anneau de fond (background ring) partiellement transparent
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Définition d'un dégradé angulaire (SweepGradient) pour un effet stylisé sur l'arc
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [color.withValues(alpha: 0.5), color, color, color.withValues(alpha: 0.5)],
      stops: const [0.0, 0.4, 0.8, 1.0],
      transform: GradientRotation(-math.pi / 2),
    );

    // Tracé de l'arc de progression qui se remplit selon 'progress'
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
