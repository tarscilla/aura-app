
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tratamento.dart';

class CronogramaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _colecaoUsuario() {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Nenhum usuário está conectado.');
    }

    return _firestore
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('tratamentos');
  }

  // Salvar um novo tratamento.
  Future<void> adicionarTratamento(Tratamento tratamento) async {
    await _colecaoUsuario().add(tratamento.toMap());
  }

  // Buscar os tratamentos do usuário.
  Future<List<Tratamento>> buscarTratamentos() async {
    final snapshot = await _colecaoUsuario()
        .orderBy('data')
        .get();

    return snapshot.docs.map((documento) {
      return Tratamento.fromMap(
        documento.id,
        documento.data(),
      );
    }).toList();
  }

  // Atualizar a conclusão de um tratamento.
  Future<void> atualizarConclusao(Tratamento tratamento) async {
    if (tratamento.id == null) {
      throw Exception('Tratamento sem identificador.');
    }

    await _colecaoUsuario()
        .doc(tratamento.id)
        .update({
      'concluido': tratamento.concluido,
    });
  }

  // Excluir um tratamento.
  Future<void> excluirTratamento(String id) async {
    await _colecaoUsuario().doc(id).delete();
  }
}
