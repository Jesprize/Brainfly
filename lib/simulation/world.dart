import 'dart:math';
import 'physical_entity.dart';

class World {
  final double width;
  final double height;

  final List<PhysicalEntity> entities = [];

  World({this.width = 1000, this.height = 1000});

  void addEntity(PhysicalEntity entity) {
    entities.add(entity);
  }

  void removeEntity(PhysicalEntity entity) {
    entities.remove(entity);
  }

  // Purely physical update step (no semantic logic like "feeding" or "reproducing")
  void physicsTick(double dt) {
    // 1. Integrate kinematics (forces -> velocity -> position)
    for (var entity in entities) {
      if (entity.mass <= 0) continue;

      // Linear
      double accelX = entity.forceX / entity.mass;
      double accelY = entity.forceY / entity.mass;
      
      entity.velocityX += accelX * dt;
      entity.velocityY += accelY * dt;
      
      // Basic friction/drag
      entity.velocityX *= 0.9; 
      entity.velocityY *= 0.9;

      entity.x += entity.velocityX * dt;
      entity.y += entity.velocityY * dt;

      // Angular
      double angularAccel = entity.torque / (entity.mass * entity.radius * entity.radius * 0.5); // Disk approximation
      entity.angularVelocity += angularAccel * dt;
      entity.angularVelocity *= 0.8; // Angular drag

      entity.heading += entity.angularVelocity * dt;
      
      // Normalize heading
      while (entity.heading > pi) entity.heading -= 2 * pi;
      while (entity.heading < -pi) entity.heading += 2 * pi;

      // Reset forces for next tick
      entity.forceX = 0;
      entity.forceY = 0;
      entity.torque = 0;
    }

    // 2. Simple Boundary Collisions
    for (var entity in entities) {
      if (entity.x < entity.radius) {
        entity.x = entity.radius;
        entity.velocityX *= -0.5; // Bounce
      } else if (entity.x > width - entity.radius) {
        entity.x = width - entity.radius;
        entity.velocityX *= -0.5;
      }

      if (entity.y < entity.radius) {
        entity.y = entity.radius;
        entity.velocityY *= -0.5;
      } else if (entity.y > height - entity.radius) {
        entity.y = height - entity.radius;
        entity.velocityY *= -0.5;
      }
    }

    // 3. Entity-to-Entity Collision (Elastic spheres)
    for (int i = 0; i < entities.length; i++) {
      for (int j = i + 1; j < entities.length; j++) {
        var e1 = entities[i];
        var e2 = entities[j];

        double dx = e2.x - e1.x;
        double dy = e2.y - e1.y;
        double distSq = dx * dx + dy * dy;
        double radiusSum = e1.radius + e2.radius;

        if (distSq < radiusSum * radiusSum && distSq > 0) {
          double dist = sqrt(distSq);
          double overlap = radiusSum - dist;
          
          // Normalized collision vector
          double nx = dx / dist;
          double ny = dy / dist;

          // Push them apart inversely proportional to mass
          double totalMass = e1.mass + e2.mass;
          double e1Ratio = e2.mass / totalMass;
          double e2Ratio = e1.mass / totalMass;

          e1.x -= nx * overlap * e1Ratio;
          e1.y -= ny * overlap * e1Ratio;
          e2.x += nx * overlap * e2Ratio;
          e2.y += ny * overlap * e2Ratio;
          
          // (In a full engine, we'd also exchange momentum here)
        }
      }
    }
  }
}
