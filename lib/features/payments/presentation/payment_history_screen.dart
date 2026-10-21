import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/sjewls_widgets.dart';
import '../../jewellery/data/jewellery_models.dart';
import '../../jewellery/presentation/jewellery_provider.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _selectedStatus = 'All';

  static const List<String> _statusFilters = [
    'All',
    'Confirmed',
    'Pending',
    'Failed',
  ];

  bool _matchesStatus(CustomerEnrolmentPaymentDto item) {
    if (_selectedStatus == 'All') return true;
    final s = item.status.toLowerCase();
    if (_selectedStatus == 'Confirmed') {
      return s.contains('confirm') ||
          s.contains('succeed') ||
          s.contains('paid') ||
          s.contains('complete');
    }
    if (_selectedStatus == 'Pending') {
      return s.contains('pend');
    }
    if (_selectedStatus == 'Failed') {
      return s.contains('fail') || s.contains('cancel') || s.contains('reject');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allCustomerPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((filter) {
                  final selected = _selectedStatus == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.gold : AppColors.dark,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedStatus = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const SJewlsLoadingView(
                message: 'Loading your payment history...',
              ),
              error: (err, _) => SJewlsErrorView(
                message: err.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(allCustomerPaymentsProvider),
              ),
              data: (payments) {
                final filtered = payments.where(_matchesStatus).toList();
                if (filtered.isEmpty) {
                  return SJewlsEmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: payments.isEmpty
                        ? 'No Payment Records Found'
                        : 'No Matching Payments',
                    subtitle: payments.isEmpty
                        ? 'Confirmed jewellery plan contributions and in-store payments will appear here.'
                        : 'No payment records match the selected "$_selectedStatus" filter.',
                    actionLabel: payments.isEmpty
                        ? 'Explore Jewellery Plans'
                        : 'Reset Filter',
                    onAction: () {
                      if (payments.isEmpty) {
                        context.go('/jewelry');
                      } else {
                        setState(() => _selectedStatus = 'All');
                      }
                    },
                  );
                }

                final totalConfirmed = filtered.fold<double>(
                  0.0,
                  (sum, p) => sum + p.currencyAmount,
                );
                final totalGrams = filtered.fold<double>(
                  0.0,
                  (sum, p) => sum + p.goldGramsCredited,
                );
                final currency = filtered.first.currency.isNotEmpty
                    ? filtered.first.currency
                    : 'LKR';

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(allCustomerPaymentsProvider);
                    await ref.read(allCustomerPaymentsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Paid (${filtered.length})',
                                      style: TextStyle(
                                        color: AppColors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.currency(
                                        totalConfirmed,
                                        currencyCode: currency,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: AppColors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gold Credited',
                                      style: TextStyle(
                                        color: AppColors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.grams(totalGrams),
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final payment = filtered[index - 1];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap:
                              payment.enrolmentId != null &&
                                  payment.enrolmentId!.isNotEmpty
                              ? () => context.push(
                                  '/jewelry/enrolments/${payment.enrolmentId}',
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        payment.planName ??
                                            'Jewellery Plan Contribution',
                                        style: const TextStyle(
                                          color: AppColors.dark,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SJewlsStatusBadge.fromStatus(
                                      payment.status,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SJewlsInfoRow(
                                  label: 'Amount Paid',
                                  value: Formatters.currency(
                                    payment.currencyAmount,
                                    currencyCode: payment.currency,
                                  ),
                                  emphasizeValue: true,
                                  goldValue: true,
                                ),
                                SJewlsInfoRow(
                                  label: 'Gold Credited',
                                  value:
                                      '+${Formatters.grams(payment.goldGramsCredited)}',
                                  emphasizeValue: true,
                                ),
                                SJewlsInfoRow(
                                  label: 'Applied Gold Rate',
                                  value:
                                      '${Formatters.currency(payment.appliedRatePerGram, currencyCode: payment.currency)} / g',
                                ),
                                if (payment.paymentMethod != null &&
                                    payment.paymentMethod!.isNotEmpty)
                                  SJewlsInfoRow(
                                    label: 'Payment Method',
                                    value: payment.paymentMethod!,
                                  ),
                                if (payment.paymentReference != null &&
                                    payment.paymentReference!.isNotEmpty)
                                  SJewlsInfoRow(
                                    label: 'Reference',
                                    value: payment.paymentReference!,
                                  ),
                                SJewlsInfoRow(
                                  label: 'Date & Time',
                                  value: Formatters.dateTime(
                                    payment.confirmedAtUtc,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
