import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/products/presentation/add_purchase_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell_scaffold.dart';

/// Centrale routenamen, zodat schermen niet met losse strings werken.
abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const settings = '/settings';
  static const addPurchase = '/add-purchase';
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
      // Buiten de shell: volledig scherm zonder onderste navigatiebalk.
      GoRoute(
        path: AppRoutes.addPurchase,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddPurchaseScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
