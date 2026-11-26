
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../widgets/perfil_prompt.dart";
import "login_page.dart";
import "main_shell.dart";

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          debugPrint("AUTHGATE: USUÁRIO LOGADO");
          return const PerfilPrompt(child: MainShell());
        }

        debugPrint("AUTHGATE: USUÁRIO DESCONECTADO");
        return const LoginPage();
      },
    );
  }
}