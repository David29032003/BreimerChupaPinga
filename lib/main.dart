import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(WriteVibeAssistant());

class WriteVibeAssistant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistente Virtual',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: AssistantPage(),
    );
  }
}

class AssistantPage extends StatefulWidget {
  @override
  _AssistantPageState createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Presiona el micrófono y habla...';
  String _respuesta = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _enviarTextoAlLLM(_text);
    }
  }

  Future<void> _enviarTextoAlLLM(String prompt) async {
    final response = await http.post(
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      headers: {
        'Authorization':
            'Bearer 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',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://writevibe.app',
        'X-Title': 'WriteVibeAssistant',
      },
      body: jsonEncode({
        "model": "deepseek/deepseek-chat:free",
        "messages": [
          {
            "role": "system",
            "content":
                "Eres un experto en redacción, poesía, discursos y ensayos. Mejora el siguiente texto conservando su estilo y mensaje original, pero hazlo más claro, elegante y emotivo. Solo envía el mensaje referente a eso."
          },
          {
            "role": "user",
            "content": prompt
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _respuesta = decoded['choices'][0]['message']['content'];
      });
    } else {
      print("Error: ${response.statusCode}");
      print("Cuerpo: ${response.body}");
      setState(() {
        _respuesta = "Error al generar respuesta:\n${response.body}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Asistente Virtual WriteVibe")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_text, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Detener' : 'Hablar'),
              onPressed: _listen,
            ),
            SizedBox(height: 30),
            Text("Respuesta generada:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_respuesta, style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
