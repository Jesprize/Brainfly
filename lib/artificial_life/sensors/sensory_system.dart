import 'dart:math';
import '../core/physical_entity.dart';
import '../world/alife_world.dart';

class SensorySystem {
  final int chemicalChannels = 3;
  
  // Sensory outputs
  List<double> get chemicalReadings => _chemicalReadings;
  List<double> _chemicalReadings = List.filled(3, 0.0);
  
  // To compute gradient
  List<double> _prevChemicalReadings = List.filled(3, 0.0);
  List<double> get chemicalGradients => _chemicalGradients;
  List<double> _chemicalGradients = List.filled(3, 0.0);

  // Simple tactile/collision proxy: if velocity drops sharply, we hit something.
  double collisionIntensity = 0.0;
  
  // Internal State
  double internalEnergy = 1.0;
  
  void update(PhysicalEntity self, ALifeWorld world, double dt) {
    // 1. Tactile/Collision
    // Simple heuristic: if forces were high but velocity is low, we hit a wall or entity
    collisionIntensity = 0.0;
    
    // 2. Olfactory (Chemicals)
    // Read ambient chemicals from all nearby entities based on distance
    for (int i=0; i<chemicalChannels; i++) {
      _prevChemicalReadings[i] = _chemicalReadings[i];
      _chemicalReadings[i] = 0.0;
    }

    for (var entity in world.entities) {
      if (entity == self) continue;
      double dx = entity.x - self.x;
      double dy = entity.y - self.y;
      double distSq = dx*dx + dy*dy;
      if (distSq < 160000) { // 400 radius max detection
        double dist = sqrt(distSq);
        double intensity = 1.0 - (dist / 400.0);
        for (int i=0; i<chemicalChannels && i<entity.chemicalSignature.length; i++) {
          _chemicalReadings[i] += entity.chemicalSignature[i] * intensity;
        }
      }
    }

    for (int i=0; i<chemicalChannels; i++) {
      _chemicalGradients[i] = _chemicalReadings[i] - _prevChemicalReadings[i];
    }
  }
}
