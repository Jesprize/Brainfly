# BrainFly

BrainFly is an advanced biological simulation engine that models the life cycle, emergent learning, and cognitive behavior of virtual entities ("flies") entirely through neural networks and physical interactions.

## Features

- **Emergent Reinforcement Learning**: Entities learn to navigate, find food, and avoid obstacles purely through positive and negative reinforcement—no hardcoded semantic concepts (like "food" or "water").
- **Full Biological Lifecycle**: Entities reproduce and pass through distinct life stages: Egg → Larva → Pupa → Adult, each with unique physics, constraints, and visualizations.
- **Genetic Inheritance & Mutation**: Traits like speed, metabolism, and sensory range are passed down from parents to offspring, driving evolutionary adaptations over time.
- **Mind & Biology Observatories**: Deep-dive inspection panels allow scientists to monitor the internal neural weights, sensory inputs, vital signs, and genetic markers of any entity in real-time.
- **Cognitive Translation**: Observe real-time scientist-facing translations of internal computational states without resorting to scripted English thoughts.

## Getting Started

1. Install [Flutter](https://flutter.dev/docs/get-started/install).
2. Clone the repository.
3. Run `flutter pub get` to install dependencies.
4. Run `flutter run` to start the simulation engine in your target environment (Web, Android, Desktop).

## Project Structure
- `lib/models/`: Core neural network logic, entity genetics, and physical modeling.
- `lib/simulation/`: The fixed-timestep physics and biology engine that manages lifecycle transitions.
- `lib/ui/`: The interactive Lab Painters and Observatory dashboards.
