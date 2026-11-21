class Tratamento {
  final String nome;
  final String categoria;
  final DateTime data;
  final String horario;
  final String descricao;
  bool concluido;

  Tratamento({
    required this.nome,
    required this.categoria,
    required this.data,
    required this.horario,
    required this.descricao,
    this.concluido = false,
  });
}