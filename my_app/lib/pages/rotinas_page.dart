import "package:flutter/material.dart";
import "../theme/app_colors.dart";
import "../widgets/aura_buttons.dart";
import "../widgets/aura_text_field.dart";

// Cores usadas só nesta tela. Se já existirem equivalentes no AppColors,
// troque por elas e apague esta classe.
class _RotinasColors {
  static const fundo = Color(0xFFF9F0F0);
  static const card = Color(0xFFFFFBFB);
  static const rosa = Color(0xFFFF8FA3);
  static const rosaSuave = Color(0xFFFFD6D6);
  static const rosaClaro = Color(0xFFFFE0E0);
  static const abaInativa = Color(0xFFE9E9E9);
}

class RotinaEtapa {
  final String titulo;
  final String descricao;
  final String? imagem;
  final bool personalizada;
  bool concluida;

  RotinaEtapa({
    required this.titulo,
    required this.descricao,
    this.imagem,
    this.personalizada = false,
    this.concluida = false,
  });
}

class RotinasPage extends StatefulWidget {
  const RotinasPage({super.key});

  @override
  State<RotinasPage> createState() => _RotinasPageState();
}

class _RotinasPageState extends State<RotinasPage> {
  int _abaSelecionada = 0;

  final List<String> _abas = ["Manhã", "Noite", "Personalizados"];

  final Map<int, List<RotinaEtapa>> _rotinas = {
    0: [
      RotinaEtapa(
        titulo: "Limpar o rosto",
        descricao: "Gel de limpeza suave",
        imagem: "assets/images/limpar-rosto.png",
        concluida: true,
      ),
      RotinaEtapa(
        titulo: "Tônico",
        descricao: "Equilibrar a pele",
        imagem: "assets/images/tonico.png",
        concluida: true,
      ),
      RotinaEtapa(
        titulo: "Sérum",
        descricao: "Controlar oleosidade",
        imagem: "assets/images/serum.png",
        concluida: true,
      ),
      RotinaEtapa(
        titulo: "Hidratante",
        descricao: "Hidratação leve",
        imagem: "assets/images/hidratante.png",
      ),
      RotinaEtapa(
        titulo: "Protetor solar",
        descricao: "FPS 50",
        imagem: "assets/images/protetor-solar.png",
      ),
    ],
    1: [],
    2: [],
  };

  List<RotinaEtapa> get _etapas => _rotinas[_abaSelecionada]!;

  void _alternarEtapa(RotinaEtapa etapa) {
    setState(() => etapa.concluida = !etapa.concluida);
  }

  Future<void> _adicionarEtapa() async {
    final nova = await showModalBottomSheet<RotinaEtapa>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _RotinasColors.fundo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NovaEtapaSheet(),
    );

    if (nova == null || !mounted) return;
    setState(() => _etapas.add(nova));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RotinasColors.fundo,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCabecalho(),
            _buildAbas(),
            const SizedBox(height: 16),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Rotinas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _RotinasColors.rosaClaro,
              border: Border.all(color: _RotinasColors.rosa),
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/avatar.png",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: _RotinasColors.rosa,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_abas.length, (i) {
          final selecionada = i == _abaSelecionada;
          return Expanded(
            flex: i == 2 ? 3 : 2,
            child: Padding(
              padding: EdgeInsets.only(right: i == _abas.length - 1 ? 0 : 6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _abaSelecionada = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selecionada
                        ? _RotinasColors.rosaSuave
                        : _RotinasColors.abaInativa,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _abas[i],
                    style: TextStyle(
                      fontSize: 14,
                      color: selecionada
                          ? _RotinasColors.rosa
                          : AppColors.subtitle,
                      fontWeight:
                          selecionada ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLista() {
    final etapas = _etapas;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        if (etapas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "Nenhuma etapa. Toque em Adicionar etapa.",
                style: TextStyle(color: AppColors.subtitle),
              ),
            ),
          ),
        ...etapas.map((e) {
          Widget card = _EtapaCard(
            etapa: e,
            onToggle: () => _alternarEtapa(e),
          );

          // Etapas criadas pela usuária podem ser removidas deslizando.
          if (e.personalizada) {
            card = Dismissible(
              key: ObjectKey(e),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => setState(() => etapas.remove(e)),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: _RotinasColors.rosaSuave,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: _RotinasColors.rosa,
                ),
              ),
              child: card,
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: card,
          );
        }),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _adicionarEtapa,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
              decoration: BoxDecoration(
                color: _RotinasColors.rosaClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: _RotinasColors.rosa),
                  SizedBox(width: 6),
                  Text(
                    "Adicionar etapa",
                    style: TextStyle(fontSize: 14, color: _RotinasColors.rosa),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EtapaCard extends StatelessWidget {
  final RotinaEtapa etapa;
  final VoidCallback onToggle;

  const _EtapaCard({required this.etapa, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
      decoration: BoxDecoration(
        color: _RotinasColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _RotinasColors.rosaSuave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: etapa.imagem == null
                ? const Icon(Icons.spa_outlined, color: _RotinasColors.rosa)
                : Image.asset(
                    etapa.imagem!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.spa_outlined,
                      color: _RotinasColors.rosa,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etapa.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  etapa.descricao,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: etapa.concluida ? _RotinasColors.rosa : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: etapa.concluida
                        ? _RotinasColors.rosa
                        : AppColors.fieldBorder,
                    width: 1.5,
                  ),
                ),
                child: etapa.concluida
                    ? const Icon(Icons.check, size: 16, color: Colors.black87)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovaEtapaSheet extends StatefulWidget {
  const _NovaEtapaSheet();

  @override
  State<_NovaEtapaSheet> createState() => _NovaEtapaSheetState();
}

class _NovaEtapaSheetState extends State<_NovaEtapaSheet> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      setState(() => _erro = "Dê um nome para a etapa.");
      return;
    }

    Navigator.pop(
      context,
      RotinaEtapa(
        titulo: titulo,
        descricao: _descricaoController.text.trim(),
        personalizada: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nova etapa",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 16),
          AuraTextField(
            controller: _tituloController,
            hint: "Nome da etapa",
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 12),
          AuraTextField(
            controller: _descricaoController,
            hint: "Descrição (opcional)",
            icon: Icons.notes_outlined,
          ),
          if (_erro != null) ...[
            const SizedBox(height: 8),
            Text(
              _erro!,
              style: const TextStyle(color: AppColors.primaryDark),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            text: "Adicionar",
            isLoading: false,
            onPressed: _salvar,
          ),
        ],
      ),
    );
  }
}
