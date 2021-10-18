import 'package:string_tools/string_tools.dart';

// v1 of Sheet. Only supports RestedScript type "String" for now.

class Sheet {
    List<List<String>> sheet = [];
    List<List<bool>> nullmap = [];

    List<String> headers = [];
    List<String> types = [];    // not in use in first version

    int lines = 0;

    Sheet();

    void addColumn(String _type, String _header) {

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

    int addRow(List<String> _row){
        for(int i = 0; i<_row.length; i++) {
            if(_row[i] == "%NULL%") {
                sheet[i].add("");
                nullmap[i].add(false);
            } else {
                sheet[i].add(_row[i]);
                nullmap[i].add(true);
            }
        }

        lines++;
        return lines;
    }

    List<String> getColumnByIndex(int _column) {
        return sheet[_column];
    }

    List<String> getColumnByName(String _name) {
        print("COLUMNS:" + headers.toString());
        print("index of " + _name + ": " + headers.indexOf(_name).toString());
        return sheet[headers.indexOf(_name)];
    }

    List<String> getRowByIndex(int _row) {
        List<String> row = [];
        for(int i = 0; i < sheet.length; i++) {
            row.add(sheet[i][_row]);
        }
        return row;
    }

    String getCellByIndex(int _column, int _row) {
        //print(sheet.toString());
        //print("getCellByIndex(" + _column.toString() + ", " + _row.toString() + ");");
        return sheet[_column][_row];
    }

    String toString(){
        return sheet.toString();
    }
}