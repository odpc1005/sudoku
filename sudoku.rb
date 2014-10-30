
puts "This is the sudoku solver"
start_time=Time.now
# needs the csv parser
################  Variables ###################

$base=[0,3,5,2,9,0,8,6,4,
		0,8,2,4,1,0,7,0,3,
		7,6,4,3,8,0,0,9,0,
		2,1,8,7,3,9,0,4,0,
		0,0,0,8,0,4,2,3,0,
		0,4,3,0,5,2,9,7,0,
		4,0,6,5,7,1,0,0,9,
		3,5,9,0,2,8,4,1,7,
		8,0,0,9,0,0,5,2,6]
#the population size
$n = 2000
# holds the chromosomes
$population =[]
$population_fitness=[]
$total_fitness=0
$gene =[]
$roulette=[]

########### FUNCTIONS IMPLEMENTATIONS #############

def calculate_fit
	$total_fitness=0
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
		end
		$population_fitness[i] = current_fitness
		$total_fitness=$total_fitness+current_fitness
	end
	$total_fitness
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
	#puts "create chromosome"
	chromosome=[]
	$gene.each_with_index do |g, i|
		scrambled=scramble(g)
		full_gene=merge(row(i,$base),scrambled)
		chromosome += full_gene
		#puts chromosome.to_s
	end
	chromosome
end

def create_genes
	(0..8).each do |i|
		$gene[i] = find_not_present(row(i,$base))
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
	# fitness is the number of checks left max 18.
	#stop when finding 18 checks
	value=0
	(0..8).each do |i|
		if find_not_present(col(i,chromo)).length == 0
			value+=1
			#puts "OK col " + i.to_s
		end
		if find_not_present(mini(i,chromo)).length == 0
			value+=1
			#puts "OK mini " + i.to_s
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
		new_chromo=chromo1
		# not everytime there is recombination
		if recombination?
			new_chromo=recombinate(chromo1,chromo2)
		end
		ram_population << new_chromo
	end
	$population = ram_population
	puts "NEW POPULATION"
	puts $population.to_s
end

# Create the population
def new_population
	(0..($n-1)).each do |i|
		puts "Create chromosome " + i.to_s
		$population[i] = create_chromosome
		$population_fitness[i]= 0
	end
end	

#create the probability of selection based on the fitness
def create_roulette
	$roulette=[]
	puts "POPULATION FITNESS"
	puts $population_fitness.to_s
	$population_fitness.each_with_index do |f,i|
		(0..f).each do |j|
			$roulette << i
		end
	end
	#puts "THE ROULETTE"
	#puts $roulette.to_s
end

#Pick a member of the population the probability if proportional to the fitness
def pick_chromo
	index=rand($roulette.length)
	chromo=$population[$roulette[index]]
	#puts "picked chromo "
	#puts $roulette[index].to_s
	#puts pretty(chromo)
	chromo
end

def pretty(arr)
	(0..8).each do |i|
		puts row(i,arr).to_s
	end
	nil
end

def recombinate(chromo1,chromo2)
	#create a child
	# random point in the sequence to recombinate
	#gene of crossing
	g=rand(8)
	# first half is from chromo1
	# second half is from chromo 2
	f=chromo1[0..(9*(g+1)-1)]
	s=chromo2[(9*(g+1))..80]
	result=f + s
	# puts "RECOMBINATED" 
	# pretty(chromo1)
	# puts "WITH"
	# pretty(chromo2)
	# puts "at " + g.to_s
	# puts result.to_s
	result
end

def recombination?
	if rand(10) >= 6
		true
	else
		false
	end
end

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

def show_stats
	puts "Generation: #{$generation}"
	puts "Best fit: #{$best_fit}" 
	$population_fitness.to_s
end

################### Execution of the algorithm #######################

create_genes
$gene.each_with_index do |g, i|
	puts "index genes " + i.to_s
	puts g.to_s
	puts "____"
end
$best_fit=0
$generation=0
new_population
puts $population.to_s
$population.each_with_index do |p, i|
	puts "chromosome index " + i.to_s
	puts p.to_s
	puts "____"
end
while $best_fit < 18 do 
	next_generation
	calculate_fit
	show_stats
	$generation=$generation+1
end
end_time=Time.now
elapsed_time= end_time-start_time

puts "THE SOLUTION"
puts pretty($solution)
puts "took " + elapsed_time.to_s