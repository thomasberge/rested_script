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

  String flag = "";

  List<CodeBlock> CreateCodeBlocks(String data) {
    int start_tags = 0;
    StringTools bparser = new StringTools(data);
    List<String> tags = [];
    tags.add('{');
    tags.add('}');
    int levels = 0;
    String character = "startvalue";
    List<int> levellist = [];
    while (character != null) {
      character = bparser.moveToListElement(tags);
      if (character != null) {
        if (character == '{') {
          levels++;
          levellist.add(levels);
          String movestring = "{{" + levels.toString() + "}}";
          int movelength = movestring.length;
          bparser.replaceCharacters(1, "{{" + levels.toString() + "}}");
          bparser.move(characters: movelength);
        } else if (character == '}') {
          int last_uplevel = levellist.removeLast();
          String movestring = "{{" + last_uplevel.toString() + "}}";
          int movelength = movestring.length;
          bparser.replaceCharacters(1, "{{" + last_uplevel.toString() + "}}");
          bparser.move(characters: movelength);
        }
      }
      print("while (character != null)");
    }
    data = bparser.data;

    List<CodeBlock> codeblocks = [];

    int i = levels;
    while (i > 0) {
      List<String> blocklist = data.split('{{' + i.toString() + '}}');
      String temp = blocklist[1].toString();
      //String temp2 = collapseBlockTags(temp, levels);
      CodeBlock newblock = new CodeBlock(i, temp);
      codeblocks.add(newblock);
      i--;
      print("while (i > 0)");
    }

    return codeblocks;
  }
/*
  // Collapses {{i}}<code>{{i}} to {{i}}
  //
  //  NOT YET DONE, CURRENTLY DOESNT RETURN ANYTHING
  String collapseBlockTags(String data, int levels) {
    StringTools bparser = new StringTools(data);
    int i = levels;
    while (i > 0) {
      String nextTag = '{{' + i.toString() + '}}';
      if (data.contains(nextTag)) {
        bparser.position = 0;
        bparser.moveTo(nextTag);
        bparser.move(characters: 5);
        bparser.startSelection();
        bparser.moveTo(nextTag);
        bparser.move(characters: 5);
        bparser.stopSelection();
        bparser.deleteSelection();
      }
      i--;
    }
    return "";
  }*/

  Future<String> createDocument(String filepath, {Arguments? args = null}) async {
    flag = "";

    if(args == null) {
      args = Arguments();
    }

    int pid = pman.createProcess(args);
    String doc = await parse(filepath, pid);

    if (flag != "") {
      doc = await parse("flagsites/" + flag, pid);
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

  Future<String> parse(String filepath, int pid, {String? externalfile = null}) async {
        debug("parse()()");
    if (filepath != "") {
      try {
        File data = new File(root + filepath);
        List<String> lines = data.readAsLinesSync(encoding: utf8);
        return (await processLines(lines, pid));
      } on FileSystemException {
        print("Error reading " + root + filepath);
        return ("");
      }
    } else if (externalfile != null) {
      LineSplitter ls = new LineSplitter();
      List<String> lines = ls.convert(externalfile);
      return (await processLines(lines, pid));
    } else {
      return "";
    }
  }

  Future<String> doCommands(List<String> commands, int pid) async {
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
                if (pman.processes[pid].args.setmap.containsKey(key)) {
                  int i = 0;
                  String constructed_string = pman.processes[pid].args.setmap[key];
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
              if (pman.processes[pid].args.setmap.containsKey(key)) {
                data = data + pman.processes[pid].args.setmap[key];
              } else {
                print("Key >" + key + "< not in setmap.");
              }
            }
          } else {
            String function = functions.isSupportedFunction(cparser.data);
            //if (function != "%NOTSUPPORTED%") {
              data = await doFunctions(function, cparser.data, pid, data);
            //} 
            /* else {
              String variabletype = variables.isVariableDeclaration(cparser.data);
              if (variabletype != "%NOTSUPPORTED%") {
                if(variabletype == "Map") {
                  cparser.data = cparser.data.substring(variabletype.length + 1);
                  if(cparser.moveTo('=')) {
                    String variablename = cparser.getAllBeforePosition().trim();
                    String variabledeclaration = cparser.getAllAfterPosition().trim();
                    cparser.data = variabledeclaration;
                    if(cparser.firstIs('{')) {
                      if(cparser.lastIs('}')) {
                        try {
                          Map valueMap = jsonDecode(variabledeclaration);
                        } catch(e) {
                          print("Unable to parse to map. Need to be valid JSON.\r\n" + variabledeclaration);
                        }
                      } else {
                        print("Map declaration not terminated with }\r\n" + variabledeclaration);
                      }
                    } else {
                      print("Map from var:" + variabledeclaration);
                    }
                  } else {
                    print("Map declaration error, missing = in declaration:\r\nMap " + cparser.data);
                  }
                  print(">" + cparser.data + "<");
                }
                
              }
            }*/
            

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
              data = data + f_set(scriptargument, pid);
            } else if (scriptfunction == "args") {
              data = data + f_args(scriptargument, pid);
            }else if (scriptfunction == "var") {
              functions.variable(scriptargument, pid);
            }
          }
        }
      }
    }
    return data;
  }

  // NEW FUNCTIONS METHOD
  Future<String> doFunctions(String function, String cursordata, int pid, data) async {

    if (function != "%NOTSUPPORTED%") {
      StringTools cursor = StringTools(cursordata);
      switch(function) {   

        case "include": {
          String filepath = cursor.getQuotedString();
          String file = await functions.include(filepath, pid);
          if (file != "") {
            String processed_file = await parse(file, pid);
            data = data + processed_file;
          }
        } 
        break;

        case "print": {
          if(cursor.data.contains('"')) {
            String string = cursor.getQuotedString();
            data = data + functions.echo('"' + string + '"', pid);
          } else {
            String variable = cursor.getFromTo("(", ")");
            data = data + functions.echo(variable, pid);
          }
        } 
        break;

        case "echo": { 
          if(cursor.data.contains('"')) {
            String string = cursor.getQuotedString();
            data = data + functions.echo('"' + string + '"', pid);
          } else {
            String variable = cursor.getFromTo("(", ")");
            data = data + functions.echo(variable, pid);
          }
        }
        break;  

        case "flag": {
          String file = cursor.getQuotedString();
          String flagsite = functions.flag(file, pid);
          if(flagsite != "unsupported") {
            flag = flagsite;
          }
        } 
        break;

        case "download": {
          String url = cursor.getQuotedString();
          String file = await functions.download('"' + url + '"', pid);
          String processed_file = await parse("", pid, externalfile: file);
          data = data + processed_file;
        } 
        break;

        case "debug": {
          
          //String message = cursor.getQuotedString();
          //functions.debug('"' + message + '"', pid);
          functions.debug(cursor.data, pid);
        } 
        break;

      }
    } else {
      String variableType = variables.isVariableDeclaration(cursordata);
      //print("Variable type=" + variableType + "<");
      //print("Data: " + cursordata);
      if( variableType != "%NOTSUPPORTED%"){
        switch(variableType) {

        case "String": {
          variables.initString(pid, cursordata);
        }
        break;

        case "Int": {
          variables.initInt(pid, cursordata);
        }
        break;

        case "Bool": {
          variables.initBool(pid, cursordata);
        }
        break;
/*
        case "Map": {
          List<String> values = [" ", "["];
          cursor.startSelection();
          String type = cursor.moveToListElement(values);

          // If first char is [ then the value is being used.
          if (type == "[") {
            cursor.stopSelection();
            String mapname = cursor.getSelection();
            if(pman.processes[pid].args.isVar(mapname)) {
              String arg = cursor.getQuotedString();
              var mapdata = pman.processes[pid].args.get(mapname);
              data = data + mapdata[arg].toString();
            }

          // If the first value is a space then the variable is being initialized.
          } else if (type == " "){

          }
        } 
        break;*/

        }
      }
    }
    return data;
  }

  /// RestedScript function: include
  ///
  /// Example:
  /// include("scripts.html");

  String f_set(String scriptargument, int pid) {
    debug("f_set()");
    StringTools argparser = new StringTools(scriptargument);
    argparser.moveTo(',');
    String key = argparser.getAllBeforePosition();
    String value = argparser.getAllAfterPosition();
    pman.processes[pid].args.setmap[key] = value;
    return "";
  }

  /// RestedScript function: args
  ///
  /// Example:
  ///
  String f_args(String scriptargument, int pid) {
    debug("f_args()");
    //Arguments args = pman.processes[pid].args;
    if (pman.processes[pid].args.args.containsKey(scriptargument)) {
      return pman.processes[pid].args.args[scriptargument].toString();
    } else {
      return "";
    }
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
      if (i < lines.length) {
        document.add(line + "\n");
      } else {
        document.add(line);
      }
      /*
      if(rs || line.contains('<?rs')) {
        if(line.contains('?>')) {
          rs = false;
          document.add(removeCommentsFromLine(line));
        } else {
          rs = true;
          document.add(removeCommentsFromLine(line));
        }
      }    
      if(rs) {
        if(line.contains('?>')) {
          rs = false;
        }
      }*/
    }

    return document.join();
  }

  Future<String> processLines(List<String> lines, int pid) async {
    debug("processLines()");
    String document = removeComments(lines);
    document = await wrapDocument(document);
    List<String> rs_blocks = [];
    StringTools dparser = new StringTools(document);
    bool run = true;

    // process <% %> tags
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
          var thelist = pman.processes[pid].args.get(listname);
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

    document = dparser.data;
    dparser = new StringTools(document);
    run = true;

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

    document = dparser.data;

    int i = 0;
    for (String block in rs_blocks) {
      if (block != null) {
        if (block.contains(';')) {
          List<String> command_list = block.split(';');
          String result = await doCommands(command_list, pid);
          String codeblocktag = "{%" + i.toString() + "%}";
          document = document.replaceAll(codeblocktag, result);
        }
      }
      i++;
    }

    return document;
  }
}
