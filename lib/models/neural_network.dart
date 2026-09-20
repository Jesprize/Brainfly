import 'dart:math';
import '../utils/random_utils.dart';

class NeuralNetwork {
  final int numInputs = 15;
  final int numHidden = 6;
  final int numOutputs = 3;

  List<double> w1;
  List<double> w2;

  int _ticksSincePerturb = 0;
  double _accumulatedReward = 0.0;
  final int perturbInterval = 60; // Evaluate every 1 second (60 ticks)

  int get ticksSincePerturb => _ticksSincePerturb;
  double get accumulatedReward => _accumulatedReward;

  bool _perturbedW1 = false;
  int _perturbedIndex = 0;
  double _previousWeightValue = 0.0;

  NeuralNetwork({List<double>? initialW1, List<double>? initialW2})
      : w1 = initialW1 ?? List.generate(15 * 6, (_) => (RandomUtils.nextDouble() - 0.5) * 2.0),
        w2 = initialW2 ?? List.generate(6 * 3, (_) => (RandomUtils.nextDouble() - 0.5) * 2.0);

  List<double> process(List<double> inputs, double rewardDelta) {
    // 1. Learning (Weight Perturbation algorithm)
    _accumulatedReward += rewardDelta;
    _ticksSincePerturb++;

    if (_ticksSincePerturb >= perturbInterval) {
      // Evaluation phase
      if (_accumulatedReward <= 0.0) {
        // Bad tweak (or no improvement)! Revert.
        if (_perturbedW1) {
          w1[_perturbedIndex] = _previousWeightValue;
        } else {
          w2[_perturbedIndex] = _previousWeightValue;
        }
      }

      // Start new evaluation cycle
      _accumulatedReward = 0.0;
      _ticksSincePerturb = 0;

      // Apply a small random perturbation to a single random weight
      _perturbedW1 = RandomUtils.nextBool();
      if (_perturbedW1) {
        _perturbedIndex = RandomUtils.nextInt(w1.length);
        _previousWeightValue = w1[_perturbedIndex];
        w1[_perturbedIndex] += (RandomUtils.nextDouble() - 0.5) * 0.5; // step size
      } else {
        _perturbedIndex = RandomUtils.nextInt(w2.length);
        _previousWeightValue = w2[_perturbedIndex];
        w2[_perturbedIndex] += (RandomUtils.nextDouble() - 0.5) * 0.5; // step size
      }
    }

    // 2. Forward Pass
    List<double> hidden = List.filled(numHidden, 0.0);
    for (int j = 0; j < numHidden; j++) {
      double sum = 0.0;
      for (int i = 0; i < numInputs; i++) {
        sum += inputs[i] * w1[j * numInputs + i];
      }
      hidden[j] = _tanh(sum);
    }

    List<double> outputs = List.filled(numOutputs, 0.0);
    for (int k = 0; k < numOutputs; k++) {
      double sum = 0.0;
      for (int j = 0; j < numHidden; j++) {
        sum += hidden[j] * w2[k * numHidden + j];
      }
      outputs[k] = _tanh(sum);
    }

    return outputs;
  }

  NeuralNetwork cloneWithMutation(double rate) {
    List<double> newW1 = List.from(w1);
    List<double> newW2 = List.from(w2);

    for (int i = 0; i < newW1.length; i++) {
      if (RandomUtils.nextDouble() < rate) {
        newW1[i] += (RandomUtils.nextDouble() - 0.5) * 0.2;
      }
    }
    for (int i = 0; i < newW2.length; i++) {
      if (RandomUtils.nextDouble() < rate) {
        newW2[i] += (RandomUtils.nextDouble() - 0.5) * 0.2;
      }
    }

    return NeuralNetwork(initialW1: newW1, initialW2: newW2);
  }

  NeuralNetwork crossover(NeuralNetwork other) {
    List<double> newW1 = List.filled(w1.length, 0.0);
    List<double> newW2 = List.filled(w2.length, 0.0);

    for (int i = 0; i < w1.length; i++) {
      newW1[i] = RandomUtils.nextBool() ? w1[i] : other.w1[i];
    }
    for (int i = 0; i < w2.length; i++) {
      newW2[i] = RandomUtils.nextBool() ? w2[i] : other.w2[i];
    }

    return NeuralNetwork(initialW1: newW1, initialW2: newW2).cloneWithMutation(0.1);
  }

  double _tanh(double x) {
    if (x > 20) return 1.0;
    if (x < -20) return -1.0;
    double e2x = exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }
}
