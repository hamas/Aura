import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../debrid/data/repositories/debrid_repository_impl.dart';
import '../../../debrid/domain/entities/debrid_account.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _rdKeyController = TextEditingController();
  final DebridRepositoryImpl _debridRepo = DebridRepositoryImpl();
  DebridAccount? _debridAccount;
  bool _isLoadingDebrid = false;

  @override
  void initState() {
    super.initState();
    _loadDebridStatus();
  }

  Future<void> _loadDebridStatus() async {
    setState(() => _isLoadingDebrid = true);
    try {
      final hasToken = await _debridRepo.hasValidToken();
      if (hasToken) {
        final account = await _debridRepo.getAccountDetails();
        setState(() {
          _debridAccount = account;
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingDebrid = false);
    }
  }

  Future<void> _saveDebridKey() async {
    final key = _rdKeyController.text.trim();
    if (key.isNotEmpty) {
      await _debridRepo.saveApiToken(key);
      _rdKeyController.clear();
      await _loadDebridStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successAccent,
            content: Text('Real-Debrid API key saved successfully'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _rdKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google Auth Section
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.user;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.surfaceElevated,
                            backgroundImage: user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? const Icon(Icons.person, color: AppTheme.textMuted)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null ? user.displayName : 'Guest User',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user != null ? user.email : 'Sign in to sync library across devices',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: state.isAuthenticated
                            ? OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorAccent,
                                  side: const BorderSide(color: AppTheme.errorAccent),
                                ),
                                onPressed: () =>
                                    context.read<AuthBloc>().add(SignOutEvent()),
                                icon: const Icon(Icons.logout, size: 18),
                                label: const Text('Sign Out'),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => context
                                    .read<AuthBloc>()
                                    .add(SignInWithGoogleEvent()),
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text('Sign In with Google'),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Real-Debrid Integration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: AppTheme.warningAccent),
                      SizedBox(width: 8),
                      Text(
                        'Real-Debrid Integration',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enables unrestricted high-speed HTTPS streaming for torrent & hoster links on Android and iOS.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingDebrid)
                    const Center(child: CircularProgressIndicator())
                  else if (_debridAccount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Account:', style: TextStyle(color: AppTheme.textMuted)),
                              Text(_debridAccount!.username,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status:', style: TextStyle(color: AppTheme.textMuted)),
                              Text(
                                _debridAccount!.isPremium ? 'PREMIUM ACTIVE' : 'FREE',
                                style: TextStyle(
                                  color: _debridAccount!.isPremium
                                      ? AppTheme.successAccent
                                      : AppTheme.warningAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorAccent),
                      onPressed: () async {
                        await _debridRepo.removeToken();
                        setState(() => _debridAccount = null);
                      },
                      child: const Text('Disconnect Real-Debrid'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _rdKeyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter API Key from real-debrid.com/apitoken',
                        prefixIcon: Icon(Icons.vpn_key, color: AppTheme.warningAccent),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAccent),
                      onPressed: _saveDebridKey,
                      child: const Text('Connect Real-Debrid'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Information
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Aura',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aura is a modular, high-performance cross-platform media center client built with Flutter, MediaKit libmpv, and the Stremio v3 protocol.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version', style: TextStyle(color: AppTheme.textMuted)),
                      Text('1.0.0 (Production Build)', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
