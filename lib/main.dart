import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrthodoxMezmurApp());
}

class Song {
  final String id;
  final String title;
  final String lyrics;
  final String category;
  final String singer;
  final String keywords;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    required this.category,
    this.singer = '',
    this.keywords = '',
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lyrics': lyrics,
      'category': category,
      'singer': singer,
      'keywords': keywords,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      lyrics: map['lyrics'],
      category: map['category'],
      singer: map['singer'] ?? '',
      keywords: map['keywords'] ?? '',
      isFavorite: map['isFavorite'] == 1,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('orthodox_mezmur.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        lyrics TEXT NOT NULL,
        category TEXT NOT NULL,
        singer TEXT,
        keywords TEXT,
        isFavorite INTEGER NOT NULL
      )
    ''');

    await db.insert('songs', Song(
      id: '1',
      title: 'ሰማይና ምድር',
      lyrics: 'ሰማይና ምድር የማይወሰኑህ\nበድንግል ማህፀን እንዴት ተወሰንክ\n\nድንቅ ነው አምላኬ የነገሩህ ነገር\nለሰው ልጅ ፍቅር ሲል የወረደው ከሰማይ',
      category: 'የምስጋና መዝሙራት',
      singer: 'ሊቀ መዘምራን ቴዎድሮስ ዮሴፍ',
      keywords: 'ሰማይ, ምድር, ድንግል',
    ).toMap());

    await db.insert('songs', Song(
      id: '2',
      title: 'የህይወቴ መንገድ',
      lyrics: 'የህይወቴ መንገድ አንተው ነህ አምላኬ\nበጨለማው አለም ብርሃን የሆንከው',
      category: 'የንስሐ መዝሙራት',
      singer: 'ሊቀ መዘምራን ይልማ ኃይሉ',
      keywords: 'ህይወት, መንገድ',
    ).toMap());
  }

  Future<List<Song>> getAllSongs() async {
    final db = await instance.database;
    final result = await db.query('songs');
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<int> insertSong(Song song) async {
    final db = await instance.database;
    return await db.insert('songs', song.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSongFavorite(String id, bool isFavorite) async {
    final db = await instance.database;
    return await db.update(
      'songs',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class OrthodoxMezmurApp extends StatefulWidget {
  const OrthodoxMezmurApp({super.key});

  @override
  State<OrthodoxMezmurApp> createState() => _OrthodoxMezmurAppState();
}

class _OrthodoxMezmurAppState extends State<OrthodoxMezmurApp> {
  List<Song> _globalSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await DatabaseHelper.instance.getAllSongs();
    setState(() {
      _globalSongs = songs;
      _isLoading = false;
    });
  }

  Future<void> _addSong(Song song) async {
    await DatabaseHelper.instance.insertSong(song);
    _loadSongs();
  }

  Future<void> _toggleFavorite(Song song) async {
    final newStatus = !song.isFavorite;
    await DatabaseHelper.instance.updateSongFavorite(song.id, newStatus);
    _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ኦርቶዶክሳዊ መዝሙራት',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10141D),
        primaryColor: const Color(0xFF1E2538),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161C2A),
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: MainNavigationScreen(
        songs: _globalSongs,
        onAddSong: _addSong,
        onToggleFavorite: _toggleFavorite,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final List<Song> songs;
  final Function(Song) onAddSong;
  final Function(Song) onToggleFavorite;

  const MainNavigationScreen({
    super.key,
    required this.songs,
    required this.onAddSong,
    required this.onToggleFavorite,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      SingersScreen(songs: widget.songs),
      FavoritesScreen(songs: widget.songs, onToggleFavorite: widget.onToggleFavorite),
      HomeScreen(songs: widget.songs, onToggleFavorite: widget.onToggleFavorite),
      SubmitSongScreen(onAddSong: widget.onAddSong),
      const InfoGuideScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF161C2A),
        selectedItemColor: const Color(0xFFE5C158),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'ዘማሪያን'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'የተመረጡ'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE5C158),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.grid_view, color: Colors.black),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'ያበርክቱ'),
          const BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'መረጃ'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Song> songs;
  final Function(Song) onToggleFavorite;

  const HomeScreen({super.key, required this.songs, required this.onToggleFavorite});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> categories = const [
    {"title": "የሰንበት ት/ቤት መዝሙራት"},
    {"title": "የምስጋና መዝሙራት"},
    {"title": "የመላእክት መዝሙራት"},
    {"title": "የልደት በዓል መዝሙራት"},
    {"title": "የጥምቀት በዓል መዝሙራት"},
    {"title": "የጽጌ መዝሙራት"},
    {"title": "የሠርግ መዝሙራት"},
    {"title": "የእመቤታችን ማርያም መዝሙራት"},
    {"title": "የቅድስት ሥላሴ መዝሙራት"},
    {"title": "የንስሐ መዝሙራት"},
    {"title": "ወረብ"},
    {"title": "ሌሎች መዝሙራት"},
  ];

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredSongs = widget.songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.singer.toLowerCase().contains(query) ||
          song.category.toLowerCase().contains(query) ||
          song.keywords.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("ኦርቶዶክሳዊ መዝሙራት", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 2),
            Text('"እግዚአብሔርን አመስግኑ፤ መዝሙር መልካም ነውና"', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "በታግ (Tags)፣ በርዕስ ወይም በዘማሪ ይፈልጉ...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Color(0xFFE5C158)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return ListTile(
                        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${song.singer} • ${song.category}"),
                        trailing: IconButton(
                          icon: Icon(
                            song.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: song.isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => widget.onToggleFavorite(song),
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailView(song: song)));
                        },
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return GestureDetector(
                        onTap: () {
                          final categorySongs = widget.songs.where((s) => s.category == cat["title"]).toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategorySongsScreen(title: cat["title"]!, songs: categorySongs),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF181F2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_note, size: 40, color: Color(0xFFE5C158)),
                              const SizedBox(height: 8),
                              Text(
                                cat["title"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SubmitSongScreen extends StatefulWidget {
  final Function(Song) onAddSong;
  const SubmitSongScreen({super.key, required this.onAddSong});

  @override
  State<SubmitSongScreen> createState() => _SubmitSongScreenState();
}

class _SubmitSongScreenState extends State<SubmitSongScreen> {
  final _titleController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _singerController = TextEditingController();
  final _lyricsController = TextEditingController();
  String _selectedCategory = 'የሰንበት ት/ቤት መዝሙራት';

  void _submit() {
    if (_titleController.text.isEmpty || _lyricsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("እባክዎን የመዝሙሩን ርዕስ እና ግጥም ያስገቡ!"), backgroundColor: Colors.red),
      );
      return;
    }

    final newSong = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      keywords: _keywordsController.text,
      singer: _singerController.text,
      category: _selectedCategory,
      lyrics: _lyricsController.text,
    );

    widget.onAddSong(newSong);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("መዝሙሩ በስኬት ተመዝግቧል!"), backgroundColor: Colors.green),
    );

    _titleController.clear();
    _keywordsController.clear();
    _singerController.clear();
    _lyricsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("መዝሙር ያበርክቱ")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "የመዝሙሩ ርዕስ *")),
            const SizedBox(height: 10),
            TextField(controller: _keywordsController, decoration: const InputDecoration(labelText: "ገላጭ ቃላት/ስሞች")),
            const SizedBox(height: 10),
            TextField(controller: _singerController, decoration: const InputDecoration(labelText: "ዘማሪ")),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['የሰንበት ት/ቤት መዝሙራት', 'የምስጋና መዝሙራት', 'የንስሐ መዝሙራት', 'ሌሎች መዝሙራት']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: const InputDecoration(labelText: "ምድብ"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lyricsController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "የመዝሙሩ ግጥም / አዝማች *", alignLabelWithHint: true),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5C158)),
                onPressed: _submit,
                child: const Text("ያበርክቱ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Song> songs;
  final Function(Song) onToggleFavorite;

  const FavoritesScreen({super.key, required this.songs, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final favSongs = songs.where((s) => s.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("የተመረጡ መዝሙራት")),
      body: favSongs.isEmpty
          ? const Center(child: Text("ምንም የተመረጠ መዝሙር አልተገኘም።"))
          : ListView.builder(
              itemCount: favSongs.length,
              itemBuilder: (context, index) {
                final song = favSongs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.singer),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailView(song: song)));
                  },
                );
              },
            ),
    );
  }
}

class CategorySongsScreen extends StatelessWidget {
  final String title;
  final List<Song> songs;

  const CategorySongsScreen({super.key, required this.title, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: songs.isEmpty
          ? const Center(child: Text("በዚህ ምድብ ምንም መዝሙር አልተገኘም።"))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.singer),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailView(song: song)));
                  },
                );
              },
            ),
    );
  }
}

class SongDetailView extends StatelessWidget {
  final Song song;
  const SongDetailView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ዘማሪ፦ ${song.singer.isEmpty ? 'አልተጠቀሰም' : song.singer}",
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(song.lyrics, style: const TextStyle(fontSize: 18, height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SingersScreen extends StatelessWidget {
  final List<Song> songs;
  const SingersScreen({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("የዘማሪያን መዝሙራት")),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(song.singer.isEmpty ? 'ያልታወቀ ዘማሪ' : song.singer),
            subtitle: Text(song.title),
          );
        },
      ),
    );
  }
}

class InfoGuideScreen extends StatelessWidget {
  const InfoGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("የአጠቃቀም መመሪያ")),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "በመተግበሪያው የመዝሙር ግጥሞችን ማሰስ፣ በፍለጋ ሳጥኑ መፈለግ፣ አዲስ መዝሙር ማበርከት እና ወደተመረጡ ማከማቸት ይችላሉ።",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
