import "package:firebase_auth/firebase_auth.dart";

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> entrar(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return null;
    } on FirebaseAuthException catch (e) {
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
      return _mensagemDeErro(e.code);
    }
  }

  Future<String?> recuperarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensagemDeErro(e.code);
    }
  }

  Future<void> sair() => _auth.signOut();

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