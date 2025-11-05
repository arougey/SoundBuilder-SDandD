import 'package:flutter/material.dart';
import 'package:soundbuilder/core/theme.dart';
import 'package:soundbuilder/services/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Upgrade screen
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iap = IapService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade')),
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
                TextButton(
                  onPressed: () => iap.restore(),
                  child: const Text('Restore Purchases'),
                ),
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
          Icon(Icons.workspace_premium, size: 72, color: AppTheme.primaryVariant),
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
                  color: Colors.amber.withValues(alpha: .2),
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

  Widget _buildSupportSection(BuildContext context) { /* unchanged */ 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Support & Feedback', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(title: const Text('Send Feedback'), onTap: () {}),
        ListTile(title: const Text('Report a Bug'), onTap: () {}),
        ListTile(title: const Text('FAQ'), onTap: () {}),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) { /* unchanged */
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('About & Legal', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(title: const Text('Privacy Policy'), onTap: () {}),
        ListTile(title: const Text('Terms of Service'), onTap: () {}),
      ],
    );
  }
}