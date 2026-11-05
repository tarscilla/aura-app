import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "../services/auth_service.dart";
import "../theme/app_colors.dart";
import "../widgets/aura_background.dart";
import "../widgets/aura_buttons.dart";
import "../widgets/aura_text_field.dart";
import "cadastro_page.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _auth = AuthService();
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem("Preencha e-mail e senha.");
      return;
    }

    setState(() => _carregando = true);
    final erro = await _auth.entrar(email, senha);
    if (!mounted) return;
    setState(() => _carregando = false);

    _mostrarMensagem(erro ?? "Login feito com sucesso!");
  }

  Future<void> _esqueciSenha() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _mostrarMensagem("Digite seu e-mail no campo acima primeiro.");
      return;
    }

    final erro = await _auth.recuperarSenha(email);
    if (!mounted) return;

    _mostrarMensagem(
      erro ?? "Enviamos um link de recuperação para o seu e-mail.",
    );
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Bem-vinda!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.title,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.favorite_border, color: AppColors.primaryDark),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Faça seu login para continuar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.subtitle),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 20),
                PrimaryButton(
                  text: "Entrar",
                  isLoading: _carregando,
                  onPressed: _entrar,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _esqueciSenha,
                  child: const Text(
                    "Esqueci minha senha",
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Não tem conta? ",
                      style: TextStyle(color: AppColors.subtitle),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CadastroPage(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Cadastre-se",
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
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