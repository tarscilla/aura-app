import "package:flutter/material.dart";
import "../widgets/aura_bottom_nav.dart";
import "home_page.dart";
import "progress_page.dart";

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  void _irParaAba(int i) {
    if (i < 0 || i >= _paginas.length) return;

    setState(() {
      _indice = i;
    });
  }

  List<Widget> get _paginas => [
        HomePage(aoIrParaAba: _irParaAba),
        const _EmConstrucao("Cronograma capilar"),
        const _EmConstrucao("Ciclo menstrual"),
        const _EmConstrucao("Rotinas"),
        const ProgressPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _paginas),
      bottomNavigationBar: AuraBottomNav(
        indice: _indice,
        aoSelecionar: _irParaAba,
      ),
    );
  }
}

class _EmConstrucao extends StatelessWidget {
  final String titulo;

  const _EmConstrucao(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("$titulo — em construção")),
    );
  }
}