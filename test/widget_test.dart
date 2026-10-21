import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sjewls_mobile/core/network/token_storage.dart';
import 'package:sjewls_mobile/core/utils/formatters.dart';
import 'package:sjewls_mobile/features/jewellery/data/jewellery_models.dart';
import 'package:sjewls_mobile/features/notifications/data/notification_models.dart';
import 'package:sjewls_mobile/features/profile/data/profile_models.dart';
import 'package:sjewls_mobile/main.dart';

void main() {
  testWidgets('SJewls splash screen renders branding and redirects to login', (
    WidgetTester tester,
  ) async {
    TokenStorage.useInMemoryOnly(true);
    const storage = TokenStorage();
    await storage.clearSession();

    await tester.pumpWidget(const ProviderScope(child: SJewlsApp()));

    expect(find.text('SARANGA'), findsOneWidget);
    expect(find.text('JEWELLERY'), findsOneWidget);

    // Advance past the 2-second splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Enter your phone or email'), findsOneWidget);
  });

  group('Formatters & Model Parsing Tests', () {
    test('Currency and grams formatters format values accurately', () {
      expect(
        Formatters.currency(125450.5, currencyCode: 'LKR'),
        'LKR 125,450.50',
      );
      expect(Formatters.grams(4.5), '4.5000 g');
      expect(Formatters.grams(8.0, trimTrailingZeros: true), '8.00 g');
      expect(Formatters.percentage(12.5), '12.5%');
      expect(Formatters.percentage(10.0), '10%');
    });

    test('CustomerProfileDto parses secondary contact verification states', () {
      final profile = CustomerProfileDto.fromJson({
        'id': 'c1111111-1111-1111-1111-111111111111',
        'fullName': 'K. Saranga',
        'dateOfBirth': '1995-04-12',
        'nic': '199512345678',
        'phoneNumber': '+94771234567',
        'email': 'customer@example.com',
        'isPhoneVerified': true,
        'isEmailVerified': false,
        'primaryBranchId': 'b1111111-1111-1111-1111-111111111111',
        'primaryBranchCode': 'JAF',
        'primaryBranchName': 'Jaffna Main',
        'isProfileComplete': true,
      });

      expect(profile.fullName, 'K. Saranga');
      expect(profile.isPhoneVerified, isTrue);
      expect(profile.hasUnverifiedPhone, isFalse);
      expect(profile.hasUnverifiedEmail, isTrue);
    });

    test('CustomerJewelleryPlanDto and CustomerEnrolmentDto parse schemas', () {
      final plan = CustomerJewelleryPlanDto.fromJson({
        'id': 'p1',
        'name': '22K Bridal Necklace Plan',
        'categoryName': 'Necklace',
        'targetGrams': 16.0,
        'offeredDurations': [6, 8, 12],
        'premiumPercentage': 8.5,
        'startDate': '2026-10-01',
      });
      expect(plan.targetGrams, 16.0);
      expect(plan.offeredDurations, [6, 8, 12]);

      final enrolment = CustomerEnrolmentDto.fromJson({
        'enrolmentId': 'e1',
        'planId': 'p1',
        'planName': '22K Bridal Necklace Plan',
        'targetGrams': 16.0,
        'selectedDurationMonths': 12,
        'joiningDate': '2026-10-19',
        'deadline': '2027-10-19',
        'premiumPercentage': 8.5,
        'currency': 'LKR',
        'totalConfirmedMoneyPaid': 120000.0,
        'netAccumulatedGoldGrams': 4.0,
        'remainingGrams': 12.0,
        'individualProgressPercentage': 25.0,
        'enrolmentStatus': 'Active',
        'isContributionAllowed': true,
      });
      expect(enrolment.netAccumulatedGoldGrams, 4.0);
      expect(enrolment.remainingGrams, 12.0);
      expect(enrolment.isCompletedOrEligible, isFalse);
    });

    test(
      'PaymentInitiationResponse parses HTTP 501 deferred gateway payload',
      () {
        final response = PaymentInitiationResponse.fromJson({
          'code': 'PaymentProviderNotConfigured',
          'message': 'Online payment gateway is not configured.',
          'quoteId': 'q1',
          'amountToPay': 45000.0,
          'currency': 'LKR',
          'isConfigured': false,
        }, httpStatusCode: 501);

        expect(response.httpStatusCode, 501);
        expect(response.isConfigured, isFalse);
        expect(response.amountToPay, 45000.0);
      },
    );

    test('CustomerNotificationsPagedResponse parses unreadCount and items', () {
      final paged = CustomerNotificationsPagedResponse.fromJson({
        'items': [
          {
            'id': 'n1',
            'title': 'Enrolment Activated',
            'message': 'Your jewellery plan enrolment is now active.',
            'type': 'EnrolmentActivated',
            'isRead': false,
            'createdAtUtc': '2026-10-19T12:00:00Z',
          },
        ],
        'totalCount': 1,
        'unreadCount': 1,
        'page': 1,
        'pageSize': 20,
        'totalPages': 1,
      });

      expect(paged.unreadCount, 1);
      expect(paged.items.first.title, 'Enrolment Activated');
      expect(paged.items.first.isRead, isFalse);
    });
  });
}
