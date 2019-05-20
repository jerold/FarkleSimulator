import 'dart:html';

import 'package:wui_builder/wui_builder.dart';

import 'package:farkle_simulator/farkle_simulator.dart';

void main() {
  final ui = new UI();
  render(ui, querySelector('#farkle'));
}
