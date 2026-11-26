import "package:flutter/material.dart";
import "package:my_app/pages/ciclo_page.dart";

import "../widgets/aura_bottom_nav.dart";
import "home_page.dart";
import "cronograma_page.dart";
import "progress_page.dart";
import "rotinas_page.dart";

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
        CronogramaPage(),
        const CicloPage(),
        const RotinasPage(),
        const ProgressPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: _paginas,
      ),
      bottomNavigationBar: AuraBottomNav(
        indice: _indice,
        aoSelecionar: _irParaAba,
      ),
    );
  }
}