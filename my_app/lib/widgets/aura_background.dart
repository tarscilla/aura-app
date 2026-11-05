import "package:flutter/material.dart";
import "../theme/app_colors.dart";

class AuraBackground extends StatelessWidget {
  final Widget child;

  const AuraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand, 
        children: [
          const Positioned(
            top: -150,
            left: -210, 
            child: _Petala(angle: 0.6),
          ),
          const Positioned(
            bottom: -110,
            right: -120,
            child: _Petala(angle: -2.5),
          ),
          child,
        ],
      ),
    );
  }
}

class _Petala extends StatelessWidget {
  final double angle;

  const _Petala({required this.angle});

  @override 
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.15,
      child: Transform.rotate(
        angle: angle,
        child: Image.asset("assets/images/aura-logo.png", width: 320),
      ),
    );
  }
}