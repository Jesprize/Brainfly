import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Need extends HiveObject {
  @HiveField(0)
  double energy;

  @HiveField(1)
  double hydration;

  Need({this.energy = 100.0, this.hydration = 100.0});
}
