import 'dart:math';
import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../models/gender.dart';
import '../models/world_resource.dart';
import '../models/fly.dart';
import '../models/life_stage.dart';
import '../simulation/simulation_engine.dart';
import '../services/storage_service.dart';

class ExperimentScreen extends StatefulWidget {
  final Experiment experiment;

  const ExperimentScreen({super.key, required this.experiment});

  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> with WidgetsBindingObserver {
  late SimulationEngine _engine;
  bool _showDashboard = true;
  Fly? _selectedFly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = SimulationEngine();
    _engine.loadExperiment(widget.experiment);
    _engine.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.pause();
    _engine.dispose();
    StorageService.saveExperiment(_engine.experiment!); // Save on exit
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _engine.pause();
      if (_engine.experiment != null) {
        StorageService.saveExperiment(_engine.experiment!);
      }
    } else if (state == AppLifecycleState.resumed) {
      _engine.start();
    }
  }

  Widget _buildDashboard() {
    final exp = _engine.experiment!;
    double totalSpeed = 0;
    double totalRange = 0;
    int livingFlies = 0;
    for (var f in exp.flyList) {
      if (!f.isDead) {
        totalSpeed += f.genetics.speedMultiplier;
        totalRange += f.genetics.sensorRange;
        livingFlies++;
      }
    }
    double avgSpeed = livingFlies > 0 ? totalSpeed / livingFlies : 0;
    double avgRange = livingFlies > 0 ? totalRange / livingFlies : 0;
    
    // Ticks to time (60 ticks per sec)
    int seconds = exp.ageTicks ~/ 60;
    int minutes = seconds ~/ 60;
    seconds = seconds % 60;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: 20,
      left: _showDashboard ? 20 : -250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 230,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lab Dashboard', style: TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24),
                _statRow('Time', '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'),
                _statRow('Population', '$livingFlies'),
                _statRow('Total Births', '${exp.totalBirths}'),
                _statRow('Total Deaths', '${exp.totalDeaths}'),
                const Divider(color: Colors.white24),
                _statRow('Avg Speed', avgSpeed.toStringAsFixed(2)),
                _statRow('Avg Sensor', avgRange.toStringAsFixed(1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_showDashboard ? Icons.chevron_left : Icons.chevron_right, color: Colors.white),
            onPressed: () {
              setState(() {
                _showDashboard = !_showDashboard;
              });
            },
            style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildBiologyObservatory(Fly fly) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biology Observatory', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => setState(() => _selectedFly = null))
              ],
            ),
            const Divider(color: Colors.white24),
            Text('Entity: ${fly.id.split('_').last}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            
            if (fly.isDead) ...[
               const SizedBox(height: 8),
               const Text('STATUS: DECEASED', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
               _statRow('Cause', fly.causeOfDeath ?? 'Unknown'),
               _statRow('Final Stage', fly.stage.name.toUpperCase()),
               _statRow('Final Age', '${fly.age} ticks'),
            ] else ...[
               const SizedBox(height: 8),
               _statRow('Stage', fly.stage.name.toUpperCase()),
               if (fly.stage == LifeStage.larva) _statRow('Instar', '${fly.instar}/3'),
               _statRow('Age in Stage', '${fly.age} ticks'),
               
               const SizedBox(height: 12),
               const Text('Vital Signs', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
               _progressBar('Energy', fly.need.energy / 100.0, Colors.redAccent),
               _progressBar('Hydration', fly.need.hydration / 100.0, Colors.blueAccent),
            ],
            
            const SizedBox(height: 12),
            const Text('Genetics', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Speed', fly.genetics.speedMultiplier.toStringAsFixed(2)),
            _statRow('Senses', fly.genetics.sensorRange.toStringAsFixed(0)),
            _statRow('Metabolism', fly.genetics.metabolismRate.toStringAsFixed(2)),
            
            const SizedBox(height: 12),
            const Text('Parentage', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Parent 1', fly.parentId1?.split('_').last ?? 'Unknown'),
            _statRow('Parent 2', fly.parentId2?.split('_').last ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildMindObservatory() {
    // Refresh selected fly reference if it died or changed
    if (_selectedFly != null) {
      try {
        _selectedFly = _engine.experiment!.flyList.firstWhere((f) => f.id == _selectedFly!.id);
      } catch (e) {
        _selectedFly = null;
      }
    }

    if (_selectedFly == null) return const SizedBox.shrink();

    final fly = _selectedFly!;
    if (fly.isDead || fly.stage != LifeStage.adult) {
      return _buildBiologyObservatory(fly);
    }
    
    final b = fly.brain;

    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurpleAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mind Observatory', style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedFly = null),
                )
              ],
            ),
            const Divider(color: Colors.white24),
            Text('Subject: ${fly.id.split('_').last}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            
            // Needs
            const Text('Internal State', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _progressBar('Energy', fly.need.energy / 100.0, Colors.redAccent),
            _progressBar('Hydration', fly.need.hydration / 100.0, Colors.blueAccent),
            const SizedBox(height: 8),

            // Actions
            const Text('Current Action', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Speed', b.currentSpeed.toStringAsFixed(2)),
            _statRow('Turn', b.currentTurnAngle.toStringAsFixed(2)),
            _statRow('Signal', b.currentSignalEmit.toStringAsFixed(2)),
            const SizedBox(height: 8),

            // Telemetry
            const Text('Telemetry', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            _statRow('Confidence', '${(b.confidence * 100).toStringAsFixed(0)}%'),
            _statRow('Recent Reward', fly.lastReward.toStringAsFixed(2)),
            _statRow('Memory X', b.memoryX?.toStringAsFixed(0) ?? 'None'),
            const SizedBox(height: 8),

            // Translated
            const Text('Translated State', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(b.getTranslatedState(fly.need.energy, fly.need.hydration), style: const TextStyle(color: Colors.yellowAccent, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showExperienceLog(fly),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('View Experience Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withOpacity(0.2),
                  foregroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExperienceLog(Fly fly) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: Text('Experience Log: ${fly.id.split('_').last}', style: const TextStyle(color: Colors.tealAccent)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: fly.brain.experiences.length,
              itemBuilder: (context, index) {
                final record = fly.brain.experiences[index];
                final rColor = record.reward > 0 ? Colors.greenAccent : (record.reward < 0 ? Colors.redAccent : Colors.grey);
                return ListTile(
                  title: Text('Tick -${(index + 1) * 60}', style: const TextStyle(color: Colors.white70)),
                  subtitle: Text('R: ${record.reward.toStringAsFixed(2)} | Out: ${record.outputs.map((e)=>e.toStringAsFixed(1)).join(',')}', style: TextStyle(color: rColor)),
                  dense: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.tealAccent)),
            )
          ],
        );
      }
    );
  }

  Widget _progressBar(String label, double val, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))),
          Expanded(child: LinearProgressIndicator(value: val, backgroundColor: Colors.white12, color: c)),
        ],
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
        title: Text('Experiment ${_engine.experiment?.id ?? ""}'),
        actions: [
          IconButton(
            icon: Icon(_engine.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                if (_engine.isRunning) {
                  _engine.pause();
                } else {
                  _engine.start();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              StorageService.saveExperiment(_engine.experiment!);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiment Saved')));
            },
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _engine.updateSize(constraints.maxWidth, constraints.maxHeight);
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: const Color(0xFF121212),
            child: ListenableBuilder(
              listenable: _engine,
              builder: (context, child) {
                return Stack(
                  children: [
                    GestureDetector(
                      onTapDown: (details) {
                        Fly? closestFly;
                        double closestDist = double.infinity;
                        for (var f in _engine.experiment!.flyList) {
                           double dist = sqrt(pow(f.x - details.localPosition.dx, 2) + pow(f.y - details.localPosition.dy, 2));
                           if (dist < 30 && dist < closestDist) {
                             closestFly = f;
                             closestDist = dist;
                           }
                        }
                        setState(() {
                          _selectedFly = closestFly;
                        });
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: LabPainter(_engine.experiment!, _selectedFly),
                      ),
                    ),
                    _buildDashboard(),
                    _buildMindObservatory(),
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

class LabPainter extends CustomPainter {
  final Experiment experiment;
  final Fly? selectedFly;

  LabPainter(this.experiment, this.selectedFly);

  @override
  void paint(Canvas canvas, Size size) {
    final sensorPaint = Paint()..color = Colors.white12..style = PaintingStyle.stroke;
    
    // Draw Resources
    for (var resource in experiment.resources) {
      if (experiment.isDiscoveryMode && resource.type != ResourceType.obstacle) {
        canvas.drawCircle(Offset(resource.x, resource.y), resource.radius, Paint()..color = Colors.white.withOpacity((resource.value / 100.0).clamp(0.2, 1.0)));
      } else {
        if (resource.type == ResourceType.food) {
          canvas.drawCircle(Offset(resource.x, resource.y), resource.radius, Paint()..color = Colors.greenAccent.withOpacity((resource.value / 100.0).clamp(0.2, 1.0)));
        } else if (resource.type == ResourceType.water) {
          canvas.drawCircle(Offset(resource.x, resource.y), resource.radius, Paint()..color = Colors.lightBlueAccent.withOpacity((resource.value / 100.0).clamp(0.2, 1.0)));
        } else if (resource.type == ResourceType.obstacle) {
          canvas.drawCircle(Offset(resource.x, resource.y), resource.radius, Paint()..color = Colors.grey);
        }
      }
    }

    // Draw Entities
    for (var fly in experiment.flyList) {
      // Selection ring
      if (selectedFly != null && fly.id == selectedFly!.id) {
        canvas.drawCircle(Offset(fly.x, fly.y), 25, Paint()..color = Colors.deepPurpleAccent..style = PaintingStyle.stroke..strokeWidth = 2.0);
      }

      if (fly.isDead) {
        canvas.save();
        canvas.translate(fly.x, fly.y);
        canvas.scale(1.0, -1.0); // flip vertically
        
        if (fly.stage == LifeStage.adult) {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 14, height: 8), Paint()..color = Colors.grey[700]!);
          canvas.drawCircle(const Offset(6, 0), 2.5, Paint()..color = Colors.grey[800]!);
        } else if (fly.stage == LifeStage.larva) {
          double lLength = 6.0 + (fly.instar * 4.0);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: lLength, height: 4.0 + fly.instar), const Radius.circular(3)), Paint()..color = Colors.grey[700]!);
        } else if (fly.stage == LifeStage.pupa) {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 8, height: 12), Paint()..color = Colors.grey[800]!);
        } else {
          canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 6, height: 8), Paint()..color = Colors.grey[600]!);
        }
        
        canvas.restore();
        continue;
      }

      if (fly.stage == LifeStage.egg) {
        canvas.drawOval(Rect.fromCenter(center: Offset(fly.x, fly.y), width: 6, height: 8), Paint()..color = Colors.white);
      } else if (fly.stage == LifeStage.larva) {
        double lLength = 6.0 + (fly.instar * 4.0);
        canvas.save();
        canvas.translate(fly.x, fly.y);
        canvas.rotate(fly.heading);
        double wriggle = sin(fly.wingFlapTime * 10) * 0.2;
        canvas.rotate(wriggle);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: lLength, height: 4.0 + fly.instar), const Radius.circular(3)), Paint()..color = Colors.yellow[200]!);
        canvas.restore();
      } else if (fly.stage == LifeStage.pupa) {
        canvas.drawOval(Rect.fromCenter(center: Offset(fly.x, fly.y), width: 8, height: 12), Paint()..color = Colors.brown[700]!);
      } else {
        // ADULT FLY RENDERING
        if (fly.brain.currentSignalEmit > 0.1) {
          final signalPaint = Paint()
            ..color = Colors.tealAccent.withOpacity((fly.brain.currentSignalEmit * 0.4).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          double pulse = 50.0 + sin(fly.wingFlapTime * 5.0) * 10.0;
          canvas.drawCircle(Offset(fly.x, fly.y), pulse * fly.brain.currentSignalEmit, signalPaint);
        }

        canvas.drawCircle(Offset(fly.x, fly.y), fly.genetics.sensorRange, sensorPaint);
        
        canvas.save();
        canvas.translate(fly.x, fly.y);
        canvas.rotate(fly.heading);
        double scale = fly.gender == Gender.female ? 1.2 : 1.0;
        canvas.scale(scale, scale);

        // Legs
        final legPaint = Paint()..color = Colors.black54..strokeWidth = 1.0;
        canvas.drawLine(const Offset(-2, -3), const Offset(-5, -6), legPaint);
        canvas.drawLine(const Offset(0, -3), const Offset(0, -7), legPaint);
        canvas.drawLine(const Offset(2, -3), const Offset(5, -6), legPaint);
        canvas.drawLine(const Offset(-2, 3), const Offset(-5, 6), legPaint);
        canvas.drawLine(const Offset(0, 3), const Offset(0, 7), legPaint);
        canvas.drawLine(const Offset(2, 3), const Offset(5, 6), legPaint);

        // Abdomen
        final abdomenColor = fly.gender == Gender.male ? Colors.black87 : Colors.brown[600]!;
        canvas.drawOval(Rect.fromCenter(center: const Offset(-4, 0), width: 10, height: 6), Paint()..color = abdomenColor);

        // Thorax
        final energyColor = Color.lerp(Colors.redAccent, Colors.brown[400], fly.need.energy / 100.0) ?? Colors.brown[400]!;
        canvas.drawOval(Rect.fromCenter(center: const Offset(2, 0), width: 8, height: 6), Paint()..color = energyColor);

        // Head & Eyes
        canvas.drawCircle(const Offset(6, 0), 2.5, Paint()..color = Colors.black87);
        canvas.drawCircle(const Offset(6, -1.5), 1.0, Paint()..color = Colors.redAccent);
        canvas.drawCircle(const Offset(6, 1.5), 1.0, Paint()..color = Colors.redAccent);

        // Wings
        double wingAngle = sin(fly.wingFlapTime * 40.0) * 0.5;
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
        canvas.restore(); // Restore adult transform

        // Thought Bubble
        String thought = fly.brain.getTranslatedState(fly.need.energy, fly.need.hydration);
        if (thought != "Exploring / Wandering") {
          TextSpan span = TextSpan(style: const TextStyle(color: Colors.white70, fontSize: 8), text: thought);
          TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
          tp.layout();
          tp.paint(canvas, Offset(fly.x - tp.width / 2, fly.y - 20));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant LabPainter oldDelegate) => true;
}
