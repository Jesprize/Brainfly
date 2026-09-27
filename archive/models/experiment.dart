import 'package:hive/hive.dart';
import 'fly.dart';
import 'world_resource.dart';

@HiveType(typeId: 4)
class Experiment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<Fly> flyList;

  @HiveField(2)
  List<WorldResource> resources;

  @HiveField(3)
  double ambientTemperature;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int ageTicks;

  @HiveField(6)
  int totalBirths;

  @HiveField(7)
  int totalDeaths;

  @HiveField(8)
  int maxFood;

  @HiveField(9)
  int maxWater;

  @HiveField(10)
  int lifespanTicks;

  @HiveField(11)
  int? seed;

  @HiveField(12)
  bool isDiscoveryMode;

  Experiment({
    required this.id,
    required this.flyList,
    List<WorldResource>? resources,
    this.ambientTemperature = 25.0,
    required this.createdAt,
    this.ageTicks = 0,
    this.totalBirths = 2,
    this.totalDeaths = 0,
    this.maxFood = 5,
    this.maxWater = 3,
    this.lifespanTicks = 36000,
    this.seed,
    this.isDiscoveryMode = false,
  }) : resources = resources ?? [];
}
