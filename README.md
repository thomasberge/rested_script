# RestedScript v0.6.0

### Currently being organized, restructured and changed. Nothing to see here yet, move along.

### How it works

The RestedScript engine is quite simple; you pass it a filepath and you receive a string. It is simple to set up. You instantiate a RestedScript object and set its root directory. 

```dart
RestedScript rscript = RestedScript(root: "/app/bin/resources/");
```

You can then - relative to its root directory, pass it file paths to text files containing RestedScript. The string you get in the result are the file with its processed content.

```dart
String index_page = await rscript.createDocument("index.html");
```

Alternatively you can leave a blank filepath reference and instead pass the data as a string.

```dart
String index_page = await rscript.createDocument("", data: 'Some data <?rs include("other_data.txt"); ?>');
```

### By Example

##### Start/End tag, comments, functioncall

```
I will be disregarded <?rs 
    // I am only a comment and will also be disregarded.
    print("I will be processed!");
?> but not I since I am outside of tags.
```

##### Debug

```
<?rs
    debug("I will be printed to stdout");
?>
```

##### Instantiate variables

```
<?rs 
    String myString = "This is a string.";
    Int myWholeNumber = 800;
    Double myNumberWithDecimals = 800.85;
    Bool theTruth = false;
    List someList = [myString, myWholeNumber, myNumberWithDecimals, theTruth];
    Map mapToNowhere = { "key1": "value", "key2": { "key3": 3, "key4": false }}
?>
```

##### Sheet object (WIP)
Currently only supports a handfull of features and only String type.

```
<?rs 
    Sheet names = [];
    sheet.addColumn(names, String: "Firstname");
    sheet.addColumn(names, String: "Lastname");
    sheet.addRow(names, "Tom", "Bola");
    sheet.printRow(apis, 0);    // "Tom Bola"

    Sheet someSheet = [String: "column1", String: "column2"];
    sheet.addRow(someSheet, "value1", "value2");
    sheet.printCell(apis, 0, 0);    // "value2"
?>
```

##### Calculations and manipulations
```
<?rs 
    Int number = 10;
    Int anotherNumber = 5.1 * number + (15 * -1(5));
    anotherNumber = anotherNumber / 2;
    String word = "cool";
    String text = "This is " + word + "!";
?>
```

##### Print/Echo in file
```
<?rs
    print("Print this sentence in the document");
    String andThis = "And print this sentence as well.");
    echo(andThis);
?>
```

##### Download text
```
<?rs
    String readme = download("https://raw.githubusercontent.com/thomasberge/rested_script/main/README.md");
    echo(readme);
    download("https://raw.githubusercontent.com/thomasberge/rested_script/main/README.md");
?>
```

### IMPORTANT
Templating is inspired by jinja2 and Twig and will aim to be able to run Twig syntax without any transformations. Templating is executed before RestedScript tags, and so RestedScript variables will not be available within the templating language. After templating is processed however the RestedScript code is executed running with the same internal process id, thus making any variables set in template available in code.

##### Templating - comments

```
{# this will be removed #}

Multi-line comments
{# are also
supported #} and they
don't need {#to be }
```

##### Templating - variables
You can echo variables either passed as arguments in code or set within the templating by enclosing the variable name with double curly braces and a space. If the variable is not present or is null, a blank string will replace the statement.

```
{{ variablename }}
```

##### Templating - include
Includes work relative to the path that the RestedScript object was initialized. It will fetch the file from disk, process it and then return the processed result. The included file will have access to all of the same arguments and process variables. Note that those values are passed by reference, not by value.

```
{% include ('header.txt') %}

Some text.

{% include ('footer.txt') %}
```

##### Templating - if
Currently if only checks on boolean values in Arguments. If the boolean variable key specified in the if conditional is not present then it equates to false. You can specify `not` or `!` if you need an inverted check. You can also prefix the variable key with a `!`. If uses `{% %}` notation. An if needs to be closed with an endif. Nesting is supported.

```
{% if thisVariableEvalutesToTrue %}
...
{% endif %}

{% if not invertsMeaningEvenIfVariableDoesntExist %}
...
{% endif %}

{% if ! canAlsoBeWrittenAsSuch %}
...
{% endif %}

{% if !andSuch %}
...
{% endif %}
```

##### Templating - foreach using list
```
<html>
    {{foreach(imageurl)}}
        <div class="imagebox">{{imageurl}}</div>
    {{endforeach(imageurl)}}
</html>
```

##### Templating - foreach using sheet
```
<html>
    {{foreach(images.*)}}
        <div class="imagebox">{{images.url}}</div>
        <div class="imagecaption">{{images.caption}}</div>
    {{endforeach(imageurl)}}
</html>
```

##### Templating - variablemap dump
Inspired by twig, a `{{ dump() }}` will dump all key/values in the arguments object to the cli/stdout. It will only dump once even if it is present multiple times.


### Testing
There is a test script included in /test that runs all functions in different variations and tests against the result. A report is written to console where each function is graded with a OK or Failed. If changes are made to rested_script then new functions should be added and all functions tested again to make sure they pass.

The accompanying Dockerfile in this repo root can be run in order to run the test.

```bash
docker build -t rested_script_test . && docker run -it rested_script_test
```


# OLD, PERHAPS NOT RELEVANT DOCUMENTATION BELOW

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
