import 'package:string_tools/string_tools.dart';
import 'sheets.dart';

class Arguments {
  Map<String, String> _varTypes = {};
  Map vars = new Map<String, dynamic>();

  void set(String key, dynamic value) {
    if(vars.containsKey(key)) {
      if(vars[key].runtimeType != value.runtimeType) {
        print("Error setting value to existing variable " + key + ": the variable is already of type " + vars[key].type.toString() + " while the incoming value is of type " + value.type.toString());
        return;
      }
    }
    vars[key] = value;
  }

  dynamic get(String key) {
    if (vars.containsKey(key)) {
      return vars[key];
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  String toString() {
    return vars.toString();
  }

  // ----------------- OLD $#"! THAT NEEDS TO GO

  List<String> getIntKeys() {
    List<String> keys = [];
    for(String k in _varTypes.keys) {
      if(k == "Int") {
        if(_varTypes[k] != null) {
          print("Int variable: " +  _varTypes[k].toString());
        }
      }
    }
    return keys;
  }

  void setSheet(String _key, Sheet _value) {
    if(isVar(_key) == false) {
      _varTypes[_key] = "Sheet";
      vars[_key] = _value;
    } else {
      print("Error: Variable " + _key + " already declared.");
    }
  }

  void setList(String key, List<dynamic> value) {
    if(isVar(key) == false) {
      _varTypes[key] = "List";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void setMap(String key, Map<String, dynamic> value) {
    if(isVar(key) == false) {
      _varTypes[key] = "Map";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  String type(String key) {
    //print(vars[key].type.toString());
    return vars[key].type.toString();
  }

  bool isVar(String key) {
    return _varTypes.containsKey(key);
  }

  bool isNumber(String key) {
    if(_varTypes.containsKey(key)) {
      if(_varTypes[key] == "Int" || _varTypes[key] == "Double") {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  void debug() {
    print(vars.toString());
  }

  // ------ UNDOCUMENTED OLD STUFF DOWN BELOW THIS LINE ------------- //
  String directoryPath = "";
  List<dynamic> list = [];
  Map<dynamic, dynamic> map = new Map();

  Map args = new Map<String, dynamic>();
  Map setmap = new Map<String, String>();
  Map stringmap = new Map<String, String>();
  Map boolmap = new Map<String, bool>();

  void setDirectoryPath(String path) {
    StringTools cursor = new StringTools(path);
    bool run = cursor.data.contains("/");
    while (run) {
      run = cursor.moveTo("/");
    }
    cursor.deleteAllFromPosition();
    //print("path=" + path);
    //print("directoryPath=" + cursor.data);
  }
}
