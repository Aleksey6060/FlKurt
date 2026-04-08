import '../models/game_model.dart';

abstract class CatalogRemoteDataSource {
  Future<List<GameModel>> getGames({String? genre, String? sortBy});
  Future<List<GameModel>> getFeaturedGames();
  Future<List<GameModel>> searchGames(String query);
  Future<GameModel> getGameById(String id);
  Future<void> seedGamesIfNeeded();
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  CatalogRemoteDataSourceImpl();

  List<GameModel> get _localGames => _sampleGames().map((data) {
        return GameModel(
          id: data['id'] as String,
          title: data['title'] as String,
          description: data['description'] as String,
          price: (data['price'] as num).toDouble(),
          genre: data['genre'] as String,
          rating: (data['rating'] as num).toDouble(),
          imageUrl: data['imageUrl'] as String,
          screenshots: List<String>.from(data['screenshots'] as List),
          publisher: data['publisher'] as String,
          releaseDate: data['releaseDate'] as DateTime,
          isNew: data['isNew'] as bool,
          isFeatured: data['isFeatured'] as bool,
        );
      }).toList();

  @override
  Future<List<GameModel>> getGames({String? genre, String? sortBy}) async {
    var games = _localGames;

    if (genre != null && genre.isNotEmpty) {
      games = games.where((g) => g.genre == genre).toList();
    }

    switch (sortBy) {
      case 'price_asc':
        games.sort((a, b) => a.price.compareTo(b.price));
      case 'price_desc':
        games.sort((a, b) => b.price.compareTo(a.price));
      case 'rating':
        games.sort((a, b) => b.rating.compareTo(a.rating));
      case 'newest':
        games.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      default:
        games.sort((a, b) => b.isFeatured ? 1 : -1);
    }
    return games;
  }

  @override
  Future<List<GameModel>> getFeaturedGames() async {
    return _localGames.where((g) => g.isFeatured).take(5).toList();
  }

  @override
  Future<List<GameModel>> searchGames(String query) async {
    final lower = query.toLowerCase();
    return _localGames
        .where(
          (g) =>
              g.title.toLowerCase().contains(lower) ||
              g.genre.toLowerCase().contains(lower) ||
              g.publisher.toLowerCase().contains(lower),
        )
        .toList();
  }

  @override
  Future<GameModel> getGameById(String id) async {
    final game = _localGames.firstWhere(
      (g) => g.id == id,
      orElse: () => throw Exception('Товар не найден'),
    );
    return game;
  }

  @override
  Future<void> seedGamesIfNeeded() async {}

  List<Map<String, dynamic>> _sampleGames() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'title': 'Беговая дорожка ProForm',
        'description':
            'Профессиональная беговая дорожка с интерактивным дисплеем, '
                'системой амортизации ProShox и мощным двигателем 3.5 л.с.',
        'price': 85000.0,
        'genre': 'Кардио',
        'rating': 4.9,
        'imageUrl': 'local:treadmill',
        'screenshots': [
          'local:treadmill_1',
          'local:treadmill_2',
        ],
        'publisher': 'ProForm',
        'releaseDate': now.subtract(const Duration(days: 15)),
        'isNew': true,
        'isFeatured': true,
      },
      {
        'id': '2',
        'title': 'Набор разборных гантелей',
        'description':
            'Премиальный набор гантелей с регулируемым весом от 2 до 24 кг. '
                'Компактная система хранения и эргономичные рукоятки.',
        'price': 15000.0,
        'genre': 'Силовые',
        'rating': 5.0,
        'imageUrl': 'local:dumbbells',
        'screenshots': [
          'local:dumbbells_1',
          'local:dumbbells_2',
        ],
        'publisher': 'Iron Strength',
        'releaseDate': now.subtract(const Duration(days: 10)),
        'isNew': true,
        'isFeatured': true,
      },
      {
        'id': '3',
        'title': 'Коврик для йоги Premium',
        'description': 'Профессиональный коврик из натурального каучука. '
            'Антискользящее покрытие, отличная амортизация и долговечность.',
        'price': 4500.0,
        'genre': 'Йога',
        'rating': 4.9,
        'imageUrl': 'local:yoga_mat',
        'screenshots': [
          'local:yoga_mat_1',
          'local:yoga_mat_2',
        ],
        'publisher': 'Yoga Master',
        'releaseDate': now.subtract(const Duration(days: 80)),
        'isNew': false,
        'isFeatured': true,
      },
      {
        'id': '4',
        'title': 'Боксерский мешок Everlast',
        'description': 'Тяжелый боксерский мешок из высококачественной кожи. '
            'Усиленные швы и система крепления в комплекте.',
        'price': 12000.0,
        'genre': 'Бокс',
        'rating': 5.0,
        'imageUrl': 'local:boxing_bag',
        'screenshots': [
          'local:boxing_bag_1',
          'local:boxing_bag_2',
        ],
        'publisher': 'Everlast',
        'releaseDate': now.subtract(const Duration(days: 5)),
        'isNew': true,
        'isFeatured': true,
      },
      {
        'id': '5',
        'title': 'Велотренажер Spin Bike',
        'description':
            'Современный спин-байк с магнитной системой сопротивления. '
                'Бесшумная работа и полная настройка под пользователя.',
        'price': 42000.0,
        'genre': 'Кардио',
        'rating': 4.8,
        'imageUrl': 'local:spin_bike',
        'screenshots': [
          'local:spin_bike_1',
          'local:spin_bike_2',
        ],
        'publisher': 'CyclePro',
        'releaseDate': now.subtract(const Duration(days: 40)),
        'isNew': false,
        'isFeatured': false,
      },
      {
        'id': '6',
        'title': 'Теннисная ракетка Wilson',
        'description':
            'Профессиональная ракетка для тенниса. Оптимальный баланс '
                'контроля и мощности. Выбор чемпионов.',
        'price': 18000.0,
        'genre': 'Теннис',
        'rating': 4.7,
        'imageUrl': 'local:tennis_racket',
        'screenshots': [
          'local:tennis_racket_1',
          'local:tennis_racket_2',
        ],
        'publisher': 'Wilson',
        'releaseDate': now.subtract(const Duration(days: 60)),
        'isNew': false,
        'isFeatured': false,
      },
    ];
  }
}
