import 'dart:math';
import 'package:flutter/material.dart';
import '../artificial_life/controller/alife_simulation_controller.dart';
import '../artificial_life/core/organism.dart';
import '../artificial_life/core/physical_entity.dart';
import '../artificial_life/world/alife_world.dart';

class ALifeExperimentScreen extends StatefulWidget {
  const ALifeExperimentScreen({super.key});

  @override
  State<ALifeExperimentScreen> createState() => _ALifeExperimentScreenState();
}

class _ALifeExperimentScreenState extends State<ALifeExperimentScreen> with WidgetsBindingObserver {
  late ALifeSimulationController _controller;
  Organism? _selectedOrganism;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ALifeSimulationController();
    _controller.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }
  
  Widget _buildObservatory() {
    if (_selectedOrganism == null) return const SizedBox.shrink();

    final org = _selectedOrganism!;
    
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ALife Observatory', style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedOrganism = null),
                )
              ],
            ),
            const Divider(color: Colors.white24),
            Text('Subject: ${org.id}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            
            const Text('Internal State', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Energy', org.internalEnergy.toStringAsFixed(1)),
            _statRow('Damage', org.damage.toStringAsFixed(1)),
            
            const SizedBox(height: 8),
            const Text('Motor Output', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Thrust', org.motors.forwardThrust.toStringAsFixed(2)),
            _statRow('Turn', org.motors.rotationalTorque.toStringAsFixed(2)),
            _statRow('Interact', org.motors.interactionAttempt.toStringAsFixed(2)),
            
            const SizedBox(height: 8),
            const Text('Sensory Input', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Chem 0 (Ben)', org.sensors.chemicalReadings[0].toStringAsFixed(2)),
            _statRow('Chem 1 (Harm)', org.sensors.chemicalReadings[1].toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ALife V3 Core Test'),
        actions: [
          IconButton(
            icon: Icon(_controller.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                if (_controller.isRunning) {
                  _controller.pause();
                } else {
                  _controller.start();
                }
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _controller.updateSize(constraints.maxWidth, constraints.maxHeight);
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: const Color(0xFF1A1A24), // Slightly different background to distinguish
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (details) {
                        Organism? closest;
                        double closestDist = double.infinity;
                        for (var e in _controller.world.entities) {
                          if (e is Organism) {
                             double dist = sqrt(pow(e.x - details.localPosition.dx, 2) + pow(e.y - details.localPosition.dy, 2));
                             if (dist < 30 && dist < closestDist) {
                               closest = e;
                               closestDist = dist;
                             }
                          }
                        }
                        setState(() {
                          _selectedOrganism = closest;
                        });
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: ALifePainter(_controller.world, _selectedOrganism),
                      ),
                    ),
                    _buildObservatory(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ALifePainter extends CustomPainter {
  final ALifeWorld world;
  final Organism? selectedOrganism;

  ALifePainter(this.world, this.selectedOrganism);

  @override
  void paint(Canvas canvas, Size size) {
    for (var entity in world.entities) {
      if (entity is Organism) {
        // Draw selected ring
        if (selectedOrganism != null && entity.id == selectedOrganism!.id) {
          canvas.drawCircle(Offset(entity.x, entity.y), 25, Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 2.0);
        }

        // Base simple rendering for biology
        canvas.save();
        canvas.translate(entity.x, entity.y);
        canvas.rotate(entity.heading);
        
        // Simple fly body
        canvas.drawOval(Rect.fromCenter(center: const Offset(-4, 0), width: 10, height: 6), Paint()..color = Colors.blueGrey); // Abdomen
        canvas.drawOval(Rect.fromCenter(center: const Offset(2, 0), width: 8, height: 6), Paint()..color = Colors.grey[700]!); // Thorax
        canvas.drawCircle(const Offset(6, 0), 2.5, Paint()..color = Colors.black87); // Head

        // Wings flapping based on physical movement
        double speed = sqrt(entity.velocityX * entity.velocityX + entity.velocityY * entity.velocityY);
        double wingAngle = (speed > 5) ? sin(DateTime.now().millisecondsSinceEpoch / 20.0) * 0.5 : 0.2;
        final wingPaint = Paint()..color = Colors.white.withOpacity(0.6);
        
        canvas.save();
        canvas.translate(1, -2);
        canvas.rotate(-wingAngle - 0.5);
        canvas.drawOval(Rect.fromCenter(center: const Offset(-4, -4), width: 10, height: 4), wingPaint);
        canvas.restore();

        canvas.save();
        canvas.translate(1, 2);
        canvas.rotate(wingAngle + 0.5);
        canvas.drawOval(Rect.fromCenter(center: const Offset(-4, 4), width: 10, height: 4), wingPaint);
        canvas.restore();

        canvas.restore();
      } else {
        // Draw physical resources
        Color c = Colors.grey;
        if (entity.chemicalSignature[0] > 0) {
           c = Colors.greenAccent.withOpacity(0.5);
        } else if (entity.chemicalSignature[1] > 0) {
           c = Colors.redAccent.withOpacity(0.5);
        }
        canvas.drawCircle(Offset(entity.x, entity.y), entity.radius, Paint()..color = c);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ALifePainter oldDelegate) => true;
}
