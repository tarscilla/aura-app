import "package:flutter/material.dart";
import "../theme/app_colors.dart";
import "../widgets/aura_background.dart";
import "../services/auth_service.dart";

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  String? _avatarSelecionado;

  final List<String> _avatares = List.generate(
  16,
  (index) =>
      "assets/images/avatares/avatar_${(index + 1).toString().padLeft(2, '0')}.png",
);

  Future<void> _sairDaConta(BuildContext context) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Sair da conta?"),
      content: const Text(
        "Tem certeza de que deseja sair do AURA?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Sair"),
        ),
      ],
    ),
  );

  if (confirmar == true) {
    await AuthService().sair();

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
  
void _abrirGaleriaAvatares() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  "Escolha seu avatar",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: GridView.builder(
                    itemCount: _avatares.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final avatar = _avatares[index];

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _avatarSelecionado = avatar;
                            });

                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.field,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.primary,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Image.asset(
                                avatar,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Meu perfil",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.title,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Foto do perfil
                Center(
                  child: Column(
                    children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Alterar foto de perfil",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.title,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      ListTile(
                                        leading: const Icon(
                                          Icons.photo_library_outlined,
                                          color: AppColors.primaryDark,
                                        ),
                                        title: const Text("Adicionar foto da galeria"),
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      ),

                                      ListTile(
                                        leading: const Icon(
                                          Icons.face_retouching_natural,
                                          color: AppColors.primaryDark,
                                        ),
                                        title: const Text("Escolher avatar ilustrado"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _abrirGaleriaAvatares();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.field,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                                    child: Center(
                                      child: _avatarSelecionado != null
                                          ? Image.asset(
                                              _avatarSelecionado!,
                                              fit: BoxFit.cover,
                                              width: 112,
                                              height: 112,
                                            )
                                          : Image.asset(
                                              "assets/images/avatar.png",
                                              fit: BoxFit.cover,
                                              width: 112,
                                              height: 112,
                                            ),
                                    ),
                                  ),
                        ),
                      ),
                    ),
                      const SizedBox(height: 14),
                      const Text(
                        "Olá!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Gerencie suas informações e preferências",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                const Text(
                  "Minha conta",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),

                const SizedBox(height: 14),

                _OpcaoPerfil(
                  icone: Icons.person_outline,
                  titulo: "Editar informações",
                  subtitulo: "Atualize seus dados pessoais",
                  aoTocar: () {},
                ),

                const SizedBox(height: 12),

                const Text(
                  "Preferências",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),

                const SizedBox(height: 14),

                _OpcaoPerfil(
                  icone: Icons.palette_outlined,
                  titulo: "Aparência",
                  subtitulo: "Personalize o visual do aplicativo",
                  aoTocar: () {},
                ),

                const SizedBox(height: 12),

                _OpcaoPerfil(
                  icone: Icons.lock_outline,
                  titulo: "Privacidade e segurança",
                  subtitulo: "Cuide da segurança da sua conta",
                  aoTocar: () {},
                ),

                const SizedBox(height: 12),

                _OpcaoPerfil(
                  icone: Icons.help_outline,
                  titulo: "Ajuda e suporte",
                  subtitulo: "Encontre ajuda para utilizar o AURA",
                  aoTocar: () {},
                ),
                const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _sairDaConta(context),
                        icon: const Icon(Icons.logout),
                        label: const Text("Sair da conta"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcaoPerfil extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTocar;

  const _OpcaoPerfil({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: aoTocar,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icone,
            color: AppColors.primaryDark,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.title,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(
            color: AppColors.subtitle,
            fontSize: 11,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}