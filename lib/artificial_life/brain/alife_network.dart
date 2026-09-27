import 'dart:math';

/// A Continuous Actor-like Neural Network using Eligibility Traces and Node Perturbation for RL.
class ALifeNetwork {
  final int numInputs;
  final int numHidden;
  final int numOutputs;

  List<double> w1;
  List<double> w2;

  // Eligibility Traces for Temporal Credit Assignment
  List<double> e1;
  List<double> e2;

  // Store intermediate activations for learning
  List<double> lastInputs = [];
  List<double> lastHidden = [];
  
  // Node perturbation noise applied in the forward pass
  List<double> outputNoise = [];
  
  final double learningRate = 0.05;
  final double discountFactor = 0.0;
  final Random rand = Random();
  double rewardBaseline = 0.0;

  ALifeNetwork(this.numInputs, this.numHidden, this.numOutputs)
      : w1 = [],
        w2 = [],
        e1 = List.filled(numHidden * numInputs, 0.0),
        e2 = List.filled(numOutputs * numHidden, 0.0),
        outputNoise = List.filled(numOutputs, 0.0) {
    w1 = List.generate(numHidden * numInputs, (_) => (rand.nextDouble() - 0.5) * 2.0);
    w2 = List.generate(numOutputs * numHidden, (_) => (rand.nextDouble() - 0.5) * 2.0);
    lastInputs = List.filled(numInputs, 0.0);
    lastHidden = List.filled(numHidden, 0.0);
  }

  List<double> forward(List<double> inputs, {bool learning = true}) {
    lastInputs = List.from(inputs);
    lastHidden = List.filled(numHidden, 0.0);

    for (int j = 0; j < numHidden; j++) {
      double sum = 0.0;
      for (int i = 0; i < numInputs; i++) {
        sum += inputs[i] * w1[j * numInputs + i];
      }
      lastHidden[j] = tanh(sum);
    }

    List<double> outputs = List.filled(numOutputs, 0.0);
    for (int k = 0; k < numOutputs; k++) {
      double sum = 0.0;
      for (int j = 0; j < numHidden; j++) {
        sum += lastHidden[j] * w2[k * numHidden + j];
      }
      
      // Output 4 is the Critic (Value)
      // Node Perturbation (Exploration) only for Actors
      if (learning && k < 4) {
        outputNoise[k] = (rand.nextDouble() - 0.5) * 2.0;
        sum += outputNoise[k];
      } else {
        outputNoise[k] = 0.0;
      }
      
      outputs[k] = tanh(sum);
    }

    // Accumulate eligibility traces based on the noise applied
    // This assumes that if positive noise caused a positive reward, we should increase the weights that were active.
    if (learning) {
      for (int k = 0; k < numOutputs; k++) {
        for (int j = 0; j < numHidden; j++) {
          int index = k * numHidden + j;
          // e_ij = gamma * e_ij + Activity * Noise
          e2[index] = discountFactor * e2[index] + (lastHidden[j] * outputNoise[k]);
        }
      }
      
      // Backpropagate noise conceptually to hidden layer for trace (simplified node perturbation)
      for (int j = 0; j < numHidden; j++) {
        double backpropNoise = 0.0;
        for (int k = 0; k < numOutputs; k++) {
          backpropNoise += outputNoise[k] * w2[k * numHidden + j];
        }
        for (int i = 0; i < numInputs; i++) {
          int index = j * numInputs + i;
          e1[index] = discountFactor * e1[index] + (lastInputs[i] * backpropNoise);
        }
      }
    }

    return outputs;
  }

  void updateWeights(double rewardDelta, double predictedValue) {
    // r is the advantage (TD Error)
    double advantage = rewardDelta - predictedValue;

    if (advantage.abs() < 0.0001) return;
    
    // Apply temporal credit assignment for Actors (0-3) using advantage
    for (int k = 0; k < 4; k++) {
      for (int j = 0; j < numHidden; j++) {
        w2[k * numHidden + j] += learningRate * advantage * e2[k * numHidden + j];
      }
    }
    
    // Train Critic (output 4) to predict rewardDelta (Supervised Learning on TD error)
    // d(Error)/dw = -advantage * hidden
    for (int j = 0; j < numHidden; j++) {
      w2[4 * numHidden + j] += learningRate * advantage * lastHidden[j];
    }
    
    // Update hidden layer (simplified: just pass advantage back through all e1 traces)
    for (int i = 0; i < w1.length; i++) {
      w1[i] += learningRate * advantage * e1[i];
    }
  }

  double tanh(double x) {
    if (x > 20) return 1.0;
    if (x < -20) return -1.0;
    double e2x = exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }
}
