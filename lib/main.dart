import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'models/clinical_trial.dart';
import 'providers/auth_provider.dart';
import 'providers/trials_provider.dart';
import 'screens/api_key_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/trial_detail_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';

final _authProvider = AuthProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _authProvider.init();
  runApp(const ClinicalSharkApp());
}

final _router = GoRouter(
  refreshListenable: _authProvider,
  redirect: (context, state) {
    final loggedIn = _authProvider.isLoggedIn;
    final path = state.uri.path;
    final onAuth = path == '/auth';
    final onSetup = path == '/profile/setup';

    if (!loggedIn && !onAuth) return '/auth';
    if (loggedIn && onAuth) return '/';
    if (loggedIn && !onSetup) {
      final profile = _authProvider.profile;
      if (profile != null && !profile.profileComplete) return '/profile/setup';
    }
    return null;
  },
  routes: [
    // Auth — no shell
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    // Profile setup wizard — no shell
    GoRoute(
      path: '/profile/setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    // Detail / utility screens — no shell (no bottom nav)
    GoRoute(
      path: '/search',
      builder: (_, state) => SearchResultsScreen(
        query: state.uri.queryParameters['q'] ?? '',
        status: state.uri.queryParameters['status'],
        phase: state.uri.queryParameters['phase'],
      ),
    ),
    GoRoute(
      path: '/trial/:nctId',
      builder: (_, state) =>
          TrialDetailScreen(nctId: state.pathParameters['nctId']!),
    ),
    GoRoute(
      path: '/chat',
      builder: (_, state) =>
          ChatScreen(trial: state.extra as ClinicalTrial?),
    ),
    GoRoute(
      path: '/setup-api-key',
      builder: (_, state) => ApiKeyScreen(
        returnPath: '/chat',
        returnExtra: state.extra as ClinicalTrial?,
      ),
    ),
    // Main tabs — wrapped in bottom-nav shell
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/matches',
          builder: (context, state) => const MatchesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class ClinicalSharkApp extends StatelessWidget {
  const ClinicalSharkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => TrialsProvider()),
      ],
      child: MaterialApp.router(
        title: 'ClinicalShark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
