# RestedScript v0.2.0

## Currently being organized, restructured and changed. Nothing to see here yet, move along.

##### v0.2.0 to-do
- [ ] Test of include in test file + documentation in README.md
- [ ] Test of print in test file + documentation in README.md
- [ ] Update readme to better standards

##### How it works
RestedScript is pretty simple to set up. You instantiate a RestedScript object and set its root directory.

```dart
RestedScript rscript = RestedScript(root: "/app/bin/resources/");
```

You can then - relative to its root directory, pass it file paths to text file containing RestedScript. RestedScript will then parse the file and process any RestedScript. Rested script start with <?rs and end with ?>, just like php. It also doesn't care about the syntax outside of the start/end tags, so it can be used in any text file. You can have start/end time appear many times within the same document. It can also be multiline, as whitespace does not matter.

### Language

#### include("");

```include("index.html");```

This immediately parse and process the included file and include the result.

#### print("");

```print("This line will be written in the document.");```

The passed string argument to print() will be written in the document.

##### #Testing
There is a test script included in /test that runs all functions in different variations and tests against the result. A report is written to console where each function is graded with a OK or Failed. If changes are made to rested_script then new functions should be added and all functions tested again to make sure they pass.

The accompanying Dockerfile in this repo root can be run in order to run the test.

```bash
$ docker build -t rested_script_test . && docker run -it rested_script_test
```
