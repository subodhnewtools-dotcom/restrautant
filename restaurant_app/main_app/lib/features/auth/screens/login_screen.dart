import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../repositories/auth_repository.dart';

/// Login screen provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.login(username, password);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        admin: result.admin,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.initial();
  }

  Future<void> checkAuthStatus() async {
    final isAuthenticated = await _repository.isAuthenticated();
    
    if (isAuthenticated) {
      final session = await _repository.getActiveSession();
      if (session != null) {
        state = state.copyWith(
          isAuthenticated: true,
          admin: AdminProfile(
            id: session.adminId,
            username: session.username,
            email: session.email,
          ),
        );
      }
    }
  }
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AdminProfile? admin;
  final String? errorMessage;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.admin,
    this.errorMessage,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: false,
      isAuthenticated: false,
      admin: null,
      errorMessage: null,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AdminProfile? admin,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      admin: admin ?? this.admin,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Login Screen UI
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authNotifierProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Navigate if already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and title
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Restaurant Admin',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to manage your restaurant',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Username field
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        
                        // Error message
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Login button
                        PrimaryButton(
                          text: 'Sign In',
                          onPressed: _handleLogin,
                          isLoading: authState.isLoading,
                          width: double.infinity,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Demo credentials hint
                        Text(
                          'Demo: admin / admin123',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
