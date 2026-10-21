import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/sjewls_widgets.dart';
import '../../jewellery/data/jewellery_models.dart';
import '../../jewellery/presentation/jewellery_provider.dart';
import '../../notifications/presentation/notification_provider.dart';
import '../../profile/presentation/profile_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final enrolmentsAsync = ref.watch(customerEnrolmentsProvider);
    final plansAsync = ref.watch(jewelleryPlansProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded, color: AppColors.gold, size: 22),
            SizedBox(width: 8),
            Text(
              'SJEWLS',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(customerProfileProvider);
          ref.invalidate(customerEnrolmentsProvider);
          ref.invalidate(jewelleryPlansProvider);
          ref.invalidate(notificationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Customer Greeting + Account Summary Hero Card
            _buildHeroSummaryCard(context, profileAsync, enrolmentsAsync),
            const SizedBox(height: 18),

            // Unverified secondary contact reminder if applicable
            profileAsync.maybeWhen(
              data: (profile) {
                if (profile.hasUnverifiedEmail || profile.hasUnverifiedPhone) {
                  final unverifiedLabel = profile.hasUnverifiedEmail
                      ? 'email'
                      : 'phone number';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your secondary $unverifiedLabel is unverified. Tap here to verify via OTP.',
                                style: const TextStyle(
                                  color: AppColors.dark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.diamond_outlined,
                    label: 'Jewellery Plans',
                    onTap: () => context.go('/jewelry'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.savings_outlined,
                    label: 'Chittu Plans',
                    onTap: () => context.go('/chittu'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Payments',
                    onTap: () => context.go('/payments'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    onTap: () => context.push('/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Jewellery Enrolments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Jewellery Enrolments',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/jewelry'),
                  child: const Text('See All'),
                ),
              ],
            ),
            enrolmentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        err.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(customerEnrolmentsProvider),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (paged) {
                if (paged.items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No Active Jewellery Enrolments',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start saving toward your favourite gold jewellery with flexible contributions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.dark.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: () => context.go('/jewelry'),
                            child: const Text('Browse Jewellery Plans'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final topItems = paged.items.take(3).toList();
                return Column(
                  children: topItems
                      .map((e) => _buildEnrolmentSummaryCard(context, e))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Available Jewellery Plans Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Jewellery Plans',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/jewelry'),
                  child: const Text('Explore All'),
                ),
              ],
            ),
            plansAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    err.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No jewellery plans are currently published for your branch.',
                        style: TextStyle(
                          color: AppColors.dark.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  );
                }
                final previewPlans = plans.take(3).toList();
                return Column(
                  children: previewPlans.map((plan) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.diamond_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            plan.name,
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Target: ${Formatters.grams(plan.targetGrams, trimTrailingZeros: true)} • ${plan.categoryName ?? 'Gold Jewellery'}',
                            style: TextStyle(
                              color: AppColors.dark.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          onTap: () =>
                              context.push('/jewelry/plans/${plan.id}'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSummaryCard(
    BuildContext context,
    AsyncValue profileAsync,
    AsyncValue<CustomerEnrolmentsPagedResponse> enrolmentsAsync,
  ) {
    final customerName = profileAsync.maybeWhen(
      data: (p) => (p.fullName != null && p.fullName!.trim().isNotEmpty)
          ? p.fullName!
          : 'Valued Customer',
      orElse: () => 'Valued Customer',
    );
    final branchName = profileAsync.maybeWhen(
      data: (p) => p.primaryBranchName ?? p.primaryBranchCode ?? 'Jaffna',
      orElse: () => 'Saranga Jewels',
    );

    final enrolments = enrolmentsAsync.maybeWhen(
      data: (res) => res.items,
      orElse: () => const <CustomerEnrolmentDto>[],
    );
    final totalSavedGrams = enrolments.fold<double>(
      0.0,
      (sum, item) => sum + item.netAccumulatedGoldGrams,
    );
    final totalPaidMoney = enrolments.fold<double>(
      0.0,
      (sum, item) => sum + item.totalConfirmedMoneyPaid,
    );
    final currency = enrolments.isNotEmpty ? enrolments.first.currency : 'LKR';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold),
                ),
                child: Text(
                  branchName,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accumulated Gold',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.grams(totalSavedGrams),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Contributed',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.currency(
                          totalPaidMoney,
                          currencyCode: currency,
                        ),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dark.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolmentSummaryCard(
    BuildContext context,
    CustomerEnrolmentDto enrolment,
  ) {
    final progress = (enrolment.individualProgressPercentage / 100).clamp(
      0.0,
      1.0,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              context.push('/jewelry/enrolments/${enrolment.enrolmentId}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        enrolment.planName,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SJewlsStatusBadge.fromStatus(enrolment.enrolmentStatus),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved: ${Formatters.grams(enrolment.netAccumulatedGoldGrams)} / ${Formatters.grams(enrolment.targetGrams, trimTrailingZeros: true)}',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      Formatters.percentage(
                        enrolment.individualProgressPercentage,
                      ),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
}
