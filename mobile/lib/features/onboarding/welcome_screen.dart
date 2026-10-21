import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/bonvrij_logo.dart';
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
      backgroundColor: AppColors.surface,
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
                      const SizedBox(height: AppSpacing.xl * 1.5),
                      const BonvrijLogo(size: 84),
                      const SizedBox(height: AppSpacing.lg),
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
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 4),
                      Text(
                        'Al je aankopen, garanties\nen documenten op één plek.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: _Illustration(),
                  ),
                  FilledButton(
                    key: const Key('welcome.start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () =>
                        ref.read(onboardingDoneProvider.notifier).complete(),
                    child: const Text('Aan de slag'),
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

/// Illustratie zoals in het ontwerp: documenten met een schild ervoor op
/// een lichte, ronde achtergrond.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 240,
        height: 190,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              right: 10,
              top: 20,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.tealContainer,
                  borderRadius: BorderRadius.all(Radius.elliptical(120, 90)),
                ),
              ),
            ),
            Positioned(
              left: 36,
              top: 8,
              child: Transform.rotate(
                angle: -0.12,
                child: const _Paper(width: 96, height: 122),
              ),
            ),
            const Positioned(
              left: 70,
              top: 26,
              child: _Paper(width: 96, height: 122),
            ),
            Positioned(
              right: 30,
              bottom: 14,
              child: Container(
                width: 92,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const BonvrijLogo(
                  size: 54,
                  color: Colors.white,
                  checkColor: AppColors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in const [0.6, 0.9, 0.75, 0.9, 0.5])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: f,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
