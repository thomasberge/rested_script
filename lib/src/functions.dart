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
      if(cursor.moveTo('"')) {
        cursor.startSelection();
        cursor.moveToNext('"');
        cursor.move();
        cursor.stopSelection();
        cursor.deleteEdgesOfSelection();
        String value = cursor.getSelection();
        cursor.deleteSelection();
        cursor.reset();
        if(value == ""){
          value = "%NULL%";
        }
        rowItems.add(value);
      } else {
        run = false;
      }
    }
  
    if(pman.processes[_pid].args.vars[key].headers.length == rowItems.length) {
      pman.processes[_pid].args.vars[key].addRow(rowItems);
      //print(pman.processes[_pid].args.vars[key].sheet.toString());
    } else {
      breakpoint(_pid);
      print("Error: Tried to insert " + rowItems.length.toString() + " items into a " + 
      pman.processes[_pid].args.vars[key].headers.length.toString() + "-column Sheet.");
    }
    
    //print(rowItems.toString());
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
    if(pman.processes[_pid].args.getType(key) == "Sheet") {
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
  StringTools cursor = StringTools(argument);
  if(argument.contains('%&')) {
    return pman.processes[_pid].getString(int.parse(cursor.getFromTo('%&', '&%')));
  } else {
    return pman.processes[_pid].args.get(argument);
  }
}

String echo(String argument, int _pid) {
  StringTools cursor = StringTools(argument);
  if(argument.contains('%&')) {
    return pman.processes[_pid].getString(int.parse(cursor.getFromTo('%&', '&%')));
  } else {
    return pman.processes[_pid].args.get(argument);
  }
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