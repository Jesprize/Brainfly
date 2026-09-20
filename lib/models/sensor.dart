import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Sensor extends HiveObject {
  @HiveField(0)
  double closestFoodDistance;
  
  @HiveField(1)
  double closestFoodAngle;

  @HiveField(2)
  double closestWaterDistance;

  @HiveField(3)
  double closestWaterAngle;

  Sensor({
    this.closestFoodDistance = double.infinity,
    this.closestFoodAngle = 0.0,
    this.closestWaterDistance = double.infinity,
    this.closestWaterAngle = 0.0,
  });
}
