import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/env.dart';
import '../core/theme.dart';

Future<void> showContactUsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const ContactUsDialog(),
  );
}

/// Contact form (name, email, message) plus social media shortcuts.
///
/// Submitting opens the user's mail client with a pre-filled email to
/// [Env.contactEmail].
// TODO(security): when a backend contact endpoint exists, POST the form there
// (server-side validation + rate limiting) instead of using `mailto:`.
class ContactUsDialog extends StatefulWidget {
  const ContactUsDialog({super.key});

  @override
  State<ContactUsDialog> createState() => _ContactUsDialogState();
}

class _ContactUsDialogState extends State<ContactUsDialog> {
  static const _maxNameLength = 80;
  static const _maxSubjectLength = 120;
  static const _maxMessageLength = 2000;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    // Uri encodes every query value, so user input cannot inject extra
    // mailto headers.
    final uri = Uri(
      scheme: 'mailto',
      path: Env.contactEmail,
      query: _encodeQuery({
        'subject': subject.isEmpty ? 'NewsAI contact from $name' : subject,
        'body': 'Name: $name\nEmail: $email\n\n$message',
      }),
    );

    try {
      final launched = await launchUrl(uri);
      if (!mounted) return;
      if (!launched) {
        setState(() {
          _errorMessage =
              'Could not open your email app. Please email us at ${Env.contactEmail}.';
        });
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your email app is ready to send.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Could not open your email app. Please email us at ${Env.contactEmail}.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  Future<void> _openSocial(String url) async {
    final uri = Uri.tryParse(url);
    // Only open well-formed https links from configuration.
    if (uri == null || uri.scheme != 'https') return;
    final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
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
                        'Contact us',
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
                  'Have a question or feedback? Send us a message and we\'ll get back to you.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: _maxNameLength,
                  decoration: _decoration(
                    label: 'Your name',
                    icon: Icons.person_outline,
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: _decoration(
                    label: 'Email address',
                    hint: 'you@example.com',
                    icon: Icons.mail_outline,
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return 'Please enter your email address';
                    if (!GetUtils.isEmail(v)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  maxLength: _maxSubjectLength,
                  decoration: _decoration(
                    label: 'Subject (optional)',
                    icon: Icons.subject,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _messageController,
                  enabled: !_isSubmitting,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: _maxMessageLength,
                  keyboardType: TextInputType.multiline,
                  decoration: _decoration(
                    label: 'Message',
                    hint: 'How can we help?',
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return 'Please enter a message';
                    if (v.length < 10) {
                      return 'Message must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text(
                      'Send message',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.line)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR FIND US ON',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.line)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SocialButton(
                      label: 'Telegram',
                      icon: Icons.telegram,
                      color: const Color(0xFF229ED9),
                      onTap: () => _openSocial(Env.telegramUrl),
                    ),
                    _SocialButton(
                      label: 'Facebook',
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      onTap: () => _openSocial(Env.facebookUrl),
                    ),
                    _SocialButton(
                      label: 'LinkedIn',
                      // Material Icons has no LinkedIn glyph; use a styled "in" badge.
                      iconWidget: const _LinkedInGlyph(),
                      color: const Color(0xFF0A66C2),
                      onTap: () => _openSocial(Env.linkedinUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      alignLabelWithHint: true,
      filled: true,
      fillColor: AppColors.field,
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
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.iconWidget,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: iconWidget ?? Icon(icon, color: color, size: 20),
      label: Text(label, style: const TextStyle(color: AppColors.ink)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _LinkedInGlyph extends StatelessWidget {
  const _LinkedInGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0A66C2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'in',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1,
        ),
      ),
    );
  }
}
