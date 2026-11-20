import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../services/auth_service.dart";
import "../theme/app_colors.dart";

class HomePage extends StatelessWidget {
  final ValueChanged<int>? aoIrParaAba;

  const HomePage({super.key, this.aoIrParaAba});
  
  static const double _progressoHoje = 0.7;
  static const String _agua = "5/8";
  static const String _sono = "5hrs 17mn";

  String _primeiroNome() {
    final nome = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? "";
    if (nome.isEmpty) return "";
    return nome.split(" ").first;
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
      backgroundColor: AppColors.backgroundBottom,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(context),
              const SizedBox(height: 24),
              _cardProgresso(),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: _MiniCard(
                      titulo: "Água",
                      valor: _agua,
                      asset: "assets/images/agua.png",
                      icone: Icons.water_drop_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MiniCard(
                      titulo: "Sono",
                      valor: _sono,
                      asset: "assets/images/sono.png",
                      icone: Icons.bedtime_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _MiniCard(
                      titulo: "Humor",
                      asset: "assets/images/humor.png",
                      icone: Icons.sentiment_satisfied_alt_outlined,
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
                    icone: Icons.calendar_month_rounded,
                    texto: "Cronograma capilar",
                    aoTocar: () => aoIrParaAba?.call(1),
                  ),
                  _AtalhoCard(
                    icone: Icons.favorite_rounded,
                    texto: "Ciclo menstrual",
                    aoTocar: () => aoIrParaAba?.call(2),
                  ),
                  _AtalhoCard(
                    icone: Icons.checklist_rounded,
                    texto: "Rotinas",
                    aoTocar: () => aoIrParaAba?.call(3),
                  ),
                  _AtalhoCard(
                    icone: Icons.favorite_border_rounded,
                    texto: "Favoritos",
                    aoTocar: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Em breve: favoritos.")),
                      );
                    },
                  ),
                ],
              ),
            ],
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
              Text(
                nome.isEmpty ? "Olá! 💖" : "Olá, $nome 💖",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Seja bem-vinda! ✨",
                style: TextStyle(fontSize: 17, color: AppColors.subtitle),
              ),
            ],
          ),
        ),
        // Temporário: tocar no avatar pergunta se quer sair.
        // Quando existir a tela de Perfil, ele abre o Perfil.
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

  Widget _cardProgresso() {
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
                      const CircularProgressIndicator(
                        value: _progressoHoje,
                        strokeWidth: 12,
                        backgroundColor: Color(0xFFEDE3E3),
                        color: AppColors.primaryDark,
                      ),
                      Center(
                        child: Text(
                          "${(_progressoHoje * 100).round()}%",
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
                const Text(
                  "concluído...",
                  style: TextStyle(fontSize: 13, color: AppColors.subtitle),
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
          color: const Color(0xFFFFFBFB),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
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
  final String? valor;
  final String asset;
  final IconData icone;

  const _MiniCard({
    required this.titulo,
    required this.asset,
    required this.icone,
    this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return _CardBranco(
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
            _ArteOuIcone(asset: asset, icone: icone, tamanho: 56),
            Text(
              valor ?? "",
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
  final IconData icone;
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
          Icon(icone, size: 36, color: AppColors.primaryDark),
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