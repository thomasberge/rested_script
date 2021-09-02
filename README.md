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

RestedScript is a process that starts execution based on an input file. As soon as it starts reading the file a Document Object is created containing the content of the initial document. More data can be added through processing or read as input from local or external data. Any data stored as arguments either at start of execution (passed as an Arguments object) or saved as variables throughout execution lives until there is no more data to read or execute. The resulting string will be returned from the starting function and the Document Object will suffer the wrath of the Dart garbage collector.


### RestedScript Language

#### include(string filepath);
This processes the file and includes the result. Keep in mind that the filepath is relative to the root directory of RestedScript, not the relative to the initial file referenced in the createDocument() argument. In other words, if createDocument('admin/index.html'); contains a include("styles.css"); file then it will not look for the file in 'admin/styles.css' but rather 'styles.css'.

```
include("index.html");
```

#### download(string url);
Downloads and includes the text in the URL. If the file contains RestedScript it will be processed just like a standard include() function.

```
download("https://raw.githubusercontent.com/thomasberge/rested_script/dev/test/pages/include.html");
```

#### print(string text); / echo(string text);
The passed string argument to print() will be written in the document. Also supports echo() for the exact same result. If the passed value is not in quotes then it is assumed to be a variable. If the variable is not a string then it will be 

```
print("This line will be written in the document.");
print(myVariable);
echo("This line will also be written in the document.");
```

#### flag(string filename);
If the flag site is called at any point in the code then the page referred to will be displayed no matter what the code contains. The code will however continue to execute, but it will not render to the user. The argument needs to point to a specific file in <root>/flagsites/.

```
download("404.html");
```

  
### The Arguments Object
An important link between your server code and RestedScript is the Arguments object. It hosts a set of variable structures you can populate and then send as one single object to the RestedScript engine. Any variables declared there are available throughout the execution process. They can be read or written to and new variables can be added directly from RestedScript.
  
In your Dart server code an Arguments object are instantiated empty through the Arguments class. They are then passed as an optional value in the createDocument function. If no Arguments object is passed then createDocument actually instatiates one for you so that RestedScript has a place to store variables created in script.
  
With an empty Arguments object you have the ability either set or get a variable. Keep in mind that although the Arguments object accept dynamic variable type, that does not mean that all Dart variable types are implemented in RestedScript.

  
#### set(string key, dynamic value);
Declares a variable with the ```key``` and ```value``` in the arguments object. Equivalent to for example ```string someKey = "Some Value";``` in RestedScript.

#### get(string key);
Returns the value of the given key. Used internally by the RestedScript engine, but also made available for your server code.
  
  
### RestedScript Document Manipulation

  
#### {{content("id")}}
Some verbs require a target location within the document. These will look for content tags. You can have many content tags within a document as long as their id is unique. Content tags are always referenced by their id and must be unique. Not just within the document itself but within the entire Document Object. 

  
#### {{wrap("/some/file.txt", "someId")}}
Will open the file.txt, find the contentId someId tag within the document. The current Document Object will be wrapped with whatever is before and after the contentId.


#### {{foreach("listname")}}
#### {{element("listname"}}
#### {{endforeach("listname")}}
Will look for a List with key "listname" in the Arguments object. If found it will replace {{element}} with each item in that list. If for example you are populating a list of users your document can contain markup around a tag {{element("usernames"}}. By iterating over list "usernames" that element would be replaced with the actual usernames from the list.
  
### Testing
There is a test script included in /test that runs all functions in different variations and tests against the result. A report is written to console where each function is graded with a OK or Failed. If changes are made to rested_script then new functions should be added and all functions tested again to make sure they pass.

The accompanying Dockerfile in this repo root can be run in order to run the test.

```bash
docker build -t rested_script_test . && docker run -it rested_script_test
```
