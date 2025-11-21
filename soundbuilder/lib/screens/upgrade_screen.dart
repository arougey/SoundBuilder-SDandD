import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard + rootBundle
import 'package:soundbuilder/core/theme.dart';
import 'package:soundbuilder/services/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

/// === Configure your support email here ===
const _kSupportEmail = 'redbeakdev@gmail.com';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iap = IapService.instance;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildUpgradeHeader(context),
          const Divider(),
          // Store availability + product list
          ValueListenableBuilder<bool>(
            valueListenable: iap.storeAvailable,
            builder: (_, available, __) {
              if (!available) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'The store is currently unavailable. Check your internet connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ValueListenableBuilder<List<ProductDetails>>(
                valueListenable: iap.products,
                builder: (_, products, __) {
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildUpgradeOptions(context, iap);
                },
              );
            },
          ),
          const Divider(),
          _buildSupportSection(context),
          const Divider(),
          _buildAboutSection(context),
          const SizedBox(height: 12),
          // Restore & status section
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: iap.isPremium,
                  builder: (_, premium, __) => Text(
                    premium ? 'Premium Active' : 'Free Tier',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: iap.purchasePending,
                  builder: (_, pending, __) =>
                      pending ? const CircularProgressIndicator() : const SizedBox.shrink(),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: iap.purchaseError,
                  builder: (_, err, __) => (err == null)
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(err, style: const TextStyle(color: Colors.red)),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUpgradeHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, size: 72, color: AppTheme.nearblack),
          const SizedBox(height: 16),
          Text('Go Premium', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Unlock All Sounds, Infinite Builds, Speed Control, Pitch Control and Pan Control',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeOptions(BuildContext context, IapService iap) {
    final monthly  = iap.find(IapService.monthlyId);
    final yearly   = iap.find(IapService.yearlyId);
    final lifetime = iap.find(IapService.lifetimeId);

    // Fallback strings in case a product is missing during early testing
    final monthlyPrice  = monthly?.price  ?? '\$3.99 / month';
    final yearlyPrice   = yearly?.price   ?? '\$24.99 / year';
    final lifetimePrice = lifetime?.price ?? '\$50 one-time';

    return Column(
      children: [
        // Monthly
        ListTile(
          leading: const Icon(Icons.stars, color: Colors.amber),
          title: const Text('Monthly Plan'),
          subtitle: Text(monthlyPrice),
          trailing: ElevatedButton(
            onPressed: monthly == null ? null : () => iap.buy(monthly),
            child: const Text('Choose'),
          ),
        ),

        // Yearly (Best Value badge)
        Stack(
          children: [
            ListTile(
              leading: const Icon(Icons.cake, color: Colors.pink),
              title: const Text('Yearly Plan'),
              subtitle: Text('$yearlyPrice • Save ~50% (6 Months Free)'),
              trailing: ElevatedButton(
                onPressed: yearly == null ? null : () => iap.buy(yearly),
                child: const Text('Choose'),
              ),
            ),
            Positioned(
              right: 16,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Best Value', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),

        // Lifetime
        ListTile(
          leading: const Icon(Icons.lock_open, color: Colors.green),
          title: const Text('Lifetime Plan'),
          subtitle: Text(lifetimePrice),
          trailing: ElevatedButton(
            onPressed: lifetime == null ? null : () => iap.buy(lifetime),
            child: const Text('Choose'),
          ),
        ),
      ],
    );
  }

  /// Support section: single fused email action.
  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Support & Feedback', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('Contact Support'),
          subtitle: Text(_kSupportEmail),
          onTap: () => _sendEmail(context, subject: 'Support Request'),
        ),
      ],
    );
  }

  /// About/legal section: open in-app Markdown pages.
  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('About & Legal', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(
          title: const Text('FAQ'),
          onTap: () => _openMarkdown(context, 'FAQ', 'assets/legal/faq.txt'),
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          onTap: () => _openMarkdown(context, 'Privacy Policy', 'assets/legal/privacy.txt'),
        ),
        ListTile(
          title: const Text('Terms of Service'),
          onTap: () => _openMarkdown(context, 'Terms of Service', 'assets/legal/terms.txt'),
        ),
      ],
    );
  }

  // ---------------- Helpers ----------------

  Future<void> _openMarkdown(BuildContext context, String title, String assetPath) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _MarkdownScreen(title: title, assetPath: assetPath)),
    );
  }

  Future<void> _sendEmail(
    BuildContext context, {
    required String subject,
    String? bodyTemplate,
  }) async {
    // ✅ cache everything derived from context BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final platformName = Theme.of(context).platform.name;

    final pkg = await PackageInfo.fromPlatform(); // safe now
    final iap = IapService.instance;

    final body = StringBuffer()
      ..writeln(bodyTemplate ?? 'Hi,')
      ..writeln()
      ..writeln('— — —')
      ..writeln('App: ${pkg.appName} ${pkg.version}+${pkg.buildNumber}')
      ..writeln('Premium: ${iap.isPremium.value ? "Yes" : "No"}')
      ..writeln('Platform: $platformName');

    final uri = Uri(
      scheme: 'mailto',
      path: _kSupportEmail,
      queryParameters: <String, String>{
        'subject': subject,
        'body': body.toString(),
      },
    );

    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!launched) {
      await Clipboard.setData(const ClipboardData(text: _kSupportEmail));
      // ✅ use the cached messenger instead of context after await
      messenger.showSnackBar(
        const SnackBar(content: Text('No mail app found. Address copied.')),
      );
    }
  }
}

/// Simple in-app Markdown reader for legal/FAQ pages.
class _MarkdownScreen extends StatelessWidget {
  const _MarkdownScreen({required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final isTxt = assetPath.toLowerCase().endsWith('.txt');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load: $assetPath'));
          }
          return isTxt
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SelectableLinkify(
                  text: snap.data ?? '',
                  onOpen: (link) => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
                ),
              )
            : Markdown(
                data: snap.data ?? '',
                selectable: true,
                softLineBreak: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
                  }
                },
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              );
        },
      ),
    );
  }
}