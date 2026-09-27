import 'package:flutter_test/flutter_test.dart';
import 'package:brain_fly/artificial_life/core/physical_entity.dart';
import 'package:brain_fly/artificial_life/core/organism.dart';
import 'package:brain_fly/artificial_life/world/alife_world.dart';

void main() {
  test('Minimum Emergent-Learning Test - Sensory Association', () {
    ALifeWorld world = ALifeWorld(width: 400, height: 400);

    var entityA = PhysicalEntity(
      id: 'A', x: 200, y: 200, chemicalSignature: [1.0, 0.0, 0.0], mass: 0.0, radius: 20,
    );

    var entityB = PhysicalEntity(
      id: 'B', x: 200, y: 200, chemicalSignature: [0.0, 1.0, 0.0], mass: 0.0, radius: 20,
    );

    var learner = Organism(id: 'Learner', x: 200, y: 200, enableLearning: true);
    var control = Organism(id: 'Control', x: 200, y: 200, enableLearning: false);

    for (int i=0; i<learner.brain.w1.length; i++) control.brain.w1[i] = learner.brain.w1[i];
    for (int i=0; i<learner.brain.w2.length; i++) control.brain.w2[i] = learner.brain.w2[i];

    Map<String, double> runAssociationBlock(Organism agent, int ticks) {
      double interactionsWithA = 0;
      double interactionsWithB = 0;

      for (int i = 0; i < ticks; i++) {
        world.entities.clear();
        // Alternate between A and B
        bool isA = (i ~/ 100) % 2 == 0;
        world.addEntity(isA ? entityA : entityB);
        
        // Keep agent centered
        agent.x = 200; agent.y = 200;
        agent.velocityX = 0; agent.velocityY = 0;
        agent.motors.forwardThrust = 0; agent.motors.rotationalTorque = 0;

        agent.biologicalTick(world, 0.016);
        
        if (agent.motors.interactionAttempt > 0.0) {
          if (isA) interactionsWithA++;
          else interactionsWithB++;
        }
      }
      return {'A': interactionsWithA, 'B': interactionsWithB};
    }

    print("--- RUNNING TRAINING PHASE ---");
    runAssociationBlock(learner, 5000);

    print("--- RUNNING POST-TRAINING EVALUATION ---");
    learner.enableLearning = false;
    var postLearner = runAssociationBlock(learner, 2000);
    var postControl = runAssociationBlock(control, 2000);

    print("Learner Interactions -> A: ${postLearner['A']}, B: ${postLearner['B']}");
    print("Control Interactions -> A: ${postControl['A']}, B: ${postControl['B']}");

    // It should learn to interact with A much more than B
    expect(postLearner['A']! > postLearner['B']!, true, reason: "Learner did not prefer A over B.");
    expect(postLearner['A']! > postControl['A']!, true, reason: "Learner did not improve over control.");
  });
}
