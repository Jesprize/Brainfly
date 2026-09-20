enum ResourceType { food, water, obstacle }

class WorldResource {
  String id;
  ResourceType type;
  double x;
  double y;
  double radius;
  double value;

  WorldResource({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.radius = 10.0,
    this.value = 100.0,
  });
}
