import 'package:flutter/material.dart';
import '../artificial_life/biology/brain/swc_parser.dart';

class SwcVisualizer extends StatelessWidget {
  final SwcNeuron neuron;
  final double width;
  final double height;

  const SwcVisualizer({
    super.key,
    required this.neuron,
    this.width = 200,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (neuron.nodes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _SwcPainter(neuron),
      ),
    );
  }
}

class _SwcPainter extends CustomPainter {
  final SwcNeuron neuron;

  _SwcPainter(this.neuron);

  @override
  void paint(Canvas canvas, Size size) {
    if (neuron.nodes.isEmpty) return;

    // Find bounding box
    double minX = neuron.nodes[0].x, maxX = minX;
    double minY = neuron.nodes[0].y, maxY = minY;
    
    Map<int, SwcNode> nodeMap = {};

    for (var node in neuron.nodes) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
      nodeMap[node.id] = node;
    }

    double rangeX = maxX - minX;
    double rangeY = maxY - minY;
    
    // Avoid division by zero
    if (rangeX == 0) rangeX = 1;
    if (rangeY == 0) rangeY = 1;

    double padding = 10.0;
    double drawWidth = size.width - padding * 2;
    double drawHeight = size.height - padding * 2;
    
    // Keep aspect ratio
    double scale = (drawWidth / rangeX < drawHeight / rangeY) ? (drawWidth / rangeX) : (drawHeight / rangeY);

    Offset getOffset(SwcNode n) {
      double cx = (n.x - minX) * scale + padding;
      double cy = (n.y - minY) * scale + padding;
      // Center it
      cx += (drawWidth - rangeX * scale) / 2;
      cy += (drawHeight - rangeY * scale) / 2;
      return Offset(cx, cy);
    }

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final somaPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    // Draw lines
    for (var node in neuron.nodes) {
      if (node.parentId != -1 && nodeMap.containsKey(node.parentId)) {
        var parent = nodeMap[node.parentId]!;
        canvas.drawLine(getOffset(node), getOffset(parent), linePaint);
      }
    }

    // Draw soma (type 1 usually)
    for (var node in neuron.nodes) {
      if (node.type == 1) {
        canvas.drawCircle(getOffset(node), 4.0, somaPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SwcPainter oldDelegate) => false;
}
