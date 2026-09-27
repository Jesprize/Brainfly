import 'package:flutter/material.dart';
import '../artificial_life/controller/alife_simulation_controller.dart';
import '../artificial_life/core/organism.dart';
import '../artificial_life/core/biology.dart';
import '../artificial_life/world/alife_world.dart';

import '../artificial_life/biology/brain/alife_biological_brain.dart';
import 'swc_visualizer.dart';

class ScientistSidebar extends StatefulWidget {
  final ALifeSimulationController controller;
  final Organism? selectedOrganism;
  final Function(Organism?) onSelectOrganism;

  const ScientistSidebar({
    super.key,
    required this.controller,
    required this.selectedOrganism,
    required this.onSelectOrganism,
  });

  @override
  State<ScientistSidebar> createState() => _ScientistSidebarState();
}

class _ScientistSidebarState extends State<ScientistSidebar> {
  final BiologicalBrainLayer _biologyLayer = BiologicalBrainLayer();

  @override
  void initState() {
    super.initState();
    _biologyLayer.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      color: const Color(0xFF15151E),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSimulationControls(context),
                const SizedBox(height: 16),
                _buildExperimentInfo(),
                const SizedBox(height: 16),
                _buildOrganismsList(),
                const SizedBox(height: 16),
                _buildWorldInfo(),
                const SizedBox(height: 16),
                _buildInspector(),
                const SizedBox(height: 16),
                _buildObservatoryLog(),
                const SizedBox(height: 16),
                _buildBiologySection(),
                const SizedBox(height: 16),
                _buildCloudState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black26,
      child: const Row(
        children: [
          Icon(Icons.science, color: Colors.amberAccent),
          SizedBox(width: 12),
          Text(
            'ALife Laboratory',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String emoji, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text('$emoji $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimulationControls(BuildContext context) {
    return _buildSection('SIMULATION', '⚙️', Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(widget.controller.isRunning ? Icons.pause : Icons.play_arrow),
              color: widget.controller.isRunning ? Colors.amber : Colors.greenAccent,
              onPressed: () {
                if (widget.controller.isRunning) widget.controller.pause();
                else widget.controller.start();
              },
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt),
              color: Colors.redAccent,
              onPressed: () {
                widget.controller.reset();
                widget.onSelectOrganism(null);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Speed:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Expanded(
              child: Slider(
                value: widget.controller.simulationSpeed,
                min: 0.1,
                max: 10.0,
                divisions: 99,
                label: '${widget.controller.simulationSpeed.toStringAsFixed(1)}x',
                onChanged: (v) => widget.controller.setSpeed(v),
              ),
            ),
            Text('${widget.controller.simulationSpeed.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ],
    ));
  }

  Widget _buildExperimentInfo() {
    int population = widget.controller.world.entities.whereType<Organism>().length;
    int maxGen = 1;
    for (var e in widget.controller.world.entities) {
      if (e is Organism && e.generation > maxGen) maxGen = e.generation;
    }
    
    return _buildSection('EXPERIMENT', '🧪', Column(
      children: [
        _statRow('Status', widget.controller.isRunning ? 'RUNNING' : 'PAUSED', valueColor: widget.controller.isRunning ? Colors.greenAccent : Colors.amber),
        _statRow('Ticks', '${widget.controller.tickCount}'),
        _statRow('Population', '$population'),
        _statRow('Max Generation', '$maxGen'),
        _statRow('World Size', '${widget.controller.world.width.toInt()} x ${widget.controller.world.height.toInt()}'),
      ],
    ));
  }
  
  Widget _buildWorldInfo() {
    int totalEntities = widget.controller.world.entities.length;
    int resources = totalEntities - widget.controller.world.entities.whereType<Organism>().length;

    return _buildSection('WORLD', '🌍', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow('Total Entities', '$totalEntities'),
        _statRow('Abiotic Resources', '$resources'),
        const SizedBox(height: 8),
        const Text('Resource Positions:', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        ...widget.controller.world.entities.where((e) => e is! Organism).map((e) {
          String type = e.chemicalSignature[0] > 0 ? "Beneficial" : "Harmful";
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('${e.id}: (${e.x.toInt()}, ${e.y.toInt()}) - $type', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          );
        }),
      ],
    ));
  }

  Widget _buildOrganismsList() {
    var organisms = widget.controller.world.entities.whereType<Organism>().toList();
    int adults = organisms.where((o) => o.stage == LifeStage.adult).length;
    int eggs = organisms.where((o) => o.stage == LifeStage.egg).length;
    int larvae = organisms.where((o) => o.stage == LifeStage.larva1 || o.stage == LifeStage.larva2 || o.stage == LifeStage.larva3).length;
    int pupae = organisms.where((o) => o.stage == LifeStage.pupa).length;
    int dead = organisms.where((o) => o.stage == LifeStage.dead).length;

    return _buildSection('ORGANISMS', '🧬', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat('Adults', adults, Colors.blueGrey[300]!),
            _miniStat('Eggs', eggs, Colors.white),
            _miniStat('Larvae', larvae, Colors.green[300]!),
            _miniStat('Pupae', pupae, Colors.brown[400]!),
            _miniStat('Dead', dead, Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Select Organism:', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
          child: organisms.isEmpty ? const Center(child: Text('No organisms', style: TextStyle(color: Colors.white54, fontSize: 12))) : ListView.builder(
            itemCount: organisms.length,
            itemBuilder: (context, index) {
              var org = organisms[index];
              bool isSelected = widget.selectedOrganism?.id == org.id;
              return InkWell(
                onTap: () => widget.onSelectOrganism(org),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: isSelected ? Colors.amber.withValues(alpha: 0.2) : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(Icons.bug_report, size: 14, color: isSelected ? Colors.amber : Colors.white54),
                      const SizedBox(width: 8),
                      Text('${org.id.split('_').last} (Gen ${org.generation})', style: TextStyle(color: isSelected ? Colors.amber : Colors.white, fontSize: 12)),
                      const Spacer(),
                      Text(org.stage.name.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ));
  }

  Widget _miniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildInspector() {
    if (widget.selectedOrganism == null) {
      return _buildSection('INSPECTOR & BRAIN', '🔬', const Text('No organism selected.', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    var org = widget.selectedOrganism!;
    
    return _buildSection('INSPECTOR & BRAIN', '🔬', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statRow('ID', org.id.split('_').last),
        _statRow('Stage', org.stage.name.toUpperCase()),
        _statRow('Age', org.age.toStringAsFixed(1)),
        _statRow('Generation', '${org.generation}'),
        if (org.parent1Id != null) _statRow('Parents', '${org.parent1Id?.split('_').last}, ${org.parent2Id?.split('_').last}'),
        
        const Divider(color: Colors.white24, height: 16),
        const Text('Internal State', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        _statRow('Energy', '${org.internalEnergy.toStringAsFixed(1)} / ${org.genetics.maxEnergy.toStringAsFixed(1)}'),
        _statRow('Damage', org.damage.toStringAsFixed(1)),
        _statRow('Mating Cooldown', org.matingCooldown > 0 ? org.matingCooldown.toStringAsFixed(1) : 'READY'),

        const Divider(color: Colors.white24, height: 16),
        const Text('Brain (Actor-Critic)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        _statRow('Learning Status', org.enableLearning ? 'ACTIVE' : 'FROZEN', valueColor: org.enableLearning ? Colors.greenAccent : Colors.redAccent),
        _statRow('Reward (Critic)', (org.internalEnergy - org.damage).toStringAsFixed(2)),
        _statRow('Memory Trace (Avg)', (org.brain.e2.isNotEmpty ? org.brain.e2.reduce((a, b) => a + b) / org.brain.e2.length : 0).toStringAsFixed(4)),

        const Divider(color: Colors.white24, height: 16),
        const Text('Sensory Payload (Inputs)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        _statRow('[0] Chem A', org.sensors.chemicalReadings[0].toStringAsFixed(3)),
        _statRow('[1] Chem B', org.sensors.chemicalReadings[1].toStringAsFixed(3)),
        _statRow('[2] Pheromone', org.sensors.chemicalReadings[2].toStringAsFixed(3)),

        const Divider(color: Colors.white24, height: 16),
        const Text('Motor Payload (Outputs)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        _statRow('Forward Thrust', org.motors.forwardThrust.toStringAsFixed(2)),
        _statRow('Lateral Thrust', org.motors.lateralThrust.toStringAsFixed(2)),
        _statRow('Torque', org.motors.rotationalTorque.toStringAsFixed(2)),
        _statRow('Interaction', org.motors.interactionAttempt.toStringAsFixed(2)),
        
        const Divider(color: Colors.white24, height: 16),
        const Text('Genetics', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        _statRow('Metabolic Rate', org.genetics.metabolicRate.toStringAsFixed(4)),
        _statRow('Maturity Speed', org.genetics.maturitySpeed.toStringAsFixed(3)),
      ],
    ));
  }

  Widget _buildObservatoryLog() {
    return _buildSection('OBSERVATORY LOG', '📊', Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: widget.controller.world.events.isEmpty 
        ? const Text('Waiting for events...', style: TextStyle(color: Colors.white54, fontSize: 11))
        : ListView.builder(
            itemCount: widget.controller.world.events.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.controller.world.events[index],
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace'),
                ),
              );
            },
          ),
    ));
  }
  
  Widget _buildBiologySection() {
    if (widget.selectedOrganism == null) return const SizedBox.shrink();

    Widget content;
    if (!_biologyLayer.isLoaded) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_biologyLayer.loadError != null || _biologyLayer.loadedNeurons.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text("DATA NOT AVAILABLE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 12),
          _statRow('Biological Brain Reference', 'PENDING IMPORT'),
          _statRow('Neurons', 'DATA NOT AVAILABLE'),
          _statRow('Connectivity', 'DATA NOT AVAILABLE'),
          _statRow('Anatomy', 'DATA NOT AVAILABLE'),
          _statRow('Provenance', 'Google Research / HHMI Janelia (Male CNS)'),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Biological Brain Reference", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Center(
            child: SwcVisualizer(neuron: _biologyLayer.loadedNeurons.first, width: 250, height: 250),
          ),
          const SizedBox(height: 8),
          _statRow('Neurons', '${_biologyLayer.loadedNeurons.length} loaded'),
          _statRow('Connectivity', 'DATA NOT AVAILABLE'),
          _statRow('Anatomy', '${_biologyLayer.loadedNeurons.first.nodes.length} nodes rendered'),
          _statRow('Provenance', 'Google Research / HHMI Janelia (Male CNS)'),
        ],
      );
    }

    return _buildSection('BIOLOGY', '🧬', content);
  }

  Widget _buildCloudState() {
    return _buildSection('CLOUD', '☁️', const Text(
      'Cloud persistence: Not implemented\n\nRuns entirely local.', 
      style: TextStyle(color: Colors.white54, fontSize: 12)
    ));
  }
}
