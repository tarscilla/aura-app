import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../theme/app_colors.dart";
import "../widgets/aura_background.dart";
import "../widgets/aura_buttons.dart";
import "perfil_page.dart";

const int _cicloPadrao = 28;

const List<String> _meses = [
  "janeiro", "fevereiro", "março", "abril", "maio", "junho",
  "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
];

const List<String> _iniciaisDias = ["D", "S", "T", "Q", "Q", "S", "S"];

const Color _corFertil = Color(0xFFE9DDF7);
const Color _corOvulacao = Color(0xFFB99AD9);

class _Sintoma {
  final String nome;
  final String asset;
  final IconData icone;

  const _Sintoma(this.nome, this.asset, this.icone);
}

const List<_Sintoma> _sintomas = [
  _Sintoma("Cólicas", "assets/images/colicas.png", Icons.healing),
  _Sintoma("Inchaço", "assets/images/inchaco.png", Icons.bubble_chart_outlined),
  _Sintoma("Ansiedade", "assets/images/ansiedade.png", Icons.psychology_outlined),
  _Sintoma("Sensível", "assets/images/sensivel.png", Icons.sentiment_dissatisfied_outlined),
];

DateTime _soData(DateTime d) => DateTime.utc(d.year, d.month, d.day);

String _chave(DateTime d) {
  final mes = d.month.toString().padLeft(2, "0");
  final dia = d.day.toString().padLeft(2, "0");
  return "${d.year}-$mes-$dia";
}

String _dataCurta(DateTime d) {
  final dia = d.day.toString().padLeft(2, "0");
  final mes = d.month.toString().padLeft(2, "0");
  return "$dia/$mes";
}

String _formatarSono(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (m == 0) return "${h}h";
  return "${h}h ${m.toString().padLeft(2, "0")}min";
}

String _capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _Periodo {
  final DateTime inicio;
  final DateTime fim;

  const _Periodo(this.inicio, this.fim);
}

class _Dados {
  final Map<String, Map<String, dynamic>> porDia;
  final Set<DateTime> diasMenstruacao;
  final List<_Periodo> periodos;

  const _Dados(this.porDia, this.diasMenstruacao, this.periodos);

  static _Dados vazio() => _Dados({}, {}, []);

  DateTime? get ultimoInicio => periodos.isEmpty ? null : periodos.last.inicio;

  int get quantidadeIntervalos =>
      periodos.length > 1 ? periodos.length - 1 : 0;

  int get duracaoCiclo {
    if (quantidadeIntervalos == 0) return _cicloPadrao;

    var soma = 0;
    for (var i = 1; i < periodos.length; i++) {
      soma += periodos[i].inicio.difference(periodos[i - 1].inicio).inDays;
    }

    final media = (soma / quantidadeIntervalos).round();
    return media.clamp(21, 45).toInt();
  }

  String get descricaoDuracaoCiclo {
    if (quantidadeIntervalos == 0) {
      return "Usando ciclo padrão de $_cicloPadrao dias";
    }
    if (quantidadeIntervalos == 1) {
      return "Baseado em 1 intervalo registrado";
    }
    return "Média de $quantidadeIntervalos intervalos registrados";
  }

  int get duracaoMenstruacao {
    if (periodos.isEmpty) return 5;

    var soma = 0;
    for (final p in periodos) {
      soma += p.fim.difference(p.inicio).inDays + 1;
    }

    return (soma / periodos.length).round().clamp(3, 8).toInt();
  }

  DateTime? proximoInicio(DateTime hoje) {
    final u = ultimoInicio;
    if (u == null) return null;

    final prox = u.add(Duration(days: duracaoCiclo));
    return prox.isBefore(hoje) ? null : prox;
  }

  bool ehPrevisto(DateTime dia, DateTime hoje) {
    final prox = proximoInicio(hoje);
    if (prox == null) return false;

    final fim = prox.add(Duration(days: duracaoMenstruacao - 1));
    return !dia.isBefore(prox) && !dia.isAfter(fim);
  }

  DateTime? ovulacaoEstimada(DateTime hoje) {
    final prox = proximoInicio(hoje);
    if (prox == null) return null;
    return prox.subtract(const Duration(days: 14));
  }

  bool ehFertil(DateTime dia, DateTime hoje) {
    final ovulacao = ovulacaoEstimada(hoje);
    if (ovulacao == null) return false;

    final inicio = ovulacao.subtract(const Duration(days: 5));
    return !dia.isBefore(inicio) && !dia.isAfter(ovulacao);
  }

  bool ehOvulacao(DateTime dia, DateTime hoje) {
    final ovulacao = ovulacaoEstimada(hoje);
    return ovulacao != null && dia == ovulacao;
  }

  int? diaDoCiclo(DateTime hoje) {
    final u = ultimoInicio;
    if (u == null) return null;

    final dia = hoje.difference(u).inDays + 1;
    return dia < 1 ? null : dia;
  }
}

_Dados _ler(QuerySnapshot<Map<String, dynamic>> snap) {
  final porDia = <String, Map<String, dynamic>>{};
  final dias = <DateTime>{};

  for (final doc in snap.docs) {
    final dados = doc.data();
    porDia[doc.id] = dados;

    if (dados["menstruou"] == true) {
      final data = DateTime.tryParse(doc.id);
      if (data != null) {
        dias.add(_soData(data));
      }
    }
  }

  final ordenados = dias.toList()..sort();
  final periodos = <_Periodo>[];

  DateTime? inicio;
  DateTime? anterior;

  for (final d in ordenados) {
    if (inicio == null || anterior == null) {
      inicio = d;
    } else if (d.difference(anterior).inDays > 6) {
      periodos.add(_Periodo(inicio, anterior));
      inicio = d;
    }
    anterior = d;
  }

  if (inicio != null && anterior != null) {
    periodos.add(_Periodo(inicio, anterior));
  }

  return _Dados(porDia, dias, periodos);
}

class CicloPage extends StatefulWidget {
  const CicloPage({super.key});

  @override
  State<CicloPage> createState() => _CicloPageState();
}

class _CicloPageState extends State<CicloPage> {
  static const int _paginaInicialSemana = 10000;

  late final PageController _semanaController;
  late DateTime _semanaBase;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>>? get _stream {
    final uid = _uid;
    if (uid == null) return null;

    return FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("registros")
        .snapshots();
  }

  DateTime _selecionado = _soData(DateTime.now());

  @override
  void initState() {
    super.initState();
    _semanaBase = _soData(DateTime.now());
    _semanaController = PageController(initialPage: _paginaInicialSemana);
  }

  @override
  void dispose() {
    _semanaController.dispose();
    super.dispose();
  }

  void _selecionarDia(DateTime dia) {
    final data = _soData(dia);

    setState(() {
      _selecionado = data;
      _semanaBase = data;
    });

    _semanaController.jumpToPage(_paginaInicialSemana);
  }

  void _aoMudarSemana(int pagina) {
    final diferenca = pagina - _paginaInicialSemana;
    final diaCentral = _soData(
      _semanaBase.add(Duration(days: diferenca * 7)),
    );

    setState(() {
      _selecionado = diaCentral;
    });
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _salvar(DateTime dia, Map<String, dynamic> dados) async {
    final uid = _uid;

    debugPrint("UID ATUAL: $uid");
    debugPrint("DATA DO REGISTRO: ${_chave(dia)}");

    if (uid == null) {
      if (mounted) {
        _mostrarMensagem("Usuária não autenticada. Entre novamente.");
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .collection("registros")
          .doc(_chave(dia))
          .set({
            ...dados,
            "atualizadoEm": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint("REGISTRO SALVO COM SUCESSO!");
    } catch (e) {
      debugPrint("ERRO AO SALVAR: $e");
      if (!mounted) return;
      _mostrarMensagem("Erro ao salvar: $e");
    }
  }

  Future<void> _alternarMenstruacao(DateTime dia, bool jaMarcado) async {
    debugPrint("TOQUEI NA DATA: ${_chave(dia)}");

    final hoje = _soData(DateTime.now());
    if (dia.isAfter(hoje)) {
      _mostrarMensagem("Escolha hoje ou um dia que já passou.");
      return;
    }

    await _salvar(dia, {"menstruou": !jaMarcado});
  }

  Future<void> _alternarSintoma(String nome, bool ativo) {
    return _alternarSintomaNoDia(_selecionado, nome, ativo);
  }

  Future<void> _alternarSintomaNoDia(
    DateTime dia,
    String nome,
    bool ativo,
  ) {
    return _salvar(dia, {
      "sintomas": ativo
          ? FieldValue.arrayUnion([nome])
          : FieldValue.arrayRemove([nome]),
    });
  }

  Future<void> _abrirCalendario({
    bool iniciarRegistroMenstruacao = false,
  }) async {
    final altura = MediaQuery.of(context).size.height * 0.92;

    final escolhido = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundTop,
      constraints: BoxConstraints(maxHeight: altura),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CalendarioSheet(
        stream: _stream,
        selecionadoInicial: _selecionado,
        aoAlternarMenstruacao: _alternarMenstruacao,
        aoAlternarSintoma: _alternarSintomaNoDia,
        iniciarRegistroMenstruacao: iniciarRegistroMenstruacao,
      ),
    );

    if (!mounted) return;
    if (escolhido != null) {
      _selecionarDia(escolhido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = _soData(DateTime.now());

    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint("Erro ao ler ciclo: ${snapshot.error}");
              }

              final dados = snapshot.hasData
                  ? _ler(snapshot.data!)
                  : _Dados.vazio();

              final doDia = dados.porDia[_chave(_selecionado)] ??
                  const <String, dynamic>{};

              final ativos = List<String>.from(
                doDia["sintomas"] ?? const [],
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    _cabecalho(),
                    const SizedBox(height: 18),
                    _semana(hoje, dados),
                    const SizedBox(height: 28),
                    _registro(dados),
                    const SizedBox(height: 22),
                    _cicloAtual(dados, hoje),
                    const SizedBox(height: 26),
                    _blocoSintomas(ativos),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _abrirCalendario(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "${_selecionado.day} de ${_meses[_selecionado.month - 1]}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
        ),
        MouseRegion(
  cursor: SystemMouseCursors.click,
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PerfilPage(),
        ),
      );
    },
    child: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.field,
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          "assets/images/avatar.png",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person,
            size: 30,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    ),
  ),
),
      ],
    );
  }

  Widget _semana(DateTime hoje, _Dados dados) {
    return SizedBox(
      height: 76,
      child: PageView.builder(
        controller: _semanaController,
        onPageChanged: _aoMudarSemana,
        itemBuilder: (context, pagina) {
          final diferenca = pagina - _paginaInicialSemana;
          final diaCentral = _soData(
            _semanaBase.add(Duration(days: diferenca * 7)),
          );

          return Row(
            children: [
              for (var i = -3; i <= 3; i++)
                Expanded(
                  child: _diaSemana(
                    diaCentral.add(Duration(days: i)),
                    hoje,
                    dados,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _diaSemana(DateTime dia, DateTime hoje, _Dados dados) {
    final ehHoje = dia == hoje;
    final selecionado = dia == _selecionado;
    final menstruou = dados.diasMenstruacao.contains(dia);
    final previsto = !menstruou && dados.ehPrevisto(dia, hoje);
    final ovulacao = !menstruou && dados.ehOvulacao(dia, hoje);
    final fertil = !menstruou && !ovulacao && dados.ehFertil(dia, hoje);

    Color? fundo;
    var corTexto = AppColors.title;

    if (menstruou) {
      fundo = AppColors.primaryDark;
      corTexto = Colors.white;
    } else if (previsto) {
      fundo = AppColors.field;
    } else if (ovulacao) {
      fundo = _corOvulacao;
    } else if (fertil) {
      fundo = _corFertil;
    } else if (selecionado) {
      fundo = AppColors.field;
    }

    Border? borda;
    if (selecionado) {
      borda = Border.all(color: AppColors.title, width: 2);
    } else if (ehHoje) {
      borda = Border.all(color: AppColors.primaryDark);
    } else if (previsto) {
      borda = Border.all(color: AppColors.primary);
    } else if (ovulacao) {
      borda = Border.all(color: const Color(0xFF8C65B5));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selecionarDia(dia),
      child: Column(
        children: [
          Text(
            ehHoje ? "HOJE" : _iniciaisDias[dia.weekday % 7],
            style: TextStyle(
              fontSize: 11,
              fontWeight: ehHoje ? FontWeight.w700 : FontWeight.w400,
              color: ehHoje ? AppColors.title : AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fundo,
              border: borda,
            ),
            child: Text(
              "${dia.day}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: corTexto,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _registro(_Dados dados) {
    final ultimo = dados.ultimoInicio;

    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          ultimo == null
              ? "Nenhum registro ainda"
              : "Última: ${_dataCurta(ultimo)}",
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: () => _abrirCalendario(
            iniciarRegistroMenstruacao: true,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
            shape: const StadiumBorder(),
          ),
          child: const Text(
            "Registrar menstruação",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cicloAtual(_Dados dados, DateTime hoje) {
    final dia = dados.diaDoCiclo(hoje);
    final total = dados.duracaoCiclo;
    final prox = dados.proximoInicio(hoje);

    final progresso = dia == null
        ? 0.0
        : (dia / total).clamp(0.0, 1.0).toDouble();

    return _Cartao(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ciclo atual",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  dia == null
                      ? "Registre sua última menstruação"
                      : "Dia $dia / $total",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dados.descricaoDuracaoCiclo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 8,
                    backgroundColor: AppColors.fieldBorder,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (prox != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Próxima: ${_dataCurta(prox)} "
                    "(em ${prox.difference(hoje).inDays} dias)",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progresso,
                  strokeWidth: 10,
                  backgroundColor: AppColors.fieldBorder,
                  color: AppColors.primaryDark,
                ),
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: _Arte(
                    asset: "assets/images/utero.png",
                    icone: Icons.favorite_border,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoSintomas(List<String> ativos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sintomas",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.title,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Como você se sentiu em ${_selecionado.day} de "
          "${_meses[_selecionado.month - 1]}?",
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 12),
        _Cartao(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          child: Row(
            children: [
              for (final s in _sintomas)
                Expanded(
                  child: _SintomaItem(
                    sintoma: s,
                    ativo: ativos.contains(s.nome),
                    aoTocar: () => _alternarSintoma(
                      s.nome,
                      !ativos.contains(s.nome),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}


class _CalendarioSheet extends StatefulWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? stream;
  final DateTime selecionadoInicial;

  final Future<void> Function(DateTime dia, bool jaMarcado)
      aoAlternarMenstruacao;

  final Future<void> Function(DateTime dia, String nome, bool ativo)
      aoAlternarSintoma;

  final bool iniciarRegistroMenstruacao;

  const _CalendarioSheet({
    required this.stream,
    required this.selecionadoInicial,
    required this.aoAlternarMenstruacao,
    required this.aoAlternarSintoma,
    required this.iniciarRegistroMenstruacao,
  });

  @override
  State<_CalendarioSheet> createState() => _CalendarioSheetState();
}

class _CalendarioSheetState extends State<_CalendarioSheet> {
  static const int _paginaInicial = 1200;

  late final DateTime _mesBase = DateTime.utc(
    widget.selecionadoInicial.year,
    widget.selecionadoInicial.month,
    1,
  );

  late final PageController _paginaController;
  late DateTime _mes = _mesBase;
  late DateTime _dia = widget.selecionadoInicial;

  int _paginaAtual = _paginaInicial;

  late bool _modoRegistrarMenstruacao;

  @override
  void initState() {
    super.initState();
    _modoRegistrarMenstruacao = widget.iniciarRegistroMenstruacao;
    _paginaController = PageController(initialPage: _paginaInicial);
  }

  @override
  void dispose() {
    _paginaController.dispose();
    super.dispose();
  }

  DateTime _mesDaPagina(int pagina) {
    return DateTime.utc(
      _mesBase.year,
      _mesBase.month + pagina - _paginaInicial,
      1,
    );
  }

  void _mudarMes(int delta) {
    final destino = _paginaAtual + delta;

    _paginaController.animateToPage(
      destino,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _aoMudarPagina(int pagina) {
    setState(() {
      _paginaAtual = pagina;
      _mes = _mesDaPagina(pagina);
    });
  }

  Widget _gradeMes(DateTime mes, _Dados dados, DateTime hoje) {
    final vazios = mes.weekday % 7;
    final diasNoMes = DateTime.utc(mes.year, mes.month + 1, 0).day;

    return GridView.count(
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: [
        for (var i = 0; i < vazios; i++) const SizedBox.shrink(),
        for (var d = 1; d <= diasNoMes; d++)
          _celula(DateTime.utc(mes.year, mes.month, d), dados, hoje),
        for (var i = vazios + diasNoMes; i < 42; i++)
          const SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoje = _soData(DateTime.now());

    final largura = MediaQuery.of(context).size.width - 32;
    final alturaGrade = largura / 7 * 6;

    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Erro ao carregar calendário: ${snapshot.error}");
          }

          final dados = snapshot.hasData
              ? _ler(snapshot.data!)
              : _Dados.vazio();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _mudarMes(-1),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${_capitalizar(_meses[_mes.month - 1])} de ${_mes.year}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _mudarMes(1),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final letra in _iniciaisDias)
                      Expanded(
                        child: Text(
                          letra,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: alturaGrade,
                  child: PageView.builder(
                    controller: _paginaController,
                    onPageChanged: _aoMudarPagina,
                    itemBuilder: (context, pagina) {
                      final mes = _mesDaPagina(pagina);
                      return _gradeMes(mes, dados, hoje);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _legenda(),
                const SizedBox(height: 14),
                _botaoRegistrarMenstruacao(),
                if (_modoRegistrarMenstruacao) ...[
                  const SizedBox(height: 8),
                  const Text(
                    "Toque nas datas para marcar ou desmarcar os dias da menstruação.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _resumo(dados, hoje),
              ],
            ),
          );
        },
      ),
    );
  }

  
  Widget _celula(DateTime dia, _Dados dados, DateTime hoje) {
    final menstruou = dados.diasMenstruacao.contains(dia);
    final previsto = !menstruou && dados.ehPrevisto(dia, hoje);

    final ovulacao =
        !menstruou && !previsto && dados.ehOvulacao(dia, hoje);

    final fertil =
        !menstruou && !previsto && !ovulacao && dados.ehFertil(dia, hoje);

    final ehHoje = dia == hoje;
    final selecionado = dia == _dia;
    final futuro = dia.isAfter(hoje);

    Color? fundo;
    final corTexto = menstruou ? Colors.white : const Color(0xFF49364F);

    if (menstruou) {
      fundo = AppColors.primaryDark;
    } else if (previsto) {
      fundo = AppColors.field;
    } else if (ovulacao) {
      fundo = _corOvulacao;
    } else if (fertil) {
      fundo = _corFertil;
    }

    Border? borda;

    if (selecionado) {
      borda = Border.all(color: AppColors.title, width: 2);
    } else if (ehHoje) {
      borda = Border.all(color: AppColors.primaryDark);
    } else if (previsto) {
      borda = Border.all(color: AppColors.primary);
    } else if (ovulacao) {
      borda = Border.all(
        color: const Color(0xFF8C65B5),
        width: 1.5,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!mounted) return;

        setState(() {
          _dia = dia;
        });

        if (_modoRegistrarMenstruacao && !futuro) {
          widget.aoAlternarMenstruacao(dia, menstruou);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fundo,
                border: borda,
              ),
              child: Text(
                dia.day.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: corTexto,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legenda() {
    Widget item(Widget marca, String texto) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          marca,
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.subtitle,
            ),
          ),
        ],
      );
    }

    Widget circulo(Color cor, {Color? borda}) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cor,
          border: borda != null ? Border.all(color: borda) : null,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        item(circulo(AppColors.primaryDark), "Menstruação"),
        item(circulo(AppColors.field, borda: AppColors.primary), "Prevista"),
        item(circulo(_corFertil), "Período fértil"),
        item(circulo(_corOvulacao), "Ovulação"),
      ],
    );
  }

  Widget _botaoRegistrarMenstruacao() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _modoRegistrarMenstruacao = !_modoRegistrarMenstruacao;
          });
        },
        icon: Icon(
          _modoRegistrarMenstruacao
              ? Icons.check_rounded
              : Icons.water_drop_outlined,
        ),
        label: Text(
          _modoRegistrarMenstruacao
              ? "Concluir registro da menstruação"
              : "Registrar menstruação",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _modoRegistrarMenstruacao
              ? AppColors.field
              : AppColors.primaryDark,
          foregroundColor: _modoRegistrarMenstruacao
              ? AppColors.primaryDark
              : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 16,
          ),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _linha(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumo(_Dados dados, DateTime hoje) {
    final d = dados.porDia[_chave(_dia)] ??
        const <String, dynamic>{};

    final menstruou = d["menstruou"] == true;
    final sintomas = List<String>.from(d["sintomas"] ?? const []);
    final futuro = _dia.isAfter(hoje);

    return _Cartao(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_dia.day} de ${_meses[_dia.month - 1]}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Edite as informações deste dia por aqui.",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Sintomas",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sintoma in _sintomas)
                FilterChip(
                  label: Text(sintoma.nome),
                  selected: sintomas.contains(sintoma.nome),
                  selectedColor: AppColors.primaryDark,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: sintomas.contains(sintoma.nome)
                        ? Colors.white
                        : AppColors.title,
                    fontWeight: sintomas.contains(sintoma.nome)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: sintomas.contains(sintoma.nome)
                        ? AppColors.primaryDark
                        : AppColors.fieldBorder,
                  ),
                  onSelected: futuro
                      ? null
                      : (ativo) => widget.aoAlternarSintoma(
                            _dia,
                            sintoma.nome,
                            ativo,
                          ),
                ),
            ],
          ),
          if (futuro) ...[
            const SizedBox(height: 10),
            const Text(
              "Você pode editar apenas hoje ou dias anteriores.",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.subtitle,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: AppColors.fieldBorder),
          if (dados.ehPrevisto(_dia, hoje) && !menstruou)
            _linha(Icons.event_outlined, "Menstruação prevista"),
          if (dados.ehFertil(_dia, hoje))
            _linha(Icons.spa_outlined, "Período fértil estimado"),
          if (dados.ehOvulacao(_dia, hoje))
            _linha(Icons.favorite_outline_rounded, "Ovulação estimada"),
          if (((d["agua"] ?? 0) as num) > 0)
            _linha(
              Icons.local_drink_outlined,
              "Água: ${(d["agua"] as num).toInt()} copos",
            ),
          if (((d["sonoMinutos"] ?? 0) as num) > 0)
            _linha(
              Icons.bedtime_outlined,
              "Sono: ${_formatarSono((d["sonoMinutos"] as num).toInt())}",
            ),
          if (((d["humor"] ?? "") as String).isNotEmpty)
            _linha(
              Icons.sentiment_satisfied_alt_outlined,
              "Humor: ${d["humor"]}",
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            text: "Concluir",
            onPressed: () => Navigator.of(context).pop(_dia),
          ),
        ],
      ),
    );
  }
}

class _SintomaItem extends StatelessWidget {
  final _Sintoma sintoma;
  final bool ativo;
  final VoidCallback aoTocar;

  const _SintomaItem({
    required this.sintoma,
    required this.ativo,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 84,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ativo ? AppColors.field : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ativo
                      ? AppColors.primaryDark
                      : AppColors.fieldBorder,
                  width: ativo ? 2 : 1,
                ),
              ),
              child: _Arte(
                asset: sintoma.asset,
                icone: sintoma.icone,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sintoma.nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: ativo ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arte extends StatelessWidget {
  final String asset;
  final IconData icone;

  const _Arte({
    required this.asset,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        icone,
        size: 34,
        color: AppColors.primary,
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Cartao({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}