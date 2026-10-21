import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../application/product_providers.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_query.dart';
import 'widgets/product_card.dart';

/// Productoverzicht met zoeken, filteren op categorie en sorteren.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(productQueryProvider).searchText,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(productQueryProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Producten'),
        actions: [
          PopupMenuButton<ProductSort>(
            tooltip: 'Sorteren',
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: ref.read(productQueryProvider.notifier).setSort,
            itemBuilder: (context) => [
              for (final sort in ProductSort.values)
                CheckedPopupMenuItem(
                  value: sort,
                  checked: sort == query.sort,
                  child: Text(sort.label),
                ),
            ],
          ),
        ],
      ),
      body: allProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (products) => products.isEmpty
            ? EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Geen producten',
                message: 'Producten die je toevoegt, verschijnen hier.',
                actionLabel: 'Aankoop toevoegen',
                onAction: () => context.push(AppRoutes.addPurchase),
              )
            : _ProductList(
                products: products,
                query: query,
                searchController: _search,
                onClearFilters: _clearFilters,
              ),
      ),
      floatingActionButton: AddFab(
        heroTag: 'fab-products',
        label: 'Toevoegen',
        onPressed: () => context.push(AppRoutes.addPurchase),
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  const _ProductList({
    required this.products,
    required this.query,
    required this.searchController,
    required this.onClearFilters,
  });

  final List<Product> products;
  final ProductQuery query;
  final TextEditingController searchController;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productQueryProvider.notifier);
    final visible = query.apply(products);
    final usedCategories = ProductCategory.values
        .where((c) => products.any((p) => p.category == c))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: TextField(
            key: const Key('products.search'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Zoek op product, merk of winkel',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.searchText.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Zoekopdracht wissen',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        notifier.setSearchText('');
                      },
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onChanged: notifier.setSearchText,
          ),
        ),
        if (usedCategories.length > 1)
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: const Text('Alle'),
                    selected: query.category == null,
                    onSelected: (_) => notifier.setCategory(null),
                  ),
                ),
                for (final category in usedCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(category.label),
                      selected: query.category == category,
                      onSelected: (selected) =>
                          notifier.setCategory(selected ? category : null),
                    ),
                  ),
              ],
            ),
          )
        else
          const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'Geen producten gevonden',
                  message: 'Probeer een andere zoekterm of categorie.',
                  actionLabel: 'Filters wissen',
                  actionIcon: Icons.filter_alt_off_outlined,
                  onAction: onClearFilters,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    96,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final product = visible[index];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          context.push(AppRoutes.productDetail(product.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
