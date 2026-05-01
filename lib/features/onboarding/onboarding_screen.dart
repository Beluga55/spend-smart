import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/features/home_screen.dart';
import 'package:mobile_expense_tracker/features/settings/currency_modal.dart';
import 'package:mobile_expense_tracker/features/settings/language_modal.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _isSigningIn = false;

  void _complete() {
    Hive.box('settings').put('onboardingComplete', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _next() {
    if (_page == 3) {
      _complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildWelcomePage(theme, primary),
                  _buildFeaturesPage(theme, primary),
                  _buildSetupPage(theme, primary),
                  _buildSignInPage(theme, primary),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _complete,
                    child: Text('Skip', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153))),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(4, (i) => Container(
                      width: i == _page ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _page ? primary : primary.withAlpha(77),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_page == 3 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 1: Welcome
  Widget _buildWelcomePage(ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: primary),
          const SizedBox(height: 24),
          Text(
            'Expense Tracker',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Track smarter, save better',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: Features
  Widget _buildFeaturesPage(ThemeData theme, Color primary) {
    const features = [
      (Icons.receipt_long, 'Track Expenses', 'Log daily spending with categories'),
      (Icons.account_balance_wallet, 'Set Budgets', 'Stay on top of monthly limits'),
      (Icons.savings, 'Saving Goals', 'Save towards what matters most'),
      (Icons.cloud_sync, 'Cloud Sync', 'Back up and access data anywhere'),
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('What you can do', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f.$1, color: primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(f.$3, style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Page 3: Currency & Language
  Widget _buildSetupPage(ThemeData theme, Color primary) {
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);
    final langName = locale.languageCode == 'zh' ? 'Chinese' : 'English';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Set up your preferences', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _settingsTile(
            theme: theme,
            icon: Icons.attach_money,
            title: 'Currency',
            subtitle: '${currency.name} (${currency.code})',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SizedBox(height: 500, child: CurrencyModal()),
            ),
          ),
          const SizedBox(height: 12),
          _settingsTile(
            theme: theme,
            icon: Icons.language,
            title: 'Language',
            subtitle: langName,
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (_) => const LanguageModal(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withAlpha(153)),
          ],
        ),
      ),
    );
  }

  // Page 4: Sign In
  Widget _buildSignInPage(ThemeData theme, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_done_outlined, size: 64, color: primary),
          const SizedBox(height: 24),
          Text('Sign in with Google', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            'Back up and sync your data across devices',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSigningIn ? null : _handleGoogleSignIn,
              icon: _isSigningIn
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.g_mobiledata, size: 24),
              label: Text(_isSigningIn ? 'Signing in...' : 'Sign in with Google'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isSigningIn ? null : _complete,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      await SupabaseService.signInWithGoogle();
      if (mounted) _complete();
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }
}
