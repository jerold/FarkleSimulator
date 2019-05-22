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
  VNode render() => new Vsection()
    ..className = "section"
    ..children = [

      new Vdiv()
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
                                ..innerHtml = "Round: ${_roundNumber()}",
                            ],
                          new Vdiv()
                            ..className = "level-item has-text-centered"
                            ..children = [
                              new Vp()
                                ..className = "title"
                                ..innerHtml = "Total Score: ${_totalScore()}",
                            ],
                        ],
                    ],
                ],
            ],
        ],

      new Vdiv()
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
            ],
        ],

      new Vdiv()
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
            ],
        ],

      new Vdiv()
        ..className = "container"
        ..children = [
          new Vdiv()
            ..className = "columns is-mobile"
            ..children = [
              new Vdiv()
                ..className = "column"
                ..children = _roundHistory(),
            ],
        ],
    ];

  int _roundNumber() => _store.state.turn;

  int _totalScore() => _store.state.scoreHistory.fold(0, (sum, next) => sum + next);

  bool _isFarkle() => _store.state.currentFarkle;

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
    ..children = [_combos(points, combos, key, state)];

  VNode _combos(int points, Iterable<Combo> combos, String key, DiceState state) {
    final lis = new List<Vli>.from(combos.map((c) => new Vli()
      ..key = "$key-$c-$state"
      ..children = _smallDice(c, state)));
    final scoreSpans = <VNode>[];
    scoreSpans.add(new Vspan()
          ..className = "title"
          ..key = "$key-$state-$points"
          ..innerHtml = "$points Points");
    if (points == 0) {
      scoreSpans.addAll([
        new Vspan()
          ..className = "title"
          ..innerHtml = "(",
        new Vspan()
          ..className = "title has-text-danger"
          ..innerHtml = "${Farkle.score(combos)}",
        new Vspan()
          ..className = "title"
          ..innerHtml = ")",
      ]);
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

  VNode _passButton() => new VButtonElement()
    ..className = "button is-success is-fullwidth"
    ..disabled = !_store.state.canPass()
    ..key = 'pass-button'
    ..onClick = (_) {
      _store.dispatch(new PassAction());
    }
    ..children = [
      new Vspan()
        ..className = "icon"
        ..children = [
          new Vi()..className = "fas fa-piggy-bank",
        ],
      new Vspan()
        ..innerHtml = "Bank",
    ];

  void _onClick(int index) => _store.dispatch(new SelectDiceAction(index));

  String _farkleText() => _store.state.currentFarkle ? " Farkle!" : "";
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
    ..key = '$index-$face'
    ..onClick = (_) {
      clickHandler(index);
    }
    ..children = [
      new Vi()..className = "fas fa-3x ${_diceFaceClass(face)}",
    ];
}

Iterable<VNode> _smallDice(Combo combo, DiceState state) {
  return new List<VNode>.generate(combo.dice.length, (i) => new Vspan()
      ..className = "animated fadeInDown icon ${_diceStateClass(state)}"
      ..children = [
        new Vi()
          ..className = "fas fa-lg ${_diceFaceClass(combo.dice[i])}"
      ]);

  // return new Vdiv()
  //   ..key = '$combo'
  //   ..children = new List<VNode>.generate(combo.dice.length, (i) => new Vspan()
  //     ..className = "animated fadeInDown icon ${_diceStateClass(state)}"
  //     ..children = [
  //       new Vi()
  //         ..className = "fas fa-lg ${_diceFaceClass(combo.dice[i])}"
  //     ]);

  // new List<VNode>.generate(combo.dice.length, (i) => new Vspan()
  //   ..className = "animated fadeInDown icon tag ${_diceStateClass(state)}"
  //   ..children = [new Vi()..className = "fas fa-lg ${_diceFaceClass(combo.dice[i])}"]);

  // return new Vspan()
  //   ..className = "animated fadeInDown icon ${_diceStateClass(state)}"
  //   ..key = '$combo'
  //   ..children = new List<VNode>.generate(combo.dice.length, (i) => new Vi()..className = "fas fa-lg ${_diceFaceClass(combo.dice[i])}");
}
