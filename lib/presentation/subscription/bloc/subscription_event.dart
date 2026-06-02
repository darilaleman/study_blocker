import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class TriggerPurchaseEvent extends SubscriptionEvent {
  final String planId;
  const TriggerPurchaseEvent({required this.planId});

  @override
  List<Object?> get props => [planId];
}
