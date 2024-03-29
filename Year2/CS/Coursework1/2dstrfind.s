
#=========================================================================
# 2D String Finder 
#=========================================================================
# Finds the matching words from dictionary in the 2D grid
# 
# Inf2C Computer Systems
# 
# Siavash Katebzadeh
# 8 Oct 2019
# 
#
#=========================================================================
# DATA SEGMENT
#=========================================================================
.data
#-------------------------------------------------------------------------
# Constant strings
#-------------------------------------------------------------------------

grid_file_name:         .asciiz  "2dgrid.txt"
dictionary_file_name:   .asciiz  "dictionary.txt"
newline:                .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
grid:                   .space 1057     # Maximun size of 2D grid_file + NULL (((32 + 1) * 32) + 1)
.align 4                                # The next field will be aligned
dictionary:             .space 11001    # Maximum number of words in dictionary *
                                        # ( maximum size of each word + \n) + NULL
# You can add your data here!
.align 2
dictionary_idx:		 .space 4000    # starting index of each word in the dictionary, 1000 words x 4 bytes per int
dict_num_words:          .word 0        # number of words in the dictionary
grid_row_length:	 .word 0	# length of each row in the current grid including \n
grid_total_length:	 .word 0	# total length of the grid including \n's
#=========================================================================
# TEXT SEGMENT  
#=========================================================================
.text

#-------------------------------------------------------------------------
# MAIN code block
#-------------------------------------------------------------------------

.globl main                     # Declare main label to be globally visible.
                                # Needed for correct operation with MARS
main:
#-------------------------------------------------------------------------
# Reading file block. DO NOT MODIFY THIS BLOCK
#-------------------------------------------------------------------------

# opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, grid_file_name        # grid file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # grid[idx] = c_input
        la   $a1, grid($t0)             # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(grid_file);
        blez $v0, END_LOOP              # if(feof(grid_file)) { break }
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP 
END_LOOP:
        sb   $0,  grid($t0)            # grid[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(grid_file)


        # opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, dictionary_file_name  # input file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # fopen(dictionary_file, "r")
        
        move $s0, $v0                   # save the file descriptor 

        # reading from  file just opened

        move $t0, $0                    # idx = 0

READ_LOOP2:                             # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # dictionary[idx] = c_input
        la   $a1, dictionary($t0)       # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(dictionary_file);
        blez $v0, END_LOOP2             # if(feof(dictionary_file)) { break }
        lb   $t1, dictionary($t0)                             
        beq  $t1, $0,  END_LOOP2        # if(c_input == '\0')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP2
END_LOOP2:
        sb   $0,  dictionary($t0)       # dictionary[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(dictionary_file)
#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------
#------------------------------------------------------------------
# Count words and write start indices to dictionary_idx
#------------------------------------------------------------------
#counting how long the whole grid is

	la $t0, grid			# char* current_char = grid;
	
COUNT_TOTAL_LOOP:
	lbu $t1, ($t0)
	beq $t1, 0, COUNT_TOTAL_LENGTH_LOOP_EXIT #  while (*current_char != '\0')
	
	lw $t2, grid_total_length
	addiu $t2, $t2, 1			# grid_low_length +=1;
	sw $t2, grid_total_length 
	
	addiu $t0, $t0, 1			# current_char +=1;
	
	j COUNT_TOTAL_LOOP
	
	COUNT_TOTAL_LENGTH_LOOP_EXIT:
	
	
#counting how long each row is in the grid
	
	la $t0, grid			# t0<-current_char = grid;

COUNT_LENGTH_LOOP:
	lbu $t1, ($t0)			# t1<-*current_char
	beq $t1, 10, COUNT_LENGTH_EXIT	#  while (*current_char != '\n')
	
	lw $t2, grid_row_length	
	addiu $t2, $t2, 1		# grid_row_length += 1;
	sw $t2, grid_row_length
	
	addiu $t0, $t0, 1		# current_char += 1;
	
	j COUNT_LENGTH_LOOP
	
COUNT_LENGTH_EXIT:

	lw $t2, grid_row_length	
	addiu $t2, $t2, 1		# grid_row_length += 1;
	sw $t2, grid_row_length



#storing the starting index of each word in the dictionary
	addiu $t0,$zero,0 		# idx = 0
	
	addiu $t4, $zero,0 		# dict_idx = 0				
	addiu $t5, $zero,0 		# start_idx = 0
	
STORE_LOOP:				# do {
	la $t1, dictionary              # &dictionary -> t1
	addu $t1,$t1,$t0               # &dictionary[idx] -> t1
	lb $t3, 0($t1)			# c_input = dictionary[idx]
	
	beqz $t3, END_STORE_LOOP	# if(c_input == '\0') {break;}
	bne $t3,10 NOT_WORD_BOUNDARY    # if(c_input == '\n') {
	
	la $t6, dictionary_idx          # &dictionary_idx -> t6
	sll $t7, $t4, 2			# since int, we multiply index by 4 -> t7
	addu $t6, $t6,$t7		# &dictionary_idx[dict_idx] ->t6
	sw $t5, ($t6)			# dictionary_idx[dict_idx] = start_idx;
	
	addiu $t4,$t4, 1			#dict_idx += 1
	addu $t5,$t0,1			#start_idx = idx + 1
	
NOT_WORD_BOUNDARY:
	addiu $t0,$t0,1			# idx += 1;
	
	j STORE_LOOP			# while (1)
	
END_STORE_LOOP:
	sw $t4, dict_num_words		# dict_num_words = dict_idx;

#------------------------------------------------------------------
# end
#------------------------------------------------------------------

#------------------------------------------------------------------
# main functionality
#------------------------------------------------------------------

	jal strfind
		
	j main_end

#-----------------------------------------------------------------
# helper functions
#-----------------------------------------------------------------
#desc: print integer
#in  : $a0 = integer 
#out : I/O
print_int:
	addiu $sp, $sp,-4		#save return address
	sw $ra, 0($sp)	
	addiu $v0, $zero, 1	#syscall for printing integers
	syscall
	lw $ra, 0($sp)
	addiu $sp, $sp,4		#load return address
	jr $ra
	
#desc: print char
#in  : $a0 = char 
#out : none
print_char:
	addiu $sp, $sp,-4		#save return address
	sw $ra, 0($sp)	
	addiu $v0, $zero, 11	#syscall for printing chars
	syscall
	lw $ra, 0($sp)
	addiu $sp, $sp,4		#load return address
	jr $ra

#desc: print the given \n terminated word
#in  : $a1 = &word (non-aligned)
#out : none
#used: $a0 = *word, $v0 = syscall code
print_word:
	addiu $sp, $sp,-4		#save return address
	sw $ra, 0($sp)	
PRINT_WORD_LOOP:
					 # while( 
	lb $a0,0($a1)                    # dereference a1: *word -> a0 
	beq $a0,10,PRINT_WORD_EXIT       # (*word != '\n' &&
	beq $a0,$zero, PRINT_WORD_EXIT   # *word != '\0')
					 
					 # print_char(*word)
	addiu $v0,$zero,11               # v0 <- 11 syscall print code for char
	syscall				 # a0 already CONTAIN_Hs char to print: *word
	
	addiu $a1,$a1,1                  # word++
	
	j PRINT_WORD_LOOP		 # complete the while loop
	
PRINT_WORD_EXIT:

	lw $ra, 0($sp)
	addiu $sp, $sp,4		#load return address
	
	jr $ra                           #return 0



#desc: given a string and a word (\n terminated) returns 1 if word is CONTAIN_Hed in string
#in  : #a1 = &word
       #a2 = &string 
#out : #v0 = (bool)
#used: #t1 = *string, $t0 = *word
		
CONTAIN_H:				#while (1){

CONTAIN_H_LOOP:	
	lbu $t0, ($a2)			#t0 <- *string
	
	lbu $t0, ($a2)			#t0 <- *string
	lbu $t1, ($a1)			#t1 <- *word	
	
	
	bne $t0, $t1, CONTAIN_H_IF1_ENTRY  #if (*string != *word || *string == '\n'){
	bne $t0, 10, CONTAIN_H_IF2_EXIT
CONTAIN_H_IF1_ENTRY:
	seq $v0, $t1, 10		#v0 = 1 if t0 == '\n'
	jr $ra				# return (*word == '\n');

CONTAIN_H_IF2_EXIT:

	addiu $a2, $a2, 1		# string++;
	addiu $a1, $a1, 1		# word++;
	
	j CONTAIN_H_LOOP
	
	jr $ra				# return 0

#desc: see if the vertical string contains the \n terminated word (uses global variables for grid dimesnsions)
#in  : #a1 = &word
       #a2 = &string 
#out : #v0 = (bool)
CONTAIN_V:

CONTAIN_V_LOOP:		#while (1) {
	lbu $t0, ($a2)			# t0 <- *string
	lbu $t1, ($a1)			# t1 <- *word
	lw $t2, grid_total_length
	la $t3, grid
	addu $t2, $t2, $t3		# t2 <- grid_total_length + grid
	sge $t2, $a2, $t2		#  t2 <- 1 if a2 >= t2
	
	beq $t2, 1, CONTAIN_V_IF1_ENTRY # if (*string!= *word || string >= grid + grid_total_length)
	beq $t0,$t1 CONTAIN_V_IF1_EXIT	# 

CONTAIN_V_IF1_ENTRY:
	seq $v0, $t1, 10		#vo = *word == '\n'
	jr $ra				#return /\
	
CONTAIN_V_IF1_EXIT:

	lw $t5, grid_row_length
	addu $a2, $a2, $t5		# string += grid_row_length; // skip a row
	addiu $a1, $a1, 1		# word++
	
	j CONTAIN_V_LOOP
	
	jr $ra				# return 0

#desc: see if the diagonal string contains the \n terminated word (uses global variables for grid dimesnsions)
#in  : #a1 = &word
       #a2 = &string 
       #a3 = string_idx
#out : #v0 = (bool)
CONTAIN_D:
	
CONTAIN_D_LOOP:			#while(1) {
	
	lw $t4, grid_total_length
	la $t5, grid
	addu $t4,$t4,$t5 # t4 <- grid_total_length + grid
	
	lbu $t0, ($a2) #*string
	lbu $t1, ($a1) #*word
	
	bne $t0, $t1, CONTAIN_D_IF1_ENTRY
	bge $a2, $t4, CONTAIN_D_IF1_ENTRY
	bne $t0, 10, CONTAIN_D_IF1_EXIT
CONTAIN_D_IF1_ENTRY:
	seq $v0, $t1, 10		#return (*word == '\n')
	jr $ra
CONTAIN_D_IF1_EXIT:
	
	lw $t5, grid_row_length
	addiu $t5, $t5, 1
	
	addu $a2,$a2, $t5	# string += grid_row_length + 1; // skip a row and go right
	addu $a3,$a3, $t5	# string_idx += grid_row_length + 1; //
	addiu $a1, $a1, 1 #word++;
	j CONTAIN_D_LOOP
	
	jr $ra

#desc: strfind for 1d grid
#in  :  
#out : I/O
#used: 
strfind:
	addiu $sp, $sp,-20		#store local variables and return address
	sw $ra, 0($sp)
       #sw $zero, 4($sp)		# int idx = 0
	sw $zero, 8($sp)		# grid_idx = 0
       #sb    	 12($sp)		# char *word  | at 12($sp)
	sb $zero, 16($sp)		# char success = '\0';
	
STRFIND_WHILE_LOOP:
	lw $s6, 8($sp)			# s6 <- grid_idx
	la $s1, grid			# s1 <- &grid base 
	addu $s3, $s6, $s1		# s2 <- &grid[grid_idx]
	lbu $s4, ($s3)			# s4 <- grid[grid_idx]
	
	beq $s4, $zero, STRFIND_WHILE_EXIT #while (grid[grid_idx] != '\0') {
	
	beq $s4, 10 STRFIND_FOR_EXIT # if(grid[grid_idx] == '\n'){continue;} // when we're at a new line, skip to the next character
	
	sw $zero, 4($sp)		# idx = 0 reset for loop counter
	addiu $s0, $zero, 0		# s0 <- idx
STRFIND_FOR_LOOP:
	lw $s0, 4($sp)
	lw $t1, dict_num_words		# t1 <- dict_num_words
	slt $t0, $s0, $t1 		# it $so < $t1, $t0 = 1 else 0
	
	beq $t0, $zero, STRFIND_FOR_EXIT# for(idx = 0; idx < dict_num_words;... {
	
	la $t0, dictionary		# t0 <- &dictionary     (CHAR ARRAY)
	la $t1, dictionary_idx		# t1 <- &dictionary_idx (INT ARRAY)
	sll $t2, $s0, 2			# t2 <- idx * 4
	addu $t3, $t2, $t1		# t3 <- &dictionary_idx + (idx * 4)
	lw $t2, ($t3)			# t2 <- dictionary_idx[idx]
	addu $s5,$t0,$t2		# s5 <- &dictionary + dictionary_idx[idx] e.g. the index in dictionary of first letter of the word
	
	sb $s5, 12($sp)			# word = dictionary + dictionary_idx[idx]; 
	
	
	#--------------------CONTAIN H ------------------------#
	addu $a1, $s5, $zero		# a1 <- &word
	addu $a2, $s1,$s6 		# a2 <- &grid + grid_idx
	
	jal CONTAIN_H 			# CONTAIN_H(grid + grid_idx, word)
					# v0 -> 1 if CONTAIN_Hs
	beq $v0, $zero,STRFIND_CONTAIN_H_EXIT # if (CONTAIN_H(grid + grid_idx, word)) {
	
	#PRINT MATCH
	
	lw $t1, grid_row_length		# t1 <- grid_row_length
	div $s6,$t1
	mflo $t1			# t1 <- s6 / t1
	mfhi $t2			# t2 <- s6 % t1
	
	addiu $a0, $t1, 0		# print_int(grid_idx / grid_row_length); // y
	jal print_int
	
	addiu $a0, $zero, 44		# a0 <- ','
	jal print_char
	
	addiu $a0, $t2, 0		# print_int(grid_idx % grid_row_length); // x
	jal print_int
	
	addiu $a0, $zero, 32		# a0 <- ' '
	jal print_char
	
	addiu $a0, $zero, 72		# a0 <- 'H'
	jal print_char
	
	addiu $a0, $zero, 32		# a0 <- ' '
	jal print_char
	
	addiu $a1, $s5, 0		# a1 <- &word
	jal print_word
	
	addiu $a0, $zero, 10		# a0 <- '\n'
	jal print_char
	
	addiu $t0, $zero, 1		# t0 <- TRUE
	sb $t0, 16($sp)			# success ='1' or TRUE e.g. we have a hit gentlemen
	
STRFIND_CONTAIN_H_EXIT:

	#--------------------CONTAIN V ------------------------#
	
	addu $a1, $s5, $zero		# a1 <- &word
	addu $a2, $s1,$s6 		# a2 <- &grid + grid_idx

	jal CONTAIN_V 			# CONTAIN_V(grid + grid_idx, word)
					# v0 -> 1 if CONTAIN_Vs
	beq $v0, $zero,STRFIND_CONTAIN_V_EXIT # if (CONTAIN_V(grid + grid_idx, word)) {
	
	#PRINT MATCH
	
	lw $t1, grid_row_length		# t1 <- grid_row_length
	div $s6,$t1
	mflo $t1			# t1 <- s6 / t1
	mfhi $t2			# t2 <- s6 % t1
	
	addiu $a0, $t1, 0		# print_int(grid_idx / grid_row_length); // y
	jal print_int
	
	addiu $a0, $zero, 44		# a0 <- ','
	jal print_char
	
	addiu $a0, $t2, 0		# print_int(grid_idx % grid_row_length); // x
	jal print_int
	
	addiu $a0, $zero, 32		# a0 <- ' '
	jal print_char
	
	addiu $a0, $zero, 86		# a0 <- 'V'
	jal print_char
	
	addiu $a0, $zero, 32		# a0 <- ' '
	jal print_char
	
	addiu $a1, $s5, 0		# a1 <- &word
	jal print_word
	
	addiu $a0, $zero, 10		# a0 <- '\n'
	jal print_char
	
	addiu $t0, $zero, 1		# t0 <- TRUE
	sb $t0, 16($sp)			# success ='1' or TRUE e.g. we have a hit gentlemen

STRFIND_CONTAIN_V_EXIT:
	
	#--------------------CONTAIN D ------------------------#
	
	addu $a1, $s5, $zero		# a1 <- &word
	addu $a2, $s1,$s6 		# a2 <- &grid + grid_idx
	addu $a3, $s6, $zero		# a3 <- grid_idx
	jal CONTAIN_D 			# CONTAIN_D(grid + grid_idx, word)
					# v0 -> 1 if CONTAIN_Ds
	beq $v0, $zero,STRFIND_CONTAIN_D_EXIT # if (CONTAIN_D(grid + grid_idx, word)) {
	
	#PRINT MATCH
	
	lw $t1, grid_row_length		# t1 <- grid_row_length
	div $s6,$t1
	mflo $t1			# t1 <- s6 / t1
	mfhi $t2			# t2 <- s6 % t1
	
	addiu $a0, $t1, 0		# print_int(grid_idx / grid_row_length); // y
	jal print_int
	
	addiu $a0, $zero, 44		# a0 <- ','
	jal print_char
	
	addiu $a0, $t2, 0		# print_int(grid_idx % grid_row_length); // x
	jal print_int
	
	addiu $a0, $zero, 32		# a0 <- ' '
	jal print_char
	
	addiu $a0, $zero, 68		# a0 <- 'D'
	jal print_char
	
	addiu $a0, $zero, 32		# a0 <- ' '
	jal print_char
	
	addiu $a1, $s5, 0		# a1 <- &word
	jal print_word
	
	addiu $a0, $zero, 10		# a0 <- '\n'
	jal print_char
	
	addiu $t0, $zero, 1		# t0 <- TRUE
	sb $t0, 16($sp)			# success ='1' or TRUE e.g. we have a hit gentlemen

STRFIND_CONTAIN_D_EXIT:
	
STRFIND_FOR_INCREMENT:
	
	addiu $s0, $s0, 1 		# ..; idx++){
	sw $s0, 4($sp)
	j STRFIND_FOR_LOOP
	
STRFIND_FOR_EXIT:
	
	addiu $s6, $s6, 1		# grid_idx++..
	sw $s6, 8($sp)			# /\ /\ /\ /\
	j STRFIND_WHILE_LOOP
	
STRFIND_WHILE_EXIT:
	
	lbu $t0, 16($sp)		# t0 <- success (char)
	seq $t1, $t0, 0			# if t0 = 0, e.g. !success , t1 = 1
	
	beq $t1, $zero, STRFIND_RETURN # if(!success)
	
	addiu $a0, $zero, -1		# a0 <- -1
	jal print_int
	
	addiu $a0, $zero, 10		# a0 <- '\n'
	jal print_char

STRFIND_RETURN:
	lw $ra, 0($sp)
	addiu $sp, $sp,20		#load return address and pop variables
	jr $ra
	
#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
