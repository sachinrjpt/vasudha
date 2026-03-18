import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _apiKey =
      "ndNq0TWNF4TA7bU65uPLgObvOWBiFzkAZu1ve1uCUi-jWZ7SMEOZsLK_n0RtIm7e"; // MeitY Authorization key

  static const String _url =
      "https://dhruva-api.bhashini.gov.in/services/inference/pipeline";

  static Future<String> translateText({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (fromLang == toLang) return text;

    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {"Content-Type": "application/json", "Authorization": _apiKey},
        body: jsonEncode({
          "pipelineTasks": [
            {
              "taskType": "translation",
              "config": {
                "language": {
                  "sourceLanguage": fromLang,
                  "targetLanguage": toLang,
                },
              },
            },
          ],
          "inputData": {
            "input": [
              {"source": text},
            ],
          },
        }),
      );

      final data = jsonDecode(res.body);
      return data["pipelineResponse"][0]["output"][0]["target"];
    } catch (e) {
      return text;
    }
  }
}
