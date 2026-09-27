import '../core/physical_entity.dart';

class MotorSystem {
  // Motor Outputs (-1.0 to 1.0)
  double forwardThrust = 0.0;
  double lateralThrust = 0.0;
  double rotationalTorque = 0.0;
  double interactionAttempt = 0.0;

  final double maxForce = 200.0;
  final double maxTorque = 200.0;

  void applyOutputs(List<double> outputs) {
    if (outputs.length < 4) return;
    forwardThrust = outputs[0].clamp(-1.0, 1.0);
    lateralThrust = outputs[1].clamp(-1.0, 1.0);
    rotationalTorque = outputs[2].clamp(-1.0, 1.0);
    interactionAttempt = outputs[3].clamp(-1.0, 1.0);
  }

  void executePhysics(PhysicalEntity self) {
    self.applyLocalForce(forwardThrust * maxForce, lateralThrust * maxForce);
    self.applyTorque(rotationalTorque * maxTorque);
  }
}
