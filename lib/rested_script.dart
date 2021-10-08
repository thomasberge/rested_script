// RestedScript
// https://github.com/thomasberge/rested_script
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:string_tools/string_tools.dart';

import 'src/io.dart' as io;
import 'src/functions.dart' as functions;
import 'src/variables.dart' as variables;
import 'src/arguments.dart';
export 'src/arguments.dart';
import 'src/processes.dart';
import 'src/debug.dart';
import 'src/templating.dart';
import 'src/comments.dart';

/*
  createDocument()
    pid = pman.createProcess(args)
    parse(filepath, pid)
      processLines(lines, pid)
        doc = removeComments(lines)
        doc = wrapDocument(doc, pid)
        doc = processForEach(doc, pid)
        doc = processRSTags(doc, pid)
          doCommands(rstag, pid)
            ...
        return doc
      return doc
    return doc
*/

class CodeBlock {
  int id;
  String data;

  CodeBlock(this.id, this.data);

  String toString() {
    return this.id.toString() + ": " + this.data;
  }
}

class RestedScript {
  RestedScript({this.root = "", bool debug = false}) {
    debugEnabled = debug;
  }

  String root;

  Future<String> createDocument(String filepath, {Arguments? args = null, bool debug = false}) async {
    if(args == null) {
      args = Arguments();
    }

    int _pid = pman.createProcess(args);

    if(debugEnabled) {
      pman.processes[_pid].debugEnabled = true;
    } else if(debug == true) {
      pman.processes[_pid].debugEnabled = true;
    }

    String doc = await parse(filepath, _pid);

    if (pman.processes[_pid].flag != "") {
      doc = await parse("flagsites/" + pman.processes[_pid].flag, _pid);
    }
    return doc;
  }

  Future<String> parse(String filepath, int _pid, {String? externalfile = null}) async {
    debug(_pid, "parse()");
    if (filepath != "") {
      try {
        File data = new File(root + filepath);
        List<String> lines = data.readAsLinesSync(encoding: utf8);
        return (await processLines(lines, _pid));
      } catch(e) {
        print(e.toString());
        return("");
      }
    } else if (externalfile != null) {
      LineSplitter ls = new LineSplitter();
      List<String> lines = ls.convert(externalfile);
      return (await processLines(lines, _pid));
    } else {
      return "";
    }
  }

  Future<String> processLines(List<String> lines, int _pid) async {
    debug(_pid, "processLines()");
    String document = removeComments(_pid, lines);
    document = await wrapDocument(_pid, document, root);
    document = processForEach(document, _pid);
    document = await processRSTags(_pid, document);
    return document;
  }

  // NEW FUNCTIONS METHOD
  Future<String> doVariables(String function, String cursordata, int _pid, data) async {

      String variableType = variables.isVariableDeclaration(cursordata);
      if(variableType != "%NOTSUPPORTED%") {
        switch(variableType) {

        case "String": {
          variables.initString(_pid, cursordata);
        }
        break;

        case "Int": {
          variables.initInt(_pid, cursordata);
        }
        break;

        case "Bool": {
          variables.initBool(_pid, cursordata);
        }
        break;

        case "Double": {
          variables.initDouble(_pid, cursordata);
        }
        break;

        case "List": {
          variables.initList(_pid, cursordata);
        }
        break;

        case "Map": {
          variables.initMap(_pid, cursordata);
        }
        break;

        case "Sheet": {
          variables.initSheet(_pid, cursordata);
        }
        break;
        }
      } else {
 
        // Check if it is a variable name

        String name = cursordata.split(new RegExp(r"[ =]"))[0];
        if(pman.processes[_pid].args.isVar(name)) {
          String type = pman.processes[_pid].args.getType(name);
          switch(type) {
            case "Int": {
              variables.updateInt(_pid, name, cursordata);
            }
            break;
            case "String": {
              variables.updateString(_pid, name, cursordata);
            }
            break;
            case "Double": {

            }
            break;
            case "List": {

            }
            break;
            case "Map": {

            }
            break;
          }
        } else {
          print("Error: Unknown command " + cursordata);
        }
      }

    return data;
  }

  /// RestedScript function: include
  ///
  /// Example:
  /// include("scripts.html");

  String f_set(String scriptargument, int _pid) {
    debug(_pid, "f_set()");
    StringTools argparser = new StringTools(scriptargument);
    argparser.moveTo(',');
    String key = argparser.getAllBeforePosition();
    String value = argparser.getAllAfterPosition();
    pman.processes[_pid].args.setmap[key] = value;
    return "";
  }

  // Parses the document for rs tags. Grabs whatever is between the tags, splits it by semicolon
  // and sends the list to the doCommands function. The rs tags and its content are deleted and the
  // result from doCommands are inserted in its place.
  Future<String> processRSTags(int _pid, String _data) async {
    debug(_pid, "doCommands()");
    
    StringTools cursor = new StringTools(_data);
    bool run = true;

    while (run) {

      if (cursor.moveTo('<?rs')) {
        cursor.deleteCharacters(4);
        cursor.startSelection();
        if (cursor.moveTo('?>')) {
          cursor.deleteCharacters(2);
          cursor.stopSelection();

          String rsdata = cursor.getSelection().trim();
          cursor.position = cursor.start_selection;
          cursor.deleteSelection();

          if (rsdata.contains(';')) {
            List<String> command_list = rsdata.split(';');
            String result = await doCommands(command_list, _pid);
            cursor.insertAtPosition(result);
          } else {
            cursor.insertAtPosition("");
          }
        } else {
          print("Missing closing bracket restedscript ?>");
        }
      } else {
        run = false;
      }
    }

    return cursor.data;
  }

  Future<String> doCommands(List<String> commands, int _pid) async {
    debug(_pid, "doCommands()");
    String data = "";

    // remove null, whitespace and empty string elements from list
    for(int i = 0; i < commands.length; i++) {
      if(commands[i] == null) {
        commands.removeAt(i);
        i--;
      } else {
        commands[i] = commands[i].trim();

        if(commands[i] == "") {
          commands.removeAt(i);
          i--;
        }
      }
    }

    /*
        1: function()
        2: variable.function()
        3: name = function();
        4: name = name;
        5: var name = function();
        6: var name = variable.function()
        7: function() { }  <-- NOT YET SUPPORTED
    */

    for (String command in commands) {
      StringTools cursor = new StringTools(command);

      List<String> commandTarget = returnTarget(_pid, cursor.data);
      //print(":: " + cursor.data);
      //print(":: commandTarget = " + commandTarget.toString());

      if(commandTarget[0] == "void") {
        String function = functions.isSupportedFunction(cursor.data);
        data = await doFunctions(function, cursor.data, _pid, data);
      } else {
        data = await doVariables("", cursor.data, _pid, data);        
      }

      //String function = functions.isSupportedFunction(cursor.data);
      //data = await doFunctions(function, cursor.data, _pid, data);
    }
    return data;
  }

  List<String> returnTarget(int _pid, String _data) {
    List<String> command = [];
    /*
      command[0]  void/create/update
      command[1]  String/Int/Double/Bool/Sheet/List/Map
      command[2]  name
    */


    StringTools cursor = new StringTools(_data);

    bool run = true;
    while(run) {
      if(cursor.moveTo('"')) {
        cursor.startSelection();
        cursor.moveTo('"');
        cursor.move();
        cursor.stopSelection();
        cursor.deleteSelection();
        cursor.reset();
      } else {
        run = false;
      }
    }

    // can be 3/4/5/6
    if(cursor.data.contains('=')) {
      String type = variables.isVariableDeclaration(cursor.data);

      // can be 3/4
      if(type == "%NOTSUPPORTED%") {
        String name = cursor.data.split("=")[0].trim();
        if(pman.processes[_pid].args.isVar(name)) {
          command.add("update");
          command.add(pman.processes[_pid].args.getType(name));
          command.add(name);
        } else {
          print("Error: Unknown variable " + cursor.data);
        }
      } else {
        cursor.reset();
        cursor.deleteCharacters(type.length);
        String name = cursor.data.split("=")[0].trim();
        command.add("create");
        command.add(type);
        command.add(name);        
      }
    } else {
      command.add("void");
    }

    return command;
  }

  List<String> commandList() {
    List<String> commands = [];
    
    commands.addAll(functions.supportedFunctions);

    return commands;
  }

  Future<String> doFunctions(String function, String cursordata, int _pid, data) async {
    if (function != "%NOTSUPPORTED%") {
      
      StringTools cursor = StringTools(cursordata);
      switch(function) {   

        case "breakpoint": {
          breakpoint(_pid);
        }
        break;

        case "include": {
          String filepath = cursor.getQuotedString();
          String file = await functions.include(filepath, _pid);
          if (file != "") {
            String processed_file = await parse(file, _pid);
            data = data + processed_file;
          }
        } 
        break;

        case "print": {
          if(cursor.data.contains('"')) {
            String string = cursor.getQuotedString();
            data = data + functions.echo('"' + string + '"', _pid);
          } else {
            String variable = cursor.getFromTo("(", ")");
            data = data + functions.echo(variable, _pid);
          }
        } 
        break;

        case "echo": { 
          if(cursor.data.contains('"')) {
            String string = cursor.getQuotedString();
            data = data + functions.echo('"' + string + '"', _pid);
          } else {
            String variable = cursor.getFromTo("(", ")");
            data = data + functions.echo(variable, _pid);
          }
        }
        break;  

        case "flag": {
          String file = cursor.getQuotedString();
          String flagsite = functions.flag(file, _pid);
          if(flagsite != "unsupported") {
            pman.processes[_pid].flag = flagsite;
          }
        } 
        break;

        case "download": {
          String url = cursor.getQuotedString();
          String file = await functions.download('"' + url + '"', _pid);
          String processed_file = await parse("", _pid, externalfile: file);
          data = data + processed_file;
        } 
        break;

        case "debug": {
          functions.debug(cursor.data, _pid);
        } 
        break;

        case "sheet.addColumn": {
          functions.sheet_addColumn(_pid, cursordata.substring("sheet.addColumn".length).trim());
        }
        break;

        case "sheet.addRow": {
          functions.sheet_addRow(_pid, cursordata.substring("sheet.addRow".length).trim());
        }
        break;

        case "sheet.printRow": {
          data = data + functions.sheet_printRow(_pid, cursordata.substring("sheet.printRow".length).trim());
        }
        break;

        case "sheet.printCell": {
          data = data + functions.sheet_printCell(_pid, cursordata.substring("sheet.printCell".length).trim());
        }
        break;
      }
    }
    return data;
  }
}
