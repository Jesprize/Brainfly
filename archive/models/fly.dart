import 'package:hive/hive.dart';
import 'brain.dart';
import 'sensor.dart';
import 'need.dart';
import 'genetics.dart';
import 'personality.dart';
import 'gender.dart';
import 'life_stage.dart';

@HiveType(typeId: 3)
class Fly extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double x;

  @HiveField(2)
  double y;

  @HiveField(3)
  double heading;

  @HiveField(4)
  Brain brain;

  @HiveField(5)
  Sensor sensor;

  @HiveField(6)
  Need need;

  @HiveField(7)
  int age;

  @HiveField(8)
  Gender gender;

  @HiveField(9)
  Genetics genetics;

  @HiveField(10)
  Personality personality;

  @HiveField(11)
  bool isDead;

  @HiveField(12)
  double matingProgress;

  @HiveField(13)
  LifeStage stage;

  @HiveField(14)
  String? parentId1;

  @HiveField(15)
  String? parentId2;

  @HiveField(16)
  int instar;

  @HiveField(17)
  String? causeOfDeath;

  double wingFlapTime = 0.0;
  double lastReward = 0.0;
  double lastCollision = 0.0;

  Fly({
    required this.id,
    required this.x,
    required this.y,
    this.heading = 0.0,
    required this.brain,
    required this.sensor,
    required this.need,
    this.age = 0,
    required this.gender,
    required this.genetics,
    required this.personality,
    this.isDead = false,
    this.matingProgress = 0.0,
    this.stage = LifeStage.adult,
    this.parentId1,
    this.parentId2,
    this.instar = 1,
    this.causeOfDeath,
  });
}
