import 'dart:math';

final __rand = new Random();

typedef bool InDiceCheck(List<int> dice);
typedef Combo ComboMaker(List<int> dice);

class Farkle {
  static int minimumScoreToStart = 500;
  static int minimumScoreToEnd = 10000;

  static int roll() => __roll(null);
  static List<int> toss({int numberOfDice = 6}) => __toss(numberOfDice ?? 6);
  static List<bool> scoringDice(List<int> dice) => __scoringDice(dice);
  static List<Combo> combos(List<int> dice) => __combos(dice);
  static List<int> remaining(List<int> dice, List<Combo> combos) => __remaining(dice, combos);
  static int score(List<Combo> combos) => __score(combos);

  static List<InDiceCheck> get inDiceChecks => __inDiceChecks;
  static List<ComboMaker> get comboMakers => __comboMakers;
}

// given a List of dice, return a List of the same length and order
// indicating this dice belongs to combos existing in the given dice @_@.
List<bool> __scoringDice(List<int> startingDice) {
  final inCombos = new List<bool>.filled(startingDice.length, false);
  final combos = Farkle.combos(startingDice);
  for (final combo in combos) {
    for (final die in combo.dice) {
      for (int i = 0; i < startingDice.length; i++) {
        if (!inCombos[i] && startingDice[i] == die) {
          inCombos[i] = true;
          break;
        }
      }
    }
  }
  return inCombos;
}

const __straight = const Combo([1,2,3,4,5,6], 1500, 'Straight');

const __one_one = const Combo([1], 100, 'One');
const __one_five = const Combo([5], 50, 'Five');

const __two_ones = const Combo([1,1], 0, 'Two Ones');
const __two_twos = const Combo([2,2], 0, 'Two Twos');
const __two_threes = const Combo([3,3], 0, 'Two Threes');
const __two_fours = const Combo([4,4], 0, 'Two Fours');
const __two_fives = const Combo([5,5], 0, 'Two Fives');
const __two_sixes = const Combo([6,6], 0, 'Two Sixes');
const __pairs = [__two_ones, __two_twos, __two_threes, __two_fours, __two_fives, __two_sixes];

const __three_ones = const Combo([1,1,1], 300, 'Three Ones');
const __three_twos = const Combo([2,2,2], 200, 'Three Twos');
const __three_threes = const Combo([3,3,3], 300, 'Three Threes');
const __three_fours = const Combo([4,4,4], 400, 'Three Fours');
const __three_fives = const Combo([5,5,5], 500, 'Three Fives');
const __three_sixes = const Combo([6,6,6], 600, 'Three Sixes');
const __triplets = [__three_ones, __three_twos, __three_threes, __three_fours, __three_fives, __three_sixes];


class Combo {
  final List<int> dice;

  final int points;

  final String name;

  const Combo(this.dice, this.points, this.name);

  bool inToss(List<int> originalDice) {
    final remaining = new List<int>.from(originalDice);
    for (final face in dice) {
      if (!remaining.remove(face)) return false;
    }
    return true;
  }

  List<int> diceMinusThisCombo(List<int> originalDice) {
    final remaining = new List<int>.from(originalDice);
    for (final face in dice) {
      remaining.remove(face);
    }
    return remaining;
  }

  String toString() => "$name(${dice}, ${points}pts)";
}


List<int> __diceInCombos(List<Combo> combos) {
  final dice = <int>[];
  for (final combo in combos) {
    dice.addAll(combo.dice);
  }
  return dice;
}

List<Combo> __pairsInDice(List<int> dice) {
  final foundPairs = <Combo>[];
  var remaining = dice;
  for (final pair in __pairs) {
    if (pair.inToss(remaining)) {
      foundPairs.add(pair);
      remaining = pair.diceMinusThisCombo(remaining);
    }
  }
  return foundPairs;
}

List<Combo> __tripletsInDice(List<int> dice) {
  final foundTriplet = <Combo>[];
  var remaining = dice;
  for (final triplet in __triplets) {
    if (triplet.inToss(remaining)) {
      foundTriplet.add(triplet);
      remaining = triplet.diceMinusThisCombo(remaining);
    }
  }
  return foundTriplet;
}

// returns the key in dice for which there is (4<=x<=6) of a kind, or 0 if not found.
int __xOfKind(int x, List<int> dice) {
  final counts = <int, int>{};
  for (final face in dice) {
    if (!counts.containsKey(face)) counts[face] = 0;
    counts[face] ++;
  }
  return counts.keys.firstWhere((face) => counts[face] == x, orElse: () => 0);
}


class _CompositeCombo extends Combo {
  final List<Combo> combos;
  _CompositeCombo(this.combos, int points, String name) : super(__diceInCombos(combos), points, name);
}


class _OfKind extends Combo {
  static String _countStr(int count) {
    switch(count) {
      case 4: return 'Four';
      case 5: return 'Five';
      case 6: return 'Six';
    }
    return '$count';
  }

  _OfKind(int face, int count, int points) : super(new List<int>.filled(count, face), points, '${_countStr(count)} of a Kind');
}


class FourOfKind extends _OfKind {
  static bool inDice(List<int> dice) => __xOfKind(4, dice) > 0;
  FourOfKind(List<int> dice) : super(__xOfKind(4, dice), 4, 1000);
}


class ThreePairs extends _CompositeCombo {
  static bool inDice(List<int> dice) => __pairsInDice(dice).length == 3;
  ThreePairs(List<int> dice) : super(__pairsInDice(dice), 1500, 'Three Pairs');
}


class FourAndPair extends _CompositeCombo {
  static bool inDice(List<int> dice) => __xOfKind(4, dice) > 0 && __pairsInDice(__remaining(dice, [new FourOfKind(dice)])).length == 1;
  static List<Combo> __getCombos(List<int> dice) => <Combo>[]
      ..add(new FourOfKind(dice))
      ..addAll(__pairsInDice(__remaining(dice, [new FourOfKind(dice)])));
  FourAndPair(List<int> dice) : super(FourAndPair.__getCombos(dice), 1500, 'Four and a Pair');
}


class FiveOfKind extends _OfKind {
  static bool inDice(List<int> dice) => __xOfKind(5, dice) > 0;
  FiveOfKind(List<int> dice) : super(__xOfKind(5, dice), 5, 2000);
}


class TwoTriplets extends _CompositeCombo {
  static bool inDice(List<int> dice) => __tripletsInDice(dice).length == 2;
  TwoTriplets(List<int> dice) : super(__tripletsInDice(dice), 2500, 'Two Triplets');
}


class SixOfKind extends _OfKind {
  static bool inDice(List<int> dice) => __xOfKind(6, dice) > 0;
  SixOfKind(List<int> dice) : super(__xOfKind(6, dice), 6, 3000);
}


final __inDiceChecks = <InDiceCheck>[
  SixOfKind.inDice,
  __straight.inToss,
  TwoTriplets.inDice,
  FiveOfKind.inDice,
  FourAndPair.inDice,
  FourOfKind.inDice,
  ThreePairs.inDice,

  __three_sixes.inToss,
  __three_fives.inToss,
  __three_fours.inToss,
  __three_threes.inToss,
  __three_twos.inToss,
  __three_ones.inToss,

  __one_one.inToss,
  __one_five.inToss,
];

final __comboMakers = <ComboMaker>[
  (List<int> dice) => new SixOfKind(dice),
  (List<int> dice) => __straight,
  (List<int> dice) => new TwoTriplets(dice),
  (List<int> dice) => new FiveOfKind(dice),
  (List<int> dice) => new FourAndPair(dice),
  (List<int> dice) => new FourOfKind(dice),
  (List<int> dice) => new ThreePairs(dice),
  
  (List<int> dice) => __three_sixes,
  (List<int> dice) => __three_fives,
  (List<int> dice) => __three_fours,
  (List<int> dice) => __three_threes,
  (List<int> dice) => __three_twos,
  (List<int> dice) => __three_ones,
  
  (List<int> dice) => __one_one,
  (List<int> dice) => __one_five,
];


List<Combo> __combos(List<int> dice) {
  final combos = <Combo>[];
  var remaining = dice;
  bool newCombos = true;
  while (newCombos) {
    newCombos = false;
    for (var i = 0; i < __inDiceChecks.length; i++) {
      final inDiceCheck = __inDiceChecks[i];
      if (inDiceCheck(remaining)) {
        final comboMaker = __comboMakers[i];
        final combo = comboMaker(remaining);
        combos.add(combo);
        remaining = combo.diceMinusThisCombo(remaining);
        newCombos = true;
      }
    }
  }
  return combos;
}

int __score(List<Combo> combos) {
  int score = 0;
  for (final combo in combos) {
    score += combo.points;
  }
  return score;
}

List<int> __remaining(List<int> dice, List<Combo> combos) {
  var remaining = dice;
  for (final combo in combos) {
    remaining = combo.diceMinusThisCombo(remaining);
  }
  return remaining;
}

int __roll(_) => __rand.nextInt(6) + 1;

List<int> __toss(int numberOfDice) => new List<int>.generate(numberOfDice, __roll, growable: false);
