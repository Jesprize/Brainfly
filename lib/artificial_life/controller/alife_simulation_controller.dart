import 'dart:async';
import 'package:flutter/foundation.dart';
import '../world/alife_world.dart';
import '../core/physical_entity.dart';
import '../core/organism.dart';
import '../core/biology.dart';
import 'dart:math';

class ALifeSimulationController extends ChangeNotifier {
  late ALifeWorld world;
  Timer? _timer;
  bool isRunning = false;
  
  // Track simulation ticks independent of flutter frames
  int tickCount = 0;
  final double dt = 0.016; // 60hz simulation logic

  ALifeSimulationController() {
    world = ALifeWorld(width: 800, height: 600);
    _initializeWorld();
  }

  void _initializeWorld() {
    // 1. Setup Environment
    var beneficial = PhysicalEntity(
      id: 'Chemical_A',
      x: 300, y: 300,
      chemicalSignature: [1.0, 0.0, 0.0],
      mass: 0.0, radius: 20,
    );

    var harmful = PhysicalEntity(
      id: 'Chemical_B',
      x: 500, y: 300,
      chemicalSignature: [0.0, 1.0, 0.0],
      mass: 0.0, radius: 20,
    );
    
    world.addEntity(beneficial);
    world.addEntity(harmful);

    // 2. Setup Organisms (Two initial flies)
    var adam = Organism(id: 'Adam', x: 400, y: 250, enableLearning: true, sex: Sex.male);
    var eve = Organism(id: 'Eve', x: 400, y: 350, enableLearning: true, sex: Sex.female);

    world.addEntity(adam);
    world.addEntity(eve);
    world.flushPendingEntities();
  }

  void start() {
    if (isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _tick();
    });
    notifyListeners();
  }

  void pause() {
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void _tick() {
    // 1. Biological Tick
    for (var entity in world.entities) {
      if (entity is Organism) {
        entity.biologicalTick(world, dt);
      }
    }
    
    // 2. Physics Tick
    world.physicsTick(dt);
    
    // 3. World Cleanup & Spawn
    world.flushPendingEntities();
    world.removeDead();
    
    tickCount++;
    notifyListeners();
  }

  void updateSize(double width, double height) {
    world.width = width;
    world.height = height;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
