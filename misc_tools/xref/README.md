# python-names-xref

Creates a table of names with name type and line number. (example of tokenizer)

Older compilers, like COBOL, used to provide a xref table with the names defined in the program so developers could check on the name allocation.

Since the advent of more interpreted languages, practices changed, and I missed those tables.

With this little utility, I can now check that variables are conforming to some standard, and filter from the output those that do, so only the non-conforming ones will be reported. But that is left to you to develop!

For information on tokenize, https://docs.python.org/3/library/tokenize.html

- Input: a file name
- Output, a table with the names defined in the program, and the line numbers where they were used. (stdout).
- No help has been created

Sample run: try against itself!!

python xref_var_table.py xref_var_table.py
