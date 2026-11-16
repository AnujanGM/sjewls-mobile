import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'jewellery_models.dart';

class JewelleryRepository {
  final ApiClient _apiClient;

  JewelleryRepository(this._apiClient);

  /// GET /api/v1/customer/jewellery-categories
  Future<List<CustomerJewelleryCategoryDto>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-categories',
      );
      final list = (response.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map(
            (e) => CustomerJewelleryCategoryDto.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load jewellery categories.',
        ),
      );
    }
  }

  List<CustomerJewelleryPlanDto> _parsePlansList(dynamic raw, String source) {
    final List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['items'] is List) {
      list = raw['items'] as List;
    } else if (raw is Map && raw['plans'] is List) {
      list = raw['plans'] as List;
    } else if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List;
    } else {
      list = const [];
    }

    final parsed = <CustomerJewelleryPlanDto>[];
    for (final item in list) {
      if (item is Map) {
        try {
          parsed.add(
            CustomerJewelleryPlanDto.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (e, st) {
          debugPrint(
            '[$source] Failed to parse plan item: $e\nData: $item\n$st',
          );
        }
      }
    }
    debugPrint(
      '[$source] Loaded ${parsed.length} plans: ${parsed.map((p) => p.name).toList()}',
    );
    return parsed;
  }

  /// GET /api/v1/customer/jewellery-categories/{categoryId}/plans
  Future<List<CustomerJewelleryPlanDto>> getPlansByCategory(
    String categoryId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-categories/$categoryId/plans',
      );
      return _parsePlansList(response.data, 'getPlansByCategory($categoryId)');
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load plans for category.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/jewellery-plans
  Future<List<CustomerJewelleryPlanDto>> getPlans({String? categoryId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-plans',
        queryParameters: {
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
        },
      );
      return _parsePlansList(response.data, 'getPlans');
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load jewellery plans.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/jewellery-plans/{planId}
  Future<CustomerJewelleryPlanDto> getPlanDetails(String planId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-plans/$planId',
      );
      return CustomerJewelleryPlanDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load jewellery plan details.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/jewellery-enrolments/preview
  Future<EnrolmentPreviewResponse> previewEnrolment({
    required String planId,
    required int selectedDurationMonths,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/jewellery-enrolments/preview',
        data: {
          'planId': planId,
          'selectedDurationMonths': selectedDurationMonths,
        },
      );
      return EnrolmentPreviewResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to preview enrolment summary.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/jewellery-enrolments
  Future<CustomerEnrolmentDto> createEnrolment({
    required String planId,
    required int selectedDurationMonths,
    bool confirmRepeatEnrolment = false,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? Formatters.generateIdempotencyKey();
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/jewellery-enrolments',
        options: Options(headers: {'X-Idempotency-Key': key}),
        data: {
          'planId': planId,
          'selectedDurationMonths': selectedDurationMonths,
          'idempotencyKey': key,
          'confirmRepeatEnrolment': confirmRepeatEnrolment,
        },
      );
      return CustomerEnrolmentDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      // If backend returns 409 RepeatEnrolmentConflictResponse and user already confirmed in UI, retry with confirmRepeatEnrolment: true
      if (e.response?.statusCode == 409 && !confirmRepeatEnrolment) {
        final retryKey = Formatters.generateIdempotencyKey();
        try {
          final retryResp = await _apiClient.dio.post(
            '/api/v1/customer/jewellery-enrolments',
            options: Options(headers: {'X-Idempotency-Key': retryKey}),
            data: {
              'planId': planId,
              'selectedDurationMonths': selectedDurationMonths,
              'idempotencyKey': retryKey,
              'confirmRepeatEnrolment': true,
            },
          );
          return CustomerEnrolmentDto.fromJson(
            Map<String, dynamic>.from(retryResp.data as Map),
          );
        } on DioException catch (retryErr) {
          throw Exception(
            ApiClient.extractErrorMessage(
              retryErr,
              fallback: 'Failed to join jewellery plan.',
            ),
          );
        }
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to join jewellery plan.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/jewellery-enrolments
  Future<CustomerEnrolmentsPagedResponse> getEnrolments({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-enrolments',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return CustomerEnrolmentsPagedResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load your jewellery enrolments.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/jewellery-enrolments/{enrolmentId}
  Future<CustomerEnrolmentDto> getEnrolmentDetails(String enrolmentId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-enrolments/$enrolmentId',
      );
      return CustomerEnrolmentDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load enrolment details.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/jewellery-enrolments/{enrolmentId}/payments
  Future<List<CustomerEnrolmentPaymentDto>> getEnrolmentPayments(
    String enrolmentId, {
    String? planName,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-enrolments/$enrolmentId/payments',
      );
      final list = (response.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map(
            (e) => CustomerEnrolmentPaymentDto.fromJson(
              Map<String, dynamic>.from(e),
              enrolmentId: enrolmentId,
              planName: planName,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load enrolment contribution history.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/jewellery-enrolments/{enrolmentId}/preview
  Future<JewelleryCalculationPreviewResponse> previewCalculation({
    required String enrolmentId,
    required bool isAmountMode,
    double? enteredAmount,
    double? requestedGrams,
  }) async {
    final primaryMode = isAmountMode ? 'BuyAmount' : 'BuyGram';
    final fallbackMode = isAmountMode ? 'Amount' : 'Grams';

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/jewellery-enrolments/$enrolmentId/preview',
        data: {
          'inputMode': primaryMode,
          if (isAmountMode) 'enteredAmount': enteredAmount,
          if (!isAmountMode) 'requestedGrams': requestedGrams,
        },
      );
      return JewelleryCalculationPreviewResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final msg = ApiClient.extractErrorMessage(e).toLowerCase();
      if (e.response?.statusCode == 400 && msg.contains('mode')) {
        try {
          final retry = await _apiClient.dio.post(
            '/api/v1/customer/jewellery-enrolments/$enrolmentId/preview',
            data: {
              'inputMode': fallbackMode,
              if (isAmountMode) 'enteredAmount': enteredAmount,
              if (!isAmountMode) 'requestedGrams': requestedGrams,
            },
          );
          return JewelleryCalculationPreviewResponse.fromJson(
            Map<String, dynamic>.from(retry.data as Map),
          );
        } on DioException catch (retryErr) {
          throw Exception(
            ApiClient.extractErrorMessage(
              retryErr,
              fallback: 'Unable to calculate gold preview.',
            ),
          );
        }
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Unable to calculate gold preview.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/jewellery-enrolments/{enrolmentId}/quotes
  Future<CustomerPaymentQuoteDto> createPaymentQuote({
    required String enrolmentId,
    required bool isAmountMode,
    double? enteredAmount,
    double? requestedGrams,
  }) async {
    final primaryMode = isAmountMode ? 'BuyAmount' : 'BuyGram';
    final fallbackMode = isAmountMode ? 'Amount' : 'Grams';

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/jewellery-enrolments/$enrolmentId/quotes',
        data: {
          'inputMode': primaryMode,
          if (isAmountMode) 'enteredAmount': enteredAmount,
          if (!isAmountMode) 'requestedGrams': requestedGrams,
        },
      );
      return CustomerPaymentQuoteDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final msg = ApiClient.extractErrorMessage(e).toLowerCase();
      if (e.response?.statusCode == 400 && msg.contains('mode')) {
        try {
          final retry = await _apiClient.dio.post(
            '/api/v1/customer/jewellery-enrolments/$enrolmentId/quotes',
            data: {
              'inputMode': fallbackMode,
              if (isAmountMode) 'enteredAmount': enteredAmount,
              if (!isAmountMode) 'requestedGrams': requestedGrams,
            },
          );
          return CustomerPaymentQuoteDto.fromJson(
            Map<String, dynamic>.from(retry.data as Map),
          );
        } on DioException catch (retryErr) {
          throw Exception(
            ApiClient.extractErrorMessage(
              retryErr,
              fallback: 'Unable to lock payment quote.',
            ),
          );
        }
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Unable to lock payment quote.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/jewellery-quotes/{quoteId}
  Future<CustomerPaymentQuoteDto> getPaymentQuote(String quoteId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-quotes/$quoteId',
      );
      return CustomerPaymentQuoteDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to retrieve payment quote status.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/jewellery-quotes/{quoteId}/pay
  /// Note: Backend documents this as returning HTTP 501 PaymentInitiationResponse (Gateway Deferred).
  Future<PaymentInitiationResponse> initiateQuotePayment(
    String quoteId, {
    double fallbackAmount = 0.0,
    String fallbackCurrency = 'LKR',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/jewellery-quotes/$quoteId/pay',
      );
      final data = response.data;
      if (data is Map) {
        return PaymentInitiationResponse.fromJson(
          Map<String, dynamic>.from(data),
          httpStatusCode: response.statusCode ?? 200,
        );
      }
      return PaymentInitiationResponse(
        quoteId: quoteId,
        amountToPay: fallbackAmount,
        currency: fallbackCurrency,
        isConfigured: true,
        httpStatusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (status == 501 && data is Map) {
        return PaymentInitiationResponse.fromJson(
          Map<String, dynamic>.from(data),
          httpStatusCode: 501,
        );
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Unable to initiate payment for this quote.',
        ),
      );
    }
  }

  /// Resolves the live branch gold rate for the Home Dashboard.
  /// 1. If the customer has an active jewellery enrolment, queries the calculation preview
  /// Fetches the authoritative live gold rate (24K and 22K in LKR) configured in
  /// the admin dashboard / live market feed.
  /// 1. Queries authoritative endpoint `GET /api/v1/customer/gold-rate`.
  /// 2. If unavailable, falls back to active jewellery enrolment preview calculation.
  /// 3. Otherwise uses the last confirmed contribution rate or Jaffna branch reference rate.
  Future<CustomerGoldRateDto> getLiveGoldRate({
    String? activeEnrolmentId,
    String? branchId,
    double? lastConfirmedRatePerGram,
    String currency = 'LKR',
  }) async {
    // 1. Primary: Direct live gold rate endpoint from backend / admin dashboard
    for (final endpoint in [
      '/api/v1/customer/gold-rate',
      '/api/v1/gold-rate',
    ]) {
      try {
        final response = await _apiClient.dio.get(
          endpoint,
          queryParameters: {
            if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
          },
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final dto = CustomerGoldRateDto.fromJson(data);
          if (dto.rate24KPerGram > 0) {
            return dto;
          }
        } else if (data is Map) {
          final dto = CustomerGoldRateDto.fromJson(
            Map<String, dynamic>.from(data),
          );
          if (dto.rate24KPerGram > 0) {
            return dto;
          }
        } else if (data is List && data.isNotEmpty && data.first is Map) {
          final first = Map<String, dynamic>.from(data.first as Map);
          final dto = CustomerGoldRateDto.fromJson(first);
          if (dto.rate24KPerGram > 0) {
            return dto;
          }
        }
      } catch (_) {
        // Continue to next endpoint or fallback
      }
    }

    // 2. Secondary fallback: preview calculation on active enrolment if available
    if (activeEnrolmentId != null && activeEnrolmentId.isNotEmpty) {
      try {
        final preview = await previewCalculation(
          enrolmentId: activeEnrolmentId,
          isAmountMode: false,
          requestedGrams: 1.0,
        );
        if (preview.ratePerGram > 0) {
          final rate24K = preview.ratePerGram;
          final rate22K = rate24K * (22.0 / 24.0);
          return CustomerGoldRateDto(
            rate24KPerGram: rate24K,
            rate22KPerGram: rate22K,
            currency: preview.currency,
            rateAsOf: preview.rateAsOf,
            rateSource: preview.rateSource ?? 'Saranga Jewels Branch Rate',
            isLiveFromBackend: true,
          );
        }
      } catch (_) {
        // Fall through to last confirmed rate
      }
    }

    // 3. Fallback: Last confirmed contribution rate
    if (lastConfirmedRatePerGram != null && lastConfirmedRatePerGram > 0) {
      return CustomerGoldRateDto(
        rate24KPerGram: lastConfirmedRatePerGram,
        rate22KPerGram: lastConfirmedRatePerGram * (22.0 / 24.0),
        currency: currency,
        rateSource: 'Last Confirmed Branch Rate',
        isLiveFromBackend: true,
      );
    }

    // 4. Default Jaffna Branch reference gold rate when offline or unconfigured
    const default24K = 29500.0;
    const default22K = 27040.0;
    return CustomerGoldRateDto(
      rate24KPerGram: default24K,
      rate22KPerGram: default22K,
      currency: currency,
      rateSource: 'Saranga Jewels Branch Rate',
      isLiveFromBackend: false,
    );
  }
}
