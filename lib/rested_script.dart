// RestedScript
// https://github.com/thomasberge/rested_script
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:string_tools/string_tools.dart';

import 'src/io.dart' as io;
import 'src/arguments.dart';
export 'src/arguments.dart';

class RestedScriptDocument {
  String flag = "";
  String document = "";

  RestedScriptDocument();
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
  RestedScript();

  String rootDirectory = "";

  String flag = "";

  // for future use
  String expandForLists(String data, int count) {
    return data;
  }

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
      String temp2 = collapseBlockTags(temp, levels);
      CodeBlock newblock = new CodeBlock(i, temp);
      codeblocks.add(newblock);
      i--;
      print("while (i > 0)");
    }

    return codeblocks;
  }

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
  }

  Future<String> createDocument(
      String filepath, RestedScriptArguments args) async {
    flag = "";
    String doc = await parse(filepath, args);
    if (flag != "") {
      doc = await parse("bin/resources/flagsites/" + flag, args);
    }
    return doc;
  }

  Future<String> parse(String filepath, RestedScriptArguments args,
      {String? externalfile = null}) async {
    args.setDirectoryPath(filepath);
    print("filepath=" + filepath);
    if (filepath != "") {
      try {
        File data = new File(filepath);
        List<String> lines = data.readAsLinesSync(encoding: utf8);
        return (await processLines(lines, args));
      } on FileSystemException {
        print("Error reading " + filepath);
        return ("");
      }
    } else if (externalfile != null) {
      LineSplitter ls = new LineSplitter();
      List<String> lines = ls.convert(externalfile);
      return (await processLines(lines, args));
    } else {
      return "";
    }
  }

  Future<String> doCommands(
      List<String> commands, RestedScriptArguments args) async {
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
                if (args.setmap.containsKey(key)) {
                  int i = 0;
                  String constructed_string = args.setmap[key];
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
              if (args.setmap.containsKey(key)) {
                data = data + args.setmap[key];
              } else {
                print("Key >" + key + "< not in setmap.");
              }
            }
          } else {
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

            if (scriptfunction == "include") {
              data = data + await f_include(scriptargument, args);
            } else if (scriptfunction == "flag") {
              data = data + f_flag(scriptargument, args);
            } else if (scriptfunction == "print" || scriptfunction == "echo") {
              data = data + f_print(scriptargument, args);
            } else if (scriptfunction == "set") {
              data = data + f_set(scriptargument, args);
            } else if (scriptfunction == "args") {
              data = data + f_args(scriptargument, args);
            } else if (scriptfunction == "debug") {
              f_debug(scriptargument, args);
            }
          }
        }
      }
    }
    return data;
  }

  /// RestedScript function: include
  ///
  /// Example:
  /// include("scripts.html");

  String f_set(String scriptargument, RestedScriptArguments args) {
    StringTools argparser = new StringTools(scriptargument);
    argparser.moveTo(',');
    String key = argparser.getAllBeforePosition();
    String value = argparser.getAllAfterPosition();
    args.setmap[key] = value;
    return "";
  }

  /// RestedScript function: args
  ///
  /// Example:
  ///
  String f_args(String scriptargument, RestedScriptArguments args) {
    if (args.args.containsKey(scriptargument)) {
      return args.args[scriptargument].toString();
    } else {
      return "";
    }
  }

  /// RestedScript function: include
  /// Reads the file and inserts the text at the position of the command.
  ///
  /// Example:
  /// include("scripts.html");

  Future<String> f_include(String argument, RestedScriptArguments args) async {
    if (argument.substring(0, 4) == "http") {
      String result = await io.downloadTextFile(argument);
      return (await parse("", args, externalfile: result));
    } else {
      argument = argument.replaceAll('"', '');
      List<String> split = argument.split('.');
      if (split.length > 1) {
        String filetype = argument.split('.')[1];

        if (filetype == 'html' || filetype == 'css') {
          return (await parse(argument, args));
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
  }

  String f_flag(String argument, RestedScriptArguments args) {
    argument = argument.replaceAll('"', '');
    String filetype = argument.split('.')[1];

    if (filetype == 'html') {
      flag = argument;
      return "";
    } else {
      print("RestedScript: Unsupported flag filetype for " + argument);
      return "";
    }
  }

  String f_print(String argument, RestedScriptArguments args) {
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

  void f_debug(String argument, RestedScriptArguments args) {
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
          print("Error: debug missing quote(s) inside parentheses.\r\n debug(" +
              fparser.data +
              ");");
          run = false;
        }
      } else {
        print("Error: debug missing quote(s) inside parentheses.\r\n debug(" +
            fparser.data +
            ");");
        run = false;
      }
    }

    print("\u001b[31m" + output + "\u001b[0m");
  }

  bool comment_on = false;

  String removeCommentsFromLine(String line) {
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

  Future<String> processLines(
      List<String> lines, RestedScriptArguments args) async {
    String document = removeComments(lines);
    List<String> rs_blocks = [];
    StringTools dparser = new StringTools(document);
    bool run = true;

    // process <% %> tags
    while (run) {
      String block;
      if (dparser.moveTo('<% forlist %>')) {
        dparser.deleteCharacters(13);
        dparser.startSelection();
        if (dparser.moveTo('<% endforlist %>')) {
          dparser.deleteCharacters(13);
          dparser.stopSelection();
          block = dparser.getSelection();
          dparser.position = dparser.start_selection;
          dparser.deleteSelection();
          int i = 0;
          while (i < args.list.length) {
            String newblock =
                block.replaceAll("<% element %>", args.list[i].toString());
            dparser.insertAtPosition(newblock);
            dparser.move(characters: newblock.length);
            i++;
          }
        } else {
          print("Missing closing <% endforlist %>");
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
          String result = await doCommands(command_list, args);
          String codeblocktag = "{%" + i.toString() + "%}";
          document = document.replaceAll(codeblocktag, result);
        }
      }
      i++;
    }

    return document;
  }

  String replaceInQuotedString(
      String block, String replace, String replaceWith) {
    StringTools block_parser = new StringTools(block);
    bool in_quote = false;
    while (block_parser.eol == false) {
      block_parser.moveTo('"');
    }
    return block;
  }

  String do_if(String command, String line, RestedScriptArguments args) {
    List<String> command_details = command.split(':');
    bool do_this = args.getBool(command_details[1]);
    return "";
  }
}
