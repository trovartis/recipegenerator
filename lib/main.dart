import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding and decoding
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Recipe Finder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _timeAvailableController = TextEditingController();
  final TextEditingController _complexityController = TextEditingController();
  String _markdownResponse = '';
  bool _isLoading = false;


  Future<void> queryChatGPT() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    const apiKey = "API_KEY"; // Replace with your actual API key
    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };
    final prompt = "I'm looking for a ${_complexityController.text} recipe "
        "that uses ${_ingredientsController.text} and takes no longer than "
        "${_timeAvailableController.text} minutes to prepare. It is not needed to use all the ingredients, keep the recipe similar to existing ones. If an ingredient is not indicated than put that as optional in the ingredients list. Don't write a summary of the recipe but directly the title, ingredients list and instruction. Add some cooking tips at the bottom. Before the ingredients list specify for how many servings you are calculating the ingredients.";
    final data = jsonEncode({
      "model": "gpt-4-0125-preview",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": prompt}
      ],
    });


      try {
    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: headers,
      body: data,
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(utf8.decode(response.bodyBytes));
      if (responseJson['choices'] != null && responseJson['choices'].isNotEmpty) {
        final latestMessage = responseJson['choices'][0]['message']['content'] as String?;
        if (latestMessage != null) {
          setState(() {
            _markdownResponse = latestMessage.trim();
          });
        } else {
          setState(() {
            _markdownResponse = "Received null for the latest message content.";
          });
        }
      } else {
        setState(() {
          _markdownResponse = "No 'choices' in response or 'choices' list is empty.";
        });
      }
    } else {
      setState(() {
        _markdownResponse = "Error: ${response.statusCode} ${response.body}";
      });
    }
  } catch (e) {
    setState(() {
      _markdownResponse = "Error: $e";
    });
  }
  setState(() {
    _isLoading = false; // Stop loading when the request is complete
  });
}

      
  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredients',
                  hintText: 'Enter ingredients you have',
                ),
              ),
              TextField(
                controller: _timeAvailableController,
                decoration: const InputDecoration(
                  labelText: 'Time Available',
                  hintText: 'Enter the time available for cooking (in minutes)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _complexityController,
                decoration: const InputDecoration(
                  labelText: 'Complexity',
                  hintText: 'Enter the desired complexity of the recipe (easy, medium, hard)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : queryChatGPT, // Disable button when loading
                child: _isLoading
                  ? CircularProgressIndicator(color: Theme.of(context).primaryColor) // Show loading indicator
                  : const Text('Get Recipe'),
              ),
              const SizedBox(height: 20),
              // Use Markdown widget to render the response
              Expanded(
                child: _markdownResponse.isNotEmpty
                  ? Markdown(data: _markdownResponse)
                  : const Text('Enter details to get a recipe.'),
              ),
            ],
          ),
        ),
      );
    }
  }
