
import 'package:farkle_simulator/src/farkle.dart';

class Roll {
  // face values rolled
  final List<int> dice;

  // Index:selected state mapping.
  final Map<int, bool> selected;

  const Roll(
    this.dice,
    this.selected,
  );

  Roll.empty()
    : this.dice = <int>[],
      this.selected = <int, bool>{};

  Roll.random({int numberOfDice})
    : this.dice = Farkle.toss(numberOfDice: numberOfDice ?? 6),
      this.selected = <int, bool>{};

  Roll copyWithToggledSelection(int index) => new Roll(dice, new Map<int, bool>.from(selected)..[index] = !isSelected(index));

  Roll copyWithAllSelected() {
    final nextSelected = <int, bool>{};
    for (int i = 0; i < dice.length; i++) {
      nextSelected[i] = true;
    }
    return new Roll(dice, nextSelected);
  }

  bool isSelected(int index) => selected[index] ?? false;

  List<int> get selectedDice => new List<int>.from(this.selected.keys.where((index) => isSelected(index)).map((index) => dice[index]));

  String toString() => "Roll(dice:$dice, selected:$selected)";
}

class FarkleState {
  // Number of turns played.
  final int turn;

  // All previous Combo scores; Farkle turns appear as zeros.
  final List<int> scoreHistory;

  // Combos from previous turns; Farkles appear as empty Lists.
  final List<List<Combo>> comboHistory;

  // Dice most recently rolled. Also contains selected dice and selected Combos.
  final Roll currentRoll;

  // Combos from previous rolls this turn. Doesn't include current roll's selected Combos.
  final List<Combo> currentCombos;

  // No dice scored; prevent rolling. User must pass.
  final bool currentFarkle;

  // All dice scored; prevent passing and deselection of current scoring dice.
  final bool currentMustRoll; 

  // User has met the minumum starting score.
  final bool currentScoreCounts;

  const FarkleState(
    this.turn,
    this.scoreHistory,
    this.comboHistory,
    this.currentRoll,
    this.currentCombos,
    this.currentFarkle,
    this.currentMustRoll,
    this.currentScoreCounts,
  );

  FarkleState.initialState()
    : this.turn = 0,
      this.scoreHistory = <int>[],
      this.comboHistory = <List<Combo>>[],
      this.currentRoll = Roll.empty(),
      this.currentCombos = <Combo>[],
      this.currentFarkle = false,
      this.currentMustRoll = true,
      this.currentScoreCounts = false;

  // So long as the user hasn't just been Farkled, they can roll.
  bool canRoll() => !currentFarkle;

  // So long as the user hasn't just scored with all dice, they can pass.
  bool canPass() => !currentMustRoll;
}

class FarkleAction {
  const FarkleAction();
}

class RollAction extends FarkleAction {}

class PassAction extends FarkleAction {}

class SelectDiceAction extends FarkleAction {
  final int index;
  const SelectDiceAction(this.index);
}

class ResetAction extends FarkleAction {}

FarkleState farkleStateReducer(FarkleState state, dynamic action) {
  if (action is RollAction) {
    // apply selected combos, and roll remaining dice
    final selectedDice = state.currentRoll.selectedDice;
    final selectedCombos = Farkle.combos(selectedDice);
    final nextCombos = <Combo>[]
      ..addAll(state.currentCombos)
      ..addAll(selectedCombos);
    final comboDiceCount = nextCombos.expand((combo) => combo.dice).length;
    final nextRoll = Roll.random(numberOfDice: 6 - comboDiceCount%6);
    final allCombos = Farkle.combos(nextRoll.dice);
    final allRemaining = Farkle.remaining(nextRoll.dice, allCombos);
    final nextFarkle = allCombos.length == 0;
    final nextMustRoll = allRemaining.length == 0;
    return new FarkleState(
      state.turn,
      state.scoreHistory,
      state.comboHistory,
      nextMustRoll ? nextRoll.copyWithAllSelected() : nextRoll, // auto select all combos when all dice score.
      nextCombos,
      nextFarkle,
      nextMustRoll,
      state.currentScoreCounts,
    );
  } else if (action is PassAction) {
    // apply combos if earned
    var nextScoreHistory = state.scoreHistory;
    var nextComboHistory = state.comboHistory;
    var nextScoreCounts = state.currentScoreCounts;
    if (!state.currentFarkle) {
      final turnScore = Farkle.score(state.currentCombos);
      if (nextScoreCounts || turnScore >= Farkle.minimumScoreToStart) {
        nextScoreCounts = true;
        nextScoreHistory.add(turnScore);
        nextComboHistory.add(state.currentCombos);
      }
    }
    return new FarkleState(
      state.turn + 1,
      nextScoreHistory,
      nextComboHistory,
      Roll.empty(),
      <Combo>[],
      false,
      true,
      nextScoreCounts,
    );
  } else if (action is SelectDiceAction) {
    return FarkleState(
      state.turn,
      state.scoreHistory,
      state.comboHistory,
      state.currentRoll.copyWithToggledSelection(action.index),
      state.currentCombos,
      state.currentFarkle,
      state.currentMustRoll,
      state.currentScoreCounts,
    );
  } else if (action is ResetAction) {
    return FarkleState.initialState();
  }

  return state;
}