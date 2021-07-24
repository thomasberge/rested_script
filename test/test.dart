import 'rested_script.dart';

main() async {
  print("Testing RestedScript:");

  RestedScript restedscript = new RestedScript();
  restedscript.rootDirectory = "/app/bin/pages/";

  String result = await restedscript.parse("index.html");
  //print(result);
}
