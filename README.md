#Sudoku puzzle solver
## Instructions of use
run ruby sudoku_backtrack.rb FILENAME -v
FILENAME should be a .csv file containing the initial puzzle as follows:

0,3,5,2,9,0,8,6,4,

0,8,2,4,1,0,7,0,3,

7,6,4,3,8,0,0,9,0,

2,1,8,7,3,9,0,4,0,
0,0,0,8,0,4,2,3,0,
0,4,3,0,5,2,9,7,0,
4,0,6,5,7,1,0,0,9,
3,5,9,0,2,8,4,1,7,
8,0,0,9,0,0,5,2,6

where the zeros represent the empty slots.

##Algorithm used.
The program stores for every empty slot all the possible answers in a hash.
It looks for an empty slot an analyses which possible number would fit in. If there are slots where there is only one possible answer
it updates the slot accordingly.
Depending on the puzzle given it could be that this methodic simplification wont continue. In that case the program would start 
a backtracing algorithm starting with the simplified puzzle.


## Optional
there is another version where instead of backtracing the program would attempt a genetic algorithm.
In this case the instruccions are as follow:
ruby sudoku_genetic.rb -n INTEGER -v
where the option -n defines the size of the population of the chromosomes and -v is a flag for running verbose version.






======
