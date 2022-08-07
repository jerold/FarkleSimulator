
import 'dart:convert';

import 'package:farkle_simulator/src/farkle.dart';

const invalid_record = Record(null, null, null, null);
final beginning_of_time = DateTime(2020, 1, 1);
final end_of_time = DateTime(2120, 1, 1);

List<Record> recordsFromJson(String json) {
  if (json == null) return <Record>[];
  try {
    var records = jsonDecode(json).map<Record>((recordJson) => Record.fromJson(recordJson)).toList();
    records = records.where((Record r) => r.isValid).toList();
    return records;
  } catch (_) {
    return <Record>[];
  }
}

String recordsToJson(List<Record> records) => jsonEncode(records.map<String>((record) => record.toJson()).toList());

class Record implements Comparable<Record> {
  final String name; // 3 char
  final int rounds;
  final int score;
  final DateTime date; // in local timezone

  const Record(this.name, this.rounds, this.score, this.date);

  factory Record.fromJson(String json) {
    try {
      final fields = jsonDecode(json) as List;
      if (fields.length != 4) return invalid_record;
      fields[0] as String;
      fields[1] as int;
      fields[2] as int;
      fields[3] as int;
      return Record(fields[0], fields[1], fields[2], DateTime.fromMillisecondsSinceEpoch(fields[3]).toLocal());
    } catch (_) {
      return invalid_record;
    }
  }

  bool get isValid => name != null
      && rounds != null
      && score != null
      && date != null
      && date.isAfter(beginning_of_time)
      && date.isBefore(end_of_time);

  @override
  int compareTo(Record other) {
    if (rounds < other.rounds) return -1;
    if (rounds == other.rounds) return -1*score.compareTo(other.score);
    return 1;
  }

  String toJson() => jsonEncode([name, rounds, score, date?.toUtc()?.millisecondsSinceEpoch]);

  String toString() => 'Record(${toJson()}, isValid:$isValid)';
}

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

  Roll copyWithToggledSelections(Iterable<int> indices) {
    final selections = new Map<int, bool>.from(selected);
    for (final index in indices) {
      selections[index] = !isSelected(index);
    }
    return new Roll(dice, selections);
  }

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

  final bool won;

  final List<Record> personalRecords;

  const FarkleState(
    this.turn,
    this.scoreHistory,
    this.comboHistory,
    this.currentRoll,
    this.currentCombos,
    this.currentFarkle,
    this.currentMustRoll,
    this.currentScoreCounts,
    this.won,
    this.personalRecords,
  );

  FarkleState.initialState({List<Record> personalRecords})
    : this.turn = 0,
      this.scoreHistory = <int>[],
      this.comboHistory = <List<Combo>>[],
      this.currentRoll = Roll.empty(),
      this.currentCombos = <Combo>[],
      this.currentFarkle = false,
      this.currentMustRoll = true,
      this.currentScoreCounts = false,
      this.won = false,
      this.personalRecords = personalRecords ?? <Record>[];

  bool hasStarted() => !currentRoll.dice.isEmpty || !currentCombos.isEmpty || !comboHistory.isEmpty;

  // So long as the user hasn't just been Farkled, they can roll.
  bool canRoll() => !won && !currentFarkle;

  // So long as the user hasn't just scored with all dice, they can pass.
  bool canPass() => !won && !currentMustRoll;

  int score() => scoreHistory.fold(0, (sum, next) => sum + next);

  String toString() => '''
FarkleState(
    turn: $turn,
    scoreHistory: $scoreHistory,
    comboHistory: $comboHistory,
    currentRoll: $currentRoll,
    currentCombos: $currentCombos,
    currentFarkle: $currentFarkle,
    currentMustRoll: $currentMustRoll,
    currentScoreCounts: $currentScoreCounts,
);
  ''';
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

class SetPersonalRecords extends FarkleAction {
  final List<Record> records;
  const SetPersonalRecords(this.records);
}

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

    final scoringIndices = Farkle.scoringDice(nextRoll.dice);
    final toSelect = <int>[];
    for (int i = 0; i < nextRoll.dice.length; i++) {
      if (scoringIndices[i]) toSelect.add(i);
    }

    return new FarkleState(
      state.turn,
      state.scoreHistory,
      state.comboHistory,
      nextRoll.copyWithToggledSelections(toSelect), // selects possible scoring dice
      nextCombos,
      nextFarkle,
      nextMustRoll,
      state.currentScoreCounts,
      state.won,
      state.personalRecords,
    );
  } else if (action is PassAction) {
    // apply combos if earned
    var nextScoreHistory = new List<int>.from(state.scoreHistory);
    var nextComboHistory = new List<List<Combo>>.from(state.comboHistory);
    var nextPersonalRecords = new List<Record>.from(state.personalRecords);
    var nextScoreCounts = state.currentScoreCounts;
    final selectedDice = state.currentRoll.selectedDice;
    final selectedCombos = Farkle.combos(selectedDice);
    var nextScore = 0;
    var nextWon = state.won;
    final nextCombos = <Combo>[]
      ..addAll(state.currentCombos)
      ..addAll(selectedCombos);
    if (!state.currentFarkle) {
      if (nextScoreCounts || Farkle.score(nextCombos) >= Farkle.minimumScoreToStart) {
        nextScore = Farkle.score(nextCombos);
        nextScoreCounts = true;
        if (state.score() + nextScore >= Farkle.minimumScoreToEnd) {
          nextWon = true;
          nextPersonalRecords.add(Record('Anon', state.turn, state.score() + nextScore, DateTime.now()));
        }
      }
    }
    nextScoreHistory.add(nextScore);
    nextComboHistory.add(nextCombos);
    return new FarkleState(
      state.turn + 1,
      nextScoreHistory,
      nextComboHistory,
      Roll.empty(),
      <Combo>[],
      false,
      true,
      nextScoreCounts,
      nextWon,
      nextPersonalRecords,
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
      state.won,
      state.personalRecords,
    );
  } else if (action is ResetAction) {
    return FarkleState.initialState(personalRecords: state.personalRecords);
  } else if (action is SetPersonalRecords) {
    return FarkleState(
      state.turn,
      state.scoreHistory,
      state.comboHistory,
      state.currentRoll,
      state.currentCombos,
      state.currentFarkle,
      state.currentMustRoll,
      state.currentScoreCounts,
      state.won,
      action.records,
    );
  }

  return state;
}