import 'package:string_tools/string_tools.dart';

import 'io.dart' as io;
import 'arguments.dart';

List<String> supportedFunctions = ["include", "print", "echo", "flag", "debug", "download"];

String isSupportedFunction(String data) {
  int i = 0;
  String supported = "%NOTSUPPORTED%";
  while(i < supportedFunctions.length) {
    if (data.substring(0, supportedFunctions[i].length + 1) == supportedFunctions[i] + "(")
    {
      supported = supportedFunctions[i];
      i = 1000;
    }
    i++;
  }

  if(supported == "%NOTSUPPORTED%") {
    //print(data + " is NOT a supported function!");
  }

  return supported;
}

Future<String> download(String argument, Arguments args) async {
  return(await io.downloadTextFile(argument));
}

String flag(String argument, Arguments args) {
  argument = argument.replaceAll('"', '');
  String filetype = argument.split('.')[1];

  if (filetype == 'html') {
    return argument;
  } else {
    print("Error: Unsupported flag filetype for " + argument);
    return "unsupported";
  }
}

Future<String> include(String argument, Arguments args) async {
  argument = argument.replaceAll('"', '');
  List<String> split = argument.split('.');
  if (split.length > 1) {
    String filetype = argument.split('.')[argument.split('.').length-1];

    if (filetype == 'html' || filetype == 'css' || filetype == 'txt') {
      return (argument);
    } else {
      print("RestedScript: Unsupported include filetype for " +
          argument.toString());
      return "";
    }
  } else {
    print("RestedScript: Attempted to include file with no filetype: " +
        argument.toString());
    return "";
  }
}

String echo(String argument, Arguments args) {
  StringTools fparser = new StringTools(argument);
  String output = "";
  bool run = true;
  while (run) {
    if (fparser.data.substring(0,1) == '"') {
      fparser.move();
      fparser.startSelection();
      if (fparser.moveTo('"')) {
        fparser.stopSelection();
        output = output + fparser.getSelection();
        run = false;
      } else {
        print("Error: print missing quote(s) inside parentheses.\r\n print(" +
            fparser.data +
            ");");
        run = false;
      }
    } else {
      if(args.get(argument).toString() != "%KEYDOESNOTEXIST%") {
        output = args.get(argument).toString();
        run = false;
      } else {
        print("Error: print missing quote(s) inside parentheses.\r\n print(" +
            fparser.data +
            ");");
        run = false;
      }
    }
  }
  return (output);
}

void debug(String argument, Arguments args) {
  StringTools cursor = new StringTools(argument);  
  String output = cursor.getQuotedString();
  print("\u001b[31m" + output + "\u001b[0m");
}

void variable(String argument, Arguments args) {
  print("var argument=" + argument);
}

String map(String argument, Arguments args) {
  print("map function called");
  return "";
}