import 'package:string_tools/string_tools.dart';
import 'debug.dart';

String removeComments(int _pid, List<String> lines) {
    debug(_pid, "removeComments()");
    List<String> document = [];
    bool rs = false;
    List<String> stopAt = ['<?rs', '"', '//', '?>'];

    int i = 0;

    // iterates over lines one by one. If rs tag is encountered the rs flag is turned on/off.
    // when on, it looks for quotes and comments. If unescaped quotes are encountered the inString
    // is turned on/off respectively. If off and comments // are encuntered then it will select the
    // rest of the script until either endofline or endofscript ?>. The selected string will be deleted.
    for (var line in lines) {
      bool inString = false;
      bool commentOn = false;
      i++;

      StringTools cursor = StringTools(line);

      String element = cursor.moveToListElement(stopAt);
      while(element != "") {
        if(element == '<?rs') {
          rs = true;
        } else if(element == '?>') {
          if(commentOn) {
            cursor.stopSelection();
            cursor.deleteSelection();
            commentOn = false;
          }
          rs = false;
        } else if(element == '"' && rs) {
          if(cursor.getBeforePosition != r'\') {
            inString = !inString;
          }
        } else if(element == '//' && rs && inString == false) {
          cursor.startSelection();
          commentOn = true;
        }
        cursor.move();
        element = cursor.moveToListElement(stopAt);
        
        if(element == "") {
          if(commentOn) {
            cursor.stopSelection();
            cursor.deleteSelection();
          }
        }
      }

      if (i < lines.length) {
        document.add(cursor.data + "\n");
      } else {
        document.add(cursor.data);
      }      
    }

    return document.join();
  }