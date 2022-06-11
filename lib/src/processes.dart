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

    dynamic get(String key) {
        if(args.isVar(key)) {
            print("found argvar " + key);
            return args.get(key);
        } else if(_variables.containsKey(key)) {
            print("found procvar " + key);
            return _variables[key];
        } else {
            print("didn't find var " + key);
            return null;
        }
    }

    bool evaluate(String conditional) {
        bool not = false;
        List<String> elements = conditional.split(' ');
        
        if(elements[0].toLowerCase() == 'not' || elements[0].toLowerCase() == '!') {
            not = true;
        } else if (elements[0].substring(0,1) == '!') {
            not = true;
            elements[0] = elements[0].substring(1, elements[0].length);
        }

        if(args.isVar(elements[0])) {
            if(args.type(elements[0]) == "Bool") {
            if(not) {
                return !args.vars[elements[0]];
            } else {
                return args.vars[elements[0]];
            }
            } else {
            if(not) {
                return true;
            } else {
                return false;
            }
            }
        } else {
            if(not) {
                return true;
            } else {
                return false;
            }
        }
    }
}