import 'package:hive/hive.dart';

@HiveType(typeId: 5)
enum LifeStage {
  @HiveField(0)
  egg,
  
  @HiveField(1)
  larva,
  
  @HiveField(2)
  pupa,
  
  @HiveField(3)
  adult
}
