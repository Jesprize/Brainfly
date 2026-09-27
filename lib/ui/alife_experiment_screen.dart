import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'scientist_sidebar.dart';
import '../artificial_life/controller/alife_simulation_controller.dart';
import '../artificial_life/core/organism.dart';
import '../artificial_life/core/physical_entity.dart';
import '../artificial_life/world/alife_world.dart';
import '../artificial_life/core/biology.dart';

class ALifeExperimentScreen extends StatefulWidget {
  const ALifeExperimentScreen({super.key});

  @override
  State<ALifeExperimentScreen> createState() => _ALifeExperimentScreenState();
}

class _ALifeExperimentScreenState extends State<ALifeExperimentScreen> with WidgetsBindingObserver {
  late ALifeSimulationController _controller;
  Organism? _selectedOrganism;
  ui.Image? _flyImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ALifeSimulationController();
    _controller.start();
    _loadFlyImage();
  }

  Future<void> _loadFlyImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/flies/drosophila_adult.png');
      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image img) {
        return completer.complete(img);
      });
      _flyImage = await completer.future;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Could not load fly image: $e");
    }
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
  

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        
        Widget mainSimulationArea = Container(
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
                      size: Size(isDesktop ? constraints.maxWidth - 350 : constraints.maxWidth, constraints.maxHeight),
                      painter: ALifePainter(_controller.world, _selectedOrganism, _flyImage),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        if (isDesktop) {
          _controller.updateSize(constraints.maxWidth - 350, constraints.maxHeight);
        } else {
          _controller.updateSize(constraints.maxWidth, constraints.maxHeight);
        }

        Widget sidebar = ScientistSidebar(
          controller: _controller,
          selectedOrganism: _selectedOrganism,
          onSelectOrganism: (o) => setState(() => _selectedOrganism = o),
        );

        return Scaffold(
          appBar: isDesktop ? null : AppBar(
            title: const Text('BrainFly Engine'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.science),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: isDesktop ? null : sidebar,
          body: isDesktop ? Row(
            children: [
              Expanded(child: mainSimulationArea),
              sidebar,
            ],
          ) : mainSimulationArea,
        );
      },
    );
  }
}

class ALifePainter extends CustomPainter {
  final ALifeWorld world;
  final Organism? selectedOrganism;
  final ui.Image? flyImage;

  ALifePainter(this.world, this.selectedOrganism, this.flyImage);

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
        
        // Render differently based on stage
        if (entity.stage == LifeStage.egg) {
          canvas.drawCircle(const Offset(0, 0), 4, Paint()..color = Colors.white70);
          canvas.restore();
          continue;
        } else if (entity.stage == LifeStage.pupa) {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 12, height: 8), Paint()..color = Colors.brown[800]!);
          canvas.restore();
          continue;
        } else if (entity.stage == LifeStage.dead) {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 10, height: 6), Paint()..color = Colors.grey[800]!);
          canvas.drawLine(const Offset(-4, -4), const Offset(4, 4), Paint()..color = Colors.black..strokeWidth = 1);
          canvas.drawLine(const Offset(-4, 4), const Offset(4, -4), Paint()..color = Colors.black..strokeWidth = 1);
          canvas.restore();
          continue;
        }

        double scale = (entity.stage == LifeStage.adult) ? 1.0 : 0.6;
        canvas.scale(scale, scale);

        if (entity.stage == LifeStage.adult && flyImage != null) {
          double imgWidth = flyImage!.width.toDouble();
          double imgHeight = flyImage!.height.toDouble();
          double targetWidth = 32.0; 
          double scaleX = targetWidth / imgWidth;
          double scaleY = targetWidth / imgHeight;
          
          canvas.save();
          // Adjust rotation because generated images usually point UP, and heading 0 is RIGHT (X-axis)
          canvas.rotate(pi / 2);
          canvas.scale(scaleX, scaleY);
          
          // Draw image centered
          canvas.drawImage(flyImage!, Offset(-imgWidth / 2, -imgHeight / 2), Paint());
          canvas.restore();
        } else {
          Color bodyColor = entity.sex == Sex.female ? Colors.blueGrey[300]! : Colors.blueGrey[700]!;
          
          // Simple fly body fallback
          canvas.drawOval(Rect.fromCenter(center: const Offset(-4, 0), width: 10, height: 6), Paint()..color = bodyColor); // Abdomen
          canvas.drawOval(Rect.fromCenter(center: const Offset(2, 0), width: 8, height: 6), Paint()..color = Colors.grey[800]!); // Thorax
          canvas.drawCircle(const Offset(6, 0), 2.5, Paint()..color = Colors.black87); // Head

          // Wings flapping based on physical movement (only for adults)
          if (entity.stage == LifeStage.adult) {
            double speed = sqrt(entity.velocityX * entity.velocityX + entity.velocityY * entity.velocityY);
            double wingAngle = (speed > 5) ? sin(DateTime.now().millisecondsSinceEpoch / 20.0) * 0.5 : 0.2;
            final wingPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
            
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
          }
        }

        canvas.restore();
      } else {
        // Draw physical resources
        Color c = Colors.grey;
        if (entity.chemicalSignature[0] > 0) {
           c = Colors.greenAccent.withValues(alpha: 0.5);
        } else if (entity.chemicalSignature[1] > 0) {
           c = Colors.redAccent.withValues(alpha: 0.5);
        }
        canvas.drawCircle(Offset(entity.x, entity.y), entity.radius, Paint()..color = c);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ALifePainter oldDelegate) => true;
}
