import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../wishlist/presentation/cubit/wishlist_cubit.dart';
import '../../../wishlist/presentation/cubit/wishlist_state.dart';
import '../../domain/entities/game_entity.dart';

class ProductCard extends StatelessWidget {
  final GameEntity product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userId = _getUserId(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'product_image_${product.id}',
                        child: product.imageUrl.startsWith('local:')
                            ? _LocalProductArt(
                                title: product.title,
                                genre: product.genre,
                              )
                            : CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.shimmerBase,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => _LocalProductArt(
                                  title: product.title,
                                  genre: product.genre,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            if (product.isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: BlocBuilder<WishlistCubit, WishlistState>(
                          builder: (context, state) {
                            final inWishlist = state is WishlistLoaded &&
                                state.contains(product.id);
                            return IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Icon(
                                  inWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: inWishlist
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              onPressed: () {
                                if (userId.isEmpty) {
                                  AppSnackBar.showInfo(
                                    context,
                                    'Войдите, чтобы добавить в избранное',
                                  );
                                  return;
                                }
                                context
                                    .read<WishlistCubit>()
                                    .toggleWishlist(userId, product);
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
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          product.genre,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.publisher,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.starColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            product.formattedPrice,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, cartState) {
                          final inCart = cartState is CartLoaded &&
                              cartState.containsGame(product.id);
                          return SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: () {
                                if (userId.isEmpty) {
                                  AppSnackBar.showError(
                                    context,
                                    'Войдите, чтобы добавить в корзину',
                                  );
                                  return;
                                }
                                if (inCart) {
                                  context.go('/cart');
                                  return;
                                }
                                context.read<CartBloc>().add(
                                      CartAddGame(
                                          userId: userId, game: product),
                                    );
                                NotificationService.instance
                                    .showCartNotification(product.title);
                                AppSnackBar.showSuccess(
                                  context,
                                  'Добавлено в корзину',
                                );
                              },
                              icon: Icon(
                                inCart
                                    ? Icons.check_circle_rounded
                                    : Icons.add_shopping_cart_rounded,
                                size: 18,
                              ),
                              label: Text(inCart ? 'В корзине' : 'В корзину'),
                              style: FilledButton.styleFrom(
                                backgroundColor: inCart
                                    ? AppColors.primary
                                    : AppColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserId(BuildContext context) {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated ? s.user.id : '';
  }
}

class _LocalProductArt extends StatelessWidget {
  final String title;
  final String genre;

  const _LocalProductArt({
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
              size: 64,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
