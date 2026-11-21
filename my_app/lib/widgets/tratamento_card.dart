import 'package:flutter/material.dart';
import '../models/tratamento.dart';

class TratamentoCard extends StatelessWidget {
  final Tratamento tratamento;
  final VoidCallback onToggle;

  const TratamentoCard({
    super.key,
    required this.tratamento,
    required this.onToggle,
  });

  Color get corCategoria {
    switch (tratamento.categoria.toLowerCase()) {
      case 'hidratação':
        return const Color(0xFF91B9D8);
      case 'nutrição':
        return const Color(0xFFE5B477);
      case 'reconstrução':
        return const Color(0xFFB59ACF);
      default:
        return const Color(0xFFE9A0B5);
    }
  }

  IconData get iconeCategoria {
    switch (tratamento.categoria.toLowerCase()) {
      case 'hidratação':
        return Icons.water_drop_outlined;
      case 'nutrição':
        return Icons.spa_outlined;
      case 'reconstrução':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.favorite_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: corCategoria.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: corCategoria.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              iconeCategoria,
              color: corCategoria,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tratamento.nome,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tratamento.concluido
                        ? Colors.grey
                        : const Color(0xFF59434B),
                    decoration: tratamento.concluido
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  tratamento.descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF99878D),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFFB49BA3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tratamento.horario,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF99878D),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          IconButton(
            onPressed: onToggle,
            icon: Icon(
              tratamento.concluido
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: tratamento.concluido
                  ? const Color(0xFF91B99A)
                  : corCategoria,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}