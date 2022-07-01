library restedscript.processes;

import 'arguments.dart';

ProcessManager pman = ProcessManager();

class ProcessManager {
    List<Process> processes = [];
    int pidCounter = 0;

    int createProcess(Arguments args) {
        int _pid = pidCounter++;
        processes.insert(_pid, Process(args));
        return _pid;
    }

    Process? getProcess(int pid) {
        return processes[pid];
    }

    Arguments? getArguments(int pid) {
        return getProcess(pid)?.args;
    }
}

class Process {
    String flag = "";
    bool debugEnabled = false;
    Arguments args = Arguments();
    DateTime createdAt = DateTime.now();
    List<String> strings = [];

    Map<String, dynamic> _variables = {};
    //List<Map<String, dynamic>> _private_variables = [];
    Map<String, dynamic> _private_variables = {};

    Process(this.args) {
        createdAt = DateTime.now();
    }

    int setString(String string){
        strings.add(string);
        return strings.length - 1;
    }

    String getString(int index){
        return strings[index].substring(1, strings[index].length - 1);
    }

    void set(String key, dynamic variable) {
        _variables[key] = variable;
    }

    void set_private(String key, dynamic variable) {
        _private_variables[key] = variable;
    }

    void reset_private_variables(int nesting_id) {
        // remember to make a way to create private variables depending on their nesting context
        // so that only variables created in that context are deleted.
    }

    dynamic get(String key) {
        if(_private_variables.containsKey(key)) {
            //print("found private variable " + key);
            return _private_variables[key];
        } else if(args.vars.containsKey(key)) {
            //print("found argvar " + key);
            return args.get(key);
        } else if(_variables.containsKey(key)) {
            //print("found procvar " + key);
            return _variables[key];
        } else {
            //print("didn't find var " + key);
            return null;
        }
    }

    bool evaluate(String conditional) {
        bool not = false;
        String key = "";
        List<String> elements = conditional.split(' ');
      
        if(elements[0].toLowerCase() == 'not' || elements[0].toLowerCase() == '!') {
            not = true;
            key = elements[1]; 
        } else if (elements[0].substring(0,1) == '!') {
            not = true;
            key = elements[0].substring(1);
        } else {
            key = elements[0];
        }

        if(args.vars.containsKey(key)) {
            if(args.vars[key] == null) {                // if it has key but null value
                if(not) {
                    return true;
                } else {
                    return false;
                }
            }
            else if(args.vars[key] is bool) {           // if its bool
                if(not) {
                    return !args.vars[key];
                } else {
                    return args.vars[key];
                }
                } else {                                // if its any other type
                if(not) {
                    return false;
                } else {
                    return true;
                }
            }
        } else {                                        // if it doesn't exist
            if(not) {
                return true;
            } else {
                return false;
            }
        }
    }
}