import 'dart:math';
import 'neural_network.dart';

class ExperienceRecord {
  final List<double> inputs;
  final List<double> outputs;
  final double reward;
  ExperienceRecord(this.inputs, this.outputs, this.reward);
}

class Brain {
  late NeuralNetwork network;
  
  // Generic Episodic Memory (Not inherited)
  double? memoryX;
  double? memoryY;
  
  // Output states
  double currentSpeed = 0.0;
  double currentTurnAngle = 0.0;
  double currentSignalEmit = 0.0;
  double confidence = 0.0;

  final List<ExperienceRecord> experiences = [];

  Brain({NeuralNetwork? initialNetwork}) {
    network = initialNetwork ?? NeuralNetwork();
  }

  void process(
    double flyX, double flyY, double flyHeading,
    double distE1, double angleE1, double densityE1,
    double distE2, double angleE2, double densityE2,
    double distFly, double angleFly,
    double neighborSignal,
    double collisionContact,
    double needEnergy, double needHydration,
    double rewardDelta,
  ) {
    // 1. Generic Episodic Memory Update
    if (rewardDelta > 5.0) {
      memoryX = flyX;
      memoryY = flyY;
    }

    // 2. Prepare Inputs
    List<double> inputs = List.filled(network.numInputs, 0.0);
    
    // Normalized Needs (0 to 1) mapped to -1 to 1
    inputs[0] = (needEnergy / 100.0) * 2.0 - 1.0; 
    inputs[1] = (needHydration / 100.0) * 2.0 - 1.0;
    
    // Closest Entity
    inputs[2] = distE1 != double.infinity ? 1.0 - (distE1 / 100.0).clamp(0.0, 1.0) : -1.0;
    inputs[3] = angleE1 / pi;

    // Second Closest Entity
    inputs[4] = distE2 != double.infinity ? 1.0 - (distE2 / 100.0).clamp(0.0, 1.0) : -1.0;
    inputs[5] = angleE2 / pi;

    // Closest Fly
    inputs[6] = distFly != double.infinity ? 1.0 - (distFly / 100.0).clamp(0.0, 1.0) : -1.0;
    inputs[7] = angleFly / pi;

    // Signal and Contact
    inputs[8] = neighborSignal;
    inputs[9] = collisionContact;

    // Memory
    if (memoryX != null && memoryY != null) {
      double dx = memoryX! - flyX;
      double dy = memoryY! - flyY;
      double dist = sqrt(dx * dx + dy * dy);
      inputs[10] = 1.0 - (dist / 200.0).clamp(0.0, 1.0);
      inputs[11] = _relativeAngle(dx, dy, flyHeading) / pi;
    } else {
      inputs[10] = -1.0;
      inputs[11] = 0.0;
    }

    // Stage E Refinements
    inputs[12] = densityE1;
    inputs[13] = densityE2;
    inputs[14] = rewardDelta;

    // 3. Process Neural Network
    List<double> outputs = network.process(inputs, rewardDelta);

    // 4. Map Outputs
    currentSpeed = (outputs[0] + 1.0) * 1.5; // -1 to 1 mapped to 0 to 3
    currentTurnAngle = outputs[1] * 0.5;
    currentSignalEmit = outputs[2] > 0 ? outputs[2] : 0.0;

    // Calculate confidence (magnitude of active decisions)
    confidence = (outputs[0].abs() + outputs[1].abs() + outputs[2].abs()) / 3.0;

    // 5. Log Experience
    if (network.ticksSincePerturb == 0) {
      experiences.insert(0, ExperienceRecord(List.from(inputs), List.from(outputs), network.accumulatedReward));
      if (experiences.length > 500) experiences.removeLast();
    }
  }

  // Returns a readable string translating internal state (for the UI)
  String getTranslatedState(double needEnergy, double needHydration) {
    if (needEnergy < 30 || needHydration < 30) return "Needs critical (Seeking)";
    if (currentSignalEmit > 0.5) return "Signaling Swarm";
    if (memoryX != null && currentSpeed > 1.5) return "Moving to Memory";
    if (currentSpeed < 0.5) return "Resting / Interacting";
    return "Exploring / Wandering";
  }

  double _relativeAngle(double dx, double dy, double fHeading) {
    double absoluteAngle = atan2(dy, dx);
    double relativeAngle = absoluteAngle - fHeading;
    while (relativeAngle > pi) relativeAngle -= 2 * pi;
    while (relativeAngle < -pi) relativeAngle += 2 * pi;
    return relativeAngle;
  }
}
