import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class TransporteurDashboardViewModel extends ChangeNotifier {
  bool loading = true;
  List<Shipment> availableMissions = [];
  List<Shipment> myShipments = [];
  int? currentUserId;

  int get activeCount => myShipments
      .where((s) =>
          s.status == ShipmentStatus.inTransit ||
          s.status == ShipmentStatus.pickedUp)
      .length;

  int get deliveredCount =>
      myShipments.where((s) => s.status == ShipmentStatus.delivered).length;

  int get pendingCount => myShipments
      .where((s) =>
          s.status != ShipmentStatus.delivered &&
          s.status != ShipmentStatus.cancelled)
      .length;

  double get completionRate {
    if (myShipments.isEmpty) return 0;
    return (deliveredCount / myShipments.length) * 100;
  }

  double get pendingRate {
    if (myShipments.isEmpty) return 0;
    return (pendingCount / myShipments.length).clamp(0, 1).toDouble();
  }

  Future<void> loadData() async {
    try {
      final user = await SessionService.getUser();
      currentUserId = user?.id;
      final data = await ApiService.getShipments();
      final all = data
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();
      availableMissions = all
          .where((s) =>
              s.transporterId == null &&
              s.status == ShipmentStatus.requested)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      myShipments = all
          .where((s) => s.transporterId == currentUserId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      loading = false;
      notifyListeners();
    } catch (_) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> acceptMission(int shipmentId) async {
    if (currentUserId == null) return;
    await ApiService.updateShipment(
      shipmentId,
      {'transporterId': currentUserId, 'status': 'assigned'},
    );
    await loadData();
  }

  Future<void> updateShipmentStatus(int shipmentId, String status) async {
    await ApiService.updateShipment(shipmentId, {'status': status});
    await loadData();
  }
}
