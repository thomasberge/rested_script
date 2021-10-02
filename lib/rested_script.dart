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

bool debugEnabled = false;
void debug(String message) {
  if(debugEnabled) {
    print(message);
  }
}

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

  Future<String> createDocument(String filepath, {Arguments? args = null}) async {
    if(args == null) {
      args = Arguments();
    }

    int _pid = pman.createProcess(args);
    String doc = await parse(filepath, _pid);

    if (pman.processes[_pid].flag != "") {
      doc = await parse("flagsites/" + pman.processes[_pid].flag, _pid);
    }
    return doc;
  }

  Future<String> wrapDocument(String data) async {
    debug("wrapDocument()");
    StringTools cursor = new StringTools(data);

    // Gets both arguments (file and content id) and deletes the wrap function call from
    // the document.
    if(cursor.moveTo('{{wrap("')) {
      cursor.deleteCharacters('{{wrap("'.length);
      cursor.startSelection();
      cursor.moveTo('")}}');
      cursor.stopSelection();
      String wrapArgs = cursor.getSelection();
      cursor.deleteCharacters('")}}'.length);
      cursor.deleteSelection();
      data = cursor.data;

      StringTools argsCursor = StringTools(wrapArgs);
      if(argsCursor.moveTo('"')) {
        argsCursor.startSelection();

        if(argsCursor.moveToNext('"')) {
          argsCursor.move();
          argsCursor.stopSelection();
          int separatorLength = argsCursor.getSelection().length;
          argsCursor.deleteSelection();
          argsCursor.move(characters: -separatorLength);
          String fileRef = argsCursor.getAllBeforePosition();
          String contentId = argsCursor.getAllFromPosition();

          String fileData = await File(root + fileRef).readAsString();
          if(fileData.contains('{{content("' + contentId + '")}}')) {
            List<String> fileDataSplit = fileData.split('{{content("' + contentId + '")}}');
            if(fileDataSplit.length == 2) {
              data = fileDataSplit[0] + data + fileDataSplit[1];
            } else {
              print('ERROR More than one contentId "' + contentId + '" in ' + root + fileRef);
            }
          } else {
            print('ERROR Unable to locate contentId reference "' + contentId + '" in ' + root + fileRef);
          }
        } else {
          print("ERROR Cannot parsing wrap() arguments: " + argsCursor.data + "\r\nwrap(string Filepath, string ContentId);");          
        }
      } else {
        print("Error parsing wrap() arguments: " + argsCursor.data + "\r\nwrap(string Filepath, string ContentId);");
      }
    }
    return data;
  }

  Future<String> parse(String filepath, int _pid, {String? externalfile = null}) async {
        debug("parse()()");
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
    debug("doCommands()");
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
    debug("f_set()");
    StringTools argparser = new StringTools(scriptargument);
    argparser.moveTo(',');
    String key = argparser.getAllBeforePosition();
    String value = argparser.getAllAfterPosition();
    pman.processes[_pid].args.setmap[key] = value;
    return "";
  }

  bool comment_on = false;

  String removeCommentsFromLine(String line) {
    debug("removeCommentsFromLine()");
    if (comment_on) {
      line = "";
    } else if (line.contains('//')) {
      line = line.split('//')[0];
    } else if (line.contains('/*')) {
      comment_on = true;
      line = line.split('/*')[0];
    } else if (line.contains('*/')) {
      comment_on = false;
      line = line.split('*/')[0];
    }
    return line;
  }

  String removeComments(List<String> lines) {
    debug("removeComments()");
    List<String> document = [];
    bool rs = false;

    int i = 0;

    for (var line in lines) {
      i++;

      // Lines with both <?rs and ?> does currently not support comments

      if(rs = false) {
        if(line.contains("<?rs")) {
          rs = true;
          StringTools cursor = StringTools(line);
          cursor.moveTo("<?rs");
          if(cursor.moveTo('//')) {
            cursor.startSelection();
            cursor.moveToEnd();
            cursor.stopSelection();
            cursor.deleteSelection();
            line = cursor.data;
          }
        }
      } else {
        if(line.contains("?>")){
          rs = false;
        } else {
          StringTools cursor = StringTools(line);
          if(cursor.moveTo('//')) {
            cursor.startSelection();
            cursor.moveToEnd();
            cursor.stopSelection();
            cursor.deleteSelection();
            line = cursor.data;
          }          
        }
      }

      if (i < lines.length) {
        document.add(line + "\n");
      } else {
        document.add(line);
      }
    }

    return document.join();
  }

  String processForEach(String data, int _pid) {
    StringTools dparser = StringTools(data);
    bool run = true;
    while (run) {
      String block;

      // If the start of a forEach is found, select it and throw it into a new ST and get
      // the key to the list. Then delete the forEach, return to the previous position and 
      // start marking the block.
      if (dparser.moveTo('{{foreach')) {
        int prevPos = dparser.position;
        dparser.startSelection();
        dparser.moveTo('}}');
        dparser.move(characters: 2);
        dparser.stopSelection();
        StringTools forEachParser = StringTools(dparser.getSelection());
        String listname = forEachParser.getQuotedString();
        dparser.deleteSelection();
        dparser.position = prevPos;
        dparser.startSelection();

        if (dparser.moveTo('{{endforeach("' + listname + '")}}')) {
          dparser.deleteCharacters(('{{endforeach("' + listname + '")}}').length);
          dparser.stopSelection();
          block = dparser.getSelection();
          dparser.position = dparser.start_selection;
          dparser.deleteSelection();


          //List<dynamic> thelist = args.get(listname);
          var thelist = pman.processes[_pid].args.get(listname);
            int i = 0;
            while (i < thelist.length) {
              String newblock =
                  block.replaceAll('{{element("' + listname + '")}}', thelist[i].toString());
              dparser.insertAtPosition(newblock);
              dparser.move(characters: newblock.length);
              i++;
            }            
        } else {
          print('Missing closing {{endforeach}}');
        }
      } else {
        run = false;
      }
    }

    return dparser.data;
  }

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
    debug("processLines()");
    String document = removeComments(lines);
    document = await wrapDocument(document);
    document = processForEach(document, _pid);
    document = await processRSTags(document, _pid);
    return document;
  }
}
