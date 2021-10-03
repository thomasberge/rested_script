import 'package:string_tools/string_tools.dart';
import 'debug.dart';

String removeComments(int _pid, List<String> lines) {
    debug(_pid, "removeComments()");
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