import 'dart:async';
import 'dart:math';

final __rand = new Random();

typedef bool InDiceCheck(Map<int, int> dice);
typedef Combo ComboMaker(Map<int, int> dice);

const __minimumScoreToStart = 500;

const __faces = [1, 2, 3, 4, 5, 6];

const __straight = const Combo({1:1, 2:1, 3:1, 4:1, 5:1, 6:1}, 1500);

const __one_one = const Combo({1: 1}, 100);
const __one_five = const Combo({5: 1}, 50);

const __two_ones = const Combo({1: 2}, 0);
const __two_twos = const Combo({2: 2}, 0);
const __two_threes = const Combo({3: 2}, 0);
const __two_fours = const Combo({4: 2}, 0);
const __two_fives = const Combo({5: 2}, 0);
const __two_sixes = const Combo({6: 2}, 0);
const __pairs = [__two_ones, __two_twos, __two_threes, __two_fours, __two_fives, __two_sixes];

const __three_ones = const Combo({1: 3}, 300);
const __three_twos = const Combo({2: 3}, 200);
const __three_threes = const Combo({3: 3}, 300);
const __three_fours = const Combo({4: 3}, 400);
const __three_fives = const Combo({5: 3}, 500);
const __three_sixes = const Combo({6: 3}, 600);
const __triplets = [__three_ones, __three_twos, __three_threes, __three_fours, __three_fives, __three_sixes];


Map<int, int> __diceInCombos(List<Combo> combos) {
  final dice = <int, int>{};
  for (final combo in combos) {
    for (final face in combo.dice.keys) {
      if (!dice.containsKey(face)) dice[face] = 0;
      dice[face] = combo.dice[face];
    }
  }
  return dice;
}

List<Combo> __pairsInDice(Map<int, int> dice) {
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

List<Combo> __tripletsInDice(Map<int, int> dice) {
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

// returns the key in dice for which there is x of a kind, or 0 if not found.
int __xOfKind(int x, Map<int, int> dice) {
    for (final face in dice.keys) {
      if (dice[face] == x) return face;
    }
    return 0;
}


class Combo {
  // face:count
  final Map<int, int> dice;

  // value of the combo if tapped
  final int points;

  const Combo(this.dice, this.points);

  double odds(int numberOfDice) {
    int diceInCombo = dice.values.fold<int>(0, (sum, next) => sum + next);
    if (numberOfDice < diceInCombo) return 0.0;
    // is there a way to calculate this only knowing dice, and not
    // specifics about grouping
  }

  bool inToss(Map<int, int> toss) {
    for (final face in dice.keys) {
      if (!toss.containsKey(face) || toss[face] < dice[face]) {
        return false;
      }
    }
    return true;
  }

  Map<int, int> diceMinusThisCombo(Map<int, int> originalDice) {
    final resultDice = <int, int>{};
    for (final face in __faces) {
      if (dice.containsKey(face)) {
        // should have already tested that toss contains combo's dice
        // so conditional really only makes sure zero face counts aren't
        // put in the map.
        if (originalDice[face] > dice[face]) resultDice[face] = originalDice[face] - dice[face];
      } else if (originalDice.containsKey(face)) {
        resultDice[face] = originalDice[face];
      }
    }
    return resultDice;
  }

  String toString() => "(${dice}, ${points}pts)";
}


class CompositeCombo extends Combo {
  final List<Combo> combos;
  CompositeCombo(this.combos, int points) : super(__diceInCombos(combos), points);
}


class FourOfKind extends Combo {
  static bool inDice(Map<int, int> dice) => __xOfKind(4, dice) > 0;
  FourOfKind(Map<int, int> dice) : super(<int, int>{__xOfKind(4, dice): 4}, 1000);
}


class ThreePairs extends CompositeCombo {
  static bool inDice(Map<int, int> dice) => __pairsInDice(dice).length == 3;
  ThreePairs(Map<int, int> dice) : super(__pairsInDice(dice), 1500);
}


class FourAndPair extends CompositeCombo {
  static bool inDice(Map<int, int> dice) => __xOfKind(4, dice) > 0 && __pairsInDice(__remaining(dice, [new FourOfKind(dice)])).length == 1;
  static List<Combo> __getCombos(Map<int, int> dice) => <Combo>[]
      ..add(new FourOfKind(dice))
      ..addAll(__pairsInDice(__remaining(dice, [new FourOfKind(dice)])));
  FourAndPair(Map<int, int> dice) : super(FourAndPair.__getCombos(dice), 1500);
}


class FiveOfKind extends Combo {
  static bool inDice(Map<int, int> dice) => __xOfKind(5, dice) > 0;
  FiveOfKind(Map<int, int> dice) : super(<int, int>{__xOfKind(5, dice): 5}, 2000);
}


class TwoTriplets extends CompositeCombo {
  static bool inDice(Map<int, int> dice) => __tripletsInDice(dice).length == 2;
  TwoTriplets(Map<int, int> dice) : super(__tripletsInDice(dice), 2500);
}


class SixOfKind extends Combo {
  static bool inDice(Map<int, int> dice) => __xOfKind(6, dice) > 0;
  SixOfKind(Map<int, int> dice) : super(<int, int>{__xOfKind(6, dice): 6}, 3000);
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
  (Map<int, int> dice) => new SixOfKind(dice),
  (Map<int, int> dice) => __straight,
  (Map<int, int> dice) => new TwoTriplets(dice),
  (Map<int, int> dice) => new FiveOfKind(dice),
  (Map<int, int> dice) => new FourAndPair(dice),
  (Map<int, int> dice) => new FourOfKind(dice),
  (Map<int, int> dice) => new ThreePairs(dice),
  
  (Map<int, int> dice) => __three_sixes,
  (Map<int, int> dice) => __three_fives,
  (Map<int, int> dice) => __three_fours,
  (Map<int, int> dice) => __three_threes,
  (Map<int, int> dice) => __three_twos,
  (Map<int, int> dice) => __three_ones,
  
  (Map<int, int> dice) => __one_one,
  (Map<int, int> dice) => __one_five,
];


List<Combo> __combos(Map<int, int> dice) {
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

Map<int, int> __remaining(Map<int, int> dice, List<Combo> combos) {
  var remaining = dice;
  for (final combo in combos) {
    remaining = combo.diceMinusThisCombo(remaining);
  }
  return remaining;
}

int __roll(_) => __rand.nextInt(6) + 1;

Map<int, int> __toss(int numberOfDice) {
  final rolls = new List<int>.generate(numberOfDice, __roll, growable: false);
  final toss = <int, int>{};
  for (final roll in rolls) {
    if (!toss.containsKey(roll)) toss[roll] = 0;
    toss[roll]++;
  }
  return toss;
}

class Farkle {
  static int roll() => __roll(null);
  static Map<int, int> toss({int numberOfDice = 6}) => __toss(numberOfDice ?? 6);
  static List<Combo> combos(Map<int, int> dice) => __combos(dice);
  static Map<int, int> remaining(Map<int, int> dice, List<Combo> combos) => __remaining(dice, combos);
  static int score(List<Combo> combos) => __score(combos);
}

class Player {

  int score = 0;

  // onBoard = false;

  // turnsBeforeJoiningBoard = 0;

  // farkleCount = 0;

  // turns = 0;

  // history?

  // called by game on its turn
  Future<List<Combo>> takeTurn() async {

  }


}
