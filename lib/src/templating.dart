import 'package:string_tools/string_tools.dart';
import 'debug.dart';
import 'dart:io';
import 'dart:async';
import 'processes.dart';
import 'sheets.dart';

/*
  Helper class for dealing with nested structures. Allows for keeping track of block ids.

  Increment to next non-used value when stepping in, add to map as open (false).
  Decrement to last non-used value when stepping out, set to closed (true).
*/
class NestingMap {
  int level = -1;
  Map<int, bool> _idmap = {};
  Map<int, String> conditionals = {};
  Map<int, String> blocks = {};
  String data = "";

  void setNextId() {
    level++;
    _idmap[level] = false;
  }

  String getPreviousId() {
    int i = level;
    while(_idmap[i] == true) {
      i--;
      if(i < 0) {
        break;
      }
    }
    _idmap[i] = true;
    return i.toString();
  }

  void addConditional(String conditional) {
    conditionals[level] = conditional;
  }
}

Future<String> removeTemplateComments(int _pid, String data) async {
  debug(_pid, "ifConditions()");
  StringTools cursor = StringTools(data);

  while(cursor.moveTo("{#")) {
    cursor.startSelection();
    if(cursor.moveTo("#}")) {
      cursor.move();
      cursor.move();
      cursor.stopSelection();
      cursor.deleteSelection();
      cursor.reset();
    }
    else {
      print("Error: missing end comment #}");
      break;
    }
  }

  return cursor.data;
}

String extractConditional(int _pid, String prefix, String data) {
  debug(_pid, "extractConditional()");
  StringTools cursor = StringTools(data);
  cursor.deleteCharacters(('{% ' + prefix + ' ').length);
  cursor.moveTo(' %}');
  cursor.deleteCharacters(' %}'.length);
  return cursor.data;
}


/*
 *    if
 */

Future<String> ifConditions(int _pid, String data) async {  
  debug(_pid, "ifConditions()");
  
  while(data.contains("{% if")) {
    StringTools cursor = new StringTools(data);

    if(cursor.moveTo('{% if')) {

      bool run = true;
      int level = 0;
      bool keep = true;
      //String conditional = "";
      List<String> conditionals = [];

      while(run) {
       
        String element = cursor.moveToListElement(["{% if", "{% endif %}"]);

        if(element == "{% if") {
          if(level == 0) {
            cursor.selectFromTo("{% ", " %}", includeArguments: true);
            conditionals.add(extractConditional(_pid, 'if', cursor.getSelection()));
            cursor.replaceSelection("{%START-IF%}");
            level++;
          } else {
            level++;
            cursor.move();
          }

        // If we encounter an 'endif' we simply add the previous unclosed id to the end
        // of the endif statement. See NestedMap for details on how previousId() works.
        } else if(element == "{% endif %}") {
          level--;
          if(level == 0) {
            cursor.selectFromTo("{% ", " %}", includeArguments: true);
            cursor.replaceSelection("{%STOP-IF%}");
            run = false;
          } else {
            cursor.move();
          }

        } else {
          run = false;
        }
      }

      // doesnt work for multiple conditionals (elseif, else), needs refactoring
      for(int i = 0;i<conditionals.length;i++) {
        //keep = evaluateConditional(_pid, conditionals[0]);
        keep = pman.processes[_pid].evaluate(conditionals[0]);
      }
      
      if(keep) {
        cursor.reset();
        cursor.moveTo("{%START-IF%}");
        cursor.deleteCharacters("{%START-IF%}".length);
        cursor.moveTo("{%STOP-IF%}");
        cursor.deleteCharacters("{%STOP-IF%}".length);
      } else {
        cursor.reset();
        cursor.deleteFromTo("{%START-IF%}", "{%STOP-IF%}", includeArguments: true);
      }
    }
    data = cursor.data;
  }
  return data;
}

Future<String> templateDebugDump(_pid, document) async {
  if(document.contains("{{ dump() }}")) {
    pman.processes[_pid].args.debug();
    return document.replaceAll("{{ dump() }}", "");
  } else {
    return document;
  }
}

/*
 *    <var> echo
 */

Future<String> echoVariables(int _pid, String data) async {
  StringTools cursor = new StringTools(data);
  while(cursor.moveTo('{{ ')) {
    cursor.selectFromTo('{{ ', ' }}', includeArguments: true);
    cursor.deleteEdgesOfSelection(characters: 3);
    String key = cursor.getSelection();
    dynamic value = pman.processes[_pid].get(key);
    if(value == null) {
      cursor.replaceSelection("");
    } else {
      cursor.replaceSelection(value.toString());
    }
  }
  return cursor.data;
}

/*
 *    wrap, to be refactored
 */

Future<String> wrapDocument(int _pid, String data, String root) async {
    debug(_pid, "wrapDocument()");
    StringTools cursor = new StringTools(data);

    // Gets both arguments (file and content id) and deletes the wrap function call from
    // the document.
    if(cursor.moveTo('{{wrap(')) {
      cursor.deleteCharacters('{{wrap('.length);
      cursor.startSelection();
      cursor.moveTo(')}}');
      cursor.stopSelection();
      String wrapArgs = cursor.getSelection();
      cursor.deleteCharacters(')}}'.length);
      cursor.deleteSelection();
      data = cursor.data;

      StringTools argsCursor = StringTools(wrapArgs);
      String fileRef = argsCursor.deleteFromTo('"', '"', deleteArguments: true);
      String contentId = argsCursor.deleteFromTo('"', '"', deleteArguments: true);
      

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
    }
    return data;
  }

/*
 *    deprecated forEach
 */

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
        String listname = dparser.getFromTo('(', ')');
        dparser.position = prevPos;
        dparser.deleteFromTo('{{', '}}', includeArguments: true);
        dparser.position = prevPos;
        dparser.startSelection();

        if (dparser.moveTo('{{endforeach(' + listname + ')}}')) {
          dparser.deleteCharacters(('{{endforeach(' + listname + ')}}').length);
          dparser.stopSelection();
          block = dparser.getSelection();
          dparser.position = dparser.start_selection;
          dparser.deleteSelection();

          var thelist;
          String sheetname = "";

          bool fullsheet = false;

          // PICK A LIST
          // If the listname contains a . then it is a sheet. A sheet is basically a collection of lists. If the column name
          // (list name) is specified after the . then that column list is used in the forEach. If an * is used however then
          // the fullsheet variable is set to true and no list is specified. Instead, each list in the sheet is parsed over
          // in the PARSE THE LIST part.
          if(listname.contains('.')) {
            sheetname = listname.split('.')[0];
            String columnname = listname.split('.')[1];

            if(columnname == '*') {
              fullsheet = true;
            } else {
              Sheet sheet = pman.processes[_pid].args.get(sheetname);
              thelist = sheet.getColumnByName(columnname);
            }
          } else {
            thelist = pman.processes[_pid].args.get(listname);  
          }
          
          // PARSE THE LIST
          if(fullsheet == false) {  // if singular list
            int i = 0;
            while (i < thelist.length) {
              String newblock = block.replaceAll('{{' + listname + '}}', thelist[i].toString());
              dparser.insertAtPosition(newblock);
              dparser.move(characters: newblock.length);
              i++;
            }
          } else {    // if full-blown sheet zomg
            Sheet sheet = pman.processes[_pid].args.get(sheetname);
            
            int i = 0;
            while (i < sheet.lines) {
              String newblock = block;
              for(String header in sheet.headers) {
                if(newblock.contains(sheetname + "." + header)) {
                  String cell = sheet.getCellByColumnName(header, i);
                  newblock = newblock.replaceAll('{{' + sheetname + '.' + header + '}}', cell);
                }
              }
              dparser.insertAtPosition(newblock);
              dparser.move(characters: newblock.length);
              i++;
            }
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

/*
 *    for <var> in <key>

      1.  Replaces a for/endfor tag-pair (it tackles nesting) with START-FOR/STOP-FOR tags, while copying the
          for expression to a separate string.
      2.  The content of the START/STOP-tags are copied to a forBlock.
      3.  The for-expression is broken up and the List (doesnt support maps yet) are fetched from the process.
      4.  Parses the forBlock one time for each List element, replacing with the corresponding values.
 */

Future<String> forin(int _pid, String data) async {
  debug(_pid, "template_forin()");

  StringTools cursor = StringTools(data);

  while(cursor.moveTo("{% for ")) {
    cursor.startSelection();
    cursor.moveTo("%}");
    cursor.move();
    cursor.move();
    cursor.stopSelection();
    String expression = cursor.getSelection();
    cursor.replaceSelection("{%START-FOR%}");

    int level = 0;
    bool run = true;

    while(run) {
      String element = cursor.moveToListElement(["{% for ", "{% endfor %}"]);

      if(element == "{% for ") {
        level++;
        cursor.move();
      } else if(element == "{% endfor %}") {
        if(level == 0) {
          cursor.selectFromTo("{% ", " %}", includeArguments: true);
          cursor.replaceSelection("{%STOP-FOR%}");
          run = false;
        } else {
          level--;
          cursor.move();
        }
      } else {
        run = false;
      }
    }

    cursor.reset();
    cursor.selectFromTo("{%START-FOR%}", "{%STOP-FOR%}", includeArguments: true);
    String forBlock = cursor.getSelection();
    forBlock = forBlock.replaceAll("{%START-FOR%}", "");
    forBlock = forBlock.replaceAll("{%STOP-FOR%}", "");

    // Return with original data if the for loop has wrong number of elements
    List<String> expList = expression.trim().split(' ');

    if(expList.length != 6) {
      print("Error in for-in loop");
      return data;
    }

    // Return with original data if the array is not present in process or arguments
    var list = pman.processes[_pid].get(expList[4]);

    if(list == null) {
      print("Unable to find array '" + expList[4] + "'");
      return data;
    }

    // Check that the var is indeed a List
    if(list is List == false) {
      print("Error in for-in loop, the argument " + expList[4] + " is not a List. Only Lists are currently supported.");
      return data;
    }

    String combinedBlocks = "";
    for(var element in list) {
      pman.processes[_pid].set(expList[2], element.toString());
      combinedBlocks = combinedBlocks + await echoVariables(_pid, forBlock);
    }

    cursor.replaceSelection(combinedBlocks);
  }
  return cursor.data;
}