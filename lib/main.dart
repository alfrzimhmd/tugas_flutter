// Import library eksternal yang digunakan dalam aplikasi
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Fungsi utama aplikasi
void main() {
  runApp(const MyApp());
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Provider digunakan untuk menyediakan state global (MyAppState)
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

// State utama aplikasi
class MyAppState extends ChangeNotifier {
  // Kata saat ini (WordPair) yang sedang ditampilkan
  var current = WordPair.random();

  // Riwayat kata yang pernah ditampilkan
  var history = <WordPair>[];

  // Kunci global untuk AnimatedList (riwayat)
  GlobalKey? historyListKey;

  // Mengambil kata baru dan menambahkan kata lama ke daftar riwayat.
  void getNext() {
    history.insert(0, current);
    // Menambahkan animasi ke daftar riwayat
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    // Ganti kata saat ini dengan yang baru
    current = WordPair.random();
    notifyListeners(); // Memberi tahu UI agar diperbarui
  }

  // Daftar kata favorit pengguna
  var favorites = <WordPair>[];

  // Menambah atau menghapus kata dari daftar favorit
  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  // Menghapus kata dari daftar favorit
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

// Halaman utama dengan navigasi
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Indeks tab yang sedang aktif (0 = Home, 1 = Favorites)
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Tentukan halaman yang aktif berdasarkan selectedIndex
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = _GeneratorPage(); // Halaman generator kata
        break;
      case 1:
        page = const FavoritesPage(); // Halaman favorit
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // LayoutBuilder digunakan agar tampilan responsif di berbagai ukuran layar
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Namer App',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 4,
        ),
        body: Row(
          children: [
            // NavigationRail di sisi kiri
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            // Konten halaman aktif di sisi kanan
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Halaman Generator Kata
class _GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    // Tentukan ikon favorit
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(), // Tampilkan riwayat kata
          ),
          const SizedBox(height: 10),
          BigCard(pair: pair), // Tampilkan kata besar saat ini
          const SizedBox(height: 10),
          // Tombol Like dan Next
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: const Text('Like'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: const Text('Next'),
              ),
            ],
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}


// Widget kartu besar (kata utama)
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary);

    return Card(
      color: theme.colorScheme.primary,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}", // Aksesibilitas
        ),
      ),
    );
  }
}


// Halaman daftar favorit
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    // Jika tidak ada favorit
    if (appState.favorites.isEmpty) {
      return const Center(
        child: Text('No favorites yet.'),
      );
    }

    // Jika ada favorit
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text('You have ${appState.favorites.length} favorites:'),
        ),
        Expanded(
          child: GridView(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}


// Widget riwayat kata (AnimatedList)
class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  // Kunci unik untuk AnimatedList
  final _key = GlobalKey<AnimatedListState>();

  // Gradien untuk efek transparansi di bagian atas daftar
  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn, // Gunakan blending agar gradasi terlihat
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: const EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          final isFavorite = appState.favorites.contains(pair);

          return FadeTransition(
            opacity: animation.drive(
              Tween<double>(begin: 0, end: 1)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      appState.toggleFavorite(pair);
                    },
                    icon: isFavorite
                        ? const Icon(Icons.favorite, color: Colors.pink, size: 14)
                        : const SizedBox(),
                    label: Text(
                      pair.asLowerCase,
                      style: TextStyle(
                        color: isFavorite
                            ? Colors.pink.shade400
                            : Colors.grey.shade800,
                        fontWeight:
                        isFavorite ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
