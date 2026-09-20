import 'package:hive_flutter/hive_flutter.dart';
import '../models/experiment.dart';
import '../models/adapters.dart';

class StorageService {
  static const String experimentBoxName = 'experiments';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(NeedAdapter());
    Hive.registerAdapter(SensorAdapter());
    Hive.registerAdapter(BrainAdapter());
    Hive.registerAdapter(FlyAdapter());
    Hive.registerAdapter(ExperimentAdapter());
    Hive.registerAdapter(GenderAdapter());
    Hive.registerAdapter(GeneticsAdapter());
    Hive.registerAdapter(PersonalityAdapter());
    Hive.registerAdapter(ResourceTypeAdapter());
    Hive.registerAdapter(WorldResourceAdapter());
    Hive.registerAdapter(LifeStageAdapter());

    // TEMPORARY: Clear old schema to prevent crash during V2 upgrade
    await Hive.deleteBoxFromDisk(experimentBoxName);
    await Hive.openBox<Experiment>(experimentBoxName);
  }

  static Box<Experiment> get experimentBox => Hive.box<Experiment>(experimentBoxName);

  static Future<void> saveExperiment(Experiment exp) async {
    await experimentBox.put(exp.id, exp);
  }

  static Experiment? getExperiment(String id) {
    return experimentBox.get(id);
  }

  static List<Experiment> getAllExperiments() {
    return experimentBox.values.toList();
  }

  static Future<void> deleteExperiment(String id) async {
    await experimentBox.delete(id);
  }
}
