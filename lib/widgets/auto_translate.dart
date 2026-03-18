import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AutoTranslate extends StatelessWidget {
  final Widget child;

  const AutoTranslate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return child;
      },
    );
  }
}
