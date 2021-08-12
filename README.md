# RestedScript v0.2.0

## Currently being organized, restructured and changed. Nothing to see here yet, move along.

##### v0.2.0 to-do
- [ ] Test of include in test file + documentation in README.md
- [ ] Test of print in test file + documentation in README.md
- [ ] Update readme to better standards

Testing
There is a test script included in /test that runs all functions in different variations and tests against the result. A report is written to console where each function is graded with a OK or Failed. If changes are made to rested_script then new functions should be added and all functions tested again to make sure they pass.

The accompanying Dockerfile in this repo root can be run in order to run the test.

```bash
$ docker build -t rested_script_test . && docker run -it rested_script_test
```
