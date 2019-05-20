import '../lib/src/farkle.dart';

String _makePercent(double value) => '${((value*10000).toInt()/100)}%';

void main() {
  for (int i = 1; i <=6; i++) {
    final results = checkAllCombosAgainstDice(i, <int>[]);
    print("$i dice: farkle ~ ${_makePercent(1-(results['scoringCount']/results['totalCount']))}, allScore ~ ${_makePercent(results['allScoringCount']/results['totalCount'])}");
    for (final key in results.keys) {
      if (key == 'scoringCount' || key == 'totalCount' || key == 'allScoringCount') continue;
      print("  $key ~ ${_makePercent(results[key]/results['totalCount'])}");
    }
  }

  final iterations = 0;
  for (int i = 0; i < iterations; i++) {
    final toss = Farkle.toss();
    final combos = Farkle.combos(toss);
    final score = Farkle.score(combos);
    final remaining = Farkle.remaining(toss, combos);
    print("Toss:${toss}, Score:${score} Combos: ${combos}, Remaining:${remaining}");
  }
}


Map<String, int> checkAllCombosAgainstDice(int diceCount, List<int> dice) {
  final counts = <String, int>{
    'totalCount': 0,
    'scoringCount': 0,
    'allScoringCount': 0,
  };
  if (diceCount == 0) return counts;

  for (int a = 1; a <= 6; a++) {
    final roll = new List<int>.from(dice)..add(a);

    if (diceCount == 1) {
      counts['totalCount']++;
      var scored = false;

      // check each scoring combo to see if it exists in the roll
      for (var i = 0; i < Farkle.inDiceChecks.length; i++) {
        final inDiceCheck = Farkle.inDiceChecks[i];
        if (inDiceCheck(roll)) {
          scored = true;
          final comboMaker = Farkle.comboMakers[i];
          final combo = comboMaker(roll);
          if (!counts.containsKey(combo.name)) counts[combo.name] = 0;
          counts[combo.name] ++;
        }
      }
      if (scored) {
        counts['scoringCount']++;
      }

      /// See in how many cases all dice will score
      final combos = Farkle.combos(roll);
      final remaining = Farkle.remaining(roll, combos);
      if (remaining.length == 0) {
        counts['allScoringCount']++;
      }
    } else {
      final recursiveCounts = checkAllCombosAgainstDice(diceCount - 1, roll);
      for (final key in recursiveCounts.keys) {
        if (!counts.containsKey(key)) counts[key] = 0;
        counts[key] += recursiveCounts[key];
      }
    }
  }

  return counts;
}