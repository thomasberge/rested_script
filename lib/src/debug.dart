import 'dart:io';
import 'dart:convert';

import 'processes.dart';

void breakpoint(int _pid) {
  while(true) {
    print("\n:: BREAKPOINT [enter] to pass through, [?] for help.");
    var line = stdin.readLineSync(encoding: utf8);
    if(line == '') {
      break;
    } else if(line == '?') {
      print("\nCOMMANDS:\nvar (dumps all variables)");
    } else if(line == 'var') {
      print(pman.processes[_pid].args.getVarTable());
    }
  }
}