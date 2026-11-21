import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../theme/app_colors.dart";
import "../widgets/aura_background.dart";

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  String _chave(DateTime data) {
    final mes = data.month.toString().padLeft(2, "0");
    final dia = data.day.toString().padLeft(2, "0");
    return "${data.year}-$mes-$dia";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Faça login para ver seu progresso.")),
      );
    }

    final registros = FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .collection("registros");

    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: registros.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text("Não foi possível carregar seu progresso."),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDark,
                  ),
                );
              }

              final hoje = DateTime.now();
              final inicio = DateTime(
                hoje.year,
                hoje.month,
                hoje.day,
              ).subtract(const Duration(days: 6));

              final dadosPorDia = <String, Map<String, dynamic>>{};

              for (final doc in snapshot.data!.docs) {
                final data = DateTime.tryParse(doc.id);

                if (data == null) continue;

                final dia = DateTime(data.year, data.month, data.day);

                if (!dia.isBefore(inicio) &&
                    !dia.isAfter(DateTime(hoje.year, hoje.month, hoje.day))) {
                  dadosPorDia[doc.id] = doc.data();
                }
              }

              final dias = List.generate(7, (index) {
                final data = inicio.add(Duration(days: index));
                final dados = dadosPorDia[_chave(data)] ?? {};

                return _DiaRegistro(
                  data: data,
                  agua: ((dados["agua"] ?? 0) as num).toInt(),
                  sono: ((dados["sonoMinutos"] ?? 0) as num).toInt(),
                  humor: dados["humor"] as String?,
                );
              });

              final diasComRegistro = dias
                  .where(
                    (d) =>
                        d.agua > 0 ||
                        d.sono > 0 ||
                        (d.humor?.isNotEmpty ?? false),
                  )
                  .length;

              final totalAgua = dias.fold<int>(
                0,
                (total, dia) => total + dia.agua,
              );

              final diasComSono = dias.where((d) => d.sono > 0).toList();

              final mediaSono = diasComSono.isEmpty
                  ? 0
                  : diasComSono.fold<int>(
                          0,
                          (total, dia) => total + dia.sono,
                        ) ~/
                        diasComSono.length;

              final humores = <String, int>{};

              for (final dia in dias) {
                if (dia.humor != null && dia.humor!.isNotEmpty) {
                  humores[dia.humor!] = (humores[dia.humor!] ?? 0) + 1;
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Seu progresso",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          "Cada pequeno cuidado conta",
                          style: TextStyle(fontSize: 15, color: AppColors.subtitle),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _CardProgresso(diasComRegistro: diasComRegistro),

                    const SizedBox(height: 18),

                    _CardGrafico(
                      titulo: "Consumo de água",
                      icone: Icons.water_drop_outlined,
                      resumo: "${(totalAgua / 7).toStringAsFixed(1)} copos/dia",
                      descricao: "Sua média diária nesta semana",
                      dias: dias,
                      valor: (d) => d.agua.toDouble(),
                      maximo: 8,
                      unidade: "copos",
                    ),

                    const SizedBox(height: 18),

                    _CardGrafico(
                      titulo: "Horas de sono",
                      icone: Icons.bedtime_outlined,
                      resumo: diasComSono.isEmpty
                          ? "Sem registros"
                          : _formatarSono(mediaSono),
                      descricao: "Média de sono nos dias registrados",
                      dias: dias,
                      valor: (d) => d.sono / 60,
                      maximo: 12,
                      unidade: "horas",
                    ),

                    const SizedBox(height: 18),

                    _CardHumor(humores: humores),

                    const SizedBox(height: 18),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Continue cuidando de você!",
                            style: TextStyle(
                              color: AppColors.subtitle,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.local_florist_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatarSono(int minutos) {
    final horas = minutos ~/ 60;
    final resto = minutos % 60;

    if (resto == 0) return "${horas}h";
    return "${horas}h ${resto}min";
  }
}

class _DiaRegistro {
  final DateTime data;
  final int agua;
  final int sono;
  final String? humor;

  const _DiaRegistro({
    required this.data,
    required this.agua,
    required this.sono,
    required this.humor,
  });
}

class _CardProgresso extends StatelessWidget {
  final int diasComRegistro;

  const _CardProgresso({required this.diasComRegistro});

  @override
  Widget build(BuildContext context) {
    final percentual = diasComRegistro / 7;

    return _CardBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text(
                "Resumo da semana",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$diasComRegistro",
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 7, left: 5),
                child: Text(
                  "de 7 dias com registros",
                  style: TextStyle(color: AppColors.subtitle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentual,
              minHeight: 10,
              backgroundColor: AppColors.field,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Seus cuidados estão sendo registrados dia após dia.",
            style: TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }
}

class _CardGrafico extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final String resumo;
  final String descricao;
  final List<_DiaRegistro> dias;
  final double Function(_DiaRegistro) valor;
  final double maximo;
  final String unidade;

  const _CardGrafico({
    required this.titulo,
    required this.icone,
    required this.resumo,
    required this.descricao,
    required this.dias,
    required this.valor,
    required this.maximo,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    return _CardBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AppColors.primaryDark, size: 23),
              const SizedBox(width: 9),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            resumo,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            descricao,
            style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final dia in dias)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            valor(dia) > 0
                                ? valor(
                                    dia,
                                  ).toStringAsFixed(valor(dia) % 1 == 0 ? 0 : 1)
                                : "",
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.subtitle,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 76,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: valor(dia) <= 0
                                  ? 5
                                  : (valor(dia) / maximo * 76).clamp(5.0, 76.0),
                              decoration: BoxDecoration(
                                color: valor(dia) > 0
                                    ? AppColors.primary
                                    : AppColors.field,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            [
                              "S",
                              "T",
                              "Q",
                              "Q",
                              "S",
                              "S",
                              "D",
                            ][dia.data.weekday - 1],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Meta de referência: ${maximo.toStringAsFixed(0)} $unidade",
            style: const TextStyle(fontSize: 11, color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }
}

class _CardHumor extends StatelessWidget {
  final Map<String, int> humores;

  const _CardHumor({required this.humores});

  static const Map<String, IconData> icones = {
    "Feliz": Icons.sentiment_satisfied_outlined,
    "Neutro": Icons.sentiment_neutral_outlined,
    "Triste": Icons.sentiment_dissatisfied_outlined,
    "Cansado": Icons.sentiment_very_dissatisfied_outlined,
    "Ansioso": Icons.psychology_alt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final total = humores.values.fold<int>(0, (a, b) => a + b);

    return _CardBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_border, color: AppColors.primaryDark),
              SizedBox(width: 9),
              Text(
                "Seu humor",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? "Você ainda não registrou seu humor nesta semana."
                : "$total ${total == 1 ? "registro" : "registros"} nesta semana",
            style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),
          const SizedBox(height: 16),
          if (humores.isEmpty)
            const Text(
              "Quando você registrar como está se sentindo, seu histórico aparecerá aqui.",
              style: TextStyle(color: AppColors.subtitle),
            )
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: humores.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.field,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icones[e.key] ?? Icons.mood_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${e.key} (${e.value})",
                        style: const TextStyle(
                          color: AppColors.title,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CardBranco extends StatelessWidget {
  final Widget child;

  const _CardBranco({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
