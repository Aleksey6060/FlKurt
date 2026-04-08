import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../wishlist/presentation/cubit/wishlist_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/repositories/catalog_repository.dart';

class GameDetailPage extends StatefulWidget {
  final String gameId;
  const GameDetailPage({super.key, required this.gameId});

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage>
    with SingleTickerProviderStateMixin {
  GameEntity? _game;
  bool _isLoading = true;
  String? _error;
  int _currentScreenshot = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
      final repo = sl<CatalogRepository>();
      final result = await repo.getGameById(widget.gameId);
      result.fold(
        (f) => setState(() {
          _error = f.message;
          _isLoading = false;
        }),
        (game) {
          setState(() {
            _game = game;
            _isLoading = false;
          });
          _animController.forward();
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _userId {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated ? s.user.id : '';
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _game != null
                  ? _buildContent()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
            expandedHeight: 320, flexibleSpace: FlexibleSpaceBar()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ShimmerLoading(width: double.infinity, height: 32),
                const SizedBox(height: 12),
                const ShimmerLoading(width: 150, height: 20),
                const SizedBox(height: 16),
                const ShimmerLoading(width: double.infinity, height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error ?? 'Ошибка загрузки'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadGame();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final game = _game!;
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(game),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(game),
                  const SizedBox(height: 16),
                  _buildMetaRow(game),
                  const SizedBox(height: 20),
                  if (game.screenshots.isNotEmpty) _buildScreenshots(game),
                  const SizedBox(height: 20),
                  Text(
                    'О товаре',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.8,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoTable(game),
                  const SizedBox(height: 32),
                  _buildActionButtons(game, formatter),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(GameEntity game) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: AppColors.primaryDark,
          ),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        BlocBuilder<WishlistCubit, WishlistState>(
          builder: (context, state) {
            final inWishlist =
                state is WishlistLoaded && state.contains(game.id);
            return IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(
                  inWishlist ? Icons.favorite : Icons.favorite_outline,
                  color: inWishlist ? Colors.red : AppColors.primaryDark,
                  size: 20,
                ),
              ),
              onPressed: () {
                if (_userId.isEmpty) return;
                final inWishlist =
                    state is WishlistLoaded && state.contains(game.id);
                context.read<WishlistCubit>().toggleWishlist(_userId, game);
                AppSnackBar.showInfo(
                  context,
                  !inWishlist
                      ? 'Добавлено в избранное'
                      : 'Удалено из избранного',
                );
              },
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_image_${game.id}',
          child: game.imageUrl.startsWith('local:')
              ? _LocalProductHeroArt(title: game.title, genre: game.genre)
              : CachedNetworkImage(
                  imageUrl: game.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _LocalProductHeroArt(
                      title: game.title, genre: game.genre),
                ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(GameEntity game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      game.genre.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.publisher,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
            if (game.isNew)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRow(GameEntity game) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetaItem(Icons.star, 'Рейтинг', '${game.rating}/5.0',
              color: AppColors.starColor),
          _buildVerticalDivider(),
          _buildMetaItem(Icons.category_rounded, 'Категория', game.genre),
          _buildVerticalDivider(),
          _buildMetaItem(Icons.verified_rounded, 'Бренд', game.publisher),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 35,
      width: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.textHint, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshots(GameEntity game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Фотографии',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${_currentScreenshot + 1} / ${game.screenshots.length}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: game.screenshots.length,
            onPageChanged: (i) => setState(() => _currentScreenshot = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: game.screenshots[i].startsWith('local:')
                    ? _LocalProductHeroArt(
                        title: game.title,
                        genre: game.genre,
                      )
                    : CachedNetworkImage(
                        imageUrl: game.screenshots[i],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _LocalProductHeroArt(
                          title: game.title,
                          genre: game.genre,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            game.screenshots.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentScreenshot == i ? 24 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: _currentScreenshot == i
                    ? AppColors.primary
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTable(GameEntity game) {
    final dateFormatter = DateFormat('d MMMM yyyy', 'ru');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Характеристики',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _infoRow('Производитель', game.publisher, isFirst: true),
              _infoRow('Категория', game.genre),
              _infoRow(
                  'Дата поступления', dateFormatter.format(game.releaseDate)),
              _infoRow('Состояние', 'Новое', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value,
      {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(GameEntity game, NumberFormat formatter) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final inCart =
            cartState is CartLoaded && cartState.containsGame(game.id);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ИТОГО',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      formatter.format(game.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: inCart ? 'В КОРЗИНЕ' : 'КУПИТЬ',
                  icon:
                      inCart ? Icons.check_circle : Icons.shopping_bag_outlined,
                  onPressed: () {
                    if (_userId.isEmpty) {
                      AppSnackBar.showError(context, 'Войдите для покупки');
                      return;
                    }
                    if (inCart) {
                      context.go('/cart');
                    } else {
                      context.read<CartBloc>().add(
                            CartAddGame(userId: _userId, game: game),
                          );
                      AppSnackBar.showSuccess(
                        context,
                        '${game.title} добавлена в корзину',
                      );
                      NotificationService.instance
                          .showCartNotification(game.title);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocalProductHeroArt extends StatelessWidget {
  final String title;
  final String genre;

  const _LocalProductHeroArt({
    required this.title,
    required this.genre,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.accent,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              _iconForGenre(genre),
              size: 88,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForGenre(String genre) {
    final g = genre.toLowerCase();
    if (g.contains('кардио')) return Icons.directions_run_rounded;
    if (g.contains('сил')) return Icons.fitness_center_rounded;
    if (g.contains('йог')) return Icons.self_improvement_rounded;
    if (g.contains('бокс')) return Icons.sports_mma_rounded;
    if (g.contains('теннис')) return Icons.sports_tennis_rounded;
    return Icons.sports_rounded;
  }
}
