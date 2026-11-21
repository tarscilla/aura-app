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
          viewModel.selecionarData(
            viewModel.dataSelecionada,
          );
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
          defaultTextStyle: TextStyle(color: texto),
          weekendTextStyle: TextStyle(color: texto),
          todayDecoration: BoxDecoration(
            color: rosaClaro,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: rosa,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: rosa,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (viewModel.possuiTratamento(day)) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: rosa,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}