import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AutoText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  const AutoText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (_, lang, __) {
        return FutureBuilder<String>(
          key: ValueKey("${lang.currentLang}-$data"),
          future: lang.translate(data),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? data,
              style: style,
              maxLines: maxLines,
              overflow: overflow,
              textAlign: textAlign,
              softWrap: softWrap,
            );
          },
        );
      },
    );
  }
}
