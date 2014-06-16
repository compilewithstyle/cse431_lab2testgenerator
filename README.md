cse431_lab2testgenerator
========================

Generates random test input for cse-431 lab 2


This script will output a series of test input for lab2 of Translation of Computer Languages.

The output will be a string in the lisp-like math language and will solve itself, giving the answer to the right of the string.

With no cmdline options, every output will be valid and solve itself correctly. If you add the option '--bad', then bad outputs will be added to valid ones and will be marked. Use this to see if your parser catches it.

To change the intensity of the test, you can change the following options via the syntax '<option>=<value>':

  max_items         --  the number of outputs
  max_list_size     --  the number of expressions per output
  max_literal_value --  the highest possible integer literal
  nesting_ratio     --  a decimal value from 0-1 which indicates the degree to which expressions are nested
  

Feel free to play with the options and make the tests as difficult as you want.

Let me know if you find any bugs/inconsistencies. Just email me at n.siow@wustl.edu or hit me up on facebook.

Cheers,
Siow


PS - this wouldn't be a problem if you would supply decent tests, Professor Shook. justsayin'
