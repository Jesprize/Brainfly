import 'physical_entity.dart';
import '../world/alife_world.dart';
import '../sensors/sensory_system.dart';
import '../motor/motor_system.dart';
import '../brain/alife_network.dart';

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

  Organism({
    required super.id,
    required super.x,
    required super.y,
    this.enableLearning = true,
  }) : sensors = SensorySystem(),
       motors = MotorSystem(),
       brain = ALifeNetwork(6, 12, 5); // 3 Chem, 3 Grad -> 4 Motor, 1 Critic

  void biologicalTick(ALifeWorld world, double dt) {
    // 1. Biological Consequence of Interaction
    // If we are touching a chemical source, ingest it.
    // Interaction Attempt is a motor output [-1 to 1]
    _prevEnergy = internalEnergy;
    _prevDamage = damage;
    
    // Base metabolic cost of movement and existing
    double physicalExertion = (motors.forwardThrust.abs() + motors.lateralThrust.abs() + motors.rotationalTorque.abs());
    internalEnergy -= (0.01 + 0.02 * physicalExertion) * dt;

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
          // chemicalSignature[0] = Energy yielding
          // chemicalSignature[1] = Damage yielding
          internalEnergy += entity.chemicalSignature[0] * motors.interactionAttempt * dt * 10.0;
          damage += entity.chemicalSignature[1] * motors.interactionAttempt * dt * 10.0;
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
    ];
    
    List<double> networkOutputs = brain.forward(inputs, learning: enableLearning);
    _lastPredictedValue = networkOutputs[4];

    // 5. Act
    motors.applyOutputs(networkOutputs);
    motors.executePhysics(this);
  }
}
