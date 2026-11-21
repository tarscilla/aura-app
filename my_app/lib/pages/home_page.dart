import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../services/auth_service.dart";
import "../theme/app_colors.dart";
import "../widgets/aura_background.dart";
import "../widgets/aura_buttons.dart";

const int _metaAgua = 8;
const int _metaSonoMin = 8 * 60;

final Map<String, IconData> _humores = {
  "Feliz": Icons.sentiment_satisfied_outlined,
  "Neutra": Icons.sentiment_neutral_outlined,
  "Triste": Icons.sentiment_dissatisfied_outlined,
  "Cansada": Icons.sentiment_very_dissatisfied_outlined,
  "Ansiosa": Icons.psychology_alt_outlined,
};

String _chaveDoDia() {
  final agora = DateTime.now();
  final mes = agora.month.toString().padLeft(2, "0");
  final dia = agora.day.toString().padLeft(2, "0");
  return "${agora.year}-$mes-$dia";
}

DocumentReference<Map<String, dynamic>>? _registroDeHoje() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return FirebaseFirestore.instance
      .collection("usuarios")
      .doc(uid)
      .collection("registros")
      .doc(_chaveDoDia());
}

Future<void> _salvarRegistro(Map<String, dynamic> dados) async {
  final ref = _registroDeHoje();
  if (ref == null) return;
  try {
    await ref.set(
      {...dados, "atualizadoEm": FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  } catch (e) {
    debugPrint("Erro ao salvar registro: $e");
  }
}

String _formatarSono(int minutos) {
  final h = minutos ~/ 60;
  final m = minutos % 60;
  if (m == 0) return "${h}h";
  return "${h}h ${m.toString().padLeft(2, "0")}min";
}

Future<void> _abrirFolha(BuildContext context, Widget conteudo) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundTop,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => conteudo,
  );
}

class HomePage extends StatelessWidget {
  final ValueChanged<int>? aoIrParaAba;

  const HomePage({super.key, this.aoIrParaAba});

  String _primeiroNome() {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? "";
    if (nome.isEmpty) return "";
    return nome.split(" ").first;
  }

  double _progresso(int agua, int sonoMin, bool temHumor) {
    final pAgua = (agua / _metaAgua).clamp(0.0, 1.0).toDouble();
    final pSono = (sonoMin / _metaSonoMin).clamp(0.0, 1.0).toDouble();
    final pHumor = temHumor ? 1.0 : 0.0;
    return (pAgua + pSono + pHumor) / 3;
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Sair da conta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );
    if (sair == true) {
      await AuthService().sair();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _registroDeHoje()?.snapshots(),
            builder: (context, snapshot) {
              final dados = snapshot.data?.data();
              final agua = ((dados?["agua"] ?? 0) as num).toInt();
              final sonoMin = ((dados?["sonoMinutos"] ?? 0) as num).toInt();
              final humor = dados?["humor"] as String?;
              final temHumor = humor != null && humor.isNotEmpty;
              final progresso = _progresso(agua, sonoMin, temHumor);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cabecalho(context),
                    const SizedBox(height: 24),
                    _cardProgresso(progresso),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MiniCard(
                            titulo: "Água",
                            valor: "$agua/$_metaAgua",
                            asset: "assets/images/agua.png",
                            icone: Icons.water_drop_outlined,
                            aoTocar: () =>
                                _abrirFolha(context, _FolhaAgua(inicial: agua)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            titulo: "Sono",
                            valor: sonoMin > 0
                                ? _formatarSono(sonoMin)
                                : "Registrar",
                            asset: "assets/images/sono.png",
                            icone: Icons.bedtime_outlined,
                            aoTocar: () => _abrirFolha(
                              context,
                              _FolhaSono(inicialMin: sonoMin),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            titulo: "Humor",
                            valor: temHumor ? humor : "Registrar",
                            asset: "assets/images/humor.png",
                            icone: Icons.sentiment_satisfied_alt_outlined,
                            aoTocar: () =>
                                _abrirFolha(context, _FolhaHumor(atual: humor)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Acesso Rápido",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 2.1,
                      children: [
                        _AtalhoCard(
                          icone: const Icon(
                            Icons.calendar_month_rounded,
                            size: 36,
                            color: AppColors.primaryDark,
                          ),
                          texto: "Cronograma capilar",
                          aoTocar: () => aoIrParaAba?.call(1),
                        ),
                        _AtalhoCard(
                          icone: const _IconeCiclo(),
                          texto: "Ciclo menstrual",
                          aoTocar: () => aoIrParaAba?.call(2),
                        ),
                        _AtalhoCard(
                          icone: const Icon(
                            Icons.assignment_outlined,
                            size: 36,
                            color: AppColors.primaryDark,
                          ),
                          texto: "Rotinas",
                          aoTocar: () => aoIrParaAba?.call(3),
                        ),
                        _AtalhoCard(
                          icone: const Icon(
                            Icons.favorite_border,
                            size: 36,
                            color: AppColors.primaryDark,
                          ),
                          texto: "Favoritos",
                          aoTocar: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Em breve: favoritos."),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    final nome = _primeiroNome();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      nome.isEmpty ? "Olá" : "Olá, $nome",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.title,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite_border, color: AppColors.primaryDark),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                "Seja bem-vinda!",
                style: TextStyle(fontSize: 17, color: AppColors.subtitle),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () => _confirmarSaida(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.field,
              border: Border.all(color: AppColors.primary, width: 1.5),
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
      ],
    );
  }

  Widget _cardProgresso(double progresso) {
    return _CardBranco(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  "Seu progresso hoje",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progresso,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFF3E4E8),
                        color: AppColors.primaryDark,
                      ),
                      Center(
                        child: Text(
                          "${(progresso * 100).round()}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.title,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                progresso >= 1.0 ? "Tudo concluído!" : "Continue assim!",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitle,
                ),
              ),
              ],
            ),
          ),
          const Expanded(
            child: _ArteOuIcone(
              asset: "assets/images/flor-progresso.png",
              icone: Icons.local_florist_rounded,
              tamanho: 120,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBranco extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? aoTocar;

  const _CardBranco({
    required this.child,
    required this.padding,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: Container(
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
      ),
    );
  }
}

class _ArteOuIcone extends StatelessWidget {
  final String asset;
  final IconData icone;
  final double tamanho;

  const _ArteOuIcone({
    required this.asset,
    required this.icone,
    required this.tamanho,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: tamanho,
      height: tamanho,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(icone, size: tamanho * 0.7, color: AppColors.primary),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String asset;
  final IconData icone;
  final VoidCallback aoTocar;

  const _MiniCard({
    required this.titulo,
    required this.valor,
    required this.asset,
    required this.icone,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return _CardBranco(
      aoTocar: aoTocar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.field,
              ),
              child: _ArteOuIcone(asset: asset, icone: icone, tamanho: 48),
            ),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtalhoCard extends StatelessWidget {
  final Widget icone;
  final String texto;
  final VoidCallback aoTocar;

  const _AtalhoCard({
    required this.icone,
    required this.texto,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return _CardBranco(
      aoTocar: aoTocar,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          icone,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconeCiclo extends StatelessWidget {
  const _IconeCiclo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 36,
            color: AppColors.primaryDark,
          ),
          Icon(
            Icons.water_drop,
            size: 15,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _BotaoRedondo extends StatelessWidget {
  final IconData icone;
  final VoidCallback aoTocar;

  const _BotaoRedondo({required this.icone, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.field,
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Icon(icone, color: AppColors.primaryDark),
      ),
    );
  }
}

class _FolhaAgua extends StatefulWidget {
  final int inicial;

  const _FolhaAgua({required this.inicial});

  @override
  State<_FolhaAgua> createState() => _FolhaAguaState();
}

class _FolhaAguaState extends State<_FolhaAgua> {
  late int _copos = widget.inicial;

  void _mudar(int novo) {
    if (novo < 0 || novo > 20) return;
    setState(() => _copos = novo);
    _salvarRegistro({"agua": novo});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Água de hoje",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Meta: $_metaAgua copos",
              style: TextStyle(color: AppColors.subtitle),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BotaoRedondo(
                  icone: Icons.remove,
                  aoTocar: () => _mudar(_copos - 1),
                ),
                const SizedBox(width: 24),
                Text(
                  "$_copos / $_metaAgua",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(width: 24),
                _BotaoRedondo(
                  icone: Icons.add,
                  aoTocar: () => _mudar(_copos + 1),
                ),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              text: "Pronto",
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolhaSono extends StatefulWidget {
  final int inicialMin;

  const _FolhaSono({required this.inicialMin});

  @override
  State<_FolhaSono> createState() => _FolhaSonoState();
}

class _FolhaSonoState extends State<_FolhaSono> {
  late double _min = widget.inicialMin > 0
      ? widget.inicialMin.clamp(0, 720).toDouble()
      : 480;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Quanto você dormiu?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatarSono(_min.round()),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.title,
              ),
            ),
            Slider(
              value: _min,
              min: 0,
              max: 720,
              divisions: 48,
              activeColor: AppColors.primaryDark,
              inactiveColor: AppColors.fieldBorder,
              onChanged: (v) => setState(() => _min = v),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: "Salvar",
              onPressed: () {
                _salvarRegistro({"sonoMinutos": _min.round()});
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FolhaHumor extends StatelessWidget {
  final String? atual;

  const _FolhaHumor({required this.atual});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Como você está hoje?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in _humores.entries)
                  ChoiceChip(
                    label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value, size: 20),
                      const SizedBox(width: 6),
                      Text(e.key),
                    ],
                  ),
                    selected: atual == e.key,
                    onSelected: (_) {
                      _salvarRegistro({"humor": e.key});
                      Navigator.of(context).pop();
                    },
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: AppColors.field,
                    side: const BorderSide(color: AppColors.fieldBorder),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: atual == e.key ? Colors.white : AppColors.title,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}