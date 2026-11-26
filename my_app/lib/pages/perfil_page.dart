
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/aura_background.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  void _abrirPrivacidade() {
  final email = FirebaseAuth.instance.currentUser?.email ??
      'E-mail não disponível';

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacidade e segurança',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primaryDark,
                ),
                title: const Text('E-mail da conta'),
                subtitle: Text(email),
              ),

              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primaryDark,
                ),
                title: const Text('Alterar senha'),
                subtitle: const Text(
                  'A alteração poderá ser realizada pelo e-mail cadastrado.',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  final ImagePicker _picker = ImagePicker();
  XFile? _fotoGaleria;
  bool _saindo = false;

  final TextEditingController _nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nomeController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _selecionarFotoGaleria() async {
    try {
      final XFile? imagem = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (imagem != null && mounted) {
        setState(() {
          _fotoGaleria = imagem;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a galeria de fotos.'),
        ),
      );
    }
  }

  void _abrirOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alterar foto de perfil',
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
                  title: const Text('Adicionar foto da galeria'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _selecionarFotoGaleria();
                  },
                ),
                if (_fotoGaleria != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Remover foto atual'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _fotoGaleria = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editarInformacoes() async {
    _nomeController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar informações'),
          content: TextField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Digite seu nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final erro = await AuthService().atualizarNome(
      _nomeController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          erro ?? 'Nome atualizado com sucesso!',
        ),
      ),
    );

    if (erro == null) {
      setState(() {});
    }
  }

  void _abrirAparencia() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aparência',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: themeService.isDarkMode,
                      activeColor: AppColors.primary,
                      title: const Text('Claro'),
                      secondary: const Icon(Icons.light_mode_outlined),
                      onChanged: (value) {
                        if (value != null) {
                          themeService.alterarTema(value);
                        }
                      },
                    ),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: themeService.isDarkMode,
                      activeColor: AppColors.primary,
                      title: const Text('Escuro'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      onChanged: (value) {
                        if (value != null) {
                          themeService.alterarTema(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sairDaConta(BuildContext context) async {
    if (_saindo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Sair da conta?"),
        content: const Text(
          "Tem certeza de que deseja sair do AURA?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _saindo = true);

    try {
      await AuthService().sair();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _saindo = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao sair da conta: $e"),
        ),
      );
    }
  }

  Widget _buildAvatarImage() {
    const double size = 112;

    if (_fotoGaleria != null) {
      if (kIsWeb) {
        return Image.network(
          _fotoGaleria!.path,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }

      return Image.file(
        File(_fotoGaleria!.path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      '/assets/images/avatar.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Widget _buildFotoPerfil() {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _abrirOpcoesFoto,
          child: Stack(
            children: [
              ClipOval(
                child: _buildAvatarImage(),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(
                    Icons.edit,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcao({
    required IconData icone,
    required String titulo,
    String? descricao,
    VoidCallback? onTap,
  }) {
    final corTexto = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 1,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(
            icone,
            color: AppColors.primaryDark,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: corTexto,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: descricao == null
            ? null
            : Text(
                descricao,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Usuário';

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
                Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppColors.title,
                            size: 21,
                          ),
                          tooltip: 'Voltar para home',
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Meu perfil',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.title,
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 24),

                _buildFotoPerfil(),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'Olá, $nome!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.title,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Minha conta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),

                const SizedBox(height: 10),

                _buildOpcao(
                  icone: Icons.person_outline,
                  titulo: 'Editar informações',
                  descricao: 'Atualize seu nome',
                  onTap: _editarInformacoes,
                ),

                const SizedBox(height: 22),

                const Text(
                  'Preferências',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.title,
                  ),
                ),

                const SizedBox(height: 10),

                _buildOpcao(
                  icone: Icons.palette_outlined,
                  titulo: 'Aparência',
                  descricao: 'Escolha entre tema claro e escuro',
                  onTap: _abrirAparencia,
                ),

                _buildOpcao(
                  icone: Icons.lock_outline,
                  titulo: 'Privacidade e segurança',
                  descricao: 'Gerencie as informações da sua conta',
                  onTap: _abrirPrivacidade,
                ),

                _buildOpcao(
                  icone: Icons.help_outline,
                  titulo: 'Ajuda e suporte',
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saindo
                        ? null
                        : () => _sairDaConta(context),
                    icon: _saindo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                    label: Text(
                      _saindo ? 'Saindo...' : 'Sair da conta',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
