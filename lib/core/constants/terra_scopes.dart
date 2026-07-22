import 'package:terra_flutter_bridge/models/enums.dart';

/// The Apple Health scopes Personally requests.
///
/// Apple rejects apps that over-ask, so this is deliberately the *minimum* set
/// that powers the formula: activity/energy, sleep, heart, body and cycle. The
/// grouping mirrors the categories shown on the consent screens.
class TerraScopes {
  const TerraScopes._();

  /// Activity & energy.
  static const List<CustomPermission> activity = [
    CustomPermission.activitySummary,
    CustomPermission.steps,
    CustomPermission.calories,
    CustomPermission.basalEnergyBurned,
    CustomPermission.activeDurations,
    CustomPermission.workoutTypes,
    CustomPermission.exerciseDistance,
    CustomPermission.flightsClimbed,
    CustomPermission.swimmingSummary,
  ];

  /// Sleep.
  static const List<CustomPermission> sleep = [CustomPermission.sleepAnalysis];

  /// Heart.
  static const List<CustomPermission> heart = [
    CustomPermission.heartRate,
    CustomPermission.restingHeartRate,
    CustomPermission.heartRateVariability,
    CustomPermission.oxygenSaturation,
    CustomPermission.vo2max,
    CustomPermission.electrocardiogram,
  ];

  /// Body measurements.
  static const List<CustomPermission> body = [
    CustomPermission.height,
    CustomPermission.weight,
    CustomPermission.bmi,
    CustomPermission.bodyFat,
  ];

  /// Cycle tracking.
  static const List<CustomPermission> cycle = [CustomPermission.menstruation];

  /// The full set handed to `initConnection`.
  static const List<CustomPermission> all = [
    ...activity,
    ...sleep,
    ...heart,
    ...body,
    ...cycle,
  ];

  /// Human-readable category names shown on the consent + manage screens,
  /// in the order the design lists them.
  static const List<String> categoryLabels = [
    'Activity & energy',
    'Sleep',
    'Heart',
    'Body measurements',
    'Cycle tracking',
  ];
}
