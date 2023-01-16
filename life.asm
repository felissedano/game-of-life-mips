# TODO: modify the info below
# Student ID: 260897013
# Name: Felis Sedano Luo
# TODO END
########### COMP 273, Winter 2022, Assignment 4, Question 2 - Game of Life ###########

.data
# You should use following two labels for opening input/output files
# DO NOT change following 2 lines for your submission!
inputFileName:	.asciiz	"life-input.txt"
outputFileName:	.asciiz "life-output.txt"
# TODO: add any variables here you if you need
BUFFER1:	.space 10000
BUFFER2:	.space 10000
NEWLINE:	.asciiz "\n"

# TODO END

.text
main:
	# read the integer n from the standard input
	jal readInt
	# now $v0 contains the number of generations n you should simulate
	
# TODO: your code in main process here
	move $s0, $v0	# $s0 now has the number of generations needed to be simulated
	jal getData1	# v0 will be the starting location of BUFFER1
	
	move $a0, $s0	# move gen counter to argument 0
	move $a1, $v0	# move buffer to argument 1
	la $a2, BUFFER2	# load buffer2
	jal gameStart	# start simulation
	
	move $s1, $v0	# move result to s1
	
	la $a0, outputFileName	# now write the result to a new file
	move $a1, $s1
	jal writeData1

# TODO END
	
	li $v0, 10	# exit the program
	syscall


# TODO: your helper functions here

	#open and initialize the reading file, then use getData2 to get column count and getData3 to get row count
getData1:
	# open and read file to a buffer and determine the row and collunm count
	la $a0, inputFileName
	li   $v0, 13       
	li   $a1, 0        
	li   $a2, 0
	syscall           
	move $s6, $v0      # save the file descriptor 
	
	la $a1, BUFFER1
	li $s3, 0	#collunm counter
	li $s4, 1	# row counter
	
	# this is a loop to get number of collums
getData2:
	li  $v0, 14      
	move $a0, $s6     
	li  $a2, 1     	
	syscall 
	
	lb $t0, 0($a1)
	addi $s3, $s3, 1	# increase collunm count (the final result would be # of colunm + 1(newline)
	beq $t0, 10, getData3	# if its a new line character, it means the end of row
	addi $a1, $a1, 1	# go to next byte of buffer

	j getData2
	
getData3:
	li $v0, 14      
	move $a0, $s6     
	addi $a2, $s3, 0    	# read column number of bytes
	syscall 
	
	beq $v0, 0, getDataDone
	addi $s4, $s4, 1	# increase row count
	add $a1, $a1, $s3	# increase location
	addi $a1, $a1, -1	# decrease 1 byte as that is the newline character, we want to overwrite it
	j getData3
	
getDataDone:
	# close file and return 
	li $v0, 16
	move $a0, $s6
	syscall
	
	la $v0, BUFFER1
	addi $s3, $s3, -1 # count - 1 (bec thats nweline)	
	jr $ra
	
	
# we want to determine the state of each cell in one buffer and store the new value to a new buffer, then swap buffer in the next generation until
# the simulation ends
gameStart:
	move $s0, $a0	#genreration counter
	move $s1, $a1	# BUFFER1 with initial state
	move $s2, $a2	# BUFFER2 empty for now
	move $s6, $s1	# this store the starting lcoation of s1 as we are going to iterate each bytes and store it to s2
	move $s7, $s2	# this store the starting location of s2 as we are going to increament s2 one byte at a time
	li $t3, 0	# temporal column counter
	li $t4, 0	# temporal row counter
	j gameMid1
	
gameSwap:
	move $s1, $s6
	move $s2, $s7	# restore starting location of s2
	move $t0, $s1
	move $s1, $s2	# swap buffer 1 and 2
	move $s2, $t0
	move $s6, $s1	# store starting location of s2
	move $s7, $s2	# store starting location of s2
	li $t3, 0	# temp row and column counts both resets
	li $t4, 0
	
gameMid1:
	li $t3, 0	# each time row increase column resets
gameMid2:
	li $t9, 0  # t9 counts the number of live cells ( int: 1, ascii: 49)
	move $s1, $s6	# reset location of s1
	mult $s3, $t4 	# s3(total num of column) times t4(current row number) = start of current row
	mflo $t5	# get by how many to increament s1 base on collums times row
	add $t5, $t5, $t3	# add current column count
	add $s1, $s1, $t5		# increase s1 location
	lb $t8, 0($s1)	# load byte at location t5
	
	#now we want to check all 8 locations around s1 to see if the cell will live or die
gameMid2Left:
	addi $t0, $t3, -1	# check if there is a left column, if not the left/leftUp/leftDown all don't exist, hence go to right side directly
	blt $t0, $0, gameMid2Right
	
	# check if the left column is 1, if not then go to next location, else increase t9 count
	addi $s1, $s1, -1
	lb $t8, 0($s1)
	addi $s1 $s1, 1
	bne $t8, 49, gameMid2LeftUp
	addi $t9, $t9, 1	
	
gameMid2LeftUp:
	addi $t0, $t4, -1	# check if theres a up row
	blt $t0, $0, gameMid2LeftDown
	
	sub $s1, $s1, $s3
	addi $s1, $s1, -1
	lb $t8, 0($s1)
	add $s1, $s1, $s3	# reset row count
	add $s1, $s1, 1		# reset column count
	bne $t8, 49, gameMid2LeftDown
	addi $t9, $t9, 1
	
gameMid2LeftDown:
	addi $t0, $t4, 1
	bge $t0, $s4, gameMid2Right
	
	add $s1, $s1, $s3
	addi $s1, $s1, -1	# sub row and column to get the neighbouring locaiton
	lb $t8, 0($s1)
	sub $s1, $s1, $s3	# reset to row count again
	addi $s1, $s1, 1	# reset column
	bne $t8, 49, gameMid2Right
	addi $t9, $t9, 1
	
gameMid2Right:
	addi $t0, $t3, 1
	bge $t0, $s3, gameMid2Up	# if not right column then all right/rightup/rightdown will be empty 
	
	addi $s1, $s1, 1
	lb $t8, 0($s1)
	addi $s1, $s1, -1
	bne $t8, 49, gameMid2RightUp
	addi $t9, $t9, 1	
	
gameMid2RightUp:
	addi $t0, $t4, -1	# check if theres a up row
	blt $t0, $0, gameMid2RightDown
	
	sub $s1, $s1, $s3
	add $s1, $s1, 1
	lb $t8, 0($s1)
	add $s1, $s1, -1
	add $s1, $s1, $s3	# reset row count
	bne $t8, 49, gameMid2RightDown
	addi $t9, $t9, 1

gameMid2RightDown:
	addi $t0, $t4, 1
	bge $t0, $s4, gameMid2Up
	
	add $s1, $s1, $s3
	addi $s1, $s1, 1
	lb $t8, 0($s1)
	sub $s1, $s1, $s3	# reset to row count again
	addi $s1, $s1, -1	# reset column
	bne $t8, 49, gameMid2Up
	addi $t9, $t9, 1
	
gameMid2Up:
	addi $t0, $t4, -1	# check if theres a up row
	blt $t0, $0, gameMid2Down
	
	sub $s1, $s1, $s3
	lb $t8, 0($s1)
	add $s1, $s1, $s3
	bne $t8, 49, gameMid2Down
	addi $t9, $t9, 1

gameMid2Down:
	addi $t0, $t4, 1	# check if theres a down row
	bge $t0, $s4, gameMid3
	
	add $s1, $s1, $s3
	lb $t8, 0($s1)
	sub $s1, $s1, $s3
	bne $t8, 49, gameMid3
	addi $t9, $t9, 1

gameMid3:
	lb $t8, 0($s1)
	beq $t8, 48, dCell	# if 0 then its a dead cell
	j lCell	# else its a live cell

lCell:
	blt $t9, 2, addDead	# if there are less than 2 or more than 3 neighbours, then the cell dies, add 0 to the location
	bgt $t9, 3, addDead
	j addLive	# else add 1
	
dCell:
	beq $t9, 3, addLive	# if exactly 3 neighbours, cell reborn
	j addDead	# else the cell stay dead

addLive:	# add 1 to location
	li $t8, 49
	sb $t8, 0($s2)
	j gameEnd1

addDead:	# add 0 to location
	li $t8, 48
	sb $t8, 0($s2)
	j gameEnd1

gameEnd1:
	add $s2, $s2, 1
	addi $t3, $t3, 1	#increase column count
	bge $t3, $s3, gameEnd2	# if end of a row, increase row count and reset column count
	j gameMid2	# continue the normal loop

gameEnd2:
	add $t4, $t4, 1
	bge $t4, $s4, gameEnd3	# if also end of row simulation of one generation is complete
	j gameMid1

gameEnd3:
	addi $s0, $s0, -1	# decrease generation counter
	bge $s0, 1, gameSwap	# if still has next gen to simulate, then reset variables, swap buffers and continue the loop
	move $v0, $s7	# if end of simulation, add the newest gen buffer to v0
	jr $ra
	
	
###########
# write the newly acquired simulation result to an output file
writeData1:
	move $s0, $a0
	move $s1, $a1
	
	# create and open an output file
	li $v0, 13
#	la $a0, outputFileName
	li $a1, 1
	li $a2, 0
	syscall
	
	move $a0, $v0
	li $t4, 0	# row counter
	
writeData2:
	beq $t4, $s4, writeData3	# if end of buffer no more data then close file
	li $v0, 15
	move $a1, $s1
	move $a2, $s3	# read # of column bytes to the file
	syscall
		
	li $v0, 15	# add new line character to the end of each row
	la $a1, NEWLINE
	li $a2, 1
	syscall
	
	addi $t4, $t4, 1
	add $s1, $s1, $s3	# increase # of column of bytes to get to the next line of data
	j writeData2

writeData3:
	li $v0, 16	# close file
	syscall
	
	jr $ra		# return
	
# TODO END

########### Helper functions for IO ###########

# read an integer
# int readInt()
readInt:
	li $v0, 5
	syscall
	jr $ra
