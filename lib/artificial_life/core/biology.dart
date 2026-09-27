import 'dart:math';

enum Sex { male, female }

enum LifeStage {
  egg,
  larva1,
  larva2,
  larva3,
  pupa,
  adult,
  dead
}

class Genetics {
  final double metabolicRate;
  final double maxEnergy;
  final double maturitySpeed;
  final double sensoryRadius;
  final List<double> baseWeights1;
  final List<double> baseWeights2;

  Genetics({
    required this.metabolicRate,
    required this.maxEnergy,
    required this.maturitySpeed,
    required this.sensoryRadius,
    required this.baseWeights1,
    required this.baseWeights2,
  });

  factory Genetics.random(int w1Len, int w2Len) {
    final rand = Random();
    return Genetics(
      metabolicRate: 0.1 + rand.nextDouble() * 0.2, // Base drain per tick
      maxEnergy: 50.0 + rand.nextDouble() * 100.0,
      maturitySpeed: 0.5 + rand.nextDouble() * 1.5,
      sensoryRadius: 200.0 + rand.nextDouble() * 200.0,
      baseWeights1: List.generate(w1Len, (_) => (rand.nextDouble() - 0.5) * 2.0),
      baseWeights2: List.generate(w2Len, (_) => (rand.nextDouble() - 0.5) * 2.0),
    );
  }

  Genetics mutate(Random rand) {
    final double mutationRate = 0.05;
    final double mutationStrength = 0.2;

    double mutateVal(double val, double min, double max) {
      if (rand.nextDouble() < mutationRate) {
        return (val + (rand.nextDouble() - 0.5) * mutationStrength * val).clamp(min, max);
      }
      return val;
    }

    List<double> mutateWeights(List<double> weights) {
      return weights.map((w) {
        if (rand.nextDouble() < mutationRate) {
          return w + (rand.nextDouble() - 0.5) * mutationStrength;
        }
        return w;
      }).toList();
    }

    return Genetics(
      metabolicRate: mutateVal(metabolicRate, 0.05, 1.0),
      maxEnergy: mutateVal(maxEnergy, 20.0, 500.0),
      maturitySpeed: mutateVal(maturitySpeed, 0.1, 5.0),
      sensoryRadius: mutateVal(sensoryRadius, 50.0, 1000.0),
      baseWeights1: mutateWeights(baseWeights1),
      baseWeights2: mutateWeights(baseWeights2),
    );
  }

  static Genetics crossover(Genetics a, Genetics b, Random rand) {
    // Uniform crossover
    List<double> mixWeights(List<double> wA, List<double> wB) {
      List<double> res = [];
      for (int i = 0; i < wA.length; i++) {
        res.add(rand.nextBool() ? wA[i] : wB[i]);
      }
      return res;
    }

    return Genetics(
      metabolicRate: rand.nextBool() ? a.metabolicRate : b.metabolicRate,
      maxEnergy: rand.nextBool() ? a.maxEnergy : b.maxEnergy,
      maturitySpeed: rand.nextBool() ? a.maturitySpeed : b.maturitySpeed,
      sensoryRadius: rand.nextBool() ? a.sensoryRadius : b.sensoryRadius,
      baseWeights1: mixWeights(a.baseWeights1, b.baseWeights1),
      baseWeights2: mixWeights(a.baseWeights2, b.baseWeights2),
    ).mutate(rand);
  }
}
