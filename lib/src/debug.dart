import 'dart:io';
import 'dart:convert';

import 'processes.dart';

bool debugEnabled = false;

Map<String, String> envVars = Platform.environment;

void debug(int _pid, String message) {
  if(pman.processes[_pid].debugEnabled) {
    if(envVars['DEBUG.STEPIN']) {
      breakpoint(_pid);
    }
    print(message);
  }
}

void breakpoint(int _pid) {
    if(pman.processes[_pid].debugEnabled) {
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
}
