import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:yjeek_driver/features/food_delivery/model/food_delivery_model.dart';
import 'package:yjeek_driver/features/food_delivery/service/food_delivery_service.dart';
import 'package:yjeek_driver/services/api_service.dart';

class FoodDeliveryProvider extends ChangeNotifier {
  FoodDeliveryProvider({FoodDeliveryService? service})
      : _service = service ?? FoodDeliveryService();

  final FoodDeliveryService _service;

  bool _isLoading = false;
  bool _isSubmitting = false;
  FoodDeliveryModel? _delivery;
  String? _error;
  String? _submitError;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  FoodDeliveryModel? get delivery => _delivery;
  String? get error => _error;
  String? get submitError => _submitError;

  Future<void> loadDelivery() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _delivery = await _service.getCurrentDelivery();
      if (_delivery == null) {
        _error = 'No active food delivery job';
      }
    } on ApiException catch (e) {
      _delivery = null;
      _error = e.message;
    } catch (_) {
      _delivery = null;
      _error = 'Failed to load active delivery';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPickup(Uint8List pickupPhotoBytes) async {
    final current = _delivery;
    if (current == null) return false;

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.ensureArrivedAtPickup(current.jobId);
      _delivery = await _service.confirmPickup(
        jobId: current.jobId,
        pickupPhotoBytes: pickupPhotoBytes,
      );
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      return false;
    } catch (_) {
      _submitError = 'Failed to confirm pickup';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> confirmDelivery({
    required Uint8List deliveryPhotoBytes,
    required bool cashCollected,
  }) async {
    final current = _delivery;
    if (current == null) return false;

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _service.ensureArrivedAtCustomer(current.jobId);
      await _service.completeDelivery(
        jobId: current.jobId,
        deliveryPhotoBytes: deliveryPhotoBytes,
        cashCollected: cashCollected,
      );
      _delivery = current.copyWith(status: 'DELIVERED');
      return true;
    } on ApiException catch (e) {
      _submitError = e.message;
      return false;
    } catch (_) {
      _submitError = 'Failed to complete delivery';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
