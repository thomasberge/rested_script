# RestedScript v0.4.0

### Currently being organized, restructured and changed. Nothing to see here yet, move along.

### How it works

The RestedScript engine is quite simple; you pass it a filepath and you receive a string. The string represents the text content of the file in the filepath, except the RestedScript in the file has been processed.

It is simple to set up. You instantiate a RestedScript object and set its root directory. You can then - relative to its root directory, pass it file paths to text file containing RestedScript.

```dart
RestedScript rscript = RestedScript(root: "/app/bin/resources/");
```

RestedScript comes in two flavors; a nested language for logical operations and a series of specific document manipulation verbs. The language needs to be expressed within the ```<?rs``` start and ```?>``` end tags within the document. Start and end tags can appear many times within a document, but each start must always be closed with an end tag. Whitespace within the tags are ignored.

Document manipulation verbs live outside of the language tags and are themselves tagged within double curly brakcets ```{{as such}}```. The document type does not matter as long as it is (or can be read as) UTF-8.


### Execution, Memory and the Document Object

RestedScript is a process that starts execution based on an input file. As soon as it starts reading the file a Document Object is created containing the content of the initial document. More data can be added through processing or read as input from local or external data. Any data stored as arguments either at start of execution (passed as an Argument Object) or saved as variables throughout execution lives until there is no more data to read or execute. The resulting string will be returned from the starting function and the Document Object will suffer the wrath of the Dart garbage collector.


### RestedScript Language Functions

#### include(string);
This immediately parse and process the included file and include the result.

```
include("index.html");
```

#### download(string);
Downloads and includes the text in the URL. If the file contains RestedScript it will be processed just like a standard include() function.

```
download("https://raw.githubusercontent.com/thomasberge/rested_script/dev/test/pages/include.html");
```

#### print(string); / echo(string);
The passed string argument to print() will be written in the document. Also supports echo() for the exact same result.

```
print("This line will be written in the document.");
echo("This line will also be written in the document.");
```

#### flag(string);
If the flag site is called at any point in the code then the page referred to will be displayed no matter what the code contains. The code will however continue to execute, but it will not render to the user. The argument needs to point to a specific file in <root>/flagsites/.

```
download("404.html");
```

  
### RestedScript Document Manipulation Verbs

  
#### {{content("id")}}
Some verbs require a target location within the document. These will look for content tags. You can have many content tags within a document as long as their id is unique. Content tags are always referenced by their id and must be unique. Not just within the document itself but within the entire Document Object. 

  
#### {{wrap("/some/file.txt", "someId")}}
Will open the file.txt, find the contentId someId tag within the document. The current Document Object will be wrapped with whatever is before and after the contentId.

  
### Testing
There is a test script included in /test that runs all functions in different variations and tests against the result. A report is written to console where each function is graded with a OK or Failed. If changes are made to rested_script then new functions should be added and all functions tested again to make sure they pass.

The accompanying Dockerfile in this repo root can be run in order to run the test.

```bash
docker build -t rested_script_test . && docker run -it rested_script_test
```
