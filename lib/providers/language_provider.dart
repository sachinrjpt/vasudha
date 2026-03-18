import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class LanguageProvider extends ChangeNotifier {
  String currentLang = "en";

  final Map<String, Map<String, String>> _cache = {};

  void changeLanguage(String lang) {
    currentLang = lang;
    notifyListeners();
  }

  Future<String> translate(String text) async {
    print("TRANSLATE CALLED => $text | lang=$currentLang");
    if (currentLang == "en") return text;

    _cache.putIfAbsent(currentLang, () => {});

    if (_cache[currentLang]!.containsKey(text)) {
      return _cache[currentLang]![text]!;
    }

    final translated = await TranslationService.translateText(
      text: text,
      fromLang: "en",
      toLang: currentLang,
    );

    _cache[currentLang]![text] = translated;
    return translated;
  }
}
