import 'dart:convert';
import 'package:flutter/services.dart';

class SwcNode {
  final int id;
  final int type;
  final double x;
  final double y;
  final double z;
  final double radius;
  final int parentId;

  SwcNode({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.radius,
    required this.parentId,
  });
}

class SwcNeuron {
  final String neuronId;
  final List<SwcNode> nodes;

  SwcNeuron({required this.neuronId, required this.nodes});

  static Future<SwcNeuron?> loadFromAssets(String path) async {
    try {
      final String contents = await rootBundle.loadString(path);
      List<SwcNode> parsedNodes = [];
      
      for (String line in const LineSplitter().convert(contents)) {
        if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
        
        List<String> parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 7) {
          parsedNodes.add(SwcNode(
            id: int.parse(parts[0]),
            type: int.parse(parts[1]),
            x: double.parse(parts[2]),
            y: double.parse(parts[3]),
            z: double.parse(parts[4]),
            radius: double.parse(parts[5]),
            parentId: int.parse(parts[6]),
          ));
        }
      }
      
      if (parsedNodes.isEmpty) return null;
      
      String nId = path.split('/').last.split('.').first;
      return SwcNeuron(neuronId: nId, nodes: parsedNodes);
    } catch (e) {
      return null;
    }
  }
}
