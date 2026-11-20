
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "package:google_sign_in/google_sign_in.dart";

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _googleIniciado = false;

  Future<String?> entrar(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase: ${e.code} - ${e.message}");
      return _mensagemDeErro(e.code);
    }
  }

  Future<String?> cadastrar(String nome, String email, String senha) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      await cred.user?.updateDisplayName(nome.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase: ${e.code} - ${e.message}");
      return _mensagemDeErro(e.code);
    }
  }

  Future<String?> recuperarSenha(String email) async {
    try {
      await _auth.setLanguageCode("pt-BR");
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase: ${e.code} - ${e.message}");
      return _mensagemDeErro(e.code);
    }
  }

  Future<String?> entrarComGoogle() async {
    try {
      debugPrint("Google: 1 - iniciando");
      if (!_googleIniciado) {
        await GoogleSignIn.instance.initialize(
          serverClientId: "215316066288-gdfk4cv0i3l5uoac5anm9piq7os8bnrm.apps.googleusercontent.com",
        );
        _googleIniciado = true;
      }

      debugPrint("Google: 2 - abrindo contas");
      final googleUser = await GoogleSignIn.instance
          .authenticate()
          .timeout(const Duration(seconds: 40));
      debugPrint("Google: 3 - conta escolhida");

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );
      await _auth.signInWithCredential(credential);
      return null;
    } catch (e) {
      debugPrint("Erro Google: $e");
      if (e.toString().toLowerCase().contains("cancel")) {
        return "Login com o Google cancelado.";
      }
      return "Não foi possível entrar com o Google.";
    }
  }

  Future<void> sair() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  String _mensagemDeErro(String code) {
    switch (code) {
      case "invalid-email":
        return "E-mail inválido.";
      case "user-not-found":
      case "wrong-password":
      case "invalid-credential":
        return "E-mail ou senha incorretos.";
      case "email-already-in-use":
        return "Esse e-mail já está cadastrado.";
      case "weak-password":
        return "A senha precisa ter pelo menos 6 caracteres.";
      case "network-request-failed":
        return "Sem conexão com a internet.";
      case "too-many-requests":
        return "Muitas tentativas. Tente de novo mais tarde.";
      default:
        return "Algo deu errado. Tente novamente.";
    }
  }
}