import "package:flutter/material.dart";
import "../theme/app_colors.dart";

class AuraTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const AuraTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override 
  State<AuraTextField> createState() => _AuraTextFieldState();
}

class _AuraTextFieldState extends State<AuraTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword && _hidden,
      keyboardType: widget.keyboardType,
      style: const TextStyle(color: AppColors.title),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.subtitle),
        filled: true,
        fillColor: AppColors.field,
        prefixIcon: Icon(widget.icon, color: AppColors.primaryDark,),
        suffixIcon: widget.isPassword
          ? IconButton(
            icon: Icon(
              _hidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
              color: AppColors.primaryDark,
            ),
            onPressed: () => setState(() => _hidden = !_hidden),
          )
        : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
      ),
    );
  }
}