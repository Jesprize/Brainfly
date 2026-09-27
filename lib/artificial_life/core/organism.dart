import 'dart:math';
import 'physical_entity.dart';
import '../world/alife_world.dart';
import '../sensors/sensory_system.dart';
import '../motor/motor_system.dart';
import '../brain/alife_network.dart';
import 'biology.dart';

class Organism extends PhysicalEntity {
  final SensorySystem sensors;
  final MotorSystem motors;
  final ALifeNetwork brain;

  bool enableLearning;

  double internalEnergy = 50.0;
  double damage = 0.0;
  
  double _prevEnergy = 50.0;
  double _prevDamage = 0.0;

  double _lastPredictedValue = 0.0;

  late Genetics genetics;
  late Sex sex;
  LifeStage stage = LifeStage.adult;
  double age = 0.0;
  int generation = 1;
  String? parent1Id;
  String? parent2Id;
  
  double matingCooldown = 0.0;

  Organism({
    required super.id,
    required super.x,
    required super.y,
    this.enableLearning = true,
    int? seed,
    Genetics? genetics,
    Sex? sex,
    this.stage = LifeStage.adult,
    this.age = 0.0,
    this.generation = 1,
    this.parent1Id,
    this.parent2Id,
  }) : sensors = SensorySystem(),
       motors = MotorSystem(),
       brain = ALifeNetwork(7, 12, 5, seed: seed, initialW1: genetics?.baseWeights1, initialW2: genetics?.baseWeights2) {
    this.genetics = genetics ?? Genetics.random(7 * 12, 5 * 12);
    this.sex = sex ?? (Random(seed).nextBool() ? Sex.male : Sex.female);
    internalEnergy = this.genetics.maxEnergy * 0.8;
    _prevEnergy = internalEnergy;
    // chemicalSignature: [Energy, Damage, Pheromone]
    // Females emit a slightly different pheromone than males
    chemicalSignature = [0.0, 0.0, this.sex == Sex.female ? 1.0 : -1.0];
  }

  void biologicalTick(ALifeWorld world, double dt) {
    // 1. Biological Consequence of Interaction
    // If we are touching a chemical source, ingest it.
    // Interaction Attempt is a motor output [-1 to 1]
    _prevEnergy = internalEnergy;
    _prevDamage = damage;
    // Biological processing
    age += dt * genetics.maturitySpeed;
    if (matingCooldown > 0) matingCooldown -= dt;

    if (stage == LifeStage.egg && age > 5.0) stage = LifeStage.larva1;
    else if (stage == LifeStage.larva1 && age > 15.0) stage = LifeStage.larva2;
    else if (stage == LifeStage.larva2 && age > 25.0) stage = LifeStage.larva3;
    else if (stage == LifeStage.larva3 && age > 35.0) stage = LifeStage.pupa;
    else if (stage == LifeStage.pupa && age > 50.0) stage = LifeStage.adult;

    if (age > 200.0) {
      stage = LifeStage.dead;
      mass = 0; // stop moving
    }
    
    // Base metabolic cost of movement and existing
    double physicalExertion = (motors.forwardThrust.abs() + motors.lateralThrust.abs() + motors.rotationalTorque.abs());
    internalEnergy -= (genetics.metabolicRate + 0.02 * physicalExertion) * dt;

    if (internalEnergy <= 0) {
      stage = LifeStage.dead;
      mass = 0;
    }
    
    if (stage == LifeStage.dead) return;

    bool isMobile = stage == LifeStage.larva1 || stage == LifeStage.larva2 || stage == LifeStage.larva3 || stage == LifeStage.adult;

    if (isMobile) {
      // Contact/ingestion
      if (motors.interactionAttempt > 0.0) {
        for (var entity in world.entities) {
          if (entity == this) continue;
          double dx = entity.x - x;
          double dy = entity.y - y;
          double distSq = dx*dx + dy*dy;
          double radSq = (radius + entity.radius) * (radius + entity.radius);
          
          if (distSq < radSq + 10) {
            // We are physically touching or extremely close, and trying to interact.
            if (entity is Organism) {
              // Mating check
              if (stage == LifeStage.adult && entity.stage == LifeStage.adult && sex != entity.sex) {
                if (matingCooldown <= 0 && entity.matingCooldown <= 0 && internalEnergy > 30 && entity.internalEnergy > 30) {
                  // Spawn Egg
                  internalEnergy -= 15.0; // cost of reproduction
                  entity.internalEnergy -= 15.0;
                  matingCooldown = 20.0;
                  entity.matingCooldown = 20.0;
                  
                  Genetics childGenetics = Genetics.crossover(genetics, entity.genetics, Random());
                  
                  world.addEntity(Organism(
                    id: 'gen${generation + 1}_${DateTime.now().millisecondsSinceEpoch}',
                    x: x + (Random().nextDouble() - 0.5) * 10,
                    y: y + (Random().nextDouble() - 0.5) * 10,
                    enableLearning: true,
                    genetics: childGenetics,
                    stage: LifeStage.egg,
                    generation: generation + 1,
                    parent1Id: id,
                    parent2Id: entity.id,
                  ));
                }
              }
            } else {
              // Chemical source ingestion
              internalEnergy += entity.chemicalSignature[0] * motors.interactionAttempt * dt * 10.0;
              damage += entity.chemicalSignature[1] * motors.interactionAttempt * dt * 10.0;
            }
          }
        }
      }

      // 2. Learning Signal
      double reward = (internalEnergy - _prevEnergy) - (damage - _prevDamage);
      if (enableLearning) {
        brain.updateWeights(reward, _lastPredictedValue);
      }

      // 3. Sense
      sensors.update(this, world, dt);

      // 4. Think
      List<double> inputs = [
        ...sensors.chemicalReadings, // 3 floats
        ...sensors.chemicalGradients, // 3 floats
        1.0, // Bias neuron
      ];
      
      List<double> networkOutputs = brain.forward(inputs, learning: enableLearning);
      _lastPredictedValue = networkOutputs[4];

      // 5. Act
      motors.applyOutputs(networkOutputs);
      motors.executePhysics(this);
    } else {
      // Immobile stages still execute physics (friction) to stop moving if they were pushed
      motors.applyOutputs([0, 0, 0, 0]);
      motors.executePhysics(this);
    }
  }
}
