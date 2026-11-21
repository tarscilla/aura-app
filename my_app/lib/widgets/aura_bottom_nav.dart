import "package:flutter/material.dart";
import "../theme/app_colors.dart";

class AuraBottomNav extends StatelessWidget {
  final int indice;
  final ValueChanged<int> aoSelecionar;

  const AuraBottomNav({
    super.key,
    required this.indice,
    required this.aoSelecionar,
  });

  static const _icones = <IconData>[
    Icons.home_rounded,
    Icons.face_retouching_natural,
    Icons.calendar_month_rounded,
    Icons.local_florist_rounded,
    Icons.insights_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF6F6),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icones.length, (i) {
              final selecionado = i == indice;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => aoSelecionar(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selecionado ? const Color(0xFFFFD6D6) : null,
                    border: selecionado
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: Icon(
                    _icones[i],
                    size: 32,
                    color: selecionado
                        ? AppColors.primaryDark
                        : const Color(0xFF8E8E8E),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
