import 'arguments.dart';

class ProcessManager {
    Map<int, Process> processes = {};
    int pid = 0;

    int createProcess(Arguments args) {
        int _pid = pid++;
        processes[_pid] = Process(args);
        return _pid;
    }
}

class Process {
    Arguments args = Arguments();
    DateTime createdAt = DateTime.now();

    Process(this.args) {
        createdAt = DateTime.now();
    }
}