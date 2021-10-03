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

/* -------- EXPERIMENTAL --------- */

/*
    result = calc;  

    var name = 

*/

List<String> commandList() {

}

/* ----------------------- */


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
        debug(_pid, "parse()()");
    if (filepath != "") {
      try {
        File data = new File(root + filepath);
        List<String> lines = data.readAsLinesSync(encoding: utf8);
        return (await processLines(lines, _pid));
      } on FileSystemException {
        print("Error reading " + root + filepath);
        return ("");
      }
    } else if (externalfile != null) {
      LineSplitter ls = new LineSplitter();
      List<String> lines = ls.convert(externalfile);
      return (await processLines(lines, _pid));
    } else {
      return "";
    }
  }

  Future<String> doCommands(List<String> commands, int _pid) async {
    debug(_pid, "doCommands()");
    String data = "";

    for (String command in commands) {
      if (command != null) {
        command = command.trim();
        if (command != "") {

          StringTools cparser = new StringTools(command);
          if ('${cparser.data[0]}' == '\$') {
            // if the character first is a $ ...
            // set-function
            if (command[command.length - 1] == ')') {
              cparser.move();
              cparser.startSelection();
              cparser.moveTo('(');
              cparser.stopSelection();
              String key = cparser.getSelection();
              cparser.move();
              cparser.startSelection();
              cparser.moveToEnd();
              cparser.move(characters: -2);
              cparser.stopSelection();
              String scriptarguments = cparser.getSelection();
              if (scriptarguments != null) {
                List<String> arglist = scriptarguments.split('|');
                if (pman.processes[_pid].args.setmap.containsKey(key)) {
                  int i = 0;
                  String constructed_string = pman.processes[_pid].args.setmap[key];
                  for (String replacement in arglist) {
                    constructed_string = constructed_string.replaceAll(
                        ('\$' + i.toString()), replacement);
                    i++;
                  }
                  data = data + constructed_string;
                } else {
                  print("Key >" + key + "< not in setmap.");
                }
              } else {
                print("Set variable reffered to as function " +
                    key +
                    "() but does not provide any arguments. Either use without () or add argument.");
              }
            } else {
              String key = cparser.data.substring(1);
              if (pman.processes[_pid].args.setmap.containsKey(key)) {
                data = data + pman.processes[_pid].args.setmap[key];
              } else {
                print("Key >" + key + "< not in setmap.");
              }
            }
          } else {

            String function = functions.isSupportedFunction(cparser.data);
            data = await doFunctions(function, cparser.data, _pid, data);

            // FUNCTIONCALLS
            cparser.startSelection();
            cparser.moveTo('(');
            cparser.stopSelection();
            String scriptfunction = cparser.getSelection();

            cparser.move();
            cparser.startSelection();
            cparser.moveToEnd();
            cparser.move(characters: -1);
            cparser.stopSelection();
            String scriptargument = cparser.getSelection();

            if (scriptfunction == "set") {
              data = data + f_set(scriptargument, _pid);
            }
          }
        }
      }
    }
    return data;
  }

  // NEW FUNCTIONS METHOD
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
          StringTools cursor = StringTools(cursordata.substring("sheet.addColumn".length).trim());
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
        break;

        case "sheet.addRow": {
          StringTools cursor = StringTools(cursordata.substring("sheet.addRow".length).trim());
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
        break;

        case "sheet.printRow": {
          StringTools cursor = StringTools(cursordata.substring("sheet.printRow".length).trim());
          cursor.deleteEdges();
          cursor.data.trim();
          cursor.data = cursor.data.replaceAll(' ', '');

          List<String> elements = cursor.data.split(',');
          List<String> row = pman.processes[_pid].args.vars[elements[0]].getRowByIndex(int.parse(elements[1]));

          //print(">" + row.toString() + "<");
          data = data + row.toString();
        }
        break;

        case "sheet.printCell": {
          StringTools cursor = StringTools(cursordata.substring("sheet.printCell".length).trim());
          cursor.deleteEdges();
          cursor.data.trim();
          cursor.data = cursor.data.replaceAll(' ', '');

          List<String> elements = cursor.data.split(',');
          String cell = pman.processes[_pid].args.vars[elements[0]].getCellByIndex(int.parse(elements[1]), int.parse(elements[2]));

          //print(">" + cell + "<");
          data = data + cell;
        }
        break;
      }
    } else {
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

  bool comment_on = false;

  Future<String> processRSTags(String data, int _pid) async {
    List<String> rs_blocks = [];
    StringTools dparser = new StringTools(data);

    bool run = true;

    // process <?rs ?> tags
    while (run) {
      if (dparser.moveTo('<?rs')) {
        dparser.deleteCharacters(4);
        dparser.startSelection();
        if (dparser.moveTo('?>')) {
          dparser.deleteCharacters(2);
          dparser.stopSelection();
          rs_blocks.add(dparser.getSelection().trim());
          dparser.position = dparser.start_selection;
          dparser.deleteSelection();
          String codeblocktag = "{%" + (rs_blocks.length - 1).toString() + "%}";
          dparser.insertAtPosition(codeblocktag);
        } else {
          print("Missing closing bracket restedscript ?>");
        }
      } else {
        run = false;
      }
    }

    String document = dparser.data;

    int i = 0;
    for (String block in rs_blocks) {
      if (block != null) {
        if (block.contains(';')) {
          List<String> command_list = block.split(';');
          String result = await doCommands(command_list, _pid);
          String codeblocktag = "{%" + i.toString() + "%}";
          document = document.replaceAll(codeblocktag, result);
        } else {  // Empty rs tags like such <?rs ?>
          String codeblocktag = "{%" + i.toString() + "%}";
          document = document.replaceAll(codeblocktag, "");
        }
      }
      i++;
    }

    return document;
  }

  Future<String> processLines(List<String> lines, int _pid) async {
    debug(_pid, "processLines()");
    String document = removeComments(_pid, lines);
    document = await wrapDocument(_pid, document, root);
    document = processForEach(document, _pid);
    document = await processRSTags(document, _pid);
    return document;
  }
}
