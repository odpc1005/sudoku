#Sudoku puzzle solver
## Instructions of use
In the terminal type: 
ruby sudoku.rb FILENAME -v

for example:
ruby sudoku.rb input1.csv


FILENAME should be a .csv file containing the initial puzzle as follows:

0,3,5,2,9,0,8,6,4,<br/>
0,8,2,4,1,0,7,0,3,<br/>
7,6,4,3,8,0,0,9,0,<br/>
2,1,8,7,3,9,0,4,0,<br/>
0,0,0,8,0,4,2,3,0,<br/>
0,4,3,0,5,2,9,7,0,<br/>
4,0,6,5,7,1,0,0,9,<br/>
3,5,9,0,2,8,4,1,7,<br/>
8,0,0,9,0,0,5,2,6<br/>

where the zeros represent the empty slots.

The program will print the solution to the console and also output the solution to output.csv

##Algorithm used
The program stores all the possible answers of unknowns (zeros) in a hash.
It starts by checking the row then look if it contradicts column or submatrix rules.
In this way it can simplify the options for every slot. If there is only one option it modifies the puzzle accordingly.

Depending on the puzzle given this methodic simplification won't continue. In that case the program would start 
a backtracking algorithm starting with the simplified puzzle.
There are two parameters for the algoritm: depth and current_option.

1. start at depth zero
2. choose the first option at that depth
3. if it is valid choose the option, update current_option and increase depth
4. if not look for other option
5. if there is no option that is valid decrease depth and continue with the current_option
6. Keep doing this until depth chooses the last not given








======
