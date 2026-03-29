import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/translation_service.dart';
import '../services/hive_service.dart';
import '../services/verb_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _translateController = TextEditingController();
  String _selectedSourceLang = 'en';
  String _selectedLang = 'it';
  String _translatedText = '';
  List<String> _historyKeys = [];
  bool _isLoading = false;
  final TextEditingController _verbController = TextEditingController();
  String _selectedVerbLang = 'en';
  Map<String, List<String>> _conjugations = {};
  bool _isConjugating = false;

  final Map<String, String> _languageMap = {
    'English': 'en',
    'Arabic': 'ar',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Italian': 'it',
    'Portuguese': 'pt',
    'Russian': 'ru',
    'Japanese': 'ja',
    'Korean': 'ko',
    'Chinese': 'zh',
  };

  final List<String> _sourceLanguages = [
    'English',
    'Arabic',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
  ];

  final List<String> _languages = [
    'English',
    'Arabic',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Japanese',
    'Korean',
    'Chinese',
  ];

  Future<void> _translate() async {
    final text = _translateController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Always fetch fresh translation (ignore cache)
      final langpair = '$_selectedSourceLang|$_selectedLang';
      final key = '$text|$langpair';
      // Remove from cache if exists to force fresh fetch
      await HiveService.clearTranslation(key);
      final translated = await TranslationService.translate(
        text,
        _selectedSourceLang,
        _selectedLang,
      );
      setState(() {
        _translatedText = translated;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadHistory() {
    _historyKeys = HiveService.getAllKeys();
    setState(() {});
  }

  Future<void> _clearAllHistory() async {
    await HiveService.clearAllTranslations();
    _loadHistory();
  }

  Future<void> _clearSingleHistory(String key) async {
    await HiveService.clearTranslation(key);
    _loadHistory();
  }

  Future<void> _conjugate() async {
    final verb = _verbController.text.trim();
    if (verb.isEmpty) return;
    setState(() {
      _isConjugating = true;
    });
    try {
      final conjugations = await VerbService.getConjugations(
        verb,
        _selectedVerbLang,
      );
      setState(() {
        _conjugations = conjugations;
      });
      // Save to history
      await HiveService.saveTranslation(
        'verb|$verb|$_selectedVerbLang',
        json.encode(conjugations),
      );
    } catch (e) {
      setState(() {
        _conjugations = {
          'Error': ['Failed to conjugate: $e'],
        };
      });
    } finally {
      setState(() {
        _isConjugating = false;
      });
    }
  }

  Widget _buildTranslateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Languages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.language, color: Colors.deepPurple),
              const SizedBox(width: 10),
              const Text('From:'),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _languageMap.entries
                      .firstWhere((e) => e.value == _selectedSourceLang)
                      .key,
                  isExpanded: true,
                  items: _sourceLanguages
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _selectedSourceLang = _languageMap[value!]!,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.translate, color: Colors.deepPurple),
              const SizedBox(width: 10),
              const Text('To:'),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _languageMap.entries
                      .firstWhere((e) => e.value == _selectedLang)
                      .key,
                  isExpanded: true,
                  items: _languages
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedLang = _languageMap[value!]!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter Text to Translate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _translateController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Type your text here...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _translate,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate),
              label: const Text('Translate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (_translatedText.isNotEmpty) ...[
            const SizedBox(height: 30),
            const Text(
              'Translated Text',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _translatedText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      tooltip: 'Clear',
                      onPressed: () {
                        setState(() {
                          _translatedText = '';
                          _translateController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Translation History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('Load History'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _historyKeys.isEmpty ? null : _clearAllHistory,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _historyKeys.isEmpty
                ? const Center(
                    child: Text(
                      'No history available. Translate some text first!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _historyKeys.length,
                    itemBuilder: (context, index) {
                      final key = _historyKeys[index];
                      final parts = key.split('|');
                      if (parts[0] == 'verb') {
                        final verb = parts[1];
                        final lang = parts[2];
                        final Map<String, dynamic> raw = json.decode(
                          HiveService.translationsBox.get(key) ?? '{}',
                        );
                        final Map<String, List<String>> conjugations = raw.map((
                          k,
                          v,
                        ) {
                          if (v is List) {
                            return MapEntry(
                              k,
                              v.map((e) => e.toString()).toList(),
                            );
                          } else {
                            return MapEntry(k, [v.toString()]);
                          }
                        });
                        final subtitle = conjugations.entries
                            .map((e) => '${e.key}: ${e.value.join(', ')}')
                            .join('\n');
                        return Card(
                          color: Colors.black,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.book,
                              color: Colors.white,
                            ),
                            title: Text(
                              'Verb: $verb',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Language: $lang\n$subtitle',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              tooltip: 'Clear',
                              onPressed: () => _clearSingleHistory(key),
                            ),
                          ),
                        );
                      } else {
                        final original = parts[0];
                        final langpair = parts[1];
                        final translated =
                            HiveService.translationsBox.get(key) ?? 'N/A';
                        return Card(
                          color: Colors.black,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.translate,
                              color: Colors.white,
                            ),
                            title: Text(
                              '$original -> $translated',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Language: $langpair',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              tooltip: 'Clear',
                              onPressed: () => _clearSingleHistory(key),
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerbsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verb Conjugations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.language, color: Colors.deepPurple),
              const SizedBox(width: 10),
              const Text('Language:'),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _languageMap.entries
                      .firstWhere((e) => e.value == _selectedVerbLang)
                      .key,
                  isExpanded: true,
                  items: _sourceLanguages
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedVerbLang = _languageMap[value!]!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter Verb',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _verbController,
            decoration: const InputDecoration(
              hintText: 'Type a verb...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isConjugating ? null : _conjugate,
              icon: _isConjugating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.book),
              label: const Text('Conjugate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (_conjugations.isNotEmpty) ...[
            const Text(
              'Conjugations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _conjugations.entries.map((entry) {
                  return Card(
                    color: Colors.black,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        entry.value.join(', '),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Row(
            children: [
              Icon(Icons.translate, color: Colors.white),
              SizedBox(width: 10),
              Text('Translation App', style: TextStyle(color: Colors.white)),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit), text: 'Translate'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.book), text: 'Verbs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTranslateTab(),
            _buildHistoryTab(),
            _buildVerbsTab(),
          ],
        ),
      ),
    );
  }
}
