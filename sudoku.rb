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
	puts "Example: ruby sudoku.rb input.csv -v"
	exit
end
if File.exists?(ARGV[0])
	file = File.open(ARGV[0])
else
	puts "There is no \"" + ARGV[0] + "\" file"
	exit
end

#####################################################################
#####################File parser and validator########################
#Converts the input csv file to an 81 length integer array.
#Checks if the file has a valid format.

$original_puzzle=[]
valid_file = true
file.each_with_index do |line, i|
	line.gsub!("\n","")
	a=line.split(",").map {|s| s.to_i}
	if a.length > 9
		puts "Check line: " + i.to_s + " has more than allowed columns"
		valid_file = false
		break
	end
	a.each_with_index do |e, j|
		# e is an element of line
		#Check elements are in range 0 to 9
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
	$original_puzzle<<a
end
if !valid_file
	puts "Please check the input file and try again"
	abort
end 

#variable to measure the time for making the calculations
$start_time=Time.now
################  GLOBAL VARIABLES ###################

# puzzle starts with the same data as original_puzzle but will be completed during
# the execution of the algorithm
$puzzle = $original_puzzle.flatten
$original_puzzle=$puzzle.dup
########
#Is a hash with key equal to the position of an unknown (zero) and value equal
# to 
$possibilities={}

########### FUNCTION IMPLEMENTATIONS #############

# Returns the amount of zeros left in the sudoku
def calculate_unknowns
	length=0
	$possibilities.each do |k, v|
		length += v.length
	end
	length
end

#returns an array corresponding to column i (0..8)
def col(i,arr)
	result =[]
	(0..8).each do |j|
		result[j] = arr[j*9+i]
	end
	result
end

def backtracking
	# hash that holds the current candidate key:depth value:number
	# Example {0=>3, 1=>6} for a sudoku with only two unknowns
	$sol={}
	
	#array where element i holds the current option index at depth i 
	# Example [0,1] for a sudoku with only two unknowns, therefore only two options
	# per unknown 
	depth_to_current_option=[]
	
	#array where element i holds the index in the original array 
	# Example [35, 40] it transforms depth which is secuential to the actual index
	# in the original array (puzzle)
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
		# stores array with all the possible values at depth
		values=$possibilities[$depth_to_possibility_index[depth]]
		#stores the current option chosen at depth
		option_index=depth_to_current_option[depth]
		down=false
		up=false
		puts "Depth " + depth.to_s if $verbose
		puts "Max progress " + (max_depth*100/possibilities_length).to_s
		while option_index < values.length && !down && !up
			# Check if the current option at depth is valid with the solution
			# traced so far
			if valid(depth,values[option_index],$sol)
				# store the new value en the current solution
				$sol[depth]=values[option_index]
				# update the current option in depth
				depth_to_current_option[depth]=option_index
				#increase depth
				depth += 1
				if depth > max_depth
					max_depth = depth
				end
				puts "going down (deeper)" if $verbose
				down = true
				break
			end
			puts "going to next option" if $verbose
			# if not valid go to next option
			option_index+=1	
			# if there are no more options then have to backtrack
			# restore option to zero, delete solution at depth and decrease depth 
			if option_index == values.length
				puts "No option available going up" if $verbose
				depth_to_current_option[depth]=0
				$sol.delete(depth)
				depth -= 1
				up = true
			end	
		end	
	end
	if depth == -1
		puts "Wrong sudoku!!! please check input file"
		abort
	else
		#Found a correct solution!!
		puts ""
		puts "THE SOLUTION"
		ram = merge($puzzle,$sol)
		pretty(ram)
		write_to_file(ram)
		puts "solution hash key:depth value: number" if $verbose
		puts $sol.to_s if $verbose
	end
end	

#Checks if using the option at the depth is valid or not
def valid(depth,option,sol)
	ram = merge($puzzle,sol)
	puts pretty(ram) if $verbose
	is_valid = true
	index=$depth_to_possibility_index[depth]
	r = index/9 # The row of the element
	c = index%9 # The column of the element
	m=(r/3)*3+c/3 # The submatrix of the element
	if col(c,ram).include?(option) || row(r,ram).include?(option) || mini(m,ram).include?(option)
		# if the element is found in the column, row or sub matrix it is not valid
		is_valid = false
	end
	is_valid
end

#Returns an array representing a puzzle including the solution so far
def merge(arr,sol)
	result =arr.dup
	sol.each do |k,v|
		result[$depth_to_possibility_index[k]]=v
	end
	result
end

#For every element not given create an array with the valid posibilities
#Checks for uniqueness in rows columns and submatrix
def fill_blanks_and_simplify
	(0..8).each do |r|
		row_arr = find_not_present(row(r,$puzzle))
		(0..8).each do |c|
			#find the not given
			arr=row_arr.dup
			if $puzzle[r*9+c] == 0
				#eliminate row valid possibilities with presence in 
				#columns (c) and submatrices (m)
				arr.each_with_index do |e,i|
					m=(r/3)*3+c/3 
					if col(c,$puzzle).include?(e) || mini(m,$puzzle).include?(e)
						puts "Deleting element " + e.to_s if $verbose
						arr[i]=10
					end
				end
				arr.delete(10)
				#If it is definite the value input it in puzzle
				if arr.length==1
					$puzzle[r*9+c] = arr[0]
					$possibilities.delete(r*9+c)
				else
					$possibilities[r*9+c]=arr
				end
				puts "After filter column and sub " +c.to_s+ " " + arr.to_s
				puts pretty($puzzle)
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

#returns an array corresponding submatrix k (0..8)
def mini(k, arr)
	#find the index
	first=k/3*27+(k%3)*3
	second=first+9
	third=first+18
	result=[]
	result=arr[first..(first+2)]+arr[second..(second+2)]+arr[third..(third+2)]
end

#Prints the puzzle. Shows in green the originally not given values
def pretty(arr)
	(0..8).each do |i|
		print "["
		(0..8).each do |j|
			if $original_puzzle[i*9+j] == 0
				print "\033[42m #{arr[i*9+j]} \033[0m"
			else
				print " #{arr[i*9+j]} "
			end
		end
		print "]\n"
	end
	nil
end

#returns an array corresponding to row j
def row(j,arr)
	result =arr[(j*9)..(j*9+8)]
end

#Write answer to csv
def write_to_file(arr)
	File.open("output.csv","w") do |f|
		(0..8).each do |r|
			(0..8).each do |c|
				f.write(arr[r*9+c].to_s+",")
			end
			f.write("\n")
		end
	end
end
#####################################################################
################### Execution of the algorithm #######################
#####################################################################

previous_unknowns=calculate_unknowns 
current_unknowns = calculate_unknowns - 1
number_of_loops = 0
#will loop fill_blanks_and_simplify until it can not reduce any more the 
#unknowns. 
while previous_unknowns > current_unknowns do
	previous_unknowns = calculate_unknowns
	puts "Number of unknowns before: " + previous_unknowns.to_s if $verbose
	fill_blanks_and_simplify
	current_unknowns = calculate_unknowns 
	puts "Number of unknowns after: " + current_unknowns.to_s if $verbose
	puts $possibilities.to_s if $verbose
	number_of_loops += 1
	puts "number of loops: " + number_of_loops.to_s
end

#after start the backtracking algoritm
backtracking

end_time=Time.now
elapsed_time= end_time-$start_time
puts "Took " + elapsed_time.to_s + " seconds"

