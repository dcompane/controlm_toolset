Published in [Names xref table for Python. Are my names consistent? Which ones are… | by Daniel Companeetz | Medium](https://medium.com/@dcompane/names-xref-table-for-python-25929f31ba47)




Are my names consistent? Which ones are not?

When starting to develop in Python less than a year ago, I came up with the realization that keeping the names of variables, functions, and alike, in a consistent way would be a bit more work that I anticipated. I am a stickler for maintainability, so documentation and consistency are important to me.

As I worked in a project that mounted to a couple thousand lines and a dozen functions, keeping mental track of all the variables, parameters, etc. was more difficult. I am sure more than one reader is also having that problem.

Wouldn’t it be great if we had a xref table that shows the names used in the program and the lines where they were? Older compilers I have worked with had that function, and I looked for a similar for Python. The reason for this article is that I did not find one, so I took to write it. Many utilities have started that way!

Tokenizer ( [https://docs.python.org/3/library/tokenize.htm) ](https://docs.python.org/3/library/tokenize.html)was the tool I found that help analyzing python code. It is a bit rough, in that will provide a lot more information than what I wanted, and not in a summarized way.

So based on this, I created this small script that provides what I wanted. The script can be found at[ **https://github.com/dcompane/python-names-xref**](https://github.com/dcompane/python-names-xref).

If you apply the program to itself, you get…

![](https://miro.medium.com/v2/resize:fit:661/1*zcNvffea_t3hGarmYr-SoA.png)

There were some choices made that I hope are properly documented in the code, or that they are self-evident, when you read it.

Since tokenizer provides everything as a name, irrespective of where it is found, I set out to find if it was a reserved, builtin, or other type of name.

There are some side-effects that will need to be worked out, but this is a good MVP at this point. Side-effects not treated at this point include:

1. Parameters for program defined functions are also considered builtins
2. Imported module names are considered program names. (only fair since it works as an include).

There are possibilities to continue evolving the script, such as:

1. reading the import statements and eliminating everything that was imported,
2. creating some regex to validate the names and reporting only those that do not comply
3. Adding some scope indications (class, method, function, global, etc.)

Please leave feedback if you check and use it, and feel free to provide new options, functions, and if needed, ask questions about the choices.

Hope you enjoy it!
