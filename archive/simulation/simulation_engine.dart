import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/experiment.dart';
import '../models/fly.dart';
import '../models/world_resource.dart';
import '../models/gender.dart';
import '../models/genetics.dart';
import '../models/personality.dart';
import '../models/brain.dart';
import '../models/sensor.dart';
import '../models/need.dart';
import '../models/life_stage.dart';
import '../utils/random_utils.dart';

class SimulationEngine extends ChangeNotifier {
  static const int EGG_HATCH_TICKS = 600;
  static const int LARVA_PUPATE_TICKS = 1800;
  static const int PUPA_EMERGE_TICKS = 600;

  Experiment? _experiment;
  Timer? _timer;
  bool _isRunning = false;
  
  DateTime _lastTickTime = DateTime.now();
  double _accumulator = 0.0;

  double width = 800;
  double height = 600;

  Experiment? get experiment => _experiment;
  bool get isRunning => _isRunning;

  void loadExperiment(Experiment exp) {
    _experiment = exp;
    notifyListeners();
  }

  void updateSize(double newWidth, double newHeight) {
    width = newWidth;
    height = newHeight;
  }

  void start() {
    if (_experiment == null || _isRunning) return;
    _isRunning = true;
    _lastTickTime = DateTime.now();
    _accumulator = 0.0;

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final now = DateTime.now();
      double dt = now.difference(_lastTickTime).inMicroseconds / 1000000.0;
      _lastTickTime = now;

      if (dt > 2.0) dt = 2.0;

      _accumulator += dt;
      const double fixedDelta = 1.0 / 60.0;

      bool updated = false;
      while (_accumulator >= fixedDelta) {
        _simulateStep(fixedDelta);
        _accumulator -= fixedDelta;
        updated = true;
      }

      if (updated) {
        notifyListeners();
      }
    });
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void _simulateStep(double dt) {
    if (_experiment == null) return;
    final exp = _experiment!;

    exp.ageTicks++;

    List<Fly> newFlies = [];
    List<Fly> deadFliesToRemove = [];

    for (var fly in exp.flyList) {
      if (fly.isDead) {
        fly.y += 2.0;
        if (fly.y > height + 20) {
          deadFliesToRemove.add(fly);
        }
        continue;
      }

      fly.age++;
      fly.wingFlapTime += dt;

      if (fly.stage == LifeStage.egg) {
        if (fly.age >= EGG_HATCH_TICKS) {
          fly.stage = LifeStage.larva;
          fly.age = 0;
        }
        continue; // Eggs don't move or think
      } else if (fly.stage == LifeStage.pupa) {
        if (fly.age >= PUPA_EMERGE_TICKS) {
          fly.stage = LifeStage.adult;
          fly.age = 0;
          fly.need.energy = 100;
          fly.need.hydration = 100;
        }
        continue; // Pupae don't move or think
      }

      if (fly.need.energy <= 0 || fly.need.hydration <= 0 || (fly.stage == LifeStage.adult && fly.age > exp.lifespanTicks)) {
        fly.isDead = true;
        if (fly.need.energy <= 0) fly.causeOfDeath = "Starvation";
        else if (fly.need.hydration <= 0) fly.causeOfDeath = "Dehydration";
        else fly.causeOfDeath = "Old Age";
        
        exp.totalDeaths++;
        continue;
      }

      // 1. Gather Sensors (Abstracted away from semantics inside the Brain)
      double distE1 = double.infinity, angleE1 = 0.0, densityE1 = 0.0;
      double distE2 = double.infinity, angleE2 = 0.0, densityE2 = 0.0;
      
      var allResources = List<WorldResource>.from(exp.resources);
      if (allResources.isNotEmpty) {
        allResources.sort((a, b) => _distance(fly.x, fly.y, a.x, a.y).compareTo(_distance(fly.x, fly.y, b.x, b.y)));
        distE1 = _distance(fly.x, fly.y, allResources[0].x, allResources[0].y);
        angleE1 = _relativeAngle(fly.x, fly.y, fly.heading, allResources[0].x, allResources[0].y);
        densityE1 = allResources[0].type == ResourceType.food ? 0.8 : (allResources[0].type == ResourceType.water ? 0.2 : 1.0);
        
        if (allResources.length > 1) {
          distE2 = _distance(fly.x, fly.y, allResources[1].x, allResources[1].y);
          angleE2 = _relativeAngle(fly.x, fly.y, fly.heading, allResources[1].x, allResources[1].y);
          densityE2 = allResources[1].type == ResourceType.food ? 0.8 : (allResources[1].type == ResourceType.water ? 0.2 : 1.0);
        }
      }

      double distFly = double.infinity, angleFly = 0.0;
      var otherFlies = exp.flyList.where((m) => m.id != fly.id && !m.isDead).toList();
      if (otherFlies.isNotEmpty) {
        var closest = otherFlies.reduce((a, b) => _distance(fly.x, fly.y, a.x, a.y) < _distance(fly.x, fly.y, b.x, b.y) ? a : b);
        distFly = _distance(fly.x, fly.y, closest.x, closest.y);
        angleFly = _relativeAngle(fly.x, fly.y, fly.heading, closest.x, closest.y);
      }

      double neighborSignal = 0.0;
      for (var other in exp.flyList) {
        if (other.id != fly.id && !other.isDead) {
          double d = _distance(fly.x, fly.y, other.x, other.y);
          if (d < 100.0) {
            neighborSignal += other.brain.currentSignalEmit * (1.0 - (d / 100.0));
          }
        }
      }
      neighborSignal = neighborSignal.clamp(0.0, 1.0);

      // 2. Process Brain
      fly.brain.process(
        fly.x, fly.y, fly.heading,
        distE1, angleE1, densityE1,
        distE2, angleE2, densityE2,
        distFly, angleFly,
        neighborSignal,
        fly.lastCollision,
        fly.need.energy, fly.need.hydration,
        fly.lastReward,
      );

      fly.lastReward = 0.0; // Reset for this tick
      fly.lastCollision = 0.0;

      // 3. Apply Physical Actions
      fly.heading += fly.brain.currentTurnAngle;
      double speed = fly.brain.currentSpeed * fly.genetics.speedMultiplier;
      
      if (fly.stage == LifeStage.larva) {
        speed *= 0.2; // larvae crawl slowly
        if (fly.age > LARVA_PUPATE_TICKS * 0.66) fly.instar = 3;
        else if (fly.age > LARVA_PUPATE_TICKS * 0.33) fly.instar = 2;
        else fly.instar = 1;

        if (fly.age >= LARVA_PUPATE_TICKS) {
          fly.stage = LifeStage.pupa;
          fly.age = 0;
          continue;
        }
      }

      fly.x += cos(fly.heading) * speed;
      fly.y += sin(fly.heading) * speed;

      // Solid walls
      if (fly.x < 0) { fly.x = 0; fly.heading = pi - fly.heading; fly.lastReward -= 1.0; fly.lastCollision = 1.0; } 
      if (fly.x > width) { fly.x = width; fly.heading = pi - fly.heading; fly.lastReward -= 1.0; fly.lastCollision = 1.0; }
      if (fly.y < 0) { fly.y = 0; fly.heading = -fly.heading; fly.lastReward -= 1.0; fly.lastCollision = 1.0; }
      if (fly.y > height) { fly.y = height; fly.heading = -fly.heading; fly.lastReward -= 1.0; fly.lastCollision = 1.0; }

      for (var resource in exp.resources) {
        if (resource.type == ResourceType.obstacle) {
          if (_distance(fly.x, fly.y, resource.x, resource.y) < resource.radius + 5.0) {
            fly.heading = pi + fly.heading;
            fly.x += cos(fly.heading) * 5;
            fly.y += sin(fly.heading) * 5;
            fly.lastReward -= 1.0; 
            fly.lastCollision = 1.0;
          }
        }
      }

      while (fly.heading > pi) fly.heading -= 2 * pi;
      while (fly.heading < -pi) fly.heading += 2 * pi;

      // 4. Update needs
      double tempFactor = exp.ambientTemperature / 25.0;
      double metabolism = fly.genetics.metabolismRate;
      if (fly.stage == LifeStage.larva) metabolism *= 0.5;

      double energyLoss = 0.005 * metabolism * tempFactor;
      double hydraLoss = 0.0035 * metabolism * tempFactor;
      fly.need.energy -= energyLoss;
      fly.need.hydration -= hydraLoss;
      
      // Minor penalty for starving/thirsting
      if (fly.need.energy < 20) fly.lastReward -= 0.1;
      if (fly.need.hydration < 20) fly.lastReward -= 0.1;

      // 5. Check if at resource
      for (int i = exp.resources.length - 1; i >= 0; i--) {
        var resource = exp.resources[i];
        if (resource.type != ResourceType.obstacle && _distance(fly.x, fly.y, resource.x, resource.y) < resource.radius + 8.0) {
          double consumptionRate = 1.0;
          if (resource.type == ResourceType.food && fly.need.energy < 100) {
            fly.need.energy += consumptionRate;
            resource.value -= consumptionRate;
            fly.lastReward += 10.0; // Positive reinforcement!
          } else if (resource.type == ResourceType.water && fly.need.hydration < 100) {
            fly.need.hydration += consumptionRate;
            resource.value -= consumptionRate;
            fly.lastReward += 10.0; // Positive reinforcement!
          }
          
          if (resource.value <= 0) {
            exp.resources.removeAt(i);
          }
        }
      }

      if (fly.need.energy > 100) fly.need.energy = 100;
      if (fly.need.hydration > 100) fly.need.hydration = 100;

      // 6. Check Emergent Mating
      if (fly.stage == LifeStage.adult) {
        var offspring = _handleEmergentReproduction(fly, exp, dt);
        if (offspring != null) {
          newFlies.add(offspring);
        }
      }
    }

    if (newFlies.isNotEmpty) {
      exp.flyList.addAll(newFlies);
    }
    if (deadFliesToRemove.isNotEmpty) {
      exp.flyList.removeWhere((f) => deadFliesToRemove.contains(f));
    }
    
    // Spawn resources
    int foodCount = exp.resources.where((r) => r.type == ResourceType.food).length;
    if (foodCount < exp.maxFood && RandomUtils.nextDouble() < 0.01) {
      exp.resources.add(WorldResource(
        id: 'food_${DateTime.now().millisecondsSinceEpoch}_${RandomUtils.nextInt(1000)}',
        type: ResourceType.food,
        x: RandomUtils.nextDouble() * width,
        y: RandomUtils.nextDouble() * height,
        radius: 14.0, // increased to help them stumble upon it
        value: 100.0,
      ));
    }
    
    int waterCount = exp.resources.where((r) => r.type == ResourceType.water).length;
    if (waterCount < exp.maxWater && RandomUtils.nextDouble() < 0.01) {
      exp.resources.add(WorldResource(
        id: 'water_${DateTime.now().millisecondsSinceEpoch}_${RandomUtils.nextInt(1000)}',
        type: ResourceType.water,
        x: RandomUtils.nextDouble() * width,
        y: RandomUtils.nextDouble() * height,
        radius: 14.0,
        value: 100.0,
      ));
    }
  }

  Fly? _handleEmergentReproduction(Fly fly, Experiment exp, double dt) {
    if (fly.age < 300 || fly.need.energy < 70 || fly.need.hydration < 70) return null;

    bool foundMate = false;
    for (var other in exp.flyList) {
      if (other.id != fly.id && !other.isDead && other.gender != fly.gender) {
        if (other.age >= 300 && other.need.energy >= 70 && other.need.hydration >= 70) {
          if (_distance(fly.x, fly.y, other.x, other.y) < 20.0) {
            if (fly.brain.currentSpeed < 0.5 && other.brain.currentSpeed < 0.5) {
              foundMate = true;
              fly.matingProgress += dt;
              if (fly.matingProgress >= 1.0) {
                fly.matingProgress = 0.0;
                other.matingProgress = 0.0;
                
                fly.lastReward += 50.0;
                other.lastReward += 50.0;

                fly.need.energy -= 30; 
                fly.need.hydration -= 30;
                other.need.energy -= 30;
                other.need.hydration -= 30;
                
                exp.totalBirths++;

                var childNetwork = fly.brain.network.crossover(other.brain.network);

                return Fly(
                  id: 'egg_${DateTime.now().millisecondsSinceEpoch}_${RandomUtils.nextInt(1000)}',
                  x: fly.x,
                  y: fly.y,
                  heading: RandomUtils.nextDouble() * pi * 2,
                  stage: LifeStage.egg,
                  parentId1: fly.id,
                  parentId2: other.id,
                  brain: Brain(initialNetwork: childNetwork),
                  sensor: Sensor(),
                  need: Need(energy: 100, hydration: 100),
                  gender: RandomUtils.nextBool() ? Gender.male : Gender.female,
                  genetics: Genetics(
                    speedMultiplier: (fly.genetics.speedMultiplier + other.genetics.speedMultiplier) / 2.0,
                    sensorRange: (fly.genetics.sensorRange + other.genetics.sensorRange) / 2.0,
                    metabolismRate: (fly.genetics.metabolismRate + other.genetics.metabolismRate) / 2.0,
                  ),
                  personality: Personality(),
                );
              }
            }
          }
        }
      }
    }
    if (!foundMate) fly.matingProgress = 0.0;
    return null;
  }

  double _relativeAngle(double fx, double fy, double fHeading, double tx, double ty) {
    double dx = tx - fx;
    double dy = ty - fy;
    double absoluteAngle = atan2(dy, dx);
    double relativeAngle = absoluteAngle - fHeading;
    while (relativeAngle > pi) relativeAngle -= 2 * pi;
    while (relativeAngle < -pi) relativeAngle += 2 * pi;
    return relativeAngle;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
