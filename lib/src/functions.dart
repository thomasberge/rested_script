import 'package:string_tools/string_tools.dart';
import 'debug.dart';
import 'processes.dart';
import 'io.dart' as io;
import 'arguments.dart';

List<String> supportedFunctions = ["include", "print", "echo", "flag", "debug", "download", "breakpoint", 
"sheet.addColumn", "sheet.addRow", "sheet.printRow", "sheet.printCell"];

String isSupportedFunction(String data) {
  int i = 0;
  String supported = "%NOTSUPPORTED%";
  for(int i = 0; i < supportedFunctions.length; i++) {
    if(data.length >= supportedFunctions[i].length + 1) {
      int width = supportedFunctions[i].length + 1;
      if(data.substring(0, width) == supportedFunctions[i] + "(") {
        supported = supportedFunctions[i];
      }
    }
  }
  return supported;
}

Future<String> download(String argument, int _pid) async {
  return(await io.downloadTextFile(argument));
}

String flag(String argument, int _pid) {
  argument = argument.replaceAll('"', '');
  String filetype = argument.split('.')[1];

  if (filetype == 'html') {
    return argument;
  } else {
    print("Error: Unsupported flag filetype for " + argument);
    return "unsupported";
  }
}

Future<String> include(String argument, int _pid) async {
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

String echo(String argument, int _pid) {
  StringTools fparser = new StringTools(argument);
  String output = "";
  bool run = true;
  while (run) {
    if (fparser.data.substring(0,1) == '"') {
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
      if(pman.processes[_pid].args.get(argument).toString() != "%KEYDOESNOTEXIST%") {
        output = pman.processes[_pid].args.get(argument).toString();
        run = false;
      } else {
        print("Error: print missing quote(s) inside parentheses.\r\n print(" +
            fparser.data +
            ");");
        run = false;
      }
    }
  }
  return (output);
}

void debug(String argument, int _pid) {
  StringTools cursor = new StringTools(argument);
  cursor.data = cursor.data.substring("debug".length);
  cursor.deleteEdges();
  if(cursor.edgesIs('"')) {
    String output = cursor.getQuotedString();
    print("\u001b[31m" + output + "\u001b[0m");
  } else {
    String output = pman.processes[_pid].args.get(cursor.data).toString();
    print("\u001b[31m" + output + "\u001b[0m");
  }
}

void variable(String argument, int _pid) {
  print("var argument=" + argument);
}

String map(String argument, int _pid) {
  print("map function called");
  return "";
}

void rsbreakpoint(int _pid) {
  breakpoint(_pid);
}