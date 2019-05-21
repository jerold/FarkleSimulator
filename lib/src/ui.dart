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
  VNode render() => new Vdiv()
    ..className = "section"
    ..children = _content();

  Iterable<VNode> _content() {
    final roll = _store.state.currentRoll;
    final combos = Farkle.combos(roll.selectedDice)..addAll(_store.state.currentCombos);

    final elements = <VNode>[];
    elements.add(new VText("Score: ${Farkle.score(combos)}${_farkleText()}"));
    elements.add(_rollAndPass());
    for (int i = 0; i < roll.dice.length; i++) {
      final face = roll.dice[i];
      final state = roll.isSelected(i) ? DiceState.selectedScoring : DiceState.enabled;
      elements.add(_bigDice(face, state, i, _onClick));
    }
    return elements;
  }

  VNode _rollAndPass() => new Vp()
    ..className = "buttons"
    ..children = [
      new VButtonElement()
        ..className = "button is-info"
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
        ],
      new VButtonElement()
        ..className = "button is-info"
        ..disabled = !_store.state.canPass()
        ..key = 'pass-button'
        ..onClick = (_) {
          _store.dispatch(new PassAction());
        }
        ..children = [
          new Vspan()
            ..innerHtml = "Pass",
          new Vspan()
            ..className = "icon"
            ..children = [
              new Vi()..className = "fas fa-caret-right",
            ],
        ],
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
}

String _diceStateClass(DiceState state) {
  switch(state) {
    case DiceState.enabled: return "has-text-grey";
    case DiceState.disabled: return "has-text-grey-lighter";
    case DiceState.selectedScoring: return "has-text-info";
    case DiceState.selectedNonScoring: return "has-text-grey-dark";
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
      new Vi()..className = "fas fa-2x ${_diceFaceClass(face)}",
    ];
}

// <progress class="progress is-info" value="45" max="100">45%</progress>