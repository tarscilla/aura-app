import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../theme/app_colors.dart";
import "aura_buttons.dart";

class PerfilPrompt extends StatefulWidget {
  final Widget child;

  const PerfilPrompt({super.key, required this.child});

  @override
  State<PerfilPrompt> createState() => _PerfilPromptState();
}

class _PerfilPromptState extends State<PerfilPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  Future<void> _verificar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(uid)
          .get();
      final concluido = doc.data()?["questionarioConcluido"] == true;
      if (concluido || !mounted) return;

      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.backgroundTop,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => _QuestionarioSheet(uid: uid),
      );
    } catch (e) {
      debugPrint("Erro ao verificar perfil: $e");
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _QuestionarioSheet extends StatefulWidget {
  final String uid;

  const _QuestionarioSheet({required this.uid});

  @override
  State<_QuestionarioSheet> createState() => _QuestionarioSheetState();
}

class _QuestionarioSheetState extends State<_QuestionarioSheet> {
  static const _tiposPele = ["Oleosa", "Seca", "Mista", "Normal", "Sensível"];
  static const _tiposCabelo = ["Liso", "Ondulado", "Cacheado", "Crespo"];

  String? _pele;
  String? _cabelo;
  bool _aceitouRecomendacoes = false;
  bool _aceitouDadosAcademicos = false;
  bool _salvando = false;
  String? _erro;

  Future<void> _salvar() async {
    if (_pele == null || _cabelo == null) {
      setState(() => _erro = "Escolha o tipo de pele e o tipo de cabelo.");
      return;
    }
    

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(widget.uid)
          .set({
        "questionarioConcluido": true,
        "tipoPele": _pele,
        "tipoCabelo": _cabelo,
        "aceitouRecomendacoes": _aceitouRecomendacoes,
        "aceitouDadosAcademicos": _aceitouDadosAcademicos,
        "atualizadoEm": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("Erro ao salvar perfil: $e");
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = "Não foi possível salvar. Tente novamente.";
      });
    }
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.title,
        ),
      ),
    );
  }

  Widget _opcoes(
    List<String> opcoes,
    String? selecionado,
    ValueChanged<String> aoEscolher,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opcao in opcoes)
          ChoiceChip(
            label: Text(opcao),
            selected: selecionado == opcao,
            onSelected: (_) => aoEscolher(opcao),
            selectedColor: AppColors.primaryDark,
            backgroundColor: AppColors.field,
            side: const BorderSide(color: AppColors.fieldBorder),
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: selecionado == opcao ? Colors.white : AppColors.title,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vamos te conhecer melhor",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Duas perguntas rápidas para recomendar o que combina com você.",
              style: TextStyle(color: AppColors.subtitle),
            ),
            const SizedBox(height: 24),
            _titulo("Qual é o seu tipo de pele?"),
            _opcoes(_tiposPele, _pele, (v) => setState(() => _pele = v)),
            const SizedBox(height: 20),
            _titulo("E o seu tipo de cabelo?"),
            _opcoes(_tiposCabelo, _cabelo, (v) => setState(() => _cabelo = v)),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _aceitouRecomendacoes,
              onChanged: (v) =>
                  setState(() => _aceitouRecomendacoes = v ?? false),
              activeColor: AppColors.primaryDark,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                "Quero receber recomendações personalizadas de produtos.",
                style: TextStyle(fontSize: 13, color: AppColors.subtitle),
              ),
            ),
            CheckboxListTile(
              value: _aceitouDadosAcademicos,
              onChanged: (v) =>
                  setState(() => _aceitouDadosAcademicos = v ?? false),
              activeColor: AppColors.primaryDark,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                "Autorizo o uso das minhas respostas, sem identificação, "
                "em análises acadêmicas de dados.",
                style: TextStyle(fontSize: 13, color: AppColors.subtitle),
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _erro!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            PrimaryButton(
              text: "Salvar",
              isLoading: _salvando,
              onPressed: _salvar,
            ),
            Center(
              child: TextButton(
                onPressed:
                    _salvando ? null : () => Navigator.of(context).pop(false),
                child: const Text(
                  "Responder depois",
                  style: TextStyle(color: AppColors.subtitle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}