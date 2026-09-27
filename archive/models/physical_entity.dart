import 'dart:math';

enum EntityType {
  organism, // e.g. a Fly
  matter,   // e.g. a rock, food, water
}

class PhysicalEntity {
  final String id;
  EntityType type;
  
  // Spatial properties
  double x;
  double y;
  double heading;
  double radius;
  double mass;

  // Physical properties
  double temperature;
  List<double> chemicalSignature; // Replaces semantic 'ResourceType'

  // Kinematics
  double velocityX = 0;
  double velocityY = 0;
  double angularVelocity = 0;

  // External forces applied this tick
  double forceX = 0;
  double forceY = 0;
  double torque = 0;

  PhysicalEntity({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.heading = 0.0,
    this.radius = 10.0,
    this.mass = 1.0,
    this.temperature = 25.0,
    List<double>? chemicalSignature,
  }) : chemicalSignature = chemicalSignature ?? List.filled(5, 0.0);

  void applyForce(double fx, double fy) {
    forceX += fx;
    forceY += fy;
  }

  void applyTorque(double t) {
    torque += t;
  }
}
