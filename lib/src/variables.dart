import 'processes.dart';
import 'package:string_tools/string_tools.dart';
import 'sheets.dart';

List<String> supportedVariableTypes = ["Map", "String", "Int", "List", "Bool", "Double", "Sheet"];
List<String> supportedSheetColumnTypes = ["String"];

RegExp keyFormat = RegExp(r"^[a-zA-Z0-9_-]*$");
RegExp variableChars = new RegExp(r"^[a-z0-9_]*$", caseSensitive: false);

String isVariableDeclaration(String data) {
  int i = 0;
  String supported = "%NOTSUPPORTED%";
  while(i < supportedVariableTypes.length) {
    if (data.substring(0, supportedVariableTypes[i].length + 1) == supportedVariableTypes[i] + " ")
    {
      supported = supportedVariableTypes[i];
      i = 10000000;
    }
    i++;
  }

  if(supported == "%NOTSUPPORTED%") {
  }

  return supported;
}

bool isSupportedSheetColumnType(String _type) {
  int i = 0;
  bool supported = false;
  while(i < supportedSheetColumnTypes.length) {
    if(_type == supportedSheetColumnTypes[i]) {
      supported = true;
    }
    i++;
  }
  return supported;
}

RegExp intStringFormat = RegExp(r"^[0-9-+/*().]*$");

List<String> doMultiplications(List<String> data) {
  bool run = true;
  while(run) {
    run = false;
    for(int i=0; i<data.length; i++) {
      if(data[i] == "*") {
        data[i] = (toNumber(data[i-1]) * toNumber(data[i+1])).toString();
        data.removeAt(i+1);
        data.removeAt(i-1);
        run = true;
      }
    }
  }
  return data;
}

List<String> doDivisions(List<String> data) {
  bool run = true;
  while(run) {
    run = false;
    for(int i=0; i<data.length; i++) {
      if(data[i] == "/") {
        data[i] = (toNumber(data[i-1]) / toNumber(data[i+1])).toString();
        data.removeAt(i+1);
        data.removeAt(i-1);
        run = true;
      }
    }
  }
  return data;
}

List<String> doAdditions(List<String> data) {
  bool run = true;
  while(run) {
    run = false;
    for(int i=0; i<data.length; i++) {
      if(data[i] == "+") {
        data[i] = (toNumber(data[i-1]) + toNumber(data[i+1])).toString();
        data.removeAt(i+1);
        data.removeAt(i-1);
        run = true;
      }
    }
  }
  return data;
}

List<String> doSubtractions(List<String> data) {
  bool run = true;
  while(run) {
    run = false;
    for(int i=0; i<data.length; i++) {
      if(data[i] == "-") {
        data[i] = (toNumber(data[i-1]) - toNumber(data[i+1])).toString();
        data.removeAt(i+1);
        data.removeAt(i-1);
        run = true;
      }
    }
  }
  return data;
}

String getSum(String data) {
  data = data.replaceAll(" ", "");
  StringTools cursor = StringTools(data);
  List<String> elements = [];
  RegExp numberFormat = RegExp(r"^[0-9.]*$");
  bool addingNumbers = false;
  int i = -1;

  while(cursor.eol == false) {
    String char = cursor.getFromPosition();

    if(addingNumbers) {
      if(numberFormat.hasMatch(char)) {
        elements[i] = elements[i] + char;
      } else {
        elements.add(char);
        addingNumbers = false;
        i++;
      }
    } else {
      if(numberFormat.hasMatch(char)) {
        elements.add(char);
        addingNumbers = true;
        i++;
      } else {
        print("Error: Cannot use two operators: " + data);
      }
    }

    cursor.move();
  }

  // Operations order:
  // Please Excuse My Dear Aunt Sally
  // Parentheses Exponents Multiplications Divisions Additions Subtractions
  elements = doMultiplications(elements);
  elements = doDivisions(elements);
  elements = doAdditions(elements);
  elements = doSubtractions(elements);

  return elements[0];
}

String addAssumedMultiplication(String data) {
  RegExp startP = new RegExp(r"^[0-9]\(");
  RegExp endP = new RegExp(r"^\)[-0-9]", caseSensitive: false);

  StringTools cursor = StringTools(data);
  if(cursor.moveToRegex(startP, width: 2)) {
    cursor.move();
    cursor.insertAtPosition('*');
    //print(cursor.getFromPosition(characters: 2));
  }

  cursor.reset();

  if(cursor.moveToRegex(endP, width: 2)) {
    cursor.move();
    cursor.insertAtPosition('*');    
    //print(cursor.getFromPosition(characters: 2));
  }

  return cursor.data;
}

// Finds an inner-parentheses pair (if there are several nested) and summarizes
// its content. Replaces the parentheses block with the answer.
String collapseParentheses(String data) {
  data = addAssumedMultiplication(data);
  StringTools cursor = StringTools(data);
  bool run = true;
  List<String> patentheses = ['(', ')'];
  bool lookingForClosing = false;
  //print("cursordata=" + cursor.data);


  while(run) {
    String char = cursor.moveToListElement(patentheses);
    if(char == '(') {
      lookingForClosing = true;
      cursor.startSelection();
      cursor.move();
    } else if(char == ')') {
      if(lookingForClosing) {
        cursor.move();
        cursor.stopSelection();
        cursor.deleteEdgesOfSelection();
        cursor.replaceSelection(getSum(cursor.getSelection()));
        run = false;
      } else {
        print("Error: Starting parentheses missing:" + data);
        run = false;
      }
    } else {
      if(lookingForClosing) {
        print("Error: Missing matching ')' :" + data);
      }
      run = false;
    }
  }

  return cursor.data;
}

bool isNumber(String string) {
  if (string == null) {
    return false;
  }
 return double.tryParse(string) != null;
}

double toNumber(String string) {
  if (string == null) {
    return 0;
  }
  return double.tryParse(string) ?? 0;
}

String getVariables(String data) {
  return " a";
}

//  Collapses a parentheses block as long as there is one present. When there are
//  no more parenthese blocks in the string it summarizes its content with getSum.
String? evaluateAsNumber(String data) {
String number = "";

  data = data.replaceAll(' ', '');
  if(intStringFormat.hasMatch(data)) {
    StringTools cursor = StringTools(data);

    if(cursor.count('(') == cursor.count(')')) {
      while(cursor.data.contains('(')) {
        cursor.data = collapseParentheses(cursor.data);
      }
    } else {
      print("Error: Not the same number of '(' as ')'." + data);
    }

    number = getSum(cursor.data);

  } else {
    print("Error: Cannot convert to number, contains illegal characters: " + data);
  }

  return number;
}

double? getNumber(String key) {

}

/*
  "Sometext" + "Some other text"
*/

void evaluateAsText(String data) {

}

/*
  "12 < 1"
  "True"
  "False"
*/

void evaluateAsBool(String data) {

}

/*


*/

void initDouble(int _pid, String data) {
  StringTools cursor = StringTools(data.substring("Map ".length));

}

/*


*/

void initMap(int _pid, String data) {
  StringTools cursor = StringTools(data.substring("Map ".length));

}

/*
    Int myNumber = 12;
    Int myNumber=12;
*/

void initInt(int _pid, String data) {
  StringTools cursor = StringTools(data.substring("Int ".length));

  if(cursor.moveTo('=')) {

    String key = cursor.getAllBeforePosition().trim();
    if(keyFormat.hasMatch(key)) {
      String value = cursor.getAllAfterPosition().trim();

      value = replaceVariableNamesWithContent(_pid, value);
      String? number = evaluateAsNumber(value);
      if(number != null) {
        pman.processes[_pid].args.setInt(key, toNumber(number).toInt());
      } else {
        print("Error: Invalid parameter value, unable to parse to integer: " + value);
      }
    } else {
      print("Error: Invalid variable name in " + key + "\r\nPlease only use a-z, A-Z, 0-9, underscore or dash.");
    }
  } else {
    print("Error: Int declaration missing = in " + data);
  }
}

void updateInt(int _pid, String key, String data) {
  StringTools cursor = StringTools(data.substring("Int ".length));

  if(cursor.moveTo('=')) {

    if(keyFormat.hasMatch(key)) {
      String value = cursor.getAllAfterPosition().trim();

      value = replaceVariableNamesWithContent(_pid, value);
      String? number = evaluateAsNumber(value);
      if(number != null) {
        pman.processes[_pid].args.updateInt(key, toNumber(number).toInt());
      } else {
        print("Error: Invalid parameter value, unable to parse to integer: " + value);
      }
    } else {
      print("Error: Invalid variable name in " + key + "\r\nPlease only use a-z, A-Z, 0-9, underscore or dash.");
    }
  } else {
    print("Error: Int declaration missing = in " + data);
  }
}

void updateString(int _pid, String key, String data) {
  
}

void updateDouble(int _pid, String key, String data) {
  
}

void updateList(int _pid, String key, String data) {
  
}

void updateMap(int _pid, String key, String data) {
  
}

String replaceVariableNamesWithContent(int _pid, String data) {
  List<String> elements = [];
  bool run = true;
  StringTools cursor = StringTools(data);
  RegExp exp1 = new RegExp(r"^[a-z]*$", caseSensitive: false);
  RegExp exp2 = new RegExp(r"^[a-z0-9_]*$", caseSensitive: false);

  while(run) {
    if(cursor.moveToRegex(exp1)) {
      cursor.startSelection();
      cursor.moveWhileRegex(exp2);
      cursor.stopSelection();
      if(pman.processes[_pid].args.isNumberVar(cursor.getSelection())) {
        //print("Declared variable found: " + cursor.getSelection());
        cursor.replaceSelection(pman.processes[_pid].args.get(cursor.getSelection()).toString());
      } else {
        print("Error: Undeclared variable " + cursor.getSelection() + " used in calculation.");
      }
    } else {
      run = false;
    }
  }

  return cursor.data;
}


void initBool(int _pid, String data) {
  StringTools cursor = StringTools(data.substring("Bool ".length));
  if(cursor.moveTo('=')) {

    String key = cursor.getAllBeforePosition().trim();
    if(keyFormat.hasMatch(key)) {
      bool value = true;
      pman.processes[_pid].args.setBool(key, value);      
    } else {
      print("Error: Invalid variable name in " + key + "\r\nPlease only use a-z, A-Z, 0-9, underscore or dash.");
    }
  } else {
    print("Error: Bool declaration missing = in " + data);
  }
}

/*
    String myText = "This is some text";
    String myText="This is some text";
*/

void initString(int _pid, String data) {
  StringTools cursor = StringTools(data.substring("String ".length));

  if(cursor.moveTo('=')) {
    String key = cursor.getAllBeforePosition().trim();
    if(keyFormat.hasMatch(key)) {
      String value = cursor.getAllAfterPosition().trim();
      
      value = combineToOneString(_pid, value);
      pman.processes[_pid].args.setString(key, value);      
    } else {
      print("Error: Invalid variable name in " + key + "\r\nPlease only use a-z, A-Z, 0-9, underscore or dash.");
    }
  } else {
    print("Error: String declaration missing = in " + data);
  }
}

String combineToOneString(int _pid, String _data) {
    RegExp exp2 = new RegExp(r"^[a-z0-9_]*$", caseSensitive: false);
    RegExp exp3 = new RegExp(r"^[ +]");

    List<String> elements = _data.split('+');
    for(int i = 0; i < elements.length; i++) {
      StringTools cursor = StringTools(elements[i].trim());
      if(cursor.edgesIs('"')) {
        cursor.deleteEdges();
        elements[i] = cursor.data;
      } else {
        if(pman.processes[_pid].args.isVar(cursor.data)) {
          elements[i] = pman.processes[_pid].args.getAsString(cursor.data);
        } else {
          elements[i] = "";
          print("Error: Unknown variable " + cursor.data);
        }
      }
    }
    return elements.join();
}

/*


*/

void initList(int _pid, String data) {
  StringTools cursor = StringTools(data.substring("List ".length));

}


/* --------------- SHEETS ----------------- */

void initSheet(int _pid, String _data) {
  StringTools cursor = StringTools(_data);
  cursor.deleteCharacters("Sheet ".length);
  cursor.startSelection();
  cursor.moveWhileRegex(variableChars);
  cursor.stopSelection();
  String key = cursor.getSelection();
  cursor.deleteSelection();
  cursor.reset();
  cursor.data = cursor.data.split('=')[1].trim();
  
  if(cursor.data == '[]') {
    pman.processes[_pid].args.setSheet(key, Sheet());
    //pman.processes[_pid].args.debug();
  } else {
    Sheet sheet = Sheet();

    if(cursor.firstIs('[') == false) {
      print("Error: Sheet not instantiated correctly, please see documentation. " + cursor.data);
      return;
    } else if(cursor.lastIs(']') == false) {
      print("Error: Sheet not instantiated correctly, please see documentation. " + cursor.data);
      return;
    }

    // Bool: "active", String: "name"

    cursor.deleteEdges();
    cursor.data.trim();
    List<String> columns = [];
    bool run = true;

    while(run) {
      cursor.startSelection();
      if(cursor.moveTo(':')) {
        cursor.stopSelection();
        String columnType = cursor.getSelection().trim();
        if(isSupportedSheetColumnType(columnType)) {
          cursor.moveTo('"');
          cursor.stopSelection();
          cursor.deleteSelection();
          cursor.reset();
          cursor.startSelection();
          if(cursor.moveToNext('"')) {
            cursor.move();
            cursor.stopSelection();
            cursor.deleteEdgesOfSelection();
            String columnName = cursor.getSelection();
            //print("columnName=" + columnName);
            cursor.deleteSelection();
            cursor.reset();
            if(cursor.moveTo(',')) {
              cursor.data = cursor.getAllAfterPosition();
              cursor.reset();
              sheet.addColumn(columnType, columnName);
            }
          } else {
            print("Error: Sheet column name missing enclosing quotes. " + cursor.data);
          }
        } else {
          print("Error: Unsupported column type " + columnType);
          run = false;
        }
      } else {
        //print("Exiting");
        //print("Sheet data: " + cursor.data);
        run = false;
      }
    }
    pman.processes[_pid].args.setSheet(key, sheet);
    //pman.processes[_pid].args.debug();
  }
}