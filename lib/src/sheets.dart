import 'package:string_tools/string_tools.dart';

// v1 of Sheet. Only supports RestedScript type "String" for now.

class Sheet {
    List<List<String>> sheet = [];
    List<List<bool>> nullmap = [];

    List<String> headers = [];
    List<String> types = [];    // not in use in first version

    int lines = 0;

    Sheet();

    void addColumn(String _header, String _type) {

        // Add check if header exists, as it must be unique!

        headers.add(_header);

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

    int addRowList(String _row){
        for(int i = 0; i<_row.length; i++) {
            if(_row[i] == "%NULL%") {
                sheet[i].add("");
                nullmap[i].add(false);
            }
        }

        lines++;
        return lines;
    }

    List<String> getRowByIndex(int _index) {
        List<String> row = [];
        for(int i = 0; i < sheet.length; i++) {
            row.add(sheet[i][_index]);
        }
        return row;
    }
}