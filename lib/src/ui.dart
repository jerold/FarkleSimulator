import 'dart:async';
import 'dart:html' show window;
import 'dart:math';

import 'package:intl/intl.dart' show DateFormat;
import 'package:redux/redux.dart';
import 'package:meta/meta.dart';
import 'package:wui_builder/components.dart';
import 'package:wui_builder/vhtml.dart';
import 'package:wui_builder/wui_builder.dart';

import 'package:farkle_simulator/src/farkle.dart';
import 'package:farkle_simulator/src/redux.dart';

const localStorageKey = 'farkle-scores';

final dateFormat = DateFormat.yMd().add_jm();

class UI extends NComponent {
  Store<FarkleState> _store;
  StreamSubscription _sub;

  void loadRecordsFromLocalStorage() {
    final records = recordsFromJson(window.localStorage[localStorageKey]);
    if (records.isNotEmpty) _store.dispatch(SetPersonalRecords(records));
    print('From Storage: ${_store.state.personalRecords}');
  }

  void saveRecordsToLocalStorage() {
    print('To Storage: ${_store.state.personalRecords}');
    window.localStorage[localStorageKey] = recordsToJson(_store.state.personalRecords);
  }

  UI() {
    _store = new Store<FarkleState>(farkleStateReducer, initialState: new FarkleState.initialState());
    loadRecordsFromLocalStorage();
  }

  @mustCallSuper
  void componentWillMount() {
    _sub = _store.onChange.listen(_update);
  }

  void _update(_) => update();

  @mustCallSuper
  void componentWillUnmount() {
    _sub.cancel();
  }

  @override
  VNode render() {
    final children = <VNode>[
      _resetOptionComponent(),
    ];

    // only show score once the score has started to accumulate
    if (_totalScore() > 0) {
      children.add(_scoreHeroComponent());
    }

    // only show dice when there are dice to show
    if (!_store.state.won && _currentDice().length > 0) {
      children.add(_currentDiceComponent());
    }

    // only show game options when playing
    if (!_store.state.won) {
      children.add(_turnOptionsComponent());
    }

    // only show game rounds when there are rounds to show
    if (_store.state.hasStarted()) {
      children.add(_roundHistoryComponent());
    } else {
      children.add(_personalRecordsTableComponent());
    }

    return new Vsection()
      ..className = "section"
      ..children = children;
  }

  VNode _scoreHeroComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vdiv()
        ..className = "columns is-mobile"
        ..children = [
          new Vdiv()
            ..className = "column has-text-centered"
            ..children = [
              new Vdiv()
                ..className = "notification"
                ..children = [
                  new Vnav()
                    ..className = "level"
                    ..children = [
                      new Vdiv()
                        ..className = "level-item has-text-centered"
                        ..children = [
                          new Vp()
                            ..className = "title"
                            ..innerHtml = "Total Score: ${_totalScore()}",
                        ]
                    ],
                ],
            ],
        ],
    ];

  VNode _currentDiceComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vdiv()
        ..className = "columns is-mobile"
        ..children = [
          new Vdiv()
            ..className = "column has-text-centered"
            ..children = [
              new Vdiv()
                ..className = "notification dice-area"
                ..children = _currentDice(),
            ],
        ]
    ];

  VNode _turnOptionsComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vdiv()
        ..className = "columns"
        ..children = [
          new Vdiv()
            ..className = "column is-half"
            ..children = [
              _rollButton(),
            ],
          new Vdiv()
            ..className = "column is-half"
            ..children = [
              _passButton(),
            ],
        ]
    ];

  VNode _roundHistoryComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vdiv()
        ..className = "columns is-mobile"
        ..children = [
          new Vdiv()
            ..className = "column"
            ..children = _roundHistory(),
        ],
    ];

  VNode _personalRecordsTableComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vtable()
        ..className = 'table is-fullwidth'
        ..children = [
          new Vthead()..children = _personalRecordsTableRows(),
        ],
    ];

  VNode _resetOptionComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vdiv()
        ..className = "columns"
        ..children = [
          new Vdiv()
            ..className = "column is-full"
            ..children = [
              _resetButton(),
            ],
        ],
    ];

  int _totalScore() => _store.state.score();

  int _currentRollScore() => Farkle.score(Farkle.combos(_store.state.currentRoll.selectedDice));

  int _currentCombosScore() => Farkle.score(_store.state.currentCombos);

  int _currentRoundScore() => _isFarkle() ? 0 : _currentCombosScore() + _currentRollScore();

  bool _isFarkle() => _store.state.currentFarkle;

  Iterable<VNode> _personalRecordsTableRows() {
    final rows = <VNode>[];
    rows.add(_personalRecordsHeaderTableRow());
    final records = _store.state.personalRecords..sort();
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      rows.add(_personalRecordTableRow(i, record));
    }
    return rows;
  }

  VNode _personalRecordsHeaderTableRow() => new Vtr()
    ..children = [
      new Vth()
        ..children = [
          new Vabbr()
            ..title = 'Rounds to Win'
            ..innerHtml = 'Rounds to Win',
        ],
      new Vth()
        ..children = [
          new Vabbr()
            ..title = 'Final Score'
            ..innerHtml = 'Final Score',
        ],
      new Vth()
        ..children = [
          new Vabbr()
            ..title = 'Date'
            ..innerHtml = 'Date',
        ],
    ];

  VNode _personalRecordTableRow(int index, Record record) {
    return new Vtr()
      ..children = [
        new Vth()..innerHtml = '${record.rounds + 1}',
        new Vtd()..innerHtml = '${record.score}',
        new Vtd()..innerHtml = '${dateFormat.format(record.date)}',
      ];
  }

  Iterable<VNode> _roundHistory() {
    final currentCombos = _store.state.currentCombos;
    final rounds = <VNode>[];
    final selectedCombos = Farkle.combos(_store.state.currentRoll.selectedDice);
    final bankedCombos = _store.state.currentCombos;
    if (selectedCombos.length > 0 || bankedCombos.length > 0) {
      final roundNumber = _store.state.comboHistory.length + 1;
      rounds.add(_round(
          roundNumber, _currentRoundScore(), currentCombos, _isFarkle() ? DiceState.nonScoring : DiceState.enabled,
          selectedCombos: selectedCombos));
    }
    for (int i = _store.state.comboHistory.length - 1; i >= 0; i--) {
      final roundNumber = i + 1;
      final round = _store.state.comboHistory[i];
      final score = _store.state.scoreHistory[i];
      rounds.add(_round(roundNumber, score, round, score == 0 ? DiceState.nonScoring : DiceState.scoring));
    }
    return rounds;
  }

  VNode _round(int round, int points, Iterable<Combo> combos, DiceState state, {Iterable<Combo> selectedCombos}) =>
      new Vdiv()
        ..className = "notification"
        ..children = [_combos(round, points, combos, state, selectedCombos: selectedCombos)];

  VNode _combos(int round, int points, Iterable<Combo> combos, DiceState state, {Iterable<Combo> selectedCombos}) {
    selectedCombos ??= <Combo>[];
    final lis = <Vli>[];

    // show score
    final farkle = points == 0 && Farkle.score(combos) > 0;
    final scoreSpans = <VNode>[];
    if (farkle) {
      scoreSpans.addAll([
        new Vspan()
          ..className = "title"
          ..innerHtml = "$points(",
        new Vspan()
          ..className = "title has-text-danger"
          ..innerHtml = "${Farkle.score(combos)}",
        new Vspan()
          ..className = "title"
          ..innerHtml = ") Points",
      ]);
    } else if (selectedCombos.length > 0) {
      scoreSpans.addAll([
        new Vspan()
          ..className = "title"
          ..innerHtml = "$points(",
        new Vspan()
          ..className = "title has-text-info"
          ..innerHtml = "${Farkle.score(selectedCombos)}",
        new Vspan()
          ..className = "title"
          ..innerHtml = ") Points",
      ]);
    } else {
      scoreSpans.add(new Vspan()
        ..className = "title"
        ..innerHtml = "$points Points");
    }
    lis.add(new Vli()..children = scoreSpans);

    var diceIndex = 0;

    // add dice showing banked and selectedcombos
    lis.addAll(selectedCombos.map((c) => new Vli()..children = _smallDice(c, DiceState.selectedScoring)));
    lis.addAll(combos.map((c) => new Vli()..children = _smallDice(c, state, key: 'dice-${round}-${diceIndex++}')));

    // add round number
    lis.add(new Vli()
      ..children = [
        new Vspan()
          ..className = "title"
          ..innerHtml = "Round #$round"
      ]);

    return new Vnav()
      ..children = [
        new Vul()..children = lis,
      ];
  }

  Iterable<VNode> _currentDice() {
    final elements = <VNode>[];
    final roll = _store.state.currentRoll;
    for (int i = 0; i < roll.dice.length; i++) {
      final face = roll.dice[i];
      final state = roll.isSelected(i) ? DiceState.selectedScoring : DiceState.enabled;
      elements.add(_bigDice(face, state, i, _onClick));
    }
    return elements;
  }

  VNode _resetButton() => new VButtonElement()
    ..className = "button is-danger is-fullwidth"
    ..onClick = (_) {
      _store.dispatch(new ResetAction());
    }
    ..children = [
      new Vspan()
        ..className = "icon"
        ..children = [
          new Vi()..className = "fas fa-redo",
        ],
      new Vspan()..innerHtml = "New Game",
    ];

  VNode _rollButton() => new VButtonElement()
    ..className = "button is-info is-fullwidth"
    ..disabled = !_store.state.canRoll()
    ..onClick = (_) {
      _store.dispatch(new RollAction());
    }
    ..children = [
      new Vspan()
        ..className = "icon"
        ..children = [
          new Vi()..className = "fas fa-dice",
        ],
      new Vspan()..innerHtml = "Roll",
    ];

  VNode _passButton() {
    var colorClass = 'is-success';
    var iconClass = 'fa-piggy-bank';
    var labelTxt = 'Bank';
    if (_store.state.currentFarkle) {
      colorClass = 'is-warning';
      iconClass = 'fa-sad-cry';
      labelTxt = 'Pass';
    }
    return new VButtonElement()
      ..className = 'button $colorClass is-fullwidth'
      ..disabled = !_store.state.canPass()
      ..onClick = (_) {
        _store.dispatch(new PassAction());
        if (!_store.state.won) {
          _store.dispatch(new RollAction());
        } else {
          saveRecordsToLocalStorage();
        }
      }
      ..children = [
        new Vspan()
          ..className = 'icon'
          ..children = [
            new Vi()..className = 'fas $iconClass',
          ],
        new Vspan()..innerHtml = labelTxt,
      ];
  }

  void _onClick(int index) => _store.dispatch(new SelectDiceAction(index));
}

typedef void DiceClickHandler(int index);

enum DiceState {
  enabled,
  disabled,
  selectedScoring,
  selectedNonScoring,
  nonScoring,
  scoring,
}

String _diceStateClass(DiceState state) {
  switch (state) {
    case DiceState.enabled:
      return "has-text-grey";
    case DiceState.disabled:
      return "has-text-grey-lighter";
    case DiceState.selectedScoring:
      return "has-text-info";
    case DiceState.selectedNonScoring:
      return "has-text-grey-dark";
    case DiceState.nonScoring:
      return "has-text-danger";
    case DiceState.scoring:
      return "has-text-success";
  }
  return "";
}

String _diceFaceClass(int face) {
  switch (face) {
    case 1:
      return "fa-dice-one";
    case 2:
      return "fa-dice-two";
    case 3:
      return "fa-dice-three";
    case 4:
      return "fa-dice-four";
    case 5:
      return "fa-dice-five";
    case 6:
      return "fa-dice-six";
  }
  return "";
}

VNode _bigDice(int face, DiceState state, int index, DiceClickHandler clickHandler) {
  return new Vspan()
    ..className = "animated jackInTheBox icon is-large ${_diceStateClass(state)}"
    ..key = '${Random().nextInt(99999999)}'
    ..onClick = (_) {
      clickHandler(index);
    }
    ..children = [
      new Vi()..className = "fas fa-3x ${_diceFaceClass(face)}",
    ];
}

Iterable<VNode> _smallDice(Combo combo, DiceState state, {String key}) {
  return new List<VNode>.generate(
      combo.dice.length,
      (i) => new Vspan()
        ..className = "icon ${_diceStateClass(state)}"
        ..key = key != null ? '$key-$i' : '${Random().nextInt(99999999)}'
        ..children = [new Vi()..className = "fas fa-lg ${_diceFaceClass(combo.dice[i])}"]);
}
