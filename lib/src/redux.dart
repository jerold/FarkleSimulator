
import 'package:farkle_simulator/src/farkle.dart';

class Roll {
  final List<int> dice;
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

  bool isSelected(int index) => selected[index] ?? false;

  List<int> get selectedDice => new List<int>.from(this.selected.keys.where((index) => isSelected(index)).map((index) => dice[index]));
}

class FarkleState {
  final int turn;
  final bool isRecording;

  final List<int> scoreHistory;
  final List<List<Combo>> comboHistory;

  final Roll currentRoll;
  final List<Combo> currentCombos;
  final bool currentFarkle;
  final bool currentMustRoll; 

  const FarkleState(
    this.turn,
    this.isRecording,
    this.scoreHistory,
    this.comboHistory,
    this.currentRoll,
    this.currentCombos,
    this.currentFarkle,
    this.currentMustRoll,
  );

  FarkleState.initialState()
    : this.turn = 0,
      this.isRecording = false,
      this.scoreHistory = <int>[],
      this.comboHistory = <List<Combo>>[],
      this.currentRoll = Roll.empty(),
      this.currentCombos = <Combo>[],
      this.currentFarkle = false,
      this.currentMustRoll = true;

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
    final nextRoll = Roll.random(numberOfDice: 6 - nextCombos.expand((combo) => combo.dice).length);
    final allCombos = Farkle.combos(nextRoll.dice);
    final allRemaining = Farkle.remaining(nextRoll.dice, allCombos);
    final nextFarkle = allCombos.length == 0;
    final nextMustRoll = allRemaining.length == 0;
    return new FarkleState(
      state.turn,
      state.isRecording,
      state.scoreHistory,
      state.comboHistory,
      nextRoll,
      nextCombos,
      nextFarkle,
      nextMustRoll,
    );
  } else if (action is PassAction) {
    // apply combos if earned
    var nextIsRecording = state.isRecording;
    var nextScoreHistory = state.scoreHistory;
    var nextComboHistory = state.comboHistory;
    if (!state.currentFarkle) {
      final turnScore = Farkle.score(state.currentCombos);
      if (nextIsRecording || turnScore >= Farkle.minimumScoreToStart) {
        nextIsRecording = true;
        nextScoreHistory.add(turnScore);
        nextComboHistory.add(state.currentCombos);
      }
    }
    return new FarkleState(
      state.turn + 1,
      nextIsRecording,
      nextScoreHistory,
      nextComboHistory,
      Roll.empty(),
      <Combo>[],
      false,
      true,
    );
  } else if (action is SelectDiceAction) {
    return FarkleState(
      state.turn,
      state.isRecording,
      state.scoreHistory,
      state.comboHistory,
      state.currentRoll.copyWithToggledSelection(action.index),
      state.currentCombos,
      state.currentFarkle,
      state.currentMustRoll,
    );
  } else if (action is ResetAction) {
    return FarkleState.initialState();
  }

  return state;
}