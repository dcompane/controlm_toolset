"""
(c) 2020 Daniel Companeetz
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
https://opensource.org/licenses/MIT

# SPDX-License-Identifier: MIT
For information on SDPX, https://spdx.org/licenses/MIT.html

For information on tokenize, https://docs.python.org/3/library/tokenize.html

Input: a file name
Output, a table with the names defined in the program, and the line numbers where they were used.
"""
import tokenize
import builtins
import keyword
from sys import exit, argv


def type_of_name(type_name=''):
    """
    Returns the type of name
        if found in the builtins, reserved ,
            returns builtin or reserved, respectively
        else
            returns pgm/module indicating is a name defined in the program
               or an imported module
    :param type_name: string
    :return: string
    """
    if type_name in builtins.dir():
        to_return = 'builtin'
    elif type_name in keyword.kwlist:
        to_return = 'reserved'
    else:
        to_return = 'pgm/module'
    return to_return


try:
    file = open(argv[1], 'rb')
    tokenized = tokenize.tokenize(file.readline)
except FileNotFoundError as error:
    print('File not found: ' + str(error))
    exit(1)
except tokenize.TokenError as error:
    print('Tokenized file error: ' + str(error))
    exit(1)


xref_vars = {}
for token in tokenized:
    if token.type == 1:

        # Initialize the key if not seen before
        if token.string not in xref_vars:
            xref_vars[token.string] = {'lines': [], 'type': ''}

        # Load the dict with values
        # Add the line number to the list of lines, if not there
        if token.start[0] not in xref_vars[token.string]['lines']:
            xref_vars[token.string]['lines'].append(token.start[0])
        # Add the type of name found.
        xref_vars[token.string]['type'] = type_of_name(token.string)

# Calculate the max key for the tabulation
# sort reverse by length of key (longer is first after sorting)
#  Trying to reduce number of imports. Use tabulate if you prefer.
max_key_len = len(sorted(xref_vars.items(), key=lambda s: len(s[0]), reverse=True)[0][0])

# Print the xref table
print('Name', ' ' * (max_key_len - 1),
      'Var Type', ' ' * 5,
      'Line numbers')
for key in sorted(xref_vars.keys(), key=lambda s: s.lower()):
    print(key, ' ' * (max_key_len + 3 - len(key)),
          xref_vars[key]['type'], ' ' * (13 - len(xref_vars[key]['type'])),
          xref_vars[key]['lines'])

exit(0)