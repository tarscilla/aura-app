import 'package:flutter/material.dart';
import '../models/tratamento.dart';

class CronogramaViewModel extends ChangeNotifier {
  DateTime dataSelecionada = DateTime.now();

  DateTime mesAtual = DateTime.now();

  final List<Tratamento> tratamentos = [
    Tratamento(
      nome: 'Hidratação',
      categoria: 'Hidratação',
      data: DateTime.now(),
      horario: '14:00',
      descricao: 'Aplicar máscara hidratante nos fios.',
    ),
    Tratamento(
      nome: 'Nutrição',
      categoria: 'Nutrição',
      data: DateTime.now().add(const Duration(days: 2)),
      horario: '10:00',
      descricao: 'Repor os óleos naturais dos cabelos.',
    ),
    Tratamento(
      nome: 'Reconstrução',
      categoria: 'Reconstrução',
      data: DateTime.now().add(const Duration(days: 5)),
      horario: '15:00',
      descricao: 'Fortalecer os fios com uma máscara reconstrutora.',
    ),
  ];

  List<Tratamento> get tratamentosDoDia {
    return tratamentos.where((tratamento) {
      return _mesmoDia(tratamento.data, dataSelecionada);
    }).toList();
  }

  List<Tratamento> get proximosTratamentos {
  return tratamentos.where((tratamento) {
    return !_mesmoDia(tratamento.data, dataSelecionada) &&
        tratamento.data.isAfter(
          DateTime(
            dataSelecionada.year,
            dataSelecionada.month,
            dataSelecionada.day,
          ),
        );
  }).toList()
    ..sort((a, b) => a.data.compareTo(b.data));
}

  bool possuiTratamento(DateTime data) {
    return tratamentos.any((tratamento) {
      return _mesmoDia(tratamento.data, data);
    });
  }

  void selecionarData(DateTime data) {
    dataSelecionada = data;
    mesAtual = DateTime(data.year, data.month);
    notifyListeners();
  }

  void mudarMes(int quantidade) {
    mesAtual = DateTime(
      mesAtual.year,
      mesAtual.month + quantidade,
    );

    notifyListeners();
  }

  void alternarConclusao(Tratamento tratamento) {
    tratamento.concluido = !tratamento.concluido;
    notifyListeners();
  }

  bool _mesmoDia(DateTime primeira, DateTime segunda) {
    return primeira.year == segunda.year &&
        primeira.month == segunda.month &&
        primeira.day == segunda.day;
  }
}