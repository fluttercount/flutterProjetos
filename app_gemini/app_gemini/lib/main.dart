import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivação Diária',
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      home: const MotivationalScreen(),
    );
  }
}

class MotivationalScreen extends StatefulWidget {
  const MotivationalScreen({Key? key}) : super(key: key);

  @override
  State<MotivationalScreen> createState() => _MotivationalScreenState();
}

class _MotivationalScreenState extends State<MotivationalScreen> {
  final TextEditingController _feelingsController = TextEditingController();
  String _motivationalMessage = '';
  bool _isLoading = false;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (errorNotification) {
        setState(() {
          _isListening = false;
        });
      },
    );
    if (!available) {
      // O reconhecimento de voz não está disponível no dispositivo
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _feelingsController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

 Future<void> _getMotivationalMessage() async {
  if (_feelingsController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, conte como você está se sentindo')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final String apiKey = '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'; // Substitua pela sua chave
    final String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

    final String userFeeling = _feelingsController.text;
    final String prompt = '''
Baseado no sentimento: "$userFeeling"

''';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://seuapp.com', // Substitua com a URL do seu app ou GitHub
      },
      body: jsonEncode({
        "model": "openrouter/auto",
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": 800
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'];

      setState(() {
        _motivationalMessage = content;
      });
    } else {
      setState(() {
        _motivationalMessage = 'Erro na resposta: ${response.statusCode}\n${response.body}';
      });
    }
  } catch (e) {
    setState(() {
      _motivationalMessage = 'Erro: $e';
    });
  } finally {
    setState(() => _isLoading = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motivação Diária'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Como você está se sentindo hoje?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feelingsController,
                    decoration: const InputDecoration(
                      hintText: 'Conte como você está se sentindo...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _listen,
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.purple,
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _getMotivationalMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Receber Motivação',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
            const SizedBox(height: 24),
            if (_motivationalMessage.isNotEmpty) ...[
              const Text(
                'Sua mensagem do dia:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _motivationalMessage,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    super.dispose();
  }
}
