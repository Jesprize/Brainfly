import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../models/fly.dart';
import '../models/brain.dart';
import '../models/sensor.dart';
import '../models/need.dart';
import '../models/gender.dart';
import '../models/genetics.dart';
import '../models/personality.dart';
import '../services/storage_service.dart';
import 'experiment_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<Experiment> _savedExperiments = [];

  @override
  void initState() {
    super.initState();
    _loadExperiments();
  }

  void _loadExperiments() {
    setState(() {
      _savedExperiments = StorageService.getAllExperiments();
    });
  }

  void _startNewExperiment() {
    final exp = Experiment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      flyList: [
        Fly(
          id: 'fly_1',
          x: 350,
          y: 300,
          brain: Brain(),
          sensor: Sensor(),
          need: Need(),
          gender: Gender.male,
          genetics: Genetics(),
          personality: Personality(),
        ),
        Fly(
          id: 'fly_2',
          x: 450,
          y: 300,
          brain: Brain(),
          sensor: Sensor(),
          need: Need(),
          gender: Gender.female,
          genetics: Genetics(),
          personality: Personality(),
        ),
      ],
      createdAt: DateTime.now(),
    );
    StorageService.saveExperiment(exp);
    _navigateToExperiment(exp);
  }

  void _startDiscoveryExperiment() {
    final exp = Experiment(
      id: 'discovery_${DateTime.now().millisecondsSinceEpoch}',
      flyList: [
        Fly(id: 'fly_1', x: 350, y: 300, brain: Brain(), sensor: Sensor(), need: Need(), gender: Gender.male, genetics: Genetics(), personality: Personality()),
        Fly(id: 'fly_2', x: 450, y: 300, brain: Brain(), sensor: Sensor(), need: Need(), gender: Gender.female, genetics: Genetics(), personality: Personality()),
      ],
      createdAt: DateTime.now(),
      seed: 42, // Seeded for reproducibility
      isDiscoveryMode: true,
    );
    StorageService.saveExperiment(exp);
    _navigateToExperiment(exp);
  }

  void _navigateToExperiment(Experiment exp) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExperimentScreen(experiment: exp)),
    ).then((_) => _loadExperiments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BrainFly Lab'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.biotech, size: 100, color: Colors.tealAccent),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startNewExperiment,
              icon: const Icon(Icons.science),
              label: const Text('Start New Experiment', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startDiscoveryExperiment,
              icon: const Icon(Icons.explore),
              label: const Text('Start Discovery Mode (Seeded)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
              ),
            ),
            if (_savedExperiments.isNotEmpty) ...[
              const SizedBox(height: 48),
              const Text('Saved Experiments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _savedExperiments.length,
                  itemBuilder: (context, index) {
                    final exp = _savedExperiments[index];
                    return ListTile(
                      title: Text('Experiment ${exp.id}'),
                      subtitle: Text('Flies: ${exp.flyList.length} | Created: ${exp.createdAt.toString().split('.')[0]}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.tealAccent),
                        onPressed: () => _navigateToExperiment(exp),
                      ),
                      onLongPress: () {
                        StorageService.deleteExperiment(exp.id);
                        _loadExperiments();
                      },
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
