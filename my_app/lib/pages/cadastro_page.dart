import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "../services/auth_service.dart";
import "../theme/app_colors.dart";
import "../widgets/aura_background.dart";
import "../widgets/aura_buttons.dart";
import "../widgets/aura_text_field.dart";

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _auth = AuthService();
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarSenhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarMensagem("Preencha todos os campos.");
      return;
    }
    if (senha != confirmar) {
      _mostrarMensagem("As senhas não são iguais.");
      return;
    }

    setState(() => _carregando = true);
    final erro = await _auth.cadastrar(nome, email, senha);
    if (!mounted) return;
    setState(() => _carregando = false);

    _mostrarMensagem(erro ?? "Conta criada com sucesso!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Image.asset("assets/images/aura-logo.png", width: 150),
                Text(
                  "AURA",
                  style: GoogleFonts.oranienbaum(
                    fontSize: 44,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Criar sua conta",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Bem-vinda! Preencha os dados abaixo para começar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.subtitle),
                ),
                const SizedBox(height: 24),
                AuraTextField(
                  controller: _nomeController,
                  hint: "Nome completo",
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 14),
                AuraTextField(
                  controller: _emailController,
                  hint: "E-mail",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AuraTextField(
                  controller: _senhaController,
                  hint: "Senha",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 14),
                AuraTextField(
                  controller: _confirmarSenhaController,
                  hint: "Confirmar senha",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: "Cadastrar",
                  isLoading: _carregando,
                  onPressed: _cadastrar,
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.fieldBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "ou",
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.fieldBorder)),
                  ],
                ),
                const SizedBox(height: 16),
                GoogleButton(onPressed: () {}),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      text: "Já tem uma conta? ",
                      style: const TextStyle(color: AppColors.subtitle),
                      children: const [
                        TextSpan(
                          text: "Entrar",
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}