import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "../services/auth_service.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logada como $email"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => AuthService().sair(),
              child: const Text("Sair"),
            ),
          ],
        ),
      ),
    );
  }
}