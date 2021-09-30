import 'package:string_tools/string_tools.dart';

// v1 of Sheet. Only supports RestedScript type "String" for now.

class Sheet {
    List<List<String>> sheet = [];
    List<List<bool>> nullmap = [];

    List<String> headers = [];
    List<String> types = [];    // not in use in first version

    int lines = 0;

    void addColumn(String _type, {String header = "%NOTSET%"}) {
        if(header == "%NOTSET%") {
            header = "column" + sheet.length.toString();
        }
        headers.add(header);

        switch(_type) {
            case "String": {
                List<String> _newColumn = [];
                List<bool> _nullColumn = [];

                for(int i = 0; i < lines; i++) {
                    _newColumn.add("");
                    _nullColumn.add(false);
                }

                types.add("String");
                sheet.add(_newColumn);
                nullmap.add(_nullColumn);
            }
            break;

            case "Int": {

            }
            break;

            case "Double": {

            }
            break;

            case "Bool": {

            }
            break;
        }
    }

    int addLine(List<String> _line){
        for(int i = 0; i<_line.length; i++) {
            if(_line[i] == "%NULL%") {
                sheet[i].add("");
                nullmap[i].add(false);
            }
        }

        lines++;
        return lines;
    }
}