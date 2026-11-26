
import 'package:flutter/material.dart';
import '../models/tratamento.dart';
import '../services/cronograma_service.dart';

class CronogramaViewModel extends ChangeNotifier {
  final CronogramaService _service = CronogramaService();

  DateTime dataSelecionada = DateTime.now();
  DateTime mesAtual = DateTime.now();

  List<Tratamento> tratamentos = [];

  bool carregando = true;
  String? erro;

  CronogramaViewModel() {
    carregarTratamentos();
  }

  Future<void> carregarTratamentos() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      tratamentos = await _service.buscarTratamentos();

      if (tratamentos.isEmpty) {
        await _criarTratamentosDemonstrativos();
        tratamentos = await _service.buscarTratamentos();
      }
    } catch (e) {
      erro = 'Não foi possível carregar os tratamentos.';
      debugPrint('Erro no cronograma: $e');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> _criarTratamentosDemonstrativos() async {
    final exemplos = [
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

    for (final tratamento in exemplos) {
      await _service.adicionarTratamento(tratamento);
    }
  }

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

  Future<void> alternarConclusao(Tratamento tratamento) async {
    tratamento.concluido = !tratamento.concluido;
    notifyListeners();

    try {
      await _service.atualizarConclusao(tratamento);
    } catch (e) {
      tratamento.concluido = !tratamento.concluido;
      erro = 'Não foi possível atualizar o tratamento.';
      debugPrint('Erro ao atualizar conclusão: $e');
      notifyListeners();
    }
  }

  bool _mesmoDia(DateTime primeira, DateTime segunda) {
    return primeira.year == segunda.year &&
        primeira.month == segunda.month &&
        primeira.day == segunda.day;
  }
}
