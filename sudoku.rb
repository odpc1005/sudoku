#Parse the command line arguments
ARGV.each_with_index do |a,i|
	if a == '-v'
		$verbose=true
	end
end

puts "This is the SUDOKU solver"
if ARGV.length ==0
	puts "Type FILENAME -v "
	puts "-v is verbose option"
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

$start_time=Time.now


################  GLOBAL VARIABLES ###################

$gene =[]
$base = $baset.flatten
$baset=$base.dup
$possibilities={}

########### FUNCTION IMPLEMENTATIONS #############
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

#returns an array corresponding submatrix k
def mini(k, arr)
	#find the index
	first=k/3*27+(k%3)*3
	second=first+9
	third=first+18
	result=[]
	result=arr[first..(first+2)]+arr[second..(second+2)]+arr[third..(third+2)]
end

#change th 
def create_chromosome
	#creates a valid chromosome
	chromosome=[]
	(0..8).each do |r|

	end

	# $gene.each_with_index do |g, i|
	# 	scrambled=scramble(g)
	# 	full_gene=merge(row(i,$base),scrambled)
	# 	chromosome += full_gene
	# end
	puts chromosome.to_s if $verbose
	chromosome
end

def backtrace
	$sol={}
	#holds the index of the current option 
	depth_to_current_option=[]
	$depth_to_possibility_index=[]
	$possibilities.each_with_index do |p,i|
		depth_to_current_option[i]=0
		$depth_to_possibility_index[i]=p[0]
	end
	depth=0
	max_depth=0
	possibilities_length=$depth_to_possibility_index.length
	#start at depth zero
	#take the first option for that depth
	#if does not contradict row, column, sub rules
	# set in solution, proceed to next depth
	# else try next option
	# if no more options return previous depth, restore
	# last option, try next option

	while depth < possibilities_length && depth >= 0
		values=$possibilities[$depth_to_possibility_index[depth]]
		option_index=depth_to_current_option[depth]
		down=false
		up=false
		puts "Depth " + depth.to_s if $verbose
		puts "Max progress " + (max_depth*100/possibilities_length).to_s
		while option_index < values.length && !down && !up
			# puts "Option index " + option_index.to_s
			# puts "options " + values.length.to_s
			
			if valid(depth,values[option_index],$sol)
				$sol[depth]=values[option_index]
				depth_to_current_option[depth]=option_index
				depth += 1
				if depth > max_depth
					max_depth = depth
				end
				puts "going down (deeper)" if $verbose
				# pretty($base)
				# puts "solution "
				# puts $sol.to_s
				# puts "depth option index"
				# puts depth_to_current_option.to_s
				down == true
				break
			end
			puts "going to next option" if $verbose
			option_index+=1	
			if option_index == values.length
				puts "No option available going up" if $verbose
				puts "-------------------" if $verbose
				depth_to_current_option[depth]=0
				$sol.delete(depth)
				depth -= 1
				up = true
			end	
		end	
	end
	ram = insert($base,$sol)
	pretty_color(ram)
	puts $sol.to_s
end	

#Checks if using the option option at the depth is valid or not
def valid(depth,option,sol)
	ram = insert($base,sol)
	puts pretty_color(ram) if $verbose
	# puts "Solution"
	# puts sol.to_s
	is_valid = true
	index=$depth_to_possibility_index[depth]
	r = index/9 # The row of the element
	c = index%9 # The column of the element
	m=(r/3)*3+c/3 # The submatrix of the element
	if col(c,ram).include?(option) || row(r,ram).include?(option) || mini(m,ram).include?(option)
		#puts "Element " +option.to_s + " row :" + r.to_s + " column:" + c.to_s + " is invalid"
		is_valid = false
	end
	is_valid
end

def insert(arr,sol)
	result =arr.dup
	sol.each do |k,v|
		result[$depth_to_possibility_index[k]]=v
	end
	result
end

#For every element not given create an array with the valid posibilities
#Checks for uniqueness in rows columns and submatrix
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

# def fitness(chromo)
# 	# evaluates the fitness of the chromosome
# 	# fitness is the number of checks passed max 18.
# 	#stop when finding 18 checks
# 	value=0
# 	(0..8).each do |i|
# 		if find_not_present(col(i,chromo)).length == 0
# 			value+=1
# 		end
# 		if find_not_present(mini(i,chromo)).length == 0
# 			value+=1
# 		end
# 	end
# 	value
# end

# def merge(arr_into, arr )
# 	#CHECK THE NUMBER OF ZEROS CORRESPOND
# 	result=arr_into.dup
# 	j=0
# 	result.each_with_index do |e, i|
# 		if e == 0
# 			result[i] = arr[j]
# 			j+=1
# 		end
# 	end
# 	result
# end

# def next_generation
# 	ram_population=[]
# 	# create a new generation of the same size as the previous one
# 	create_roulette
# 	while ram_population.length < $n do 
# 		chromo1=pick_chromo
# 		chromo2=pick_chromo
# 		new_chromo1=chromo1
# 		new_chromo2=chromo2
# 		# not everytime there is recombination
# 		if recombination?
# 			new_chromo1=recombinate(chromo1,chromo2)
# 			new_chromo2=recombinate(chromo2,chromo1)
# 		end
# 		ram_population << new_chromo1
# 		ram_population << new_chromo2
# 	end
# 	$population = ram_population
# 	puts "GENERATION: " + $generation.to_s
# 	puts "Time elapsed: " + (Time.now - $start_time).to_s + " s"
# end

# # Create the population
# def new_population
# 	(0..($n-1)).each do |i|
# 		puts "Create chromosome " + i.to_s if $verbose
# 		$population[i] = create_chromosome
# 		$population_fitness[i]= 1
# 	end
# end	

# #create the probability of selection based on the fitness
# def create_roulette
# 	$roulette=[]
# 	$population_fitness.each_with_index do |f,i|
# 		if f > 0
# 			(1..f).each do |j|
# 				$roulette << i
# 			end
# 		end
# 	end
# end

#Pick a member of the population the probability if proportional to the fitness
# def pick_chromo
# 	index=rand($roulette.length)
# 	chromo=$population[$roulette[index]]
# 	chromo
# end

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


# def recombinate(chromo1,chromo2)
# 	#create a child
# 	# random point in the sequence to recombinate
# 	#gene index of crossing
# 	g=rand(8)
# 	# first half is from chromo1
# 	# second half is from chromo 2
# 	f=chromo1[0..(9*(g+1)-1)]
# 	s=chromo2[(9*(g+1))..80]
# 	result=f + s
# 	result
# end

# #Recombinate with a probability of 0.7
# def recombination?
# 	if rand(10) >= 1
# 		true
# 	else
# 		false
# 	end
# end

#returns an array corresponding to row j
def row(j,arr)
	result =arr[(j*9)..(j*9+8)]
end

# # Scramble the order of the possible unknowns
# def scramble(arr)
# 	n=arr.length
# 	copy=arr.dup
# 	(0..(n-1)).each do |i|
# 		exchange_index=rand(n)
# 		ram=copy[i]
# 		copy[i]=copy[exchange_index]
# 		copy[exchange_index]=ram
# 	end
# 	copy
# end
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

backtrace
end_time=Time.now
elapsed_time= end_time-$start_time
puts "took " + elapsed_time.to_s + "seconds"

exit

# $best_fit=0
# $generation=0
# new_population
# puts $population.to_s if $verbose




# puts "THE SOLUTION"
# puts "Number of unknows: " + $gene.flatten.length.to_s
# puts "Individuals: " + $n.to_s
# puts "Generations: " + ($generation-1).to_s
# puts pretty_color($solution)
# puts "took " + elapsed_time.to_s + "seconds"
