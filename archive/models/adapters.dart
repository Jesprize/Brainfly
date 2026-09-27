import 'package:hive/hive.dart';
import 'need.dart';
import 'sensor.dart';
import 'brain.dart';
import 'fly.dart';
import 'experiment.dart';
import 'gender.dart';
import 'genetics.dart';
import 'personality.dart';
import 'world_resource.dart';
import 'life_stage.dart';

class LifeStageAdapter extends TypeAdapter<LifeStage> {
  @override
  final int typeId = 10; // Must be unique. typeIds in use: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9. 

  @override
  LifeStage read(BinaryReader reader) {
    return LifeStage.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, LifeStage obj) {
    writer.writeInt(obj.index);
  }
}

class NeedAdapter extends TypeAdapter<Need> {
  @override
  final int typeId = 0;

  @override
  Need read(BinaryReader reader) {
    return Need(
      energy: reader.readDouble(),
      hydration: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Need obj) {
    writer.writeDouble(obj.energy);
    writer.writeDouble(obj.hydration);
  }
}

class SensorAdapter extends TypeAdapter<Sensor> {
  @override
  final int typeId = 1;

  @override
  Sensor read(BinaryReader reader) {
    return Sensor(
      closestFoodDistance: reader.readDouble(),
      closestFoodAngle: reader.readDouble(),
      closestWaterDistance: reader.readDouble(),
      closestWaterAngle: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Sensor obj) {
    writer.writeDouble(obj.closestFoodDistance);
    writer.writeDouble(obj.closestFoodAngle);
    writer.writeDouble(obj.closestWaterDistance);
    writer.writeDouble(obj.closestWaterAngle);
  }
}

class BrainAdapter extends TypeAdapter<Brain> {
  @override
  final int typeId = 2;

  @override
  Brain read(BinaryReader reader) {
    Brain b = Brain();
    b.memoryX = reader.read();
    b.memoryY = reader.read();
    
    var w1Raw = (reader.read() as List?)?.cast<double>();
    if (w1Raw == null || w1Raw.length != 12 * 6) w1Raw = List.generate(12 * 6, (_) => 0.0);
    b.network.w1 = w1Raw;
    
    var w2Raw = (reader.read() as List?)?.cast<double>();
    if (w2Raw == null || w2Raw.length != 6 * 3) w2Raw = List.generate(6 * 3, (_) => 0.0);
    b.network.w2 = w2Raw;

    return b;
  }

  @override
  void write(BinaryWriter writer, Brain obj) {
    writer.write(obj.memoryX);
    writer.write(obj.memoryY);
    writer.writeList(obj.network.w1);
    writer.writeList(obj.network.w2);
  }
}

class GenderAdapter extends TypeAdapter<Gender> {
  @override
  final int typeId = 5;

  @override
  Gender read(BinaryReader reader) {
    return Gender.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, Gender obj) {
    writer.writeInt(obj.index);
  }
}

class GeneticsAdapter extends TypeAdapter<Genetics> {
  @override
  final int typeId = 6;

  @override
  Genetics read(BinaryReader reader) {
    return Genetics(
      speedMultiplier: reader.readDouble(),
      sensorRange: reader.readDouble(),
      metabolismRate: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Genetics obj) {
    writer.writeDouble(obj.speedMultiplier);
    writer.writeDouble(obj.sensorRange);
    writer.writeDouble(obj.metabolismRate);
  }
}

class PersonalityAdapter extends TypeAdapter<Personality> {
  @override
  final int typeId = 7;

  @override
  Personality read(BinaryReader reader) {
    return Personality(
      curiosity: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Personality obj) {
    writer.writeDouble(obj.curiosity);
  }
}

class FlyAdapter extends TypeAdapter<Fly> {
  @override
  final int typeId = 3;

  @override
  Fly read(BinaryReader reader) {
    return Fly(
      id: reader.readString(),
      x: reader.readDouble(),
      y: reader.readDouble(),
      heading: reader.readDouble(),
      brain: reader.read(),
      sensor: reader.read(),
      need: reader.read(),
      age: reader.readInt(),
      gender: reader.read(),
      genetics: reader.read(),
      personality: reader.read(),
      isDead: reader.read() ?? false,
      matingProgress: reader.read() ?? 0.0,
      stage: reader.read() ?? LifeStage.adult,
      parentId1: reader.read(),
      parentId2: reader.read(),
      instar: reader.read() ?? 1,
      causeOfDeath: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Fly obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.x);
    writer.writeDouble(obj.y);
    writer.writeDouble(obj.heading);
    writer.write(obj.brain);
    writer.write(obj.sensor);
    writer.write(obj.need);
    writer.writeInt(obj.age);
    writer.write(obj.gender);
    writer.write(obj.genetics);
    writer.write(obj.personality);
    writer.writeBool(obj.isDead);
    writer.writeDouble(obj.matingProgress);
    writer.write(obj.stage);
    writer.write(obj.parentId1);
    writer.write(obj.parentId2);
    writer.write(obj.instar);
    writer.write(obj.causeOfDeath);
  }
}

class ResourceTypeAdapter extends TypeAdapter<ResourceType> {
  @override
  final int typeId = 8;

  @override
  ResourceType read(BinaryReader reader) {
    return ResourceType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, ResourceType obj) {
    writer.writeInt(obj.index);
  }
}

class WorldResourceAdapter extends TypeAdapter<WorldResource> {
  @override
  final int typeId = 9;

  @override
  WorldResource read(BinaryReader reader) {
    return WorldResource(
      id: reader.readString(),
      type: reader.read(),
      x: reader.readDouble(),
      y: reader.readDouble(),
      radius: reader.readDouble(),
      value: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, WorldResource obj) {
    writer.writeString(obj.id);
    writer.write(obj.type);
    writer.writeDouble(obj.x);
    writer.writeDouble(obj.y);
    writer.writeDouble(obj.radius);
    writer.writeDouble(obj.value);
  }
}

class ExperimentAdapter extends TypeAdapter<Experiment> {
  @override
  final int typeId = 4;

  @override
  Experiment read(BinaryReader reader) {
    return Experiment(
      id: reader.readString(),
      flyList: (reader.readList()).cast<Fly>(),
      resources: (reader.readList()).cast<WorldResource>(),
      ambientTemperature: reader.readDouble(),
      createdAt: DateTime.parse(reader.readString()),
      ageTicks: reader.read() ?? 0,
      totalBirths: reader.read() ?? 0,
      totalDeaths: reader.read() ?? 0,
      maxFood: reader.read() ?? 5,
      maxWater: reader.read() ?? 3,
      lifespanTicks: reader.read() ?? 36000,
      seed: reader.read(),
      isDiscoveryMode: reader.read() ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Experiment obj) {
    writer.writeString(obj.id);
    writer.writeList(obj.flyList);
    writer.writeList(obj.resources);
    writer.writeDouble(obj.ambientTemperature);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.write(obj.ageTicks);
    writer.write(obj.totalBirths);
    writer.write(obj.totalDeaths);
    writer.write(obj.maxFood);
    writer.write(obj.maxWater);
    writer.write(obj.lifespanTicks);
    writer.write(obj.seed);
    writer.write(obj.isDiscoveryMode);
  }
}
