import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../data/models/partner.dart';

class PartnerCircle extends StatelessWidget {
  const PartnerCircle({
    super.key,
    required this.partner,
    this.size = 100,
  });

  final PartnerItems partner;
  final double size;

  static bool isValidPartnerUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return false;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  Future<void> _open() async {
    final raw = partner.url?.trim();
    if (!isValidPartnerUrl(raw)) return;
    final uri = Uri.parse(raw!);
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Widget _buildFallback() {
    final name = (partner.name ?? '').trim();
    if (name.isNotEmpty) {
      return Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );
    }
    return const Icon(Icons.public, size: 20, color: AppColors.ink);
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = (partner.logoUrl ?? '').trim();
    final tooltipText = (partner.name ?? '').trim();

    final circle = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.field,
        clipBehavior: Clip.antiAlias,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _open,
          child: logoUrl.isNotEmpty
              ? Image.network(
                  logoUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (context, error, stack) => _buildFallback(),
                )
              : _buildFallback(),
        ),
      ),
    );

    if (tooltipText.isEmpty) return circle;
    return Tooltip(
      message: tooltipText,
      child: circle,
    );
  }
}
