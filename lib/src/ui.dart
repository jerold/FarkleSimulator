import 'dart:async';

import 'package:redux/redux.dart';
import 'package:meta/meta.dart';
import 'package:wui_builder/components.dart';
import 'package:wui_builder/vhtml.dart';
import 'package:wui_builder/wui_builder.dart';

import 'package:farkle_simulator/src/farkle.dart';
import 'package:farkle_simulator/src/redux.dart';

class UI extends NComponent {
  Store<FarkleState> _store;
  StreamSubscription _sub;

  UI() {
    this._store = new Store<FarkleState>(farkleStateReducer, initialState: new FarkleState.initialState());
  }

  @mustCallSuper
  void componentWillMount() {
    _store.onChange.listen(_update);
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
      _scoreHeroComponent(),
      _currentDiceComponent(),
      _turnOptionsComponent(),
    ];

    print('JJA - ${_store.state.hasStarted()}');

    if (_store.state.hasStarted()) {
      children.add(_roundHistoryComponent());
    } else {
      children.add(_historyTableComponent());
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
                    ..children = _scoreHeroChildren(),
                ],
            ],
        ],
    ];

  Iterable<VNode> _scoreHeroChildren() {
    final roundNum = _roundNumber();
    final children = <VNode>[new Vdiv()
        ..className = "level-item has-text-centered"
        // ..key = 'round-$roundNum'
        ..children = [
          new Vp()
            ..className = "title"
            ..innerHtml = "Round: $roundNum",
        ]
    ];

    final roundScore = _currentRoundScore();
    if (!_store.state.won && (_isFarkle() || roundScore > 0)) {
      children.add(new Vdiv()
          ..className = "level-item has-text-centered"
          // ..key = 'score-$roundScore'
          ..children = [
            new Vp()
              ..className = "title"
              ..innerHtml = _isFarkle() ? 'Farkle!' : 'Score: $roundScore',
          ]);
    }

    final totalScore = _totalScore();
    if (totalScore > 0) {
      children.add(new Vdiv()
          ..className = "level-item has-text-centered"
          // ..key = 'total-$totalScore'
          ..children = [
            new Vp()
              ..className = "title"
              ..innerHtml = "Total Score: $totalScore",
          ]);
    }
    return children;
  }

  VNode _currentDiceComponent() {
    final children = <VNode>[];
    final currentDice = _currentDice();
    if (!_store.state.won && currentDice.length > 0) {
      children.add(new Vdiv()
        ..className = "columns is-mobile"
        ..children = [
          new Vdiv()
          ..className = "column has-text-centered"
          ..children = [
            new Vdiv()
              ..className = "notification dice-area"
              ..children = _currentDice(),
          ],
        ]);
    }
    return new Vdiv()
    ..className = "container"
    ..children = children;
  }

  VNode _turnOptionsComponent() {
    final children = <VNode>[];
    if (!_store.state.won) {
      children.add(new Vdiv()
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
        ]);
    }
    return new Vdiv()
    ..className = "container"
    ..children = children;
  }

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

  VNode _historyTableComponent() => new Vdiv()
    ..className = "container"
    ..children = [
      new Vtable()
        ..className = 'table is-fullwidth'
        ..children = [
          new Vthead()
            ..children = _gameHistoryTableRows(),
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

  int _roundNumber() => _store.state.won ? _store.state.turn : _store.state.turn + 1;

  int _totalScore() => _store.state.score();

  int _currentRollScore() => Farkle.score(Farkle.combos(_store.state.currentRoll.dice));

  int _currentCombosScore() => Farkle.score(_store.state.currentCombos);

  int _currentRoundScore() => _isFarkle() ? 0 : _currentCombosScore() + _currentRollScore();

  bool _isFarkle() => _store.state.currentFarkle;

  Iterable<VNode> _gameHistoryTableRows() {
    final rounds = <VNode>[];
    rounds.add(_gameHistoryHeaderTableRow());
    for (int i = _store.state.comboHistory.length - 1; i >= 0; i--) {
      final round = _store.state.comboHistory[i];
      final score = _store.state.scoreHistory[i];
      rounds.add(_gameHistoryTableRow(i, score, round, 'round-$i', score == 0 ? DiceState.nonScoring : DiceState.scoring));
    }
    return rounds;
  }

  VNode _gameHistoryHeaderTableRow() => new Vtr()
    ..children = [
      new Vth()
        ..children = [
          new Vabbr()
            ..title = 'Round'
            ..innerHtml = 'Round',
        ],
      new Vth()
        ..children = [
          new Vabbr()
            ..title = 'Points Scored'
            ..innerHtml = 'Points Scored',
        ],
      new Vth()
        ..children = [
          new Vabbr()
            ..title = 'Points Missed'
            ..innerHtml = 'Points Missed',
        ],
    ];

  VNode _gameHistoryTableRow(int round, int points, Iterable<Combo> combos, String key, DiceState state) {
    final farkle = points == 0 && Farkle.score(combos) > 0;
    final pointsScored = !farkle && points > 0 ? '$points' : '';
    final pointsMissed = farkle || points == 0 ? '${Farkle.score(combos)}' : '';
    final txtColorClass = round == _store.state.comboHistory.length ? 'has-text-info' : '';
    return new Vtr()
      ..children = [
        new Vth()
          ..className = txtColorClass
          ..innerHtml = '${round + 1}',
        new Vtd()
          ..className = 'has-text-success'
          ..innerHtml = pointsScored,
        new Vtd()
          ..className = 'has-text-danger'
          ..innerHtml = pointsMissed,
      ];
  }

  Iterable<VNode> _roundHistory() {
    final currentCombos = _store.state.currentCombos;
    final currentScore = _isFarkle() ? 0 : Farkle.score(currentCombos);
    final rounds = <VNode>[];
    if ( _store.state.currentCombos.length > 0) {
      rounds.add(_round(currentScore, currentCombos, 'current', _isFarkle() ? DiceState.nonScoring : DiceState.enabled));
    }
    for (int i = _store.state.comboHistory.length - 1; i >= 0; i--) {
      final round = _store.state.comboHistory[i];
      final score = _store.state.scoreHistory[i];
      rounds.add(_round(score, round, 'round-$i', score == 0 ? DiceState.nonScoring : DiceState.scoring));
    }
    return rounds;
  }

  VNode _round(int points, Iterable<Combo> combos, String key, DiceState state) => new Vdiv()
    ..className = "notification"
    ..key = "rount-$key"
    ..children = [_combos(points, combos, key, state)];

  VNode _combos(int points, Iterable<Combo> combos, String key, DiceState state) {
    final lis = new List<Vli>.from(combos.map((c) => new Vli()
      ..key = "combos-$key-$c-$state"
      ..children = _smallDice(c, state, key)));
    final farkle = points == 0 && Farkle.score(combos) > 0;
    final scoreSpans = <VNode>[];
    if (farkle) {
      scoreSpans.addAll([
        new Vspan()
          ..className = "title"
          ..key = "combo-$key-$state-$points-0"
          ..innerHtml = "$points(",
        new Vspan()
          ..className = "title has-text-danger"
          ..key = "combo-$key-$state-$points-1"
          ..innerHtml = "${Farkle.score(combos)}",
        new Vspan()
          ..className = "title"
          ..key = "combo-$key-$state-$points-2"
          ..innerHtml = ") Points",
      ]);
    } else {
      scoreSpans.add(new Vspan()
        ..className = "title"
        ..key = "score-$key-$state-$points"
        ..innerHtml = "$points Points");
    }
    lis.add(new Vli()..children = scoreSpans);

    return new Vnav()
      //..className = "breadcrumb has-bullet-separator"
      ..key = "$key-$combos"
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
    ..key = 'reset-button'
    ..onClick = (_) {
      _store.dispatch(new ResetAction());
    }
    ..children = [
      new Vspan()
        ..className = "icon"
        ..children = [
          new Vi()..className = "fas fa-redo",
        ],
      new Vspan()
        ..innerHtml = "New Game",
    ];

  VNode _rollButton() => new VButtonElement()
    ..className = "button is-info is-fullwidth"
    ..disabled = !_store.state.canRoll()
    ..key = 'roll-button'
    ..onClick = (_) {
      _store.dispatch(new RollAction());
    }
    ..children = [
      new Vspan()
        ..className = "icon"
        ..children = [
          new Vi()..className = "fas fa-dice",
        ],
      new Vspan()
        ..innerHtml = "Roll",
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
    ..key = 'pass-button'
    ..onClick = (_) {
      _store.dispatch(new PassAction());
      _store.dispatch(new RollAction());
    }
    ..children = [
      new Vspan()
        ..key = 'pass-button-icon-$iconClass'
        ..className = 'icon'
        ..children = [
          new Vi()..className = 'fas $iconClass',
        ],
      new Vspan()
        ..innerHtml = labelTxt,
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
  switch(state) {
    case DiceState.enabled: return "has-text-grey";
    case DiceState.disabled: return "has-text-grey-lighter";
    case DiceState.selectedScoring: return "has-text-info";
    case DiceState.selectedNonScoring: return "has-text-grey-dark";
    case DiceState.nonScoring: return "has-text-danger";
    case DiceState.scoring: return "has-text-success";
  }
  return "";
}

String _diceFaceClass(int face) {
  switch(face) {
    case 1: return "fa-dice-one";
    case 2: return "fa-dice-two";
    case 3: return "fa-dice-three";
    case 4: return "fa-dice-four";
    case 5: return "fa-dice-five";
    case 6: return "fa-dice-six";
  }
  return "";
}

VNode _bigDice(int face, DiceState state, int index, DiceClickHandler clickHandler) {
  return new Vspan()
    ..className = "animated jackInTheBox icon is-large ${_diceStateClass(state)}"
    ..key = 'big-dice-$index-$face-state'
    ..onClick = (_) {
      clickHandler(index);
    }
    ..children = [
      new Vi()..className = "fas fa-3x ${_diceFaceClass(face)}",
    ];
}

Iterable<VNode> _smallDice(Combo combo, DiceState state, String key) {
  return new List<VNode>.generate(combo.dice.length, (i) => new Vspan()
      ..className = "icon ${_diceStateClass(state)}"
      ..key = "small-dice-$i-${combo.dice[i]}-$state-$key"
      ..children = [
        new Vi()
          ..className = "fas fa-lg ${_diceFaceClass(combo.dice[i])}"
      ]);
}
