import 'package:dio/dio.dart';
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

  /// GET /api/v1/customer/jewellery-categories/{categoryId}/plans
  Future<List<CustomerJewelleryPlanDto>> getPlansByCategory(
    String categoryId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/jewellery-categories/$categoryId/plans',
      );
      final list = (response.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map(
            (e) =>
                CustomerJewelleryPlanDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
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
      final list = (response.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map(
            (e) =>
                CustomerJewelleryPlanDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
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
    final primaryMode = isAmountMode ? 'Amount' : 'Grams';
    final fallbackMode = isAmountMode ? 'BuyAmount' : 'BuyGram';

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
    final primaryMode = isAmountMode ? 'Amount' : 'Grams';
    final fallbackMode = isAmountMode ? 'BuyAmount' : 'BuyGram';

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
}
