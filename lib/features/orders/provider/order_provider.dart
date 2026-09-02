import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/dashboard/model/ui_banner_model.dart';
import 'package:yjeek_driver/features/orders/model/contact_attempts_model.dart';
import 'package:yjeek_driver/features/orders/model/job_board_model.dart';
import 'package:yjeek_driver/features/orders/model/job_complete_model.dart';
import 'package:yjeek_driver/features/orders/model/job_decline_model.dart';
import 'package:yjeek_driver/features/orders/model/job_detail_model.dart';
import 'package:yjeek_driver/features/orders/model/job_offer_model.dart';
import 'package:yjeek_driver/features/orders/model/job_report_model.dart';
import 'package:yjeek_driver/features/orders/model/job_report_wait_model.dart';
import 'package:yjeek_driver/features/orders/model/job_resend_code_model.dart';
import 'package:yjeek_driver/features/orders/model/job_confirm_return_model.dart';
import 'package:yjeek_driver/features/orders/model/job_return_age_restricted_model.dart';
import 'package:yjeek_driver/features/orders/model/order_model.dart';
import 'package:yjeek_driver/features/orders/service/order_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  final OrderService _orderService;

  bool _isLoading = false;
  bool _isLoadingOffers = false;
  bool _isLoadingInstantBoard = false;
  bool _isLoadingScheduledNewBoard = false;
  bool _isLoadingScheduledOnTrackBoard = false;
  bool _isLoadingScheduledRequireConfirmBoard = false;
  bool _isLoadingScheduledCompletedBoard = false;
  bool _isLoadingJobDetail = false;
  bool _isArrivingAtCustomer = false;
  bool _isArrivingAtPickup = false;
  bool _isCompletingJob = false;
  bool _isLoggingContactAttempt = false;
  bool _isReportingJobIssue = false;
  bool _isReportingWait = false;
  bool _isMarkingUnableToDeliver = false;
  bool _isConfirmingOrder = false;
  bool _isAcceptingJob = false;
  bool _isDecliningJob = false;
  bool _isConfirmingPickup = false;
  bool _isResendingSecureCode = false;
  bool _isReturningAgeRestricted = false;
  bool _isReturningSecureOrder = false;
  bool _isConfirmingReturn = false;
  List<OrderModel> _orders = [];
  List<JobOfferModel> _offers = const [];
  List<JobsBoardJob> _instantActiveJobs = const [];
  List<JobsBoardJob> _instantCompletedJobs = const [];
  List<JobsBoardJob> _scheduledNewJobs = const [];
  List<JobsBoardJob> _scheduledOnTrackJobs = const [];
  List<JobsBoardJob> _scheduledRequireConfirmJobs = const [];
  List<JobsBoardJob> _scheduledCompletedJobs = const [];
  JobsBoardCounts _instantCounts = const JobsBoardCounts();
  JobsBoardCounts _scheduledCounts = const JobsBoardCounts();
  OrderModel? _currentOrder;
  OrderModel? _newRequest;
  JobOfferModel? _currentOffer;
  JobDetailModel? _currentJobDetail;
  JobCompleteResult? _lastCompleteResult;
  ContactAttemptsResult? _contactAttempts;
  JobReportResult? _lastJobReportResult;
  JobReportWaitResult? _lastReportWaitResult;
  String? _offersError;
  String? _instantBoardError;
  String? _scheduledNewBoardError;
  String? _scheduledOnTrackBoardError;
  String? _scheduledRequireConfirmBoardError;
  String? _scheduledCompletedBoardError;
  String? _jobDetailError;
  String? _arriveCustomerError;
  String? _arrivePickupError;
  String? _completeJobError;
  String? _contactAttemptError;
  String? _jobReportError;
  String? _reportWaitError;
  String? _unableToDeliverError;
  String? _confirmOrderError;
  String? _acceptJobError;
  String? _declineJobError;
  bool _jobsBannersLoading = false;
  String? _jobsBannersError;
  HomeUiBannersModel? _jobsBanners;
  String? _confirmPickupError;
  String? _resendSecureCodeError;
  JobResendCodeResult? _lastResendSecureCodeResult;
  JobReturnAgeRestrictedResult? _lastReturnAgeRestrictedResult;
  String? _returnAgeRestrictedError;
  JobReturnAgeRestrictedResult? _lastReturnSecureOrderResult;
  String? _returnSecureOrderError;
  JobConfirmReturnResult? _lastConfirmReturnResult;
  String? _confirmReturnError;
  String _filter = 'Active';
  int _deliveryStep = 0;

  static const List<String> deliverySteps = [
    'Go to pickup',
    'Picked up',
    'Go to drop-off',
    'Delivered',
  ];

  bool get isLoading => _isLoading;
  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoadingInstantBoard => _isLoadingInstantBoard;
  bool get isLoadingScheduledNewBoard => _isLoadingScheduledNewBoard;
  bool get isLoadingScheduledOnTrackBoard => _isLoadingScheduledOnTrackBoard;
  bool get isLoadingScheduledRequireConfirmBoard =>
      _isLoadingScheduledRequireConfirmBoard;
  bool get isLoadingScheduledCompletedBoard =>
      _isLoadingScheduledCompletedBoard;
  bool get isLoadingJobDetail => _isLoadingJobDetail;
  bool get isArrivingAtCustomer => _isArrivingAtCustomer;
  bool get isArrivingAtPickup => _isArrivingAtPickup;
  bool get isCompletingJob => _isCompletingJob;
  bool get isLoggingContactAttempt => _isLoggingContactAttempt;
  bool get isReportingJobIssue => _isReportingJobIssue;
  bool get isReportingWait => _isReportingWait;
  bool get isMarkingUnableToDeliver => _isMarkingUnableToDeliver;
  bool get isConfirmingOrder => _isConfirmingOrder;
  bool get isAcceptingJob => _isAcceptingJob;
  bool get isDecliningJob => _isDecliningJob;
  bool get isConfirmingPickup => _isConfirmingPickup;
  bool get isResendingSecureCode => _isResendingSecureCode;
  bool get isReturningAgeRestricted => _isReturningAgeRestricted;
  bool get isReturningSecureOrder => _isReturningSecureOrder;
  bool get isReturningOrder =>
      _isReturningAgeRestricted || _isReturningSecureOrder;
  bool get isConfirmingReturn => _isConfirmingReturn;
  bool get isProcessingReturn => isReturningOrder || _isConfirmingReturn;
  bool get jobsBannersLoading => _jobsBannersLoading;
  String? get jobsBannersError => _jobsBannersError;

  List<UiBannerModel> jobsBannersFor(String placementKey) =>
      _jobsBanners?.forPlacement(placementKey) ?? const [];

  List<OrderModel> get orders => _orders;
  List<JobOfferModel> get offers => _offers;
  List<JobsBoardJob> get instantActiveJobs => _instantActiveJobs;
  List<JobsBoardJob> get instantCompletedJobs => _instantCompletedJobs;
  List<JobsBoardJob> get scheduledNewJobs => _scheduledNewJobs;
  List<JobsBoardJob> get scheduledOnTrackJobs => _scheduledOnTrackJobs;
  List<JobsBoardJob> get scheduledRequireConfirmJobs =>
      _scheduledRequireConfirmJobs;
  List<JobsBoardJob> get scheduledCompletedJobs => _scheduledCompletedJobs;
  JobsBoardCounts get instantCounts => _instantCounts;
  JobsBoardCounts get scheduledCounts => _scheduledCounts;
  int get scheduledNewCount => _scheduledNewJobs.length;
  int get scheduledOnTrackCount => _scheduledOnTrackJobs.length;
  int get offersCount => _offers.length;
  OrderModel? get currentOrder => _currentOrder;
  OrderModel? get newRequest => _newRequest;
  JobOfferModel? get currentOffer => _currentOffer;
  JobDetailModel? get currentJobDetail => _currentJobDetail;
  JobCompleteResult? get lastCompleteResult => _lastCompleteResult;
  ContactAttemptsResult? get contactAttempts =>
      _contactAttempts ?? _currentJobDetail?.contactAttempts;
  JobReportResult? get lastJobReportResult => _lastJobReportResult;
  JobReportWaitResult? get lastReportWaitResult => _lastReportWaitResult;
  String? get offersError => _offersError;
  String? get instantBoardError => _instantBoardError;
  String? get scheduledNewBoardError => _scheduledNewBoardError;
  String? get scheduledOnTrackBoardError => _scheduledOnTrackBoardError;
  String? get scheduledRequireConfirmBoardError =>
      _scheduledRequireConfirmBoardError;
  String? get scheduledCompletedBoardError => _scheduledCompletedBoardError;
  String? get jobDetailError => _jobDetailError;
  String? get arriveCustomerError => _arriveCustomerError;
  String? get arrivePickupError => _arrivePickupError;
  String? get completeJobError => _completeJobError;
  String? get contactAttemptError => _contactAttemptError;
  String? get jobReportError => _jobReportError;
  String? get reportWaitError => _reportWaitError;
  String? get unableToDeliverError => _unableToDeliverError;
  String? get confirmOrderError => _confirmOrderError;
  String? get acceptJobError => _acceptJobError;
  String? get declineJobError => _declineJobError;
  String? get confirmPickupError => _confirmPickupError;
  String? get resendSecureCodeError => _resendSecureCodeError;
  JobResendCodeResult? get lastResendSecureCodeResult =>
      _lastResendSecureCodeResult;
  JobReturnAgeRestrictedResult? get lastReturnAgeRestrictedResult =>
      _lastReturnAgeRestrictedResult;
  String? get returnAgeRestrictedError => _returnAgeRestrictedError;
  JobReturnAgeRestrictedResult? get lastReturnSecureOrderResult =>
      _lastReturnSecureOrderResult;
  String? get returnSecureOrderError => _returnSecureOrderError;
  JobConfirmReturnResult? get lastConfirmReturnResult =>
      _lastConfirmReturnResult;
  String? get confirmReturnError => _confirmReturnError;
  String get filter => _filter;
  int get deliveryStep => _deliveryStep;
  String get currentStepLabel =>
      deliverySteps[_deliveryStep.clamp(0, deliverySteps.length - 1)];

  List<OrderModel> get filteredOrders {
    if (_filter == 'All') return _orders;
    return _orders
        .where((o) => o.status.toLowerCase() == _filter.toLowerCase())
        .toList();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    _orders = await _orderService.getOrders();
    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> loadJobsBanners() async {
    _jobsBannersLoading = true;
    _jobsBannersError = null;
    notifyListeners();

    try {
      _jobsBanners = await _orderService.getJobsBanners();
    } on ApiException catch (e) {
      _jobsBannersError = e.message;
    } catch (_) {
      _jobsBannersError = 'Failed to load banners';
    } finally {
      _jobsBannersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJobOffers() async {
    _isLoadingOffers = true;
    _offersError = null;
    notifyListeners();

    try {
      final offers = await _orderService.getJobOffers();
      _offers = offers;
      _currentOffer = offers.isNotEmpty ? offers.first : null;
      _newRequest = _currentOffer == null
          ? null
          : OrderModel(
              id: _currentOffer!.id,
              pickupAddress: _currentOffer!.pickupSubtitle,
              dropoffAddress: _currentOffer!.dropoffSubtitle,
              customerName: _currentOffer!.customerName,
              vendorName: _currentOffer!.vendorName,
              status: _currentOffer!.status,
              price: _currentOffer!.driverEarnings,
              distance: _currentOffer!.distanceKm,
              createdAt: DateTime.now(),
              paymentStatus: _currentOffer!.paymentMethod,
            );
    } on ApiException catch (e) {
      _offersError = e.message;
      _offers = const [];
      _currentOffer = null;
      _newRequest = null;
    } catch (_) {
      _offersError = 'Failed to load job offers';
      _offers = const [];
      _currentOffer = null;
      _newRequest = null;
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }

  Future<void> loadInstantJobsBoard() async {
    _isLoadingInstantBoard = true;
    _instantBoardError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _orderService.getJobsBoard(
          type: 'instant',
          section: 'active',
          limit: 20,
        ),
        _orderService.getJobsBoard(
          type: 'instant',
          section: 'completed',
          limit: 20,
        ),
      ]);

      final active = results[0];
      final completed = results[1];

      _instantActiveJobs = active.jobs;
      _instantCompletedJobs = completed.jobs;
      _instantCounts = JobsBoardCounts(
        active: active.counts.active > 0
            ? active.counts.active
            : active.jobs.length,
        completed: completed.counts.completed > 0
            ? completed.counts.completed
            : completed.jobs.length,
      );
    } on ApiException catch (e) {
      _instantBoardError = e.message;
      _instantActiveJobs = const [];
      _instantCompletedJobs = const [];
      _instantCounts = const JobsBoardCounts();
    } catch (_) {
      _instantBoardError = 'Failed to load orders';
      _instantActiveJobs = const [];
      _instantCompletedJobs = const [];
      _instantCounts = const JobsBoardCounts();
    } finally {
      _isLoadingInstantBoard = false;
      notifyListeners();
    }
  }

  /// `GET /drivers/jobs/board?type=scheduled&section=new&limit=20`
  /// Refreshes scheduled filter counts (and new-section jobs when present).
  Future<void> loadScheduledNewJobsBoard() async {
    _isLoadingScheduledNewBoard = true;
    _scheduledNewBoardError = null;
    notifyListeners();

    try {
      final data = await _orderService.getJobsBoard(
        type: 'scheduled',
        section: 'new',
        limit: 20,
      );
      _scheduledNewJobs = data.jobs;
      _scheduledCounts = data.counts;
    } on ApiException catch (e) {
      _scheduledNewBoardError = e.message;
      _scheduledNewJobs = const [];
    } catch (_) {
      _scheduledNewBoardError = 'Failed to load scheduled orders';
      _scheduledNewJobs = const [];
    } finally {
      _isLoadingScheduledNewBoard = false;
      notifyListeners();
    }
  }

  /// `GET /drivers/jobs/board?type=scheduled&section=require_confirmation`
  Future<void> loadScheduledRequireConfirmJobsBoard() async {
    _isLoadingScheduledRequireConfirmBoard = true;
    _scheduledRequireConfirmBoardError = null;
    notifyListeners();

    try {
      final data = await _orderService.getJobsBoard(
        type: 'scheduled',
        section: 'require_confirmation',
        limit: 20,
      );
      _scheduledRequireConfirmJobs = data.jobs;
      _scheduledCounts = data.counts;
    } on ApiException catch (e) {
      _scheduledRequireConfirmBoardError = e.message;
      _scheduledRequireConfirmJobs = const [];
    } catch (_) {
      _scheduledRequireConfirmBoardError =
          'Failed to load confirmation orders';
      _scheduledRequireConfirmJobs = const [];
    } finally {
      _isLoadingScheduledRequireConfirmBoard = false;
      notifyListeners();
    }
  }

  /// `GET /drivers/jobs/board?type=scheduled&section=on_track&limit=20`
  Future<void> loadScheduledOnTrackJobsBoard() async {
    _isLoadingScheduledOnTrackBoard = true;
    _scheduledOnTrackBoardError = null;
    notifyListeners();

    try {
      final data = await _orderService.getJobsBoard(
        type: 'scheduled',
        section: 'on_track',
        limit: 20,
      );
      _scheduledOnTrackJobs = data.jobs;
      _scheduledCounts = data.counts;
    } on ApiException catch (e) {
      _scheduledOnTrackBoardError = e.message;
      _scheduledOnTrackJobs = const [];
    } catch (_) {
      _scheduledOnTrackBoardError = 'Failed to load on-track orders';
      _scheduledOnTrackJobs = const [];
    } finally {
      _isLoadingScheduledOnTrackBoard = false;
      notifyListeners();
    }
  }

  /// `GET /drivers/jobs/board?type=scheduled&section=completed&limit=20`
  Future<void> loadScheduledCompletedJobsBoard() async {
    _isLoadingScheduledCompletedBoard = true;
    _scheduledCompletedBoardError = null;
    notifyListeners();

    try {
      final data = await _orderService.getJobsBoard(
        type: 'scheduled',
        section: 'completed',
        limit: 20,
      );
      _scheduledCompletedJobs = data.jobs;
      _scheduledCounts = data.counts;
    } on ApiException catch (e) {
      _scheduledCompletedBoardError = e.message;
      _scheduledCompletedJobs = const [];
    } catch (_) {
      _scheduledCompletedBoardError = 'Failed to load completed orders';
      _scheduledCompletedJobs = const [];
    } finally {
      _isLoadingScheduledCompletedBoard = false;
      notifyListeners();
    }
  }

  void removeScheduledNewJob(String jobId) {
    final id = jobId.trim();
    if (id.isEmpty) return;
    _scheduledNewJobs = _scheduledNewJobs
        .where((job) => job.id != id && job.displayOrderId != id)
        .toList(growable: false);
    notifyListeners();
  }

  void removeOffer(String jobId) {
    final id = jobId.trim();
    if (id.isEmpty) return;
    _offers = _offers
        .where(
          (offer) =>
              offer.id != id &&
              offer.orderNumber != id,
        )
        .toList(growable: false);
    if (_currentOffer?.id == id || _currentOffer?.orderNumber == id) {
      _currentOffer = _offers.isNotEmpty ? _offers.first : null;
      _newRequest = _currentOffer == null
          ? null
          : OrderModel(
              id: _currentOffer!.id,
              pickupAddress: _currentOffer!.pickupSubtitle,
              dropoffAddress: _currentOffer!.dropoffSubtitle,
              customerName: _currentOffer!.customerName,
              vendorName: _currentOffer!.vendorName,
              status: _currentOffer!.status,
              price: _currentOffer!.driverEarnings,
              distance: _currentOffer!.distanceKm,
              createdAt: DateTime.now(),
              paymentStatus: _currentOffer!.paymentMethod,
            );
    }
    notifyListeners();
  }

  Future<void> loadNewRequest() async {
    await loadJobOffers();
  }

  Future<void> loadOrderById(String id) async {
    _isLoading = true;
    notifyListeners();
    _currentOrder = await _orderService.getOrderById(id);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadJobDetail(String jobId) async {
    _isLoadingJobDetail = true;
    _jobDetailError = null;
    notifyListeners();

    try {
      _currentJobDetail = await _orderService.getJobById(jobId);
      _contactAttempts = _currentJobDetail?.contactAttempts;
    } on ApiException catch (e) {
      _jobDetailError = e.message;
      _currentJobDetail = null;
    } catch (_) {
      _jobDetailError = 'Failed to load job details';
      _currentJobDetail = null;
    } finally {
      _isLoadingJobDetail = false;
      notifyListeners();
    }
  }

  void clearJobDetail({bool preserveCompleteResult = false}) {
    _currentJobDetail = null;
    if (!preserveCompleteResult) {
      _lastCompleteResult = null;
    }
    _contactAttempts = null;
    _lastJobReportResult = null;
    _lastReportWaitResult = null;
    _jobDetailError = null;
    _arriveCustomerError = null;
    _arrivePickupError = null;
    _completeJobError = null;
    _contactAttemptError = null;
    _jobReportError = null;
    _reportWaitError = null;
    _unableToDeliverError = null;
    _confirmOrderError = null;
    _acceptJobError = null;
    _declineJobError = null;
    _confirmPickupError = null;
    _resendSecureCodeError = null;
    _lastResendSecureCodeResult = null;
    _lastReturnAgeRestrictedResult = null;
    _returnAgeRestrictedError = null;
    _lastReturnSecureOrderResult = null;
    _returnSecureOrderError = null;
    _lastConfirmReturnResult = null;
    _confirmReturnError = null;
    _isLoadingJobDetail = false;
    _isArrivingAtCustomer = false;
    _isArrivingAtPickup = false;
    _isCompletingJob = false;
    _isLoggingContactAttempt = false;
    _isReportingJobIssue = false;
    _isReportingWait = false;
    _isMarkingUnableToDeliver = false;
    _isConfirmingOrder = false;
    _isAcceptingJob = false;
    _isDecliningJob = false;
    _isConfirmingPickup = false;
    _isResendingSecureCode = false;
    _isReturningAgeRestricted = false;
    _isReturningSecureOrder = false;
    _isConfirmingReturn = false;
    notifyListeners();
  }

  /// Clears active job UI state after a successful complete and refreshes boards.
  Future<void> finalizeAfterJobComplete({
    bool refreshInstantBoard = true,
    bool refreshScheduledBoards = false,
  }) async {
    clearJobDetail(preserveCompleteResult: true);
    _currentOrder = null;
    _newRequest = null;
    _currentOffer = null;
    _deliveryStep = 0;

    final tasks = <Future<void>>[];
    if (refreshInstantBoard) {
      tasks.add(loadInstantJobsBoard());
    }
    if (refreshScheduledBoards) {
      tasks.add(loadScheduledOnTrackJobsBoard());
      tasks.add(loadScheduledCompletedJobsBoard());
    }
    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
  }

  /// `POST /drivers/jobs/:jobId/arrive-customer`
  Future<bool> arriveAtCustomer(String jobId) async {
    _isArrivingAtCustomer = true;
    _arriveCustomerError = null;
    notifyListeners();

    try {
      _currentJobDetail = await _orderService.arriveAtCustomer(jobId);
      return true;
    } on ApiException catch (e) {
      _arriveCustomerError = e.message;
      return false;
    } catch (_) {
      _arriveCustomerError = 'Failed to mark arrived at customer';
      return false;
    } finally {
      _isArrivingAtCustomer = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/arrive-pickup`
  Future<bool> arriveAtPickup(String jobId) async {
    _isArrivingAtPickup = true;
    _arrivePickupError = null;
    notifyListeners();

    try {
      _currentJobDetail = await _orderService.arriveAtPickup(jobId);
      return true;
    } on ApiException catch (e) {
      _arrivePickupError = e.message;
      return false;
    } catch (_) {
      _arrivePickupError = 'Failed to mark arrived at pickup';
      return false;
    } finally {
      _isArrivingAtPickup = false;
      notifyListeners();
    }
  }

  /// Upload proof photo then `POST /drivers/jobs/:jobId/complete`.
  Future<JobCompleteResult?> completeJob({
    required String jobId,
    required Uint8List deliveryPhotoBytes,
    required bool cashCollected,
  }) async {
    _isCompletingJob = true;
    _completeJobError = null;
    _lastCompleteResult = null;
    notifyListeners();

    try {
      final photoUrl = await _orderService.uploadDeliveryProof(
        bytes: deliveryPhotoBytes,
      );
      final result = await _orderService.completeJob(
        jobId: jobId,
        deliveryPhotoUrl: photoUrl,
        cashCollected: cashCollected,
      );
      _lastCompleteResult = result;
      return result;
    } on ApiException catch (e) {
      _completeJobError = e.message;
      return null;
    } catch (_) {
      _completeJobError = 'Failed to complete delivery';
      return null;
    } finally {
      _isCompletingJob = false;
      notifyListeners();
    }
  }

  /// Upload CPR + delivery proof then age-restricted `/complete`.
  Future<JobCompleteResult?> completeAgeRestrictedJob({
    required String jobId,
    required Uint8List ageVerificationPhotoBytes,
    required Uint8List deliveryPhotoBytes,
    bool nameMatches = true,
    bool photoMatches = true,
    bool verified18OrOlder = true,
  }) async {
    _isCompletingJob = true;
    _completeJobError = null;
    _lastCompleteResult = null;
    notifyListeners();

    try {
      final ageUpload = await _orderService.uploadAgeVerificationProof(
        bytes: ageVerificationPhotoBytes,
      );
      final deliveryPhotoUrl = await _orderService.uploadDeliveryProof(
        bytes: deliveryPhotoBytes,
      );
      final result = await _orderService.completeAgeRestrictedJob(
        jobId: jobId,
        deliveryPhotoUrl: deliveryPhotoUrl,
        secureUploadId: ageUpload.id,
        nameMatches: nameMatches,
        photoMatches: photoMatches,
        verified18OrOlder: verified18OrOlder,
      );
      _lastCompleteResult = result;
      return result;
    } on ApiException catch (e) {
      _completeJobError = e.message;
      return null;
    } catch (_) {
      _completeJobError = 'Failed to complete age-restricted delivery';
      return null;
    } finally {
      _isCompletingJob = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/contact-attempts`
  Future<ContactAttemptsResult?> logContactAttempt({
    required String jobId,
    String type = 'CALL',
  }) async {
    _isLoggingContactAttempt = true;
    _contactAttemptError = null;
    notifyListeners();

    try {
      final result = await _orderService.logContactAttempt(
        jobId: jobId,
        type: type,
      );
      _contactAttempts = result;
      return result;
    } on ApiException catch (e) {
      _contactAttemptError = e.message;
      return null;
    } catch (_) {
      _contactAttemptError = 'Failed to log contact attempt';
      return null;
    } finally {
      _isLoggingContactAttempt = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/report`
  Future<JobReportResult?> reportJobIssue({
    required String jobId,
    required String reason,
    required String note,
    String? damageType,
    Uint8List? photoBytes,
    bool? declineItems,
  }) async {
    _isReportingJobIssue = true;
    _jobReportError = null;
    _lastJobReportResult = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (photoBytes != null) {
        photoUrl = await _orderService.uploadDeliveryProof(
          bytes: photoBytes,
          filename: 'damage-pickup.jpg',
        );
      }

      final result = await _orderService.reportJobIssue(
        jobId: jobId,
        reason: reason,
        note: note,
        damageType: damageType,
        photoUrl: photoUrl,
        declineItems: declineItems,
      );
      _lastJobReportResult = result;
      return result;
    } on ApiException catch (e) {
      _jobReportError = e.message;
      return null;
    } catch (_) {
      _jobReportError = 'Failed to report issue';
      return null;
    } finally {
      _isReportingJobIssue = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/report-wait`
  Future<JobReportWaitResult?> reportWaitAtVendor(String jobId) async {
    _isReportingWait = true;
    _reportWaitError = null;
    _lastReportWaitResult = null;
    notifyListeners();

    try {
      final result = await _orderService.reportWaitAtVendor(jobId);
      _lastReportWaitResult = result;
      return result;
    } on ApiException catch (e) {
      _reportWaitError = e.message;
      return null;
    } catch (_) {
      _reportWaitError = 'Failed to report wait';
      return null;
    } finally {
      _isReportingWait = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/unable-to-deliver`
  Future<JobReportResult?> markUnableToDeliver({
    required String jobId,
    required String note,
  }) async {
    _isMarkingUnableToDeliver = true;
    _unableToDeliverError = null;
    notifyListeners();

    try {
      final result = await _orderService.markUnableToDeliver(
        jobId: jobId,
        note: note,
      );
      _lastJobReportResult = result;
      return result;
    } on ApiException catch (e) {
      _unableToDeliverError = e.message;
      return null;
    } catch (_) {
      _unableToDeliverError = 'Failed to mark unable to deliver';
      return null;
    } finally {
      _isMarkingUnableToDeliver = false;
      notifyListeners();
    }
  }

  /// Upload pickup photo then `POST /drivers/jobs/:jobId/confirm-pickup`.
  Future<JobDetailModel?> confirmPickup({
    required String jobId,
    required Uint8List pickupPhotoBytes,
  }) async {
    _isConfirmingPickup = true;
    _confirmPickupError = null;
    notifyListeners();

    try {
      final photoUrl = await _orderService.uploadDeliveryProof(
        bytes: pickupPhotoBytes,
        filename: 'pickup-proof.jpg',
      );
      final result = await _orderService.confirmPickup(
        jobId: jobId,
        pickupPhotoUrl: photoUrl,
      );
      _currentJobDetail = result;
      _contactAttempts = result.contactAttempts;
      return result;
    } on ApiException catch (e) {
      _confirmPickupError = e.message;
      return null;
    } catch (_) {
      _confirmPickupError = 'Failed to confirm pickup';
      return null;
    } finally {
      _isConfirmingPickup = false;
      notifyListeners();
    }
  }

  /// Upload return photo then `POST /drivers/jobs/:jobId/return-age-restricted`.
  Future<JobReturnAgeRestrictedResult?> returnAgeRestricted({
    required String jobId,
    required String reason,
    required Uint8List returnPhotoBytes,
    required String note,
  }) async {
    _isReturningAgeRestricted = true;
    _returnAgeRestrictedError = null;
    _lastReturnAgeRestrictedResult = null;
    notifyListeners();

    try {
      final photoUrl = await _orderService.uploadDeliveryProof(
        bytes: returnPhotoBytes,
        filename: 'sealed-return.jpg',
      );
      final result = await _orderService.returnAgeRestricted(
        jobId: jobId,
        reason: reason,
        returnPhotoUrl: photoUrl,
        note: note,
      );
      _lastReturnAgeRestrictedResult = result;
      if (result.job != null) {
        _currentJobDetail = result.job;
        _contactAttempts = result.job!.contactAttempts;
      }
      return result;
    } on ApiException catch (e) {
      _returnAgeRestrictedError = e.message;
      return null;
    } catch (_) {
      _returnAgeRestrictedError = 'Failed to start age-restricted return';
      return null;
    } finally {
      _isReturningAgeRestricted = false;
      notifyListeners();
    }
  }

  /// Upload return photo then `POST /drivers/jobs/:jobId/return`.
  Future<JobReturnAgeRestrictedResult?> returnSecureOrder({
    required String jobId,
    required String reason,
    required Uint8List returnPhotoBytes,
    required String note,
  }) async {
    _isReturningSecureOrder = true;
    _returnSecureOrderError = null;
    _lastReturnSecureOrderResult = null;
    notifyListeners();

    try {
      final photoUrl = await _orderService.uploadDeliveryProof(
        bytes: returnPhotoBytes,
        filename: 'sealed-return.jpg',
      );
      final result = await _orderService.returnSecureOrder(
        jobId: jobId,
        reason: reason,
        returnPhotoUrl: photoUrl,
        note: note,
      );
      _lastReturnSecureOrderResult = result;
      if (result.job != null) {
        _currentJobDetail = result.job;
        _contactAttempts = result.job!.contactAttempts;
      }
      return result;
    } on ApiException catch (e) {
      _returnSecureOrderError = e.message;
      return null;
    } catch (_) {
      _returnSecureOrderError = 'Failed to start secure order return';
      return null;
    } finally {
      _isReturningSecureOrder = false;
      notifyListeners();
    }
  }

  /// Upload handover photo then `POST /drivers/jobs/:jobId/confirm-return`.
  Future<JobConfirmReturnResult?> confirmReturnHandover({
    required String jobId,
    required Uint8List vendorHandoverPhotoBytes,
  }) async {
    _isConfirmingReturn = true;
    _confirmReturnError = null;
    _lastConfirmReturnResult = null;
    notifyListeners();

    try {
      final photoUrl = await _orderService.uploadDeliveryProof(
        bytes: vendorHandoverPhotoBytes,
        filename: 'vendor-return-handover.jpg',
      );
      final result = await _orderService.confirmReturnHandover(
        jobId: jobId,
        vendorHandoverPhotoUrl: photoUrl,
      );
      _lastConfirmReturnResult = result;
      return result;
    } on ApiException catch (e) {
      _confirmReturnError = e.message;
      return null;
    } catch (_) {
      _confirmReturnError = 'Failed to confirm return handover';
      return null;
    } finally {
      _isConfirmingReturn = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/resend-code`
  Future<JobResendCodeResult?> resendSecureCode({
    required String jobId,
    required String code,
  }) async {
    _isResendingSecureCode = true;
    _resendSecureCodeError = null;
    _lastResendSecureCodeResult = null;
    notifyListeners();

    try {
      final result = await _orderService.resendSecureCode(
        jobId: jobId,
        code: code,
      );
      _lastResendSecureCodeResult = result;
      return result;
    } on ApiException catch (e) {
      _resendSecureCodeError = e.message;
      return null;
    } catch (_) {
      _resendSecureCodeError = 'Failed to resend code';
      return null;
    } finally {
      _isResendingSecureCode = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/confirm-order`
  Future<JobDetailModel?> confirmOrder(String jobId) async {
    _isConfirmingOrder = true;
    _confirmOrderError = null;
    notifyListeners();

    try {
      final result = await _orderService.confirmOrder(jobId);
      _currentJobDetail = result;
      _contactAttempts = result.contactAttempts;
      return result;
    } on ApiException catch (e) {
      _confirmOrderError = e.message;
      return null;
    } catch (_) {
      _confirmOrderError = 'Failed to confirm order';
      return null;
    } finally {
      _isConfirmingOrder = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/accept`
  Future<JobDetailModel?> acceptJob(String jobId) async {
    final id = jobId.trim();
    if (id.isEmpty || id.startsWith('#')) {
      _acceptJobError = 'Invalid job id';
      notifyListeners();
      return null;
    }

    _isAcceptingJob = true;
    _acceptJobError = null;
    notifyListeners();

    try {
      final result = await _orderService.acceptJob(id);
      _currentJobDetail = result;
      _contactAttempts = result.contactAttempts;
      removeOffer(id);
      removeOffer(result.id);
      removeOffer(result.order.orderNumber);
      removeScheduledNewJob(id);
      removeScheduledNewJob(result.id);
      _deliveryStep = 0;
      return result;
    } on ApiException catch (e) {
      _acceptJobError = e.message;
      return null;
    } catch (_) {
      _acceptJobError = 'Failed to accept job';
      return null;
    } finally {
      _isAcceptingJob = false;
      notifyListeners();
    }
  }

  /// `POST /drivers/jobs/:jobId/decline`
  Future<JobDeclineResult?> declineJob({
    required String jobId,
    required String reason,
    String note = '',
  }) async {
    final id = jobId.trim();
    if (id.isEmpty || id.startsWith('#')) {
      _declineJobError = 'Invalid job id';
      notifyListeners();
      return null;
    }

    final reasonCode = reason.trim();
    if (reasonCode.isEmpty) {
      _declineJobError = 'Decline reason is required';
      notifyListeners();
      return null;
    }

    _isDecliningJob = true;
    _declineJobError = null;
    notifyListeners();

    try {
      final result = await _orderService.declineJob(
        jobId: id,
        reason: reasonCode,
        note: note,
      );
      removeOffer(id);
      removeScheduledNewJob(id);
      return result;
    } on ApiException catch (e) {
      _declineJobError = e.message;
      return null;
    } catch (_) {
      _declineJobError = 'Failed to decline job';
      return null;
    } finally {
      _isDecliningJob = false;
      notifyListeners();
    }
  }

  void acceptOrder() {
    if (_newRequest != null) {
      _currentOrder = _newRequest!.copyWith(status: 'Accepted');
      _deliveryStep = 0;
      notifyListeners();
    }
  }

  void rejectOrder() {
    _newRequest = null;
    _currentOffer = null;
    notifyListeners();
  }

  void advanceDeliveryStep() {
    if (_deliveryStep < deliverySteps.length - 1) {
      _deliveryStep++;
      notifyListeners();
    }
  }

  void resetDelivery() {
    _deliveryStep = 0;
    _currentOrder = null;
    _currentOffer = null;
    _newRequest = null;
    notifyListeners();
  }
}
