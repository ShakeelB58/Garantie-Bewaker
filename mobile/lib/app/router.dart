import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/products/presentation/add_purchase_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/products/presentation/product_form_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell_scaffold.dart';

/// Centrale routes, zodat schermen niet met losse strings werken.
abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const settings = '/settings';
  static const addPurchase = '/add-purchase';
  static const newProduct = '/product/new';

  static String productDetail(String id) => '/product/$id';
  static String editProduct(String id) => '/product/$id/edit';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, state) => const ProductsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Buiten de shell: volledige schermen zonder onderste navigatiebalk.
      GoRoute(
        path: AppRoutes.addPurchase,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddPurchaseScreen(),
      ),
      // Let op: '/product/new' moet vóór '/product/:id' staan.
      GoRoute(
        path: AppRoutes.newProduct,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) =>
                ProductFormScreen(productId: state.pathParameters['id']),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
