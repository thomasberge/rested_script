import 'package:string_tools/string_tools.dart';
import 'debug.dart';
import 'dart:io';
import 'dart:async';
import 'processes.dart';
import 'sheets.dart';

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