#Parse the command line arguments
ARGV.each_with_index do |a,i|
	if a == '-v'
		$verbose=true
	end
	if a== '-n' && ARGV[i+1] != nil
		$n=ARGV[i+1].to_i
	end
end

puts "This is the sudoku solver"
if ARGV.length ==0
	puts "Type FILENAME -v -n INTEGER"
	puts "-v -n INTEGER are options"
	puts "Example: ruby sudoku.rb input.csv -v -n 10000"
	exit
end
if File.exists?(ARGV[0])
	file = File.open(ARGV[0])
else
	puts "There is no \"" + ARGV[0] + "\" file"
	exit
end
$baset=[]

#File parser and validator
#Converts the input csv file to an 81 length integer array.
#Checks if the file is valid format wise.
valid_file = true
file.each_with_index do |line, i|
	line.gsub!("\n","")
	a=line.split(",").map {|s| s.to_i}
	if a.length > 9
		puts "Check line: " + i.to_s + " too many columns"
		valid_file = false
		break
	end
	a.each_with_index do |e, j|
		# e is an element of line
		#Check elements are in range
		if  e.to_i < 0 || e.to_i > 9 
			puts "Check element row: " + i.to_s + " column: " + j.to_s 
 			valid_file=false
			break
		end
		#check elements are not repeated
		(0..8).each do |k|
			if e != 0 && k != j &&  e == a[k]
				puts "Repeated " + e.to_s + " in row: " + i.to_s
				valid_file=false
				break
			end
		end
	end
	# check there are 9 rows"
	if i > 8
		puts "File has more than allowed rows"
		valid_file = false
	end
	$baset<<a
end
if !valid_file
	puts "Please check the input file and try again"
	abort
end 

$base = $baset.flatten
$baset= $base.dup

# $base=[0,3,5,2,9,0,8,6,4,
# 		0,8,2,4,1,0,7,0,3,
# 		7,6,4,3,8,0,0,9,0,
# 		2,1,8,7,3,9,0,4,0,
# 		0,0,0,8,0,4,2,3,0,
# 		0,4,3,0,5,2,9,7,0,
# 		4,0,6,5,7,1,0,0,9,
# 		3,5,9,0,2,8,4,1,7,
# 		8,0,0,9,0,0,5,2,6]



$start_time=Time.now

################  Variables ###################

#the population size should be adjusted
# according to the amount of unknowns of rows
# ideally make a good fit for this.

#$n = 1000
# Every element is a chromosome
$population =[]
#Holds the fitness of each chromosome
#The fitness is defined by the amount of constraints satisfied
#there are 9 row constrains, 9 column constrains, 9 submatrices constrains
# The 9 row constrains are always satisfied therefore the solutions is
# the individual with fitness 18
$population_fitness=[]

#Holds arrays with the elements missing per row
$gene =[]
#Used to create the probability of being chosen proportional to
#the fitness
$roulette=[]
$possibilities={}

########### FUNCTIONS IMPLEMENTATIONS #############

def calculate_fit
	$best_fit=0
	$population.each_with_index do |e, i|
		#puts "calculating fit of "
		#puts pretty(e)
		current_fitness=fitness(e)
		#puts "fitness is " + current_fitness.to_s
		if current_fitness > $best_fit
			$best_fit = current_fitness
			$solution = e
			puts pretty(e)
			puts "Best fit: " + $best_fit.to_s
			puts ""
		end
		$population_fitness[i] = current_fitness
	end
end

def calculate_unknowns
	length=0
	$possibilities.each do |k, v|
		length += v.length
	end
	length
end

#returns an array corresponding to column i
def col(i,arr)
	result =[]
	(0..8).each do |j|
		result[j] = arr[j*9+i]
	end
	result
end

#returns an array corresponding to row j
def row(j,arr)
	result =arr[(j*9)..(j*9+8)]
end

#returns an array corresponding submatrix k
def mini(k, arr)
	#find the index
	first=k/3*27+(k%3)*3
	second=first+9
	third=first+18
	result=[]
	result=arr[first..(first+2)]+arr[second..(second+2)]+arr[third..(third+2)]
end

def create_chromosome
	#creates a valid chromosome
	chromosome=[]
	$gene.each_with_index do |g, i|
		scrambled=scramble(g)
		full_gene=merge(row(i,$base),scrambled)
		chromosome += full_gene
	end
	puts chromosome.to_s if $verbose
	chromosome

end


def create_genes
	(0..8).each do |r|
		row_arr = find_not_present(row(r,$base))
		(0..8).each do |c|
			#find the not given
			arr=row_arr.dup
			if $base[r*9+c] == 0
				#eliminate row valid possibilities with presence in 
				#columns and submatrices
				arr.each_with_index do |e,i|
					m=(r/3)*3+c/3
					#puts "m: " + m.to_s 
					if col(c,$base).include?(e) || mini(m,$base).include?(e)
						#puts "Not present in row " + r.to_s + " " + row_arr.to_s
						#puts "choque con col: " + c.to_s
						puts "delete element " + e.to_s
						arr[i]=10
					end
				end
				arr.delete(10)
				#If it is definite the value simplify the chromosome
				if arr.length==1
					$base[r*9+c] = arr[0]
					$possibilities.delete(r*9+c)
				else
					$possibilities[r*9+c]=arr
				end
				puts "After filter column and sub " +c.to_s+ " " + arr.to_s
				puts pretty_color($base)
			end
		end
	end
end


#Returns array with the numbers from 1 to 9 that are not in the input array
def find_not_present(arr)
	result=[]
	(1..9).each do |i|
		exists = false
		arr.each do |e|
			if e == i
				exists=true
				break
			end
		end
		if !exists
			result << i
		end
	end
	result
end

def fitness(chromo)
	# evaluates the fitness of the chromosome
	# fitness is the number of checks passed max 18.
	#stop when finding 18 checks
	value=0
	(0..8).each do |i|
		if find_not_present(col(i,chromo)).length == 0
			value+=1
		end
		if find_not_present(mini(i,chromo)).length == 0
			value+=1
		end
	end
	value
end

def merge(arr_into, arr )
	#CHECK THE NUMBER OF ZEROS CORRESPOND
	result=arr_into.dup
	j=0
	result.each_with_index do |e, i|
		if e == 0
			result[i] = arr[j]
			j+=1
		end
	end
	result
end

def next_generation
	ram_population=[]
	# create a new generation of the same size as the previous one
	create_roulette
	while ram_population.length < $n do 
		chromo1=pick_chromo
		chromo2=pick_chromo
		new_chromo1=chromo1
		new_chromo2=chromo2
		# not everytime there is recombination
		if recombination?
			new_chromo1=recombinate(chromo1,chromo2)
			new_chromo2=recombinate(chromo2,chromo1)
		end
		ram_population << new_chromo1
		ram_population << new_chromo2
	end
	$population = ram_population
	puts "GENERATION: " + $generation.to_s
	puts "Time elapsed: " + (Time.now - $start_time).to_s + " s"
end

# Create the population
def new_population
	(0..($n-1)).each do |i|
		puts "Create chromosome " + i.to_s if $verbose
		$population[i] = create_chromosome
		$population_fitness[i]= 1
	end
end	

#create the probability of selection based on the fitness
def create_roulette
	$roulette=[]
	$population_fitness.each_with_index do |f,i|
		if f > 0
			(1..f).each do |j|
				$roulette << i
			end
		end
	end
end

#Pick a member of the population the probability if proportional to the fitness
def pick_chromo
	index=rand($roulette.length)
	chromo=$population[$roulette[index]]
	chromo
end

def pretty(arr)
	(0..8).each do |i|
		puts row(i,arr).to_s
	end
	nil
end
def pretty_color(arr)
	(0..8).each do |i|
		print "["
		(0..8).each do |j|
			if $baset[i*9+j] == 0
				print "\033[42m #{arr[i*9+j]} \033[0m"
			else
				print " #{arr[i*9+j]} "
			end
		end
		print "]\n"
	end
	nil
end


def recombinate(chromo1,chromo2)
	#create a child
	# random point in the sequence to recombinate
	#gene index of crossing
	g=rand(8)
	# first half is from chromo1
	# second half is from chromo 2
	f=chromo1[0..(9*(g+1)-1)]
	s=chromo2[(9*(g+1))..80]
	result=f + s
	result
end

#Recombinate with a probability of 0.7
def recombination?
	if rand(10) >= 1
		true
	else
		false
	end
end

# Scramble the order of the possible unknowns
def scramble(arr)
	n=arr.length
	copy=arr.dup
	(0..(n-1)).each do |i|
		exchange_index=rand(n)
		ram=copy[i]
		copy[i]=copy[exchange_index]
		copy[exchange_index]=ram
	end
	copy
end
#####################################################################
################### Execution of the algorithm #######################
#####################################################################
create_genes
previous_unknowns=calculate_unknowns 

current_unknowns = calculate_unknowns - 1
number_of_loops = 0
while previous_unknowns > current_unknowns do
	previous_unknowns = calculate_unknowns
	puts "Number of unknowns before: " + previous_unknowns.to_s
	create_genes
	current_unknowns = calculate_unknowns
	puts "Number of unknowns after: " + current_unknowns.to_s
	puts $possibilities.to_s
	number_of_loops += 1
	puts "number of loops: " + number_of_loops.to_s
end
puts pretty_color($base)

$best_fit=0
$generation=0
new_population
puts $population.to_s if $verbose
puts "THE SOLUTION"
puts "Number of unknows: " + $gene.flatten.length.to_s
puts "Individuals: " + $n.to_s
puts "Generations: " + ($generation-1).to_s
puts pretty_color($base)



while $best_fit < 18 do 
	next_generation
	calculate_fit
	$generation=$generation+1
end
end_time=Time.now
elapsed_time= end_time-$start_time

puts "THE SOLUTION"
puts "Number of unknows: " + $gene.flatten.length.to_s
puts "Individuals: " + $n.to_s
puts "Generations: " + ($generation-1).to_s
puts pretty_color($solution)
puts "took " + elapsed_time.to_s + "seconds"
