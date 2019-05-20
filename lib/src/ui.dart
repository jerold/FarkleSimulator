import 'package:redux/redux.dart';
import 'package:wui_builder/components.dart';
import 'package:wui_builder/vhtml.dart';
import 'package:wui_builder/wui_builder.dart';

import 'package:farkle_simulator/src/redux.dart';

class UI extends NComponent {
  Store<FarkleState> store;

  UI() {
    this.store = new Store<FarkleState>(farkleStateReducer, initialState: new FarkleState.initialState());
  }

  @override
  VNode render() => new Vsection()
    ..className = "section";
}