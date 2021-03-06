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
}