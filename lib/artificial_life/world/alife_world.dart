import 'dart:math';
import '../core/physical_entity.dart';

class ALifeWorld {
  double width;
  double height;
  List<PhysicalEntity> entities = [];
  final List<PhysicalEntity> _pendingEntities = [];
  final List<String> events = [];

  ALifeWorld({this.width = 1000, this.height = 1000});

  void logEvent(String message) {
    String timeStr = DateTime.now().toIso8601String().substring(11, 19);
    events.insert(0, '[$timeStr] $message');
    if (events.length > 50) {
      events.removeLast();
    }
  }

  void addEntity(PhysicalEntity entity) {
    _pendingEntities.add(entity);
  }

  void flushPendingEntities() {
    entities.addAll(_pendingEntities);
    _pendingEntities.clear();
  }
  
  void removeDead() {
    entities.removeWhere((e) => e.mass == 0 && e.radius < 5); // Example of cleanup if needed, but for now dead bodies can persist with mass=0
  }

  void physicsTick(double dt) {
    // 1. Integration
    for (var e in entities) {
      if (e.mass <= 0) continue;

      e.velocityX += (e.forceX / e.mass) * dt;
      e.velocityY += (e.forceY / e.mass) * dt;
      
      // Friction
      e.velocityX *= 0.9;
      e.velocityY *= 0.9;

      e.x += e.velocityX * dt;
      e.y += e.velocityY * dt;

      e.angularVelocity += (e.torque / (e.mass * e.radius * e.radius * 0.5)) * dt;
      e.angularVelocity *= 0.8;
      e.heading += e.angularVelocity * dt;

      while (e.heading > pi) e.heading -= 2 * pi;
      while (e.heading < -pi) e.heading += 2 * pi;

      e.forceX = 0;
      e.forceY = 0;
      e.torque = 0;
    }

    // 2. Boundary Collisions
    for (var e in entities) {
      if (e.x < e.radius) { e.x = e.radius; e.velocityX *= -0.5; }
      else if (e.x > width - e.radius) { e.x = width - e.radius; e.velocityX *= -0.5; }
      
      if (e.y < e.radius) { e.y = e.radius; e.velocityY *= -0.5; }
      else if (e.y > height - e.radius) { e.y = height - e.radius; e.velocityY *= -0.5; }
    }

    // 3. Entity Collisions
    for (int i = 0; i < entities.length; i++) {
      for (int j = i + 1; j < entities.length; j++) {
        var e1 = entities[i];
        var e2 = entities[j];

        double dx = e2.x - e1.x;
        double dy = e2.y - e1.y;
        double distSq = dx * dx + dy * dy;
        double rSum = e1.radius + e2.radius;

        if (distSq > 0 && distSq < rSum * rSum) {
          double dist = sqrt(distSq);
          double overlap = rSum - dist;
          double nx = dx / dist;
          double ny = dy / dist;

          double totalMass = e1.mass + e2.mass;
          double ratio1 = e2.mass / totalMass;
          double ratio2 = e1.mass / totalMass;

          e1.x -= nx * overlap * ratio1;
          e1.y -= ny * overlap * ratio1;
          e2.x += nx * overlap * ratio2;
          e2.y += ny * overlap * ratio2;
        }
      }
    }
  }
}
