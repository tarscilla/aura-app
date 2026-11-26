
class Tratamento {
  final String? id;
  final String nome;
  final String categoria;
  final DateTime data;
  final String horario;
  final String descricao;
  bool concluido;

  Tratamento({
    this.id,
    required this.nome,
    required this.categoria,
    required this.data,
    required this.horario,
    required this.descricao,
    this.concluido = false,
  });

  // Converte o tratamento em um mapa para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'categoria': categoria,
      'data': data,
      'horario': horario,
      'descricao': descricao,
      'concluido': concluido,
    };
  }

  // Reconstrói um tratamento usando os dados do Firestore.
  factory Tratamento.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return Tratamento(
      id: id,
      nome: map['nome'] ?? '',
      categoria: map['categoria'] ?? '',
      data: (map['data'] as dynamic).toDate(),
      horario: map['horario'] ?? '',
      descricao: map['descricao'] ?? '',
      concluido: map['concluido'] ?? false,
    );
  }
}
