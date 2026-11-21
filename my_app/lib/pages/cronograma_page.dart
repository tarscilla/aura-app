import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tratamento.dart';
import '../viewmodels/cronograma_viewmodel.dart';
import '../widgets/calendario_widget.dart';
import '../widgets/tratamento_card.dart';

class CronogramaPage extends StatelessWidget {
  const CronogramaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CronogramaViewModel(),
      child: const _CronogramaConteudo(),
    );
  }
}

class _CronogramaConteudo extends StatelessWidget {
  const _CronogramaConteudo();

  static const Color rosa = Color(0xFFE9A0B5);
  static const Color fundo = Color(0xFFFFF7F9);
  static const Color texto = Color(0xFF59434B);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CronogramaViewModel>();

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu cabelo, seu cuidado',
                        style: TextStyle(
                          color: Color(0xFF99878D),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Cronograma Capilar',
                        style: TextStyle(
                          color: texto,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.person_outline,
                        color: rosa,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Calendário',
                style: TextStyle(
                  color: texto,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              CalendarioWidget(viewModel: viewModel),

              const SizedBox(height: 25),

              const Text(
                'Tratamentos do dia',
                style: TextStyle(
                  color: texto,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '${viewModel.dataSelecionada.day.toString().padLeft(2, '0')}/'
                '${viewModel.dataSelecionada.month.toString().padLeft(2, '0')}/'
                '${viewModel.dataSelecionada.year}',
                style: const TextStyle(
                  color: Color(0xFF99878D),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              if (viewModel.tratamentosDoDia.isEmpty)
                _mensagemVazia(
                  'Nenhum tratamento programado para este dia.',
                  Icons.spa_outlined,
                )
              else
                ...viewModel.tratamentosDoDia.map(
                  (tratamento) => TratamentoCard(
                    tratamento: tratamento,
                    onToggle: () {
                      viewModel.alternarConclusao(tratamento);
                    },
                  ),
                ),

              const SizedBox(height: 15),

              const Text(
                'Próximos tratamentos',
                style: TextStyle(
                  color: texto,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              if (viewModel.proximosTratamentos.isEmpty)
                _mensagemVazia(
                  'Não há próximos tratamentos programados.',
                  Icons.calendar_today_outlined,
                )
              else
                ..._agruparTratamentos(
                  viewModel.proximosTratamentos,
                  viewModel,
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _agruparTratamentos(List<Tratamento> tratamentos,
  CronogramaViewModel viewModel,) {
  final Map<DateTime, List<Tratamento>> agrupados = {};

  for (final tratamento in tratamentos) {
    final data = DateTime(
      tratamento.data.year,
      tratamento.data.month,
      tratamento.data.day,
    );

    agrupados.putIfAbsent(data, () => []);
    agrupados[data]!.add(tratamento);
  }

  return agrupados.entries.expand((grupo) {
    final data = grupo.key;

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 5),
        child: Text(
          '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}',
          style: const TextStyle(
            color: Color(0xFF99878D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      ...grupo.value.map(
        (tratamento) => TratamentoCard(
          tratamento: tratamento,
          onToggle: () {
            viewModel.alternarConclusao(tratamento);
          },
        ),
      ),
    ];
  }).toList();
}

  Widget _mensagemVazia(String mensagem, IconData icone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icone, color: rosa, size: 30),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF99878D),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}