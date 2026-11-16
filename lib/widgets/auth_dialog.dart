import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../core/theme.dart';
import '../data/repositories/auth_repository.dart';

enum AuthDialogMode { signIn, signUp, verifyCode }

Future<void> showAuthDialog(
  BuildContext context, {
  AuthDialogMode initialMode = AuthDialogMode.signIn,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AuthDialog(initialMode: initialMode),
  );
}

/// Masks an email address for safe UI display (e.g., `jo***@example.com`).
String _maskEmail(String email) {
  final trimmed = email.trim();
  final parts = trimmed.split('@');
  if (parts.length != 2) return trimmed;
  final local = parts[0];
  final domain = parts[1];
  if (local.length <= 2) {
    return '${local.isEmpty ? '*' : local[0]}***@$domain';
  }
  return '${local.substring(0, 2)}***@$domain';
}

class _AuthDialog extends StatefulWidget {
  const _AuthDialog({required this.initialMode});

  final AuthDialogMode initialMode;

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;

  late AuthDialogMode _mode = widget.initialMode;
  AuthDialogMode _previousMode = AuthDialogMode.signUp;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final List<TextEditingController> _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  late final List<FocusNode> _otpFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _isResending = false;

  String? _errorMessage;
  String? _infoMessage;

  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsRemaining = _resendCooldownSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsRemaining = 0;
        });
      } else {
        setState(() {
          _resendSecondsRemaining--;
        });
      }
    });
  }

  void _switchMode(AuthDialogMode nextMode, {String? infoMessage}) {
    setState(() {
      if (nextMode == AuthDialogMode.verifyCode &&
          _mode != AuthDialogMode.verifyCode) {
        _previousMode = _mode;
      }
      _mode = nextMode;
      _errorMessage = null;
      _infoMessage = infoMessage;
    });
    if (nextMode == AuthDialogMode.verifyCode) {
      _clearOtpFields();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes.first.requestFocus();
        }
      });
    }
  }

  void _clearOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  String get _currentOtpCode =>
      _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final result = await Get.find<AppController>().registerWithEmail(
        email: email,
        password: password,
      );
      if (!mounted) return;
      _startResendCooldown();
      _switchMode(
        AuthDialogMode.verifyCode,
        infoMessage: result.message,
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Something went wrong during sign up. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await Get.find<AppController>().loginWithEmail(
        username: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully.')),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to sign in. Please check your credentials and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleVerifyCode() async {
    final email = _emailController.text.trim();
    final otpCode = _currentOtpCode;

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      setState(() {
        _errorMessage = 'Please provide a valid email address.';
      });
      return;
    }

    if (otpCode.length < _otpLength) {
      setState(() {
        _errorMessage = 'Please enter the full 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final result = await Get.find<AppController>().verifyEmailOtp(
        email: email,
        otpCode: otpCode,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Email verified and signed in!',
          ),
        ),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to verify code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_resendSecondsRemaining > 0 || _isResending) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address first.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final message = await Get.find<AppController>().resendVerificationOtp(
        email: email,
      );
      if (!mounted) return;
      _clearOtpFields();
      _startResendCooldown();
      setState(() {
        _infoMessage = message;
      });
      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes.first.requestFocus();
      }
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not resend verification code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _onOtpDigitChanged(int index, String rawValue) {
    final digitsOnly = rawValue.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle multi-digit paste (e.g., pasting a 6-digit code into any box)
    if (digitsOnly.length > 1) {
      for (var i = 0; i < _otpLength; i++) {
        _otpControllers[i].text = i < digitsOnly.length ? digitsOnly[i] : '';
      }
      final targetIndex = (digitsOnly.length - 1).clamp(0, _otpLength - 1);
      _otpFocusNodes[targetIndex].requestFocus();
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    if (digitsOnly.isEmpty) {
      _otpControllers[index].clear();
      setState(() {});
      return;
    }

    final char = digitsOnly.substring(digitsOnly.length - 1);
    if (_otpControllers[index].text != char) {
      _otpControllers[index].text = char;
      _otpControllers[index].selection =
          TextSelection.collapsed(offset: char.length);
    }

    if (index < _otpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else {
      _otpFocusNodes[index].unfocus();
    }

    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _mode == AuthDialogMode.verifyCode
                ? _buildVerifyCodeView(context)
                : _buildCredentialsView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialsView(BuildContext context) {
    final isSignUp = _mode == AuthDialogMode.signUp;
    final textTheme = Theme.of(context).textTheme;

    return KeyedSubtree(
      key: ValueKey(_mode),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSignUp ? 'Create an account' : 'Sign in to NewsAI',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isSignUp
                  ? 'Sign up with your email and password to receive a verification code.'
                  : 'Welcome back! Enter your email and password to continue.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              _StatusBanner(
                message: _errorMessage!,
                isError: true,
              ),
              const SizedBox(height: 16),
            ],
            if (_infoMessage != null) ...[
              _StatusBanner(
                message: _infoMessage!,
                isError: false,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !_isSubmitting,
              decoration: _inputDecoration(
                label: 'Email address',
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outline,
              ),
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) {
                  return 'Please enter your email address';
                }
                if (isSignUp && !GetUtils.isEmail(v)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction:
                  isSignUp ? TextInputAction.next : TextInputAction.done,
              autofillHints: [
                isSignUp ? AutofillHints.newPassword : AutofillHints.password,
              ],
              enabled: !_isSubmitting,
              onFieldSubmitted: (_) {
                if (!isSignUp) _handleSignIn();
              },
              decoration: _inputDecoration(
                label: 'Password',
                hint:
                    isSignUp ? 'At least 8 characters' : 'Enter your password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                final v = value ?? '';
                if (v.isEmpty) {
                  return 'Please enter a password';
                }
                if (isSignUp && v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (v.length > 128) {
                  return 'Password must be 128 characters or fewer';
                }
                return null;
              },
            ),
            if (isSignUp) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_isSubmitting,
                onFieldSubmitted: (_) => _handleSignUp(),
                decoration: _inputDecoration(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_reset_outlined,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmPassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  final v = value ?? '';
                  if (v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : (isSignUp ? _handleSignUp : _handleSignIn),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isSignUp ? 'Sign up' : 'Sign in',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _switchMode(AuthDialogMode.verifyCode),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isSignUp
                    ? const Text(
                        'Have a verification code?',
                        style: TextStyle(fontSize: 13),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.line)),
              ],
            ),
            const SizedBox(height: 14),
            _ProviderButton(
              icon: Icons.g_mobiledata,
              label: isSignUp ? 'Sign up with Google' : 'Login with Google',
              onTap: _isSubmitting
                  ? null
                  : () {
                      Get.find<AppController>().login('google');
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(height: 10),
            _ProviderButton(
              icon: Icons.facebook,
              label: isSignUp ? 'Sign up with Facebook' : 'Login with Facebook',
              onTap: _isSubmitting
                  ? null
                  : () {
                      Get.find<AppController>().login('facebook');
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSignUp
                      ? 'Already have an account?'
                      : "Don't have an account?",
                  style: textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _switchMode(
                            isSignUp
                                ? AuthDialogMode.signIn
                                : AuthDialogMode.signUp,
                          ),
                  child: Text(
                    isSignUp ? 'Sign in' : 'Sign up',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCodeView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final email = _emailController.text.trim();
    final hasEmail = email.isNotEmpty && GetUtils.isEmail(email);
    final isOtpComplete = _currentOtpCode.length == _otpLength;

    return Column(
      key: const ValueKey(AuthDialogMode.verifyCode),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _isSubmitting || _isResending
                  ? null
                  : () => _switchMode(_previousMode),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
            Expanded(
              child: Text(
                'Verify your email',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasEmail
              ? 'Enter the 6-digit verification code sent to ${_maskEmail(email)}.'
              : 'Enter your email address and the 6-digit verification code sent to your inbox.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 18),
        if (_errorMessage != null) ...[
          _StatusBanner(
            message: _errorMessage!,
            isError: true,
          ),
          const SizedBox(height: 16),
        ],
        if (_infoMessage != null) ...[
          _StatusBanner(
            message: _infoMessage!,
            isError: false,
          ),
          const SizedBox(height: 16),
        ],
        if (!hasEmail) ...[
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSubmitting && !_isResending,
            decoration: _inputDecoration(
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return _OtpDigitBox(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              enabled: !_isSubmitting,
              onChanged: (value) => _onOtpDigitChanged(index, value),
              onBackspaceWhenEmpty: () {
                if (index > 0) {
                  _otpControllers[index - 1].clear();
                  _otpFocusNodes[index - 1].requestFocus();
                  setState(() {});
                }
              },
              onSubmitted: (_) {
                if (_currentOtpCode.length == _otpLength) {
                  _handleVerifyCode();
                }
              },
            );
          }),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed:
                (_isSubmitting || !isOtpComplete) ? null : _handleVerifyCode,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify code',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.75),
              ),
            ),
            if (_resendSecondsRemaining > 0)
              Text(
                'Resend in ${_resendSecondsRemaining}s',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
              )
            else
              TextButton(
                onPressed:
                    (_isResending || _isSubmitting) ? null : _handleResendCode,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _isResending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Resend code',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    );
  }
}

class _OtpDigitBox extends StatefulWidget {
  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onBackspaceWhenEmpty,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceWhenEmpty;
  final ValueChanged<String> onSubmitted;

  @override
  State<_OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<_OtpDigitBox> {
  final FocusNode _keyboardFocusNode = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 54,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspaceWhenEmpty();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.field,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: widget.controller.text.isNotEmpty
                    ? AppColors.ink
                    : AppColors.line,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.ink, width: 2),
            ),
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bgColor = isError ? const Color(0xFFFDEDED) : const Color(0xFFEAF3FF);
    final borderColor =
        isError ? const Color(0xFFF5C2C7) : const Color(0xFFB6D4FE);
    final textColor =
        isError ? const Color(0xFF842029) : const Color(0xFF084298);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
