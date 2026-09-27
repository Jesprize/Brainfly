import 'dart:math';

class PhysicalEntity {
  final String id;
  
  // Spatial
  double x;
  double y;
  double heading;
  double radius;
  double mass;

  // Kinematics
  double velocityX = 0;
  double velocityY = 0;
  double angularVelocity = 0;

  // Forces
  double forceX = 0;
  double forceY = 0;
  double torque = 0;

  // Properties
  List<double> chemicalSignature;

  PhysicalEntity({
    required this.id,
    required this.x,
    required this.y,
    this.heading = 0.0,
    this.radius = 10.0,
    this.mass = 1.0,
    List<double>? chemicalSignature,
  }) : chemicalSignature = chemicalSignature ?? List.filled(3, 0.0);

  void applyForce(double fx, double fy) {
    forceX += fx;
    forceY += fy;
  }

  void applyLocalForce(double forward, double lateral) {
    forceX += cos(heading) * forward - sin(heading) * lateral;
    forceY += sin(heading) * forward + cos(heading) * lateral;
  }

  void applyTorque(double t) {
    torque += t;
  }
}
