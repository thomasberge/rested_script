import 'rested_script.dart';

Map<String, String> errors = {};
List<Function> functions = [
  test_debug,
  test_wrap_and_content,
  test_include,
  test_download,
  test_print,
  test_flag,
  test_printVariable,
  test_varDeclarations,
  test_comments,
  test_sheet,
  test_if,
  test_template_variables,
  test_template_forin,
  test_template_include,
  test_template_comments,
  test_simpleif,
  test_mapvariable
  //test_template_block
];

main() async {
  print("\r\n  ------------------------------------------------------------------");
  print("  :: Running Test Script                                          ::");
  print("  ------------------------------------------------------------------");  
  int cleared = 0;
  int failed = 0;

  for(Function f in functions) {
    if(await f()) {
      failed++;
      String error_message = "Unknown error";
      if(errors.containsKey(getFunctionName(f))) {
        error_message = errors[getFunctionName(f)].toString();
      }
      print("  \u001b[31m" + getFunctionName(f) + " failed. Reason: " + error_message + "\u001b[0m");
    } else {
      cleared++;
    }
  }

  if(failed == 0) {
    print("  :: [" + cleared.toString() + "/" + cleared.toString() + "] tests completed without fail.                        ::");
  } else {
  print("\r\n  ------------------------------------------------------------------");  
    print("  ::  [\u001b[31m" + cleared.toString() + "\u001b[0m/" + (cleared + failed).toString() + "] tests completed without fail. Review errors above.  ::");
  }
  print("  ------------------------------------------------------------------\r\n");
}


/*  UTILITY FUNCTIONS   
*/

void printErrorMessages(String key) {
  for(MapEntry e in errors.entries) {
    if(e.key == key) {
      print(errors[key]);
    }
  }
}

String getFunctionName(Function f) {
  return ""+f.toString().split("from Function 'test_", )[1].split("': ")[0] + "()".toString();  // yes this is bad
}

Future<bool> test_include() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("index.html");
  if(result == "1234567890") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_download() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("downloadfile.txt");
  if(result == "1234567890") {
    bugs = false;
  } else {
    print('expected "1234567890", got "' + result + '"');
  }
  return bugs;
}

Future<bool> test_print() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("print.html");
  if(result == "this is a test!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_flag() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("flagsite.html");
  if(result == "404 NOT FOUND") {
    String result = await restedscript.createDocument("flagsite_include.html");
    if(result == "404 NOT FOUND") {
      bugs = false;
    }
  }
  return bugs;
}

Future<bool> test_var() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("variables.html");
  //print(result);
  if(result == "this is a test!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_wrap_and_content() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("wrapping.html");
  if(result == "ABCDEFGHI") {
    bugs = false;
  } else {
    print(result);
  }
  return bugs;
}

Future<bool> test_printVariable() async {
  bool bugs = true;
  Arguments args = Arguments();
  args.set("test", "rocketship");
  args.set("condition", true);
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("arguments-stringmap.html", args: args);
  if(result == "This is a rocketship!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_foreach() async {
  bool bugs = true;
  Arguments args = Arguments();
  List<String> numbers = [];
  numbers.add("4");
  numbers.add("5");
  numbers.add("6");
  args.set("numbers", numbers);
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("foreach.html", args: args);
  if(result == "123456789") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_debug() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("debug.html");
  if(result == "") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_map() async {
  bool bugs = true;
  Arguments args = Arguments();
  Map<String, dynamic> testmap = { "name": "Terminator", "version": 2000 };
  args.set("movies", testmap);
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("maps.html", args: args);
  if(result == "This is a rocketship!") {
    bugs = false;
  }
  print(args.vars.toString());
  return bugs;
}

Future<bool> test_varDeclarations() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("varDeclarations.html");
  if(result == "The movie Knives Out has a runtime of 135 minutes") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_comments() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("comments.html");
  if(result == "sneakysolidsnake") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_sheet() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("sheet.html");
  if(result == "nope") {
    bugs = false;
  } else {
    print(result);
  }
  return bugs;
}

Future<bool> test_sheetForEach() async {
  bool bugs = true;

  Arguments args = Arguments();

  Sheet sheet = Sheet();
  sheet.addColumn("String", "Letters");
  sheet.addRow(["A"]);
  sheet.addRow(["B"]);
  sheet.addRow(["C"]);
  sheet.addRow(["D"]);

  sheet.addColumn("String", "Numbers");
  sheet.addRow(["E", "1"]);
  sheet.addRow(["F", "2", "overflow deløx"]);

  args.setSheet("collection", sheet);

  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("foreachsheet.html", args: args);

  if(result == "ABCDE1F2") {
    bugs = false;
  } else {
    print(result);
  }
  
  return bugs;
}

Future<bool> test_if() async {
  bool bugs = true;
  Arguments args = Arguments();

  args.set("zero", false);
  args.set("one", true);
  args.set("two", false);
  args.set("five", true);
  
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("ifsentence.html", args: args);
  if(result == "block0block5") {

    args.set("zero", true);
    args.set("one", false);
    args.set("two", true);
    args.set("five", false);
    
    restedscript = RestedScript(root: "/app/bin/pages/");
    result = await restedscript.createDocument("ifsentence.html", args: args);
    if(result=="") {

      args.set("variable", true);
      
      restedscript = RestedScript(root: "/app/bin/pages/");
      result = await restedscript.createDocument("ifsentence2.html", args: args);
      if(result == "visible") {
        bugs = false;
      }
    }
  } else {
    print(result);
  }
  return bugs;
}

Future<bool> test_simpleif() async {
  bool bugs = true;
  Arguments args = Arguments();

  args.set("somebool", true);
  
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.stringToDoc("{% if somebool %}test{% else %}test2{% endif %}", args: args);
  if(result == "test") {
    args.set("somebool", false);
    result = await restedscript.stringToDoc("{% if somebool %}test{% else %}test2{% endif %}", args: args);
    if(result == "test2") {
      args.set("stringparam", "I am a string!");
      result = await restedscript.stringToDoc("{% if stringparam %}test3{% endif %}", args: args);
      if(result == "test3") {
        bugs = false;
      }
    } else {
      print(">"+result.toString()+"<");
    }
  } else {
    //errors['simpleif()'] = "Unexpected value (" + result + ")";
    print(">"+result.toString()+"<");
  }
  return bugs;
}

Future<bool> test_template_variables() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  Arguments args = Arguments();
  args.set("argvar", true);
  String result = await restedscript.createDocument("template_variables.html", args: args);
  if(result == "true") {
    bugs = false;
  } else {
    print(result);
  }
  return bugs;
}

Future<bool> test_template_forin() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  Arguments args = Arguments();
  List<String> users = ["admin", "user1", "user2"];
  args.setList("users", users);
  String result = await restedscript.createDocument("forin.html", args: args);
  if(result == "admin;user1;user2;") {
    bugs = false;
  } else {
    errors['template_forin()'] = "Unexpected value (" + result + ")";
  }
  return bugs;
}

Future<bool> test_template_include() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("index2.html");
  if(result == "1234567890") {
    bugs = false;
  } else {
    errors['template_include()'] = "Unexpected value (" + result + ")";
  }
  return bugs;
}

Future<bool> test_template_comments() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("template_comments.html");
  if(result == "I am visible!") {
    bugs = false;
  } else {
    errors['template_comments()'] = "Unexpected value (" + result + ")";
  }
  return bugs;
}

Future<bool> test_mapvariable() async {
  bool bugs = true;
  Arguments args = Arguments();

  Map<String, String> somemap = { "username": "ninjaman", "occupation": "ninja", "dangerlevel": "over 9000" };

  args.set("user", somemap);
  
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.stringToDoc("{{ user.username }}", args: args);
  if(result == "ninjaman") {
    bugs = false;
  } else {
    print(">"+result.toString()+"<");
  }
  return bugs;
}

Future<bool> test_template_block() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("block.html");
  if(result == "ninjaman") {
    bugs = false;
  } else {
    print(result.toString());
  }
  return bugs;
}