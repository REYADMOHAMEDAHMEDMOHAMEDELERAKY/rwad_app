import 'package:flutter/material.dart';

InputDecoration appInputDecoration(
  String label, {
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) => InputDecoration(
  labelText: label,
  hintText: hintText,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: Colors.grey.shade50,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
);

ButtonStyle primaryButtonStyle(BuildContext context) =>
    ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

ButtonStyle dangerButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: Colors.redAccent,
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle outlinedActionStyle() => OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);
