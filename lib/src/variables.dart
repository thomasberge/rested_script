import 'processes.dart';
import 'package:string_tools/string_tools.dart';

List<String> supportedVariableTypes = ["Map", "String", "Int", "List", "Bool"];

RegExp keyFormat = RegExp(r"^[a-zA-Z0-9_-]*$");

String isVariableDeclaration(String data) {
  int i = 0;
  String supported = "%NOTSUPPORTED%";
  while(i < supportedVariableTypes.length) {
    if (data.substring(0, supportedVariableTypes[i].length + 1) == supportedVariableTypes[i] + " ")
    {
      supported = supportedVariableTypes[i];
      //print(supportedVariableTypes[i] + " is a supported variable type!");
      i = 1000;
    }
    i++;
  }

  if(supported == "%NOTSUPPORTED%") {
    //print(data + " is NOT a supported variable type!");
  }

  return supported;
} 

/*
  Examples:
  "14 + 12 + (4 * 3)"
  "(13)"
  "11/3"
*/

int? evaluateAsNumber(String data) {
  return int.tryParse(data) ?? null;
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

void initMap(int pid, String data) {
  StringTools cursor = StringTools(data.substring("Map ".length));

}

/*
    Int myNumber = 12;
    Int myNumber=12;
*/

void initInt(int pid, String data) {
  StringTools cursor = StringTools(data.substring("Int ".length));

  if(cursor.moveTo('=')) {

    String key = cursor.getAllBeforePosition().trim();
    if(keyFormat.hasMatch(key)) {
      String value = cursor.getAllAfterPosition().trim();
      int? number = evaluateAsNumber(value);
      if(number != null) {
        pman.processes[pid].args.setInt(key, number);
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

/*


*/

void initBool(int pid, String data) {
  StringTools cursor = StringTools(data.substring("Bool ".length));
  if(cursor.moveTo('=')) {

    String key = cursor.getAllBeforePosition().trim();
    if(keyFormat.hasMatch(key)) {
      bool value = true;
      pman.processes[pid].args.setBool(key, value);      
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

void initString(int pid, String data) {
  StringTools cursor = StringTools(data.substring("String ".length));

  if(cursor.moveTo('=')) {
    String key = cursor.getAllBeforePosition().trim();
    if(keyFormat.hasMatch(key)) {
      String value = "testValue";
      pman.processes[pid].args.setString(key, value);      
    } else {
      print("Error: Invalid variable name in " + key + "\r\nPlease only use a-z, A-Z, 0-9, underscore or dash.");
    }
  } else {
    print("Error: String declaration missing = in " + data);
  }
}

/*


*/

void initList(int pid, String data) {
  StringTools cursor = StringTools(data.substring("List ".length));

}