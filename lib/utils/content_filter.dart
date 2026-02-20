/// Utility class for filtering inappropriate content from messages
/// Supports both English and Tagalog bad words
class ContentFilter {
  ContentFilter._internal();

  static final ContentFilter _instance = ContentFilter._internal();

  factory ContentFilter() => _instance;

  /// List of bad words to filter (English)
  static const List<String> _englishBadWords = [
    'fuck',
    'fucking',
    'fucked',
    'fucker',
    'fucks',
    'shit',
    'shitting',
    'shitted',
    'shitter',
    'shits',
    'damn',
    'dammit',
    'damned',
    'ass',
    'asshole',
    'asses',
    'assholes',
    'bitch',
    'bitching',
    'bitched',
    'bitches',
    'bastard',
    'bastards',
    'cunt',
    'cunts',
    'dick',
    'dicks',
    'dickhead',
    'pussy',
    'pussies',
    'whore',
    'whores',
    'slut',
    'sluts',
    'crap',
    'craps',
    'hell',
    'piss',
    'pissed',
    'pissing',
    'pisses',
    'cock',
    'cocks',
    'suck',
    'sucks',
    'sucking',
    'sucked',
    'wank',
    'wanker',
    'wanking',
    'twat',
    'twats',
    'prick',
    'pricks',
    'bollocks',
    'bollock',
    'wtf',
    'stfu',
    'gtfo',
    'nigger',
    'nigga',
    'niggers',
    'niggas',
    'retard',
    'retarded',
    'retards',
    'fag',
    'faggot',
    'faggots',
    'fags',
    'motherfucker',
    'motherfuckers',
    'son of a bitch',
    'douche',
    'douchebag',
    'douchebags',
    'pissed off',
  ];

  /// List of bad words to filter (Tagalog)
  static const List<String> _tagalogBadWords = [
    'putang',
    'puta',
    'putangina',
    'putang ina',
    'putang inamo',
    'kantot',
    'kantutan',
    'kantotan',
    'titi',
    'tite',
    'titi mo',
    'puki',
    'puke',
    'puki mo',
    'kupal',
    'kupals',
    'gago',
    'gaga',
    'gagi',
    'gago ka',
    'tanga',
    'tangang',
    'tanga ka',
    'bobo',
    'bobong',
    'bobo ka',
    'bobo mo',
    'ulol',
    'ulol ka',
    'uwol',
    'leche',
    'lechero',
    'punyeta',
    'punyemas',
    'pakshet',
    'pakyu',
    'pak yu',
    'buang',
    'buang ka',
    'sira',
    'sira ulo',
    'siraulo',
    'ampota',
    'ampotah',
    'hinayupak',
    'hinayupak ka',
    'lintik',
    'lintik ka',
    'tarantado',
    'tarantado ka',
    'bwisit',
    'bwisit ka',
    'yawa',
    'yawaa',
    'piste',
    'pisteng',
    'animal',
    'animal ka',
    'demonyo',
    'demonyo ka',
    'shit',
    'bullshit',
    'fuck',
    'fucking',
    'asshole',
    'bitch',
    'bastos',
    'bastos ka',
    'pokpok',
    'pokpoks',
    'kantotero',
    'kantoteros',
    'malibog',
    'libog',
    'landi',
    'landiin',
    'malandi',
    'tangina',
    'tang ina',
    'tang inamo',
    'inamo',
    'inana mo',
    'kainmo',
    'kain mo',
    'sayo',
    'sayop',
    'gago',
    'gaga',
    'tanga',
    'tangang',
    'bobo',
    'bobong',
    'ulol',
    'uwol',
    'buang',
    'sira',
    'lintik',
    'yawa',
    'piste',
    'leche',
    'punyeta',
    'pakshet',
    'hinayupak',
    'tarantado',
    'bwisit',
    'ampota',
  ];

  /// Combined list of all bad words
  static final List<String> _allBadWords = [
    ..._englishBadWords,
    ..._tagalogBadWords,
  ];

  /// Trie node for efficient word matching
  static late final TrieNode _rootTrie;

  /// Initialize the trie
  static void _initializeTrie() {
    _rootTrie = TrieNode();
    for (final word in _allBadWords) {
      _insertWord(word.toLowerCase());
    }
  }

  /// Insert a word into the trie
  static void _insertWord(String word) {
    TrieNode node = _rootTrie;
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      if (!node.children.containsKey(char)) {
        node.children[char] = TrieNode();
      }
      node = node.children[char]!;
    }
    node.isEndOfWord = true;
  }

  /// Check if a word is in the trie
  static bool _isBadWord(String word) {
    TrieNode node = _rootTrie;
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      if (!node.children.containsKey(char)) {
        return false;
      }
      node = node.children[char]!;
    }
    return node.isEndOfWord;
  }

  /// Filter text by replacing bad words with asterisks
  /// Returns the filtered text
  static String filterText(String text) {
    if (_allBadWords.isEmpty) {
      _initializeTrie();
    }

    if (text.isEmpty) return text;

    final words = text.split(RegExp(r'\s+'));
    final filteredWords = <String>[];

    for (final word in words) {
      final cleanWord = _removeSpecialChars(word.toLowerCase());
      if (_isBadWord(cleanWord)) {
        // Replace with asterisks of same length
        filteredWords.add('*' * word.length);
      } else {
        filteredWords.add(word);
      }
    }

    return filteredWords.join(' ');
  }

  /// Remove special characters from a word for matching
  static String _removeSpecialChars(String word) {
    return word.replaceAll(RegExp(r'[^\w]'), '');
  }

  /// Check if text contains bad words
  /// Returns true if any bad word is found
  static bool containsBadWords(String text) {
    if (_allBadWords.isEmpty) {
      _initializeTrie();
    }

    if (text.isEmpty) return false;

    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      final cleanWord = _removeSpecialChars(word.toLowerCase());
      if (_isBadWord(cleanWord)) {
        return true;
      }
    }
    return false;
  }

  /// Get the list of bad words found in text
  /// Returns a list of bad words found
  static List<String> getBadWordsInText(String text) {
    if (_allBadWords.isEmpty) {
      _initializeTrie();
    }

    final badWords = <String>[];
    if (text.isEmpty) return badWords;

    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      final cleanWord = _removeSpecialChars(word.toLowerCase());
      if (_isBadWord(cleanWord)) {
        badWords.add(cleanWord);
      }
    }
    return badWords;
  }
}

/// Trie node class for efficient word matching
class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
}
