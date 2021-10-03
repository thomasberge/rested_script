import 'package:string_tools/string_tools.dart';
import 'debug.dart';
import 'dart:io';
import 'dart:async';
import 'processes.dart';

Future<String> wrapDocument(int _pid, String data, String root) async {
    debug(_pid, "wrapDocument()");
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