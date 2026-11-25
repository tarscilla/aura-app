import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/cronograma_viewmodel.dart';

class CalendarioWidget extends StatelessWidget {
  final CronogramaViewModel viewModel;

  const CalendarioWidget({
    super.key,
    required this.viewModel,
  });

  static const Color rosa = Color(0xFFE9A0B5);
  static const Color rosaClaro = Color(0xFFFCEEF2);
  static const Color texto = Color(0xFF59434B);

  Color _corCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'hidratação':
        return const Color(0xFF91B9D8);
      case 'nutrição':
        return const Color(0xFFE5B477);
      case 'reconstrução':
        return const Color(0xFFB59ACF);
      default:
        return rosa;
    }
  }

  List<Color> _coresDoDia(DateTime dia) {
    final tratamentos = viewModel.tratamentos.where((tratamento) {
      return isSameDay(tratamento.data, dia);
    });

    return tratamentos
        .map((tratamento) => _corCategoria(tratamento.categoria))
        .toSet()
        .toList();
  }

  Widget _construirDia(
    DateTime dia, {
    bool selecionado = false,
    bool hoje = false,
  }) {
    final cores = _coresDoDia(dia);

    return Center(
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selecionado || hoje)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selecionado ? rosa : rosaClaro,
                  shape: BoxShape.circle,
                ),
              ),

            if (cores.isNotEmpty)
              CustomPaint(
                size: const Size(40, 40),
                painter: CirculoEtapasPainter(cores: cores),
              ),

            Text(
              '${dia.day}',
              style: TextStyle(
                color: selecionado
                    ? Colors.white
                    : hoje
                        ? rosa
                        : texto,
                fontWeight:
                    selecionado || hoje ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: rosa.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: viewModel.mesAtual,
        currentDay: DateTime.now(),

        selectedDayPredicate: (day) {
          return isSameDay(day, viewModel.dataSelecionada);
        },

        onDaySelected: (selectedDay, focusedDay) {
          viewModel.selecionarData(selectedDay);
        },

        onPageChanged: (focusedDay) {
          viewModel.selecionarData(viewModel.dataSelecionada);
          viewModel.mudarMes(
            (focusedDay.year - viewModel.mesAtual.year) * 12 +
                focusedDay.month -
                viewModel.mesAtual.month,
          );
        },

        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: rosa,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: rosa,
          ),
          titleTextStyle: TextStyle(
            color: texto,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: texto,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: rosa,
            fontSize: 12,
          ),
        ),

        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _construirDia(day);
          },

          todayBuilder: (context, day, focusedDay) {
            return _construirDia(day, hoje: true);
          },

          selectedBuilder: (context, day, focusedDay) {
            return _construirDia(day, selecionado: true);
          },
        ),
      ),
    );
  }
}

class CirculoEtapasPainter extends CustomPainter {
  final List<Color> cores;

  CirculoEtapasPainter({required this.cores});

  @override
  void paint(Canvas canvas, Size size) {
    if (cores.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final centro = Offset(size.width / 2, size.height / 2);
    final raio = 18.5;
    final retangulo = Rect.fromCircle(
      center: centro,
      radius: raio,
    );

    if (cores.length == 1) {
      paint.color = cores.first;
      canvas.drawCircle(centro, raio, paint);
      return;
    }

    final anguloPorEtapa = (2 * math.pi) / cores.length;
    const espacamento = 0.10;

    for (int i = 0; i < cores.length; i++) {
      paint.color = cores[i];

      canvas.drawArc(
        retangulo,
        -math.pi / 2 + (i * anguloPorEtapa),
        anguloPorEtapa - espacamento,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CirculoEtapasPainter oldDelegate) {
    return oldDelegate.cores.length != cores.length ||
        !oldDelegate.cores.every(
          (cor) => cores.contains(cor),
        );
  }
}