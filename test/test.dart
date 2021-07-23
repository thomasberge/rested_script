import 'rested_script.dart';

main() async {
  print("Testing RestedScript:");

  RestedScript restedscript = new RestedScript();
  restedscript.rootDirectory = "/app/bin/pages/";

  RestedScriptArguments args = new RestedScriptArguments();
  String result = await restedscript.parse("index.html", args);
  //print(result);
}
