import 'dart:html';

import 'package:pwa/client.dart' as pwa;
import 'package:wui_builder/wui_builder.dart';

import 'package:farkle_simulator/farkle_simulator.dart';

void main() {
  new pwa.Client();
  final ui = new UI();
  render(ui, querySelector('#farkle'));
}
