import 'package:string_tools/string_tools.dart';

import 'io.dart' as io;
import 'arguments.dart';

Future<String> download(String argument, RestedScriptArguments args) async {
  return(await io.downloadTextFile(argument));
}

String flag(String argument, RestedScriptArguments args) {
  argument = argument.replaceAll('"', '');
  String filetype = argument.split('.')[1];

  if (filetype == 'html') {
    return argument;
  } else {
    print("Error: Unsupported flag filetype for " + argument);
    return "unsupported";
  }
}

Future<String> include(String argument, RestedScriptArguments args) async {
  argument = argument.replaceAll('"', '');
  List<String> split = argument.split('.');
  if (split.length > 1) {
    String filetype = argument.split('.')[argument.split('.').length-1];

    if (filetype == 'html' || filetype == 'css' || filetype == 'txt') {
      return (argument);
    } else {
      print("RestedScript: Unsupported include filetype for " +
          argument.toString());
      return "";
    }
  } else {
    print("RestedScript: Attempted to include file with no filetype: " +
        argument.toString());
    return "";
  }
}

String echo(String argument, RestedScriptArguments args) {
  StringTools fparser = new StringTools(argument);
  String output = "";
  bool run = true;
  while (run) {
    if (fparser.getFromPosition() == '"') {
      fparser.move();
      fparser.startSelection();
      if (fparser.moveTo('"')) {
        fparser.stopSelection();
        output = output + fparser.getSelection();
        run = false;
      } else {
        print("Error: print missing quote(s) inside parentheses.\r\n print(" +
            fparser.data +
            ");");
        run = false;
      }
    } else {
      print("Error: print missing quote(s) inside parentheses.\r\n print(" +
          fparser.data +
          ");");
      run = false;
    }
  }
  return (output);
}

void variable(String argument, RestedScriptArguments args) {
  print("var argument=" + argument);
}