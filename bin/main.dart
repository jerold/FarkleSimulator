import '../lib/farkle_simulator.dart';

void main() {
  var counter = 0;
  final iterations = 10000;

  for (int i = 0; i < iterations; i++) {
    final toss = Farkle.toss();
    final combos = Farkle.combos(toss);
    final score = Farkle.score(combos);
    final remaining = Farkle.remaining(toss, combos);
    if (combos.any((c) => c is SixOfKind)) {
      counter++;
      print("Toss:${toss}, Score:${score} Combos: ${combos}, Remaining:${remaining}");
    }
  }
  print("Found:$counter/$iterations");
}
