import 'package:string_tools/string_tools.dart';
import 'debug.dart';
import 'processes.dart';
import 'io.dart' as io;
import 'arguments.dart';
import 'functions.dart' as functions;

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

String sheet_printRow(int _pid, String _data) {
  StringTools cursor = StringTools(_data);
  cursor.deleteEdges();
  cursor.data.trim();
  cursor.data = cursor.data.replaceAll(' ', '');

  List<String> elements = cursor.data.split(',');
  List<String> row = pman.processes[_pid].args.vars[elements[0]].getRowByIndex(int.parse(elements[1]));

  //print(">" + row.toString() + "<");
  return row.toString();  
}

void sheet_addRow(int _pid, String _data) {
  StringTools cursor = StringTools(_data);
  cursor.deleteEdges();
  cursor.data.trim();
  bool run = true;
  List<String> rowItems = [];

  cursor.startSelection();
  cursor.moveTo(',');
  cursor.stopSelection();
  String key = cursor.getSelection().trim();
  cursor.deleteSelection();
  cursor.reset();
  
  if(pman.processes[_pid].args.isVar(key)) {
    while(run) {
      if(cursor.data.contains('%&') && cursor.data.contains('&%')) {
        rowItems.add(functions.getString(_pid, cursor.deleteFromTo('%&', '&%', includeArguments: true)));
      } else {
        run = false;
      }
    }
  
    if(pman.processes[_pid].args.vars[key].headers.length == rowItems.length) {
      pman.processes[_pid].args.vars[key].addRow(rowItems);
    } else {
      breakpoint(_pid);
      print("Error: Tried to insert " + rowItems.length.toString() + " items into a " + 
      pman.processes[_pid].args.vars[key].headers.length.toString() + "-column Sheet.");
    }
  } else {
    print("Error: Unknown variable " + key);
  }  
}

void sheet_addColumn(int _pid, String _data) {
  StringTools cursor = StringTools(_data);
  cursor.deleteEdges();
  cursor.startSelection();
  cursor.moveTo(',');
  cursor.stopSelection();
  String key = cursor.getSelection().trim();

  if(pman.processes[_pid].args.isVar(key)) {
    if(pman.processes[_pid].args.type(key) == "Sheet") {
      cursor.move();
      cursor.stopSelection();
      cursor.deleteSelection();
      cursor.reset();
      cursor.data = cursor.data.trim();

      String type = cursor.data.split(':')[0];

      cursor.moveTo('"');
      cursor.move();
      cursor.startSelection();
      cursor.moveToNext('"');
      cursor.stopSelection();
      String name = cursor.getSelection();

      pman.processes[_pid].args.vars[key].addColumn(type, name);
    } else {
      print("Error: " + key + " is not of type Sheet");
    }
  } else {
    print("Error: Unknown variable " + key);
  }  
}

String sheet_printCell(int _pid, String _data) {
  StringTools cursor = StringTools(_data);
  cursor.deleteEdges();
  cursor.data.trim();
  cursor.data = cursor.data.replaceAll(' ', '');

  List<String> elements = cursor.data.split(',');
  String cell = pman.processes[_pid].args.vars[elements[0]].getCellByIndex(int.parse(elements[1]), int.parse(elements[2])); 
  return cell;
}

String map(String argument, int _pid) {
  print("map function called");
  return "";
}

void rsbreakpoint(int _pid) {
  breakpoint(_pid);
}

String getString(int _pid, String _argument) {
  StringTools cursor = StringTools(_argument);
  if(_argument.contains('%&')) {
    return pman.processes[_pid].getString(int.parse(cursor.deleteFromTo('%&', '&%')));
  } else {
    return pman.processes[_pid].args.get(_argument).toString();
  }
}