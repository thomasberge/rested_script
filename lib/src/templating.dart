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

String extractConditional(String prefix, String data) {
  debug(_pid, "extractConditional()");
  StringTools c_cursor = StringTools(data);
  c_cursor.deleteCharacters(('{% ' + prefix + ' ').length);
  c_cursor.moveTo(' %}');
  c_cursor.deleteCharacters(' %}'.length);
  return c_cursor.data;
}

bool evaluateConditional(int _pid, String conditional) {
  debug(_pid, "evaluateConditional()");

  bool not = false;
  List<String> elements = conditional.split(' ');
  
  if(elements[0].toLowerCase() == 'not' || elements[0].toLowerCase() == '!') {
    not = true;
  } else if (elements[0].substring(0,1) == '!') {
    not = true;
    elements[0] = elements[0].substring(1, elements[0].length);
  }

  if(pman.processes[_pid].args.isVar(elements[0])) {
    if(pman.processes[_pid].args.type(elements[0]) == "Bool") {
      if(not) {
        return !pman.processes[_pid].args.vars[elements[0]];
      } else {
        return pman.processes[_pid].args.vars[elements[0]];
      }
    } else {
      if(not) {
        return true;
      } else {
        return false;
      }
    }
  } else {
      if(not) {
        return true;
      } else {
        return false;
      }
  }
}

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
            conditionals.add(extractConditional('if', cursor.getSelection()));
            cursor.replaceSelection("{%START%}");
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
            cursor.replaceSelection("{%STOP%}");
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
        keep = evaluateConditional(_pid, conditionals[0]);
      }
      
      if(keep) {
        cursor.reset();
        cursor.moveTo("{%START%}");
        cursor.deleteCharacters("{%START%}".length);
        cursor.moveTo("{%STOP%}");
        cursor.deleteCharacters("{%STOP%}".length);
      } else {
        cursor.reset();
        cursor.deleteFromTo("{%START%}", "{%STOP%}", includeArguments: true);
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