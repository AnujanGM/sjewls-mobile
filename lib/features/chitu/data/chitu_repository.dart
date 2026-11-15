import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import 'chitu_models.dart';

class ChituRepository {
  final ApiClient _apiClient;

  ChituRepository(this._apiClient);

  /// GET /api/v1/customer/chitu-plans
  Future<CustomerChituPlansPagedResponse> getAvailablePlans({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-plans',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return CustomerChituPlansPagedResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 &&
          (e.response?.data == null ||
              e.response?.data.toString().trim().isEmpty == true)) {
        throw Exception(
          'Customer Chittu plans endpoint (/api/v1/customer/chitu-plans) is not yet deployed on the Railway backend. Please deploy backend API v1.2 to Railway.',
        );
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load available Chittu plans.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/chitu-plans/{planId}
  Future<CustomerChituPlanDetailDto> getPlanDetails(String planId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-plans/$planId',
      );
      return CustomerChituPlanDetailDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load Chittu plan details.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/chitu-plans/{planId}/join-preview
  Future<CustomerChituJoinPreviewResponse> previewJoin({
    required String planId,
    required int quantity,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/chitu-plans/$planId/join-preview',
        data: {'quantity': quantity},
      );
      return CustomerChituJoinPreviewResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to calculate Chittu join preview.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/chitu-plans/{planId}/join
  Future<CustomerChituJoinResponse> confirmJoin({
    required String planId,
    required int quantity,
    String? previewReference,
    double? expectedTotalInitialAmount,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? Formatters.generateIdempotencyKey();
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/chitu-plans/$planId/join',
        options: Options(headers: {'X-Idempotency-Key': key}),
        data: {
          'quantity': quantity,
          'idempotencyKey': key,
          if (previewReference != null && previewReference.isNotEmpty)
            'previewReference': previewReference,
          'expectedTotalInitialAmount': ?expectedTotalInitialAmount,
        },
      );
      return CustomerChituJoinResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) {
        final data = e.response?.data;
        if (data is Map) {
          return CustomerChituJoinResponse.fromJson(
            Map<String, dynamic>.from(data),
            isGatewayDeferred: true,
          );
        }
        return CustomerChituJoinResponse(
          paymentId: '',
          planId: planId,
          planName: 'Chittu Plan',
          slotsCount: quantity,
          totalAmountPaid: expectedTotalInitialAmount ?? 0.0,
          currency: 'LKR',
          isSimulated: false,
          assignedSlots: const [],
          message:
              'Online payment gateway is not configured yet. Please visit your Saranga Jewels branch to join and pay in store.',
          isGatewayDeferred: true,
        );
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Unable to join Chittu plan.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/chitu-investments (with alias fallback /api/v1/customer/my-plans)
  Future<CustomerChituInvestmentsPagedResponse> getMyInvestments({
    String? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-investments',
        queryParameters: queryParams,
      );
      return CustomerChituInvestmentsPagedResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final fallbackResp = await _apiClient.dio.get(
            '/api/v1/customer/my-plans',
            queryParameters: queryParams,
          );
          return CustomerChituInvestmentsPagedResponse.fromJson(
            Map<String, dynamic>.from(fallbackResp.data as Map),
          );
        } on DioException catch (fallbackErr) {
          if (fallbackErr.response?.statusCode == 404) {
            return CustomerChituInvestmentsPagedResponse(
              items: const [],
              totalCount: 0,
              page: page,
              pageSize: pageSize,
              totalPages: 0,
            );
          }
        }
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load your Chittu plans and slots.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/chitu-investments/{planId}
  Future<CustomerChituInvestmentPlanDto> getInvestmentPlanDetails(
    String planId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-investments/$planId',
      );
      return CustomerChituInvestmentPlanDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load Chittu portfolio details.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/chitu-slots/{slotId}
  Future<CustomerChituSlotDetailDto> getSlotDetails(String slotId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-slots/$slotId',
      );
      return CustomerChituSlotDetailDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load Chittu slot details.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/chitu-slots/{slotId}/payments
  Future<List<CustomerPaymentSummaryDto>> getSlotPayments(String slotId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-slots/$slotId/payments',
      );
      final list = (response.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map(
            (e) => CustomerPaymentSummaryDto.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load slot payment history.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/chitu-plans/{planId}/payable-slots
  Future<CustomerPayableSlotsDto> getPayableSlots(String planId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/chitu-plans/$planId/payable-slots',
      );
      return CustomerPayableSlotsDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load payable slots for this Chittu plan.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/chitu-plans/{planId}/payments/preview
  Future<CustomerChituPaymentPreviewResponse> previewSlotPayment({
    required String planId,
    required List<CustomerSlotPaymentSelectionDto> slotSelections,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/chitu-plans/$planId/payments/preview',
        data: {
          'slotSelections': slotSelections.map((s) => s.toJson()).toList(),
        },
      );
      return CustomerChituPaymentPreviewResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Unable to preview Chittu instalment allocation.',
        ),
      );
    }
  }

  /// POST /api/v1/customer/chitu-plans/{planId}/payments
  Future<CustomerChituPaymentConfirmResponse> confirmSlotPayment({
    required String planId,
    required List<CustomerSlotPaymentSelectionDto> slotSelections,
    String? previewReference,
    double? expectedTotalAmount,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? Formatters.generateIdempotencyKey();
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/customer/chitu-plans/$planId/payments',
        options: Options(headers: {'X-Idempotency-Key': key}),
        data: {
          'slotSelections': slotSelections.map((s) => s.toJson()).toList(),
          'idempotencyKey': key,
          if (previewReference != null && previewReference.isNotEmpty)
            'previewReference': previewReference,
          'expectedTotalAmount': ?expectedTotalAmount,
        },
      );
      return CustomerChituPaymentConfirmResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 501) {
        final data = e.response?.data;
        if (data is Map) {
          return CustomerChituPaymentConfirmResponse.fromJson(
            Map<String, dynamic>.from(data),
            isGatewayDeferred: true,
          );
        }
        return CustomerChituPaymentConfirmResponse(
          paymentId: '',
          planId: planId,
          planName: 'Chittu Plan',
          totalAmount: expectedTotalAmount ?? 0.0,
          currency: 'LKR',
          paidAtUtc: '',
          isSimulated: false,
          receipts: const [],
          message:
              'Online payment gateway is not configured yet. Please visit your Saranga Jewels branch to pay your Chittu instalment in store.',
          isGatewayDeferred: true,
        );
      }
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Unable to complete Chittu instalment payment.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/payments
  Future<CustomerPaymentsPagedResponse> getUnifiedPayments({
    String? planType,
    String? planId,
    String? status,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/payments',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (planType != null && planType.isNotEmpty) 'planType': planType,
          if (planId != null && planId.isNotEmpty) 'planId': planId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return CustomerPaymentsPagedResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load payment history.',
        ),
      );
    }
  }

  /// GET /api/v1/customer/payments/{paymentId}
  Future<CustomerPaymentDetailDto> getUnifiedPaymentDetail(
    String paymentId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/customer/payments/$paymentId',
      );
      return CustomerPaymentDetailDto.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractErrorMessage(
          e,
          fallback: 'Failed to load payment receipt details.',
        ),
      );
    }
  }
}
