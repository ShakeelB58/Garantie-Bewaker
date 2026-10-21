import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../settings/application/settings_providers.dart';

/// Of het welkomstscherm al is gezien.
final onboardingDoneProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends AsyncNotifier<bool> {
  static const key = 'onboarding_done';

  @override
  Future<bool> build() async =>
      await ref.watch(settingsRepositoryProvider).read(key) == 'true';

  Future<void> complete() async {
    state = const AsyncData(true);
    await ref.read(settingsRepositoryProvider).write(key, 'true');
  }
}

/// Eerste scherm bij het openen van de app.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.lg * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      const Icon(
                        Icons.verified_user,
                        size: 72,
                        color: AppColors.teal,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        header: true,
                        label: 'Bonvrij',
                        child: ExcludeSemantics(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Bon'),
                                TextSpan(
                                  text: 'vrij',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Al je aankopen, garanties en documenten op één plek.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: _Illustration(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Point(
                        icon: Icons.lock_outline,
                        text:
                            'Alles blijft op je telefoon. Geen account nodig.',
                      ),
                      const _Point(
                        icon: Icons.document_scanner_outlined,
                        text: 'Scan een bon of importeer een factuur.',
                      ),
                      const _Point(
                        icon: Icons.notifications_none,
                        text:
                            'Krijg een herinnering op de datum die jij kiest.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('welcome.start'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: () => ref
                            .read(onboardingDoneProvider.notifier)
                            .complete(),
                        child: const Text('Aan de slag'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Eenvoudige illustratie: een bon met een schild ervoor.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 180,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 130,
              decoration: const BoxDecoration(
                color: AppColors.tealContainer,
                shape: BoxShape.circle,
              ),
            ),
            Positioned(
              left: 30,
              top: 10,
              child: Container(
                width: 80,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 44,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: 8,
              child: Container(
                width: 64,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
