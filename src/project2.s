###########################################################################
# Upper bound constants for static memory reservation
###########################################################################
.equ CONST_DIMENSION 4
.equ CONST_BUFFER_SIZE 1024
.equ CONST_MAX_VOCAB_TOKENS 100
.equ CONST_MAX_INPUT_TOKENS 10

###########################################################################
# System call constants
###########################################################################
.equ CONST_SYSCALL_PRINT_INT 1
.equ CONST_SYSCALL_PRINT_STRING 4
.equ CONST_SYSCALL_PRINT_CHAR 11
.equ CONST_SYSCALL_EXIT 10
.equ CONST_SYSCALL_EXIT2 93
.equ CONST_SYSCALL_OPEN 1024
.equ CONST_SYSCALL_CLOSE 57
.equ CONST_SYSCALL_READ 63
.equ CONST_SYSCALL_WRITE 64

###########################################################################
# ASCII character constants
###########################################################################
.equ CONST_CHAR_EOF 0
.equ CONST_CHAR_SPACE 32
.equ CONST_CHAR_NEWLINE 10
.equ CONST_CHAR_HYPHEN 45
.equ CONST_CHAR_ZERO 48

.data
###########################################################################
# Data section with static memory reservations.
# Feel free to add more if needed.
###########################################################################
VOCABULARY_FILENAME:     .string "vocab.txt"
EMBEDDINGS_FILENAME:     .string "embeddings.txt"
INPUT_FILENAME:          .string "input.txt"

W_Q_FILENAME:            .string "W_Q.txt"
W_K_FILENAME:            .string "W_K.txt"
W_V_FILENAME:            .string "W_V.txt"

VOCAB_BUFFER:            .zero CONST_BUFFER_SIZE                              # Contents of the vocabulary file
INPUT_BUFFER:            .zero CONST_BUFFER_SIZE                              # Contents of the input file
MATRIX_BUFFER:           .zero CONST_BUFFER_SIZE                              # Contents of a matrix file (used for W_Q, W_K, W_V, and embeddings)

INPUT_INDICES_VECTOR:    .zero (CONST_MAX_INPUT_TOKENS * 4)                   # Vector of input token indices (#inputs x 4 bytes)
SCORES_VECTOR:           .zero (CONST_MAX_INPUT_TOKENS * 4)                   # Vector of scores (#tokens x 4 bytes)

INPUT_TOTAL_TOKENS:      .word 0                                              # Number of tokens in the input
VOCAB_TOTAL_TOKENS:      .word 0                                              # Number of tokens in the vocabulary

VOCAB_EMBEDDINGS_MATRIX: .zero (CONST_MAX_VOCAB_TOKENS * CONST_DIMENSION * 4) # Embedding matrix (#tokens x dimension x 4 bytes)
INPUT_EMBEDDINGS_MATRIX: .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # Embedding matrix (#tokens x dimension x 4 bytes)
W_Q_MATRIX:              .zero (CONST_DIMENSION * CONST_DIMENSION * 4)        # W_Q matrix (dimension x dimension x 4 bytes)
W_K_MATRIX:              .zero (CONST_DIMENSION * CONST_DIMENSION * 4)        # W_K matrix (dimension x dimension x 4 bytes)
W_V_MATRIX:              .zero (CONST_DIMENSION * CONST_DIMENSION * 4)        # W_V matrix (dimension x dimension x 4 bytes)
Q_MATRIX:                .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # Q matrix (#tokens x dimension x 4 bytes)
K_MATRIX:                .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # K matrix (#tokens x dimension x 4 bytes)
V_MATRIX:                .zero (CONST_MAX_INPUT_TOKENS * CONST_DIMENSION * 4) # V matrix (#tokens x dimension x 4 bytes)

.text
main:
    ###########################################################################
    # Read vocabulary 
    ###########################################################################
    la a0, VOCABULARY_FILENAME # a0 = filename address of vocabulary
    la a1, VOCAB_BUFFER        # a1 = destination buffer for file contents
    li a2, CONST_BUFFER_SIZE   # a2 = maximum number of bytes to read (1024)
    jal ra, read_file

    ###########################################################################
    # Read input
    ###########################################################################
    la a0, INPUT_FILENAME      # a0 = filename address of input sentence
    la a1, INPUT_BUFFER        # a1 = destination buffer
    li a2, CONST_BUFFER_SIZE   # a2 = maximum number of bytes to read
    jal ra, read_file

    ###########################################################################
    # Read W_Q matrix
    ###########################################################################
    la a0, W_Q_FILENAME        # a0 = filename address of W_Q
    la a1, MATRIX_BUFFER       # a1 = shared temporary matrix buffer
    li a2, CONST_BUFFER_SIZE   # a2 = maximum number of bytes to read
    jal ra, read_file

    ###########################################################################
    # Parse W_Q matrix from buffer
    ###########################################################################
    la a0, W_Q_MATRIX          # a0 = destination matrix for W_Q integers
    la a1, MATRIX_BUFFER       # a1 = source text buffer
    jal ra, parse_matrix_buffer

    ###########################################################################
    # Read W_K matrix
    ###########################################################################
    la a0, W_K_FILENAME        # a0 = filename address of W_K
    la a1, MATRIX_BUFFER       # a1 = shared temporary matrix buffer
    li a2, CONST_BUFFER_SIZE   # a2 = maximum number of bytes to read
    jal ra, read_file

    ###########################################################################
    # Parse W_K matrix from buffer
    ###########################################################################
    la a0, W_K_MATRIX          # a0 = destination matrix for W_K integers
    la a1, MATRIX_BUFFER       # a1 = source text buffer
    jal ra, parse_matrix_buffer

    ###########################################################################
    # Read W_V matrix
    ###########################################################################
    la a0, W_V_FILENAME        # a0 = filename address of W_V
    la a1, MATRIX_BUFFER       # a1 = shared temporary matrix buffer
    li a2, CONST_BUFFER_SIZE   # a2 = maximum number of bytes to read
    jal ra, read_file

    ###########################################################################
    # Parse W_V matrix from buffer
    ###########################################################################
    la a0, W_V_MATRIX          # a0 = destination matrix for W_V integers
    la a1, MATRIX_BUFFER       # a1 = source text buffer
    jal ra, parse_matrix_buffer

    ###########################################################################
    # Read embeddings matrix
    ###########################################################################
    la a0, EMBEDDINGS_FILENAME # a0 = filename address of embeddings
    la a1, MATRIX_BUFFER       # a1 = shared temporary matrix buffer
    li a2, CONST_BUFFER_SIZE   # a2 = maximum number of bytes to read
    jal ra, read_file

    ###########################################################################
    # Parse vocabulary embeddings matrix from buffer
    ###########################################################################
    la a0, VOCAB_EMBEDDINGS_MATRIX # a0 = destination matrix for vocabulary embeddings
    la a1, MATRIX_BUFFER       # a1 = source text buffer
    jal ra, parse_matrix_buffer
    la t0, VOCAB_TOTAL_TOKENS  # t0 = address of VOCAB_TOTAL_TOKENS variable
    sw a1, 0(t0)               # store the number of vocabulary tokens

    ###########################################################################
    # Convert input tokens to indices
    ###########################################################################
    la a0, INPUT_INDICES_VECTOR  # a0 = output vector of vocabulary indices
    la a2, INPUT_BUFFER        # a2 = input sentence buffer
    la a3, VOCAB_BUFFER        # a3 = vocabulary buffer
    jal ra, tokens_to_indices
    la t0, INPUT_TOTAL_TOKENS  # t0 = address of INPUT_TOTAL_TOKENS variable
    sw a1, 0(t0)               # store the number of input tokens

    ###########################################################################
    # Build input embeddings matrix
    ###########################################################################
    la a0, INPUT_EMBEDDINGS_MATRIX # a0 = output embedding matrix E (n_tokens x 4)
    la a1, VOCAB_EMBEDDINGS_MATRIX # a1 = full vocabulary embedding matrix
    la a2, INPUT_INDICES_VECTOR    # a2 = array of token indices into the vocabulary
    la t0, INPUT_TOTAL_TOKENS
    lw a3, 0(t0)                   # a3 = number of input tokens
    jal ra, build_input_embeddings_matrix

    ###########################################################################
    # Build matrix Q
    ###########################################################################
    la a0, Q_MATRIX            # a0 = output Q matrix
    la a1, INPUT_EMBEDDINGS_MATRIX # a1 = E matrix (left operand)
    la t0, INPUT_TOTAL_TOKENS
    lw a2, 0(t0)               # a2 = number of rows of E (= number of tokens)
    li a3, CONST_DIMENSION     # a3 = number of columns of E (= 4)
    la a4, W_Q_MATRIX          # a4 = W_Q matrix (right operand)
    li a5, CONST_DIMENSION     # a5 = number of rows of W_Q (= 4)
    li a6, CONST_DIMENSION     # a6 = number of columns of W_Q (= 4)
    jal ra, matrix_multiply

    ###########################################################################
    # Build matrix K
    ###########################################################################
    la a0, K_MATRIX            # a0 = output K matrix
    la a1, INPUT_EMBEDDINGS_MATRIX # a1 = E matrix (left operand)
    la t0, INPUT_TOTAL_TOKENS
    lw a2, 0(t0)               # a2 = number of rows of E
    li a3, CONST_DIMENSION     # a3 = number of columns of E
    la a4, W_K_MATRIX          # a4 = W_K matrix (right operand)
    li a5, CONST_DIMENSION     # a5 = number of rows of W_K
    li a6, CONST_DIMENSION     # a6 = number of columns of W_K
    jal ra, matrix_multiply

    ###########################################################################
    # Build matrix V
    ###########################################################################
    la a0, V_MATRIX            # a0 = output V matrix
    la a1, INPUT_EMBEDDINGS_MATRIX # a1 = E matrix (left operand)
    la t0, INPUT_TOTAL_TOKENS
    lw a2, 0(t0)               # a2 = number of rows of E
    li a3, CONST_DIMENSION     # a3 = number of columns of E
    la a4, W_V_MATRIX          # a4 = W_V matrix (right operand)
    li a5, CONST_DIMENSION     # a5 = number of rows of W_V
    li a6, CONST_DIMENSION     # a6 = number of columns of W_V
    jal ra, matrix_multiply

    ###########################################################################
    # Compute scores for the last input token
    ###########################################################################
    la a0, SCORES_VECTOR       # a0 = output scores vector
    la a1, Q_MATRIX            # a1 = Q matrix
    la a2, K_MATRIX            # a2 = K matrix
    la t0, INPUT_TOTAL_TOKENS
    lw a3, 0(t0)               # a3 = number of tokens (= number of rows in Q and K)
    li a4, CONST_DIMENSION     # a4 = vector dimension (number of columns)
    addi a5, a3, -1            # a5 = index of the last token (n-1)
    jal ra, compute_scores
    
    ###########################################################################
    # Get the highest score index using argmax
    ###########################################################################
    la a1, SCORES_VECTOR       # a1 = scores vector computed in the previous step
    la t0, INPUT_TOTAL_TOKENS
    lw a2, 0(t0)               # a2 = number of elements in the scores vector
    jal ra, argmax

    ###########################################################################
    # Select chosen vector in V using the index from argmax
    ###########################################################################
    mv a4, a1                  # a4 = row index to select from V (result of argmax)
    la a1, V_MATRIX            # a1 = address of V matrix
    la t0, INPUT_TOTAL_TOKENS
    lw a2, 0(t0)               # a2 = number of rows in V
    li a3, CONST_DIMENSION     # a3 = number of columns (dimension = 4)
    jal ra, select_vector_in_matrix # a0 = pointer to V[a4]

    ###########################################################################
    # Pick the next token in the vocabulary with the highest score
    ###########################################################################
    la a1, VOCAB_EMBEDDINGS_MATRIX # a1 = full vocabulary embedding matrix
    la t0, VOCAB_TOTAL_TOKENS
    lw a2, 0(t0)               # a2 = total number of vocabulary tokens
    jal ra, decide_next_token  # a0 = index of the predicted next token
    
    ###########################################################################
    # Print the predicted token
    ###########################################################################
    la a1, VOCAB_BUFFER        # a1 = vocabulary text buffer
    jal ra, search_word        # a0 = token index (carried over from decide_next_token)
    
    ###########################################################################
    # Terminate program successfully
    ###########################################################################
    li a0, 0                   # a0 = exit code 0 (success)
    j exit_with_code           # Exit with code 0


# Read from a text file into a buffer.
# (in)     a0: filename address (char*)
# (in/out) a1: destination buffer
# (in)     a2: maximum number of bytes to read
read_file:
    mv t0, a1                  # Save destination buffer (a1) in t0       
    mv t1, a2                  # Save max number of bytes (a2) in t1
    
    li a7, CONST_SYSCALL_OPEN  # System call 1024 (a7) to open the file
    li a1, 0                   # Flag a1 = 0 (read only)
    ecall                      # Open file

    mv a2, t1                  # a2 = max number of bytes
    mv a1, t0                  # a1 = destination buffer
    mv t0, a0                  # Save file descriptor in t0
    li a7, CONST_SYSCALL_READ  # System call 63 (a7) to read the file
    ecall                      # Read file               

    li a7, CONST_SYSCALL_CLOSE # System call 57 (a7) to close the file 
    mv a0, t0                  # a0 = file descriptor 
    ecall 
    ret


# Parses a text buffer of space-separated signed integers and writes the 
# resulting integers into a flat memory array.
# Assumes the matrix is stored in the buffer as space-separated integers.
# Assumes columns are separated by 1 space (' '), and rows by 1 newline ('\n').
# Assumes only signed integers are provided.
# (in/out) a0: address of the matrix to fill (int*)
# (out)    a1: number of rows in the matrix (int)
# (in)     a1: address of the buffer containing the matrix data (char*)
parse_matrix_buffer:
    mv t0, a1                 # t0 = buffer pointer (current position in text buffer)
    mv t1, x0                 # t1 = row counter
    mv t2, x0                 # t2 = current number accumulator

check_signal:
    lb t3, 0(t0)              # Load current character
    li t4, CONST_CHAR_HYPHEN  # t4 = '-' (45)
    mv t5, x0                 # t5 = sign flag (0 = positive, 1 = negative)
    bne t3, t4, read_chars    # If not '-', start reading digits
    li t5, 1                  # Set sign flag to negative
    addi t0, t0, 1            # Advance buffer pointer past '-'

read_chars:
    lb t3, 0(t0)              # Load current character
    beqz t3, read_chars_end   # If '\0' (EOF), finish
    li t4, CONST_CHAR_SPACE   # t4 = ' ' (32)
    beq t3, t4, see_signal    # If space, current number is complete
    li t4, CONST_CHAR_NEWLINE # t4 = '\n' (10)
    beq t3, t4, new_line      # If newline, current number is complete and row ends
    li t4, CONST_CHAR_ZERO    # t4 = '0' (48)
    sub t3, t3, t4            # Convert ASCII digit to integer
    li t4, 10
    mul t2, t2, t4            # accumulator = accumulator * 10
    add t2, t2, t3            # accumulator = accumulator + digit
    addi t0, t0, 1            # Advance buffer pointer
    j read_chars              # Process next character

new_line:
    addi t1, t1, 1            # Increment row counter

see_signal:
    beq t5, x0, save_number   # If positive, skip negation
    sub t2, x0, t2            # Negate accumulator

save_number:
    sw t2, 0(a0)              # Store integer in output matrix
    mv t2, x0                 # Reset accumulator for next number
    addi a0, a0, 4            # Advance output matrix pointer
    addi t0, t0, 1            # Advance buffer pointer past separator
    j check_signal            # Process next number

read_chars_end:
    mv a1, t1                 # Return number of rows in a1
    jr ra                     # Return to caller
    

# Check if 2 words are the same
# (in) a0: pointer to input word
# (in) a1: pointer to vocab word
# (out) a0: success/error code
word_match_loop:
    lb t0, 0(a0)              # load current char from input
    lb t1, 0(a1)              # load current char from vocab
    li t2, CONST_CHAR_NEWLINE

    beq t0, t2, word_match_check_end    # input char in '\n' -> word ended, check if vocab ended too
    bne t0, t1, word_match_error        # input char != vocab char -> error
    
    addi a0, a0, 1            # next char from input
    addi a1, a1, 1            # next char from vocab
    j word_match_loop

word_match_check_end:
    bne t1, t2, word_match_error  # input ended but vocab not -> words don't match
    mv a1, a0                 # returns in a1 the input pointer ('\n')
    li a0, 1                  # if they match, load success code to a0
    ret

word_match_error:
    li a0, 0                  # no match -> load error code 0 to a0
    ret


# Converts the input tokens into their corresponding indices in the vocabulary.
# (in/out) a0: address of input indices vector to fill (int*)
# (in/out) a1: size of input indices vector (number of tokens in input)/pointer end of input
# (in)     a2: address to input buffer
# (in)     a3: address to vocabulary buffer
tokens_to_indices:
    addi sp, sp, -16          # allocate stack space
    sw ra, 0(sp)              # save return adress
    sw s1, 4(sp)              # save s1 (vocab start)
    sw s2, 8(sp)              # save s2 (current input word start)
    sw s3, 12(sp)             # save s3 (output vector pointer)
    
    mv s3, a0                 # s3 points to the output vector
    li t5, 0                  # int vocab_line = 0 
    li t6, 0                  # int word_count = 0
    mv s1, a3                 # save vocab start (never changes)

tokens_to_indices_input_loop:
    lb t0, 0(a2)              # load first char of current input word
    beq t0, x0, tokens_to_indices_end   # if char is '\0' input ended -> break
    mv s2, a2                 # save current input word start
    mv a3, s1                 # reset vocab pointer
    li t5, 0                  # reset vocab line counter

tokens_to_indices_vocab_loop_start:
    mv a0, s2                 # word_match needs a0 as input word pointer
    mv a1, a3                 # word_match needs a1 as vocab word pointer

    jal word_match_loop       # call word_match function

    mv t2, a0                 # save word_match result to t2
    mv t0, a1                 # t0 now points to the end of input word returned by word_match
    
    bne t2, x0, tokens_to_indices_word_found # if word_match return != 0 -> match

    mv t1, a3                 # if vocab word pointer stopped at the middle -> reset t1 to the start of vocab word

tokens_to_indices_skip_word:
    lb t3, 0(t1)              # load char from the vocab word
    addi t1, t1, 1            # increase pointer before comparison (next word is '\n' + 1)
    li t4, CONST_CHAR_NEWLINE                # t4 = '\n' (for comparison)
    bne t3, t4, tokens_to_indices_skip_word  # while t3 (char) != '\n' continue

    mv a3, t1                 # update a3 to the start of next vocab word
    addi t5, t5, 1            # vocab_line ++ (1 word = 1 line)
    j tokens_to_indices_vocab_loop_start

tokens_to_indices_word_found:
    sw t5, 0(s3)              # store word vocab line on the output vector
    addi s3, s3, 4            # point a0 to the next number
    addi a2, t0, 1            # t0 points to '\n' next input word is '\n' + 1
    addi t6, t6, 1            # word count ++
    j tokens_to_indices_input_loop  # try word match with the next input word

tokens_to_indices_end:
    mv a1, t6                 # return number of tokens (words) found
    lw ra, 0(sp)              # restore return address
    lw s1, 4(sp)              # restore s1
    lw s2, 8(sp)              # restore s2
    lw s3, 12(sp)             # restore s3
    addi sp, sp, 16           # free stack space
    ret
    

# Builds the input embedding matrix E: for each index in the input indices array,
# copies the corresponding row from the vocabulary embedding matrix into the output.
# The result is a matrix of shape n_tokens x CONST_DIMENSION.
# (in/out) a0: address of the output matrix to fill (int*)
# (in)     a1: address of the vocabulary embeddings matrix (int*)
# (in)     a2: address of the input indices array (int*)
# (in)     a3: number of tokens in the input (int)
build_input_embeddings_matrix:
    mv t0, x0                 # t0 = token counter (i = 0)
    
build_loop1:
    mv t1, a1                 # t1 = base address of vocab embeddings matrix
    lw t2, 0(a2)              # t2 = current input index
    li t3, CONST_DIMENSION    # t3 = 4 (number of columns)
    mul t2, t2, t3            # t2 = index * 4 (number of elements to skip)
    slli t2, t2, 2            # t2 = index * 4 * 4 (number of bytes to skip)
    add t1, t1, t2            # t1 = address of the correct row in vocab embeddings matrix
    mv t4, x0                 # t4 = column counter (j = 0)

build_loop2:
    lw t2, 0(t1)              # t2 = current element of vocab embeddings matrix
    sw t2, 0(a0)              # Store element in output matrix
    addi a0, a0, 4            # Advance output matrix pointer
    addi t1, t1, 4            # Advance vocab embeddings matrix pointer
    addi t4, t4, 1            # j++
    bne t4, t3, build_loop2   # If j != 4, continue copying row

    addi t0, t0, 1            # i++
    addi a2, a2, 4            # Advance input indices pointer
    bne t0, a3, build_loop1   # If i != num_tokens, process next token

    jr ra                     # Return to caller
    

# Multiplies two matrices and stores the result in the output matrix.
# (in/out) a0: address of the output matrix to fill (int*)
# (in)     a1: address of the first matrix (int*)
# (in)     a2: #rows of the first matrix (int)
# (in)     a3: #columns of the first matrix (int)
# (in)     a4: address of the second matrix (int*)
# (in)     a5: #rows of the second matrix (int)
# (in)     a6: #columns of the second matrix (int)
matrix_multiply:
    mv t0, x0                 # accumulator of dot products
    mv t1, x0                 # t1 = row counter i = 0

for_i:
    mv t2, x0                 # t2 = column counter j = 0

for_j:
    mv t3, x0                 # t3 = element counter k = 0
    
for_k:
    # address of E[i][k] = a1 + i * a3 * 4 + k * 4
    slli t4, a3, 2            # t4 = a3 * 4 (row size in bytes)
    mul t4, t4, t1            # t4 = i * a3 * 4
    slli t5, t3, 2            # t5 = k * 4
    add t4, t5, t4            # t4 = i * a3 * 4 + k * 4
    add t4, a1, t4            # t4 = address of E[i][k]
    lw t4, 0(t4)              # t4 = E[i][k]
    
    # address of W[k][j] = a4 + k * a6 * 4 + j * 4
    slli t5, a6, 2            # t5 = a6 * 4 (row size in bytes)
    mul t5, t3, t5            # t5 = k * a6 * 4
    slli t6, t2, 2            # t6 = j * 4
    add t5, t5, t6            # t5 = k * a6 * 4 + j * 4
    add t5, a4, t5            # t5 = address of W[k][j]
    lw t5, 0(t5)              # t5 = W[k][j]
    
    mul t4, t4, t5            # t4 = E[i][k] * W[k][j]
    add t0, t0, t4            # accumulator += E[i][k] * W[k][j]
    
    addi t3, t3, 1            # k++
    bne t3, a3, for_k         # If k != num_cols_E, continue
    
    sw t0, 0(a0)              # Store result in output matrix C[i][j]
    addi a0, a0, 4            # Advance output matrix pointer
    mv t0, x0                 # Reset accumulator
    
    addi t2, t2, 1            # j++
    bne t2, a6, for_j         # If j != num_cols_W, continue
    
    addi t1, t1, 1            # i++
    bne t1, a2, for_i         # If i != num_rows_E, continue

    jr ra                     # Return to caller
    

# Computes the attention scores for the target token: for each position j, calculates
# score(j) = Q[a5].K[j] via dot product and writes the result to the output vector.
# (in/out) a0: address of the output scores vector to fill (int*)
# (in)     a1: address of Q matrix (int*)
# (in)     a2: address of K matrix (int*)
# (in)     a3: #rows of Q and K (int)
# (in)     a4: #columns of Q and K (int)
# (in)     a5: target token index for which we want to compute the score (int)
compute_scores:
    addi sp, sp, -28          # allocate stack space
    sw ra, 0(sp)              # save return address 
    sw s0, 4(sp)              # save s0 (j)
    sw s1, 8(sp)              # save s1 (output vector)
    sw s2, 12(sp)             # save s2 (pointer to Q[a5])
    sw s3, 16(sp)             # save s3 (pointer to copy of a2 - K matrix)
    sw s4, 20(sp)             # save s4 (copy of a3 - number of rows)
    sw s5, 24(sp)             # save s5 (copy of a4 - number of columns)

    mv s0, x0                 # int j = 0
    mv s1, a0                 # copy a0 to s1 to manipulate it
    mv s3, a2                 # copy a2 to s3
    mv s4, a3                 # copy a3 to s4
    mv s5, a4                 # copy a4 to s5

    # find Q[n-1] (Q[a5])
    mul t1, a5, a4            # jump a5 index * num of column numbers in matrix
    slli t1, t1, 2            # each number is 4 bytes
    add s2, t1, a1            # s2 = pointer to Q[a5]

compute_scores_loop:
    beq s0, s4, compute_scores_loop_end # if (j == number of rows) break

    # find K[j] for each j
    mul t2, s0, s5            # jump j index * num of column numbers in matrix
    slli t2, t2, 2            # each number is 4 bytes
    add a2, t2, s3            # a2 = pointer to K[j] - dot needs a2 as 2nd vector
    
    mv a1, s2                 # dot needs a1 as 1st vector (Q[n-1])
    mv a3, s5                 # dot needs a3 as number of columns

    jal dot                   # call dot function

    sw a1, 0(s1)              # write a1 (dot product) on the vector s1
    addi s1, s1, 4            # point s1 to the next number
    addi s0, s0, 1            # j++

    j compute_scores_loop

compute_scores_loop_end:
    lw ra, 0(sp)              # restore ra from the stack
    lw s0, 4(sp)              # restore s0 from the stack
    lw s1, 8(sp)              # restore s1 from the stack
    lw s2, 12(sp)             # restore s2 from the stack
    lw s3, 16(sp)             # restore s3 from the stack
    lw s4, 20(sp)             # restore s4 from the stack
    lw s5, 24(sp)             # restore s5 from the stack
    addi sp, sp, 28           # free stack space
    
    ret


# Returns a pointer to the row at index a4 in a flat row-major matrix.
# (out) a0: address of the selected vector (int*)
# (in)  a1: address of matrix (int*)
# (in)  a2: #rows (int)
# (in)  a3: #cols (int)
# (in)  a4: target row
select_vector_in_matrix:
    mul t0, a4, a3            # Jump a4 index * number of column numbers in matrix   
    slli t0, t0, 2            # Each number = 4 bytes
    add a0, a1, t0            # a0 points to the adress of the selected array
    ret


# Compares the target vector against every vocabulary embedding using dot products
# and returns the index of the most similar token.
# (out) a0: index of the predicted token in the vocabulary (int)
# (in)  a0: address of target vector (int*)
# (in)  a1: vocabulary embeddings address (int*)
# (in)  a2: number of tokens in vocabulary (int)
decide_next_token:
    addi sp, sp, -28          # Reserve space on the stack
    sw ra, 0(sp)              # Save return address on the stack
    sw s0, 4(sp)              # Save s0 on the stack
    sw s1, 8(sp)              # Save s1 on the stack
    sw s2, 12(sp)             # Save s2 on the stack
    sw s3, 16(sp)             # Save s3 on the stack
    sw s4, 20(sp)             # Save s4 on the stack
    sw s5, 24(sp)             # Save s5 on the stack

    mv s0, a0                 # s0 = address of target vector
    mv s1, a1                 # s1 = address of vocabulary embeddings
    mv s2, a2                 # s2 = number of tokens in vocabulary
    mv s3, x0                 # s3 = loop counter (i = 0)
    li s4, -2147483648        # s4 = smallest 32-bit integer (initial best score)
    mv s5, x0                 # s5 = index of best token (initialized to 0)
    
decide_next_token_loop:
    beq s3, s2, decide_next_token_loop_end  # If i == number of tokens, exit loop

    li t1, CONST_DIMENSION    # t1 = number of columns of the embeddings matrix

    mul t2, t1, s3            # t2 = number columns * counter 
    slli t2, t2, 2            # Each number = 4 bytes
    add t2, t2, s1            # t2 is the pointer to the matrix vector

    mv a1, s0                 # a1 = address of target vector
    mv a2, t2                 # a2 = address of token i's embedding vector
    mv a3, t1                 # a3 = number of columns of the embeddings matrix

    jal dot                   # Call dot; dot product result returned in a1

    mv t3, a1                 # t3 = computed dot product
    bgt t3, s4, decide_next_token_switch    # If new score > best score, update
    
decide_next_token_loop_continue: 
    addi s3, s3, 1            # i++
    j decide_next_token_loop                       

decide_next_token_switch:
    mv s4, t3                 # Update best score
    mv s5, s3                 # Save index of best token
    j decide_next_token_loop_continue

decide_next_token_loop_end:
    mv a0, s5                 # a0 = index of highest-scoring token(return value)

    lw ra, 0(sp)              # Restore return address from the stack
    lw s0, 4(sp)              # Restore s0 from the stack
    lw s1, 8(sp)              # Restore s1 from the stack
    lw s2, 12(sp)             # Restore s2 from the stack
    lw s3, 16(sp)             # Restore s3 from the stack
    lw s4, 20(sp)             # Restore s4 from the stack
    lw s5, 24(sp)             # Restore s5 from the stack
    addi sp, sp, 28           # Free stack space
    
    ret
    

# Scans the vocabulary text buffer, counting newlines until reaching the word at
# index a0, then calls print_predicted_token to print that word to the console.   
# (in) a0: index of the token in the vocabulary (int)
# (in) a1: address of vocabulary buffer
search_word:
    mv t0, a0                 # t0 = target index to reach
    mv a0, a1                 # a0 = current pointer into the vocabulary buffer (starts at beginning)
    mv t1, x0                 # t1 = counter of words already passed (current line number)
    li a2, CONST_CHAR_NEWLINE # a2 = '\n' (word separator)
    
    addi sp, sp, -4           # Reserve space on the stack
    sw ra, 0(sp)              # Save return address on the stack

search_word_loop:
    beq t1, t0, search_word_end  # if we have reached the target line, stop and print
    
    lb t2, 0(a0)              # load current character from the buffer
    beq t2, a2, new_word      # if it is '\n', we have passed into a new wor
    
    addi a0, a0, 1            # advance to the next character
    j search_word_loop

new_word:
    addi t1, t1, 1            # increment the word counter
    addi a0, a0, 1            # advance past the '\n' to the start of the next word
    j search_word_loop
    
search_word_end:
    jal ra, print_predicted_token  # print the word that a0 currently points to
    
    lw ra, 0(sp)              # Restore return address from the stack
    addi sp, sp, 4            # Free stack space
    jr ra                     # return to caller
    
    
#############################################################################################################
# Dot product and argmax helper functions.
#############################################################################################################

# (in)  a1: address of first vector (int*)
# (in)  a2: address of second vector (int*)
# (in)  a3: length of the vectors (int)
# (out) a0: status code (0 for success, non-zero for error)
# (out) a1: dot product result (int)
dot:
    addi sp, sp, -4
    sw ra, 0(sp)                                    # Save return address on the stack
    # Initialize the result and the loop index.
    mv t0, zero                                     # t0 will hold the result (dot product)
    mv t1, zero                                     # t1 will be our loop index
    # Let's see first if SIZE < 1, and jump to dot_end if that's the case.
    slti t2, a3, 1                                  # t2 = (SIZE < 1)
    beq t2, zero, dot_loop                          # If SIZE >= 1, we can proceed to the loop
    li a0, 50                                       # Set a0 to 50 to indicate an error (invalid size)
    j dot_end                                       # If SIZE < 1, jump to dot_end
dot_loop:
    beq t1, a3, dot_end_loop                        # If t1 == SIZE, we are done
    lw t2, 0(a1)                                    # Load A[t1] into t2
    lw t3, 0(a2)                                    # Load B[t1] into t3
    mul t4, t2, t3                                  # t4 = A[t1] * B[t1]
    # Check if the multiplication of A[t1] and B[t1] overflows
    mulh t5, t2, t3                                 # t5 = high 32 bits of A[t1] * B[t1] (signed)
    srai t6, t4, 31                                 # t6 = sign extension of low 32 bits (0 or -1)
    bne t5, t6, overflow                            # Overflow if high bits != sign extension of low bits
    mv t6, t0                                       # Store the current result in t6 for overflow checking
    add t0, t0, t4                                  # t0 += A[t1] * B[t1]
    # Check if the previous addition caused an overflow
    # Careful: adding negative numbers will correctly result in a negative number, so we need to check for overflow in both directions.
    bgt t6, zero, check_positive_overflow           # If previous result was positive, check for positive overflow
    blt t6, zero, check_negative_overflow           # If previous result was negative, check for negative overflow
    j dot_continue_loop
check_positive_overflow:
    blt t4, zero, dot_continue_loop                 # If we added a negative number, we can't have a positive overflow
    blt t0, zero, overflow                          # If t0 < 0 after adding a positive number, we have an overflow
    j dot_continue_loop
check_negative_overflow:
    bgt t4, zero, dot_continue_loop                 # If we added a positive number, we can't have a negative overflow
    bgt t0, zero, overflow                          # If t0 > 0 after adding a negative number, we have an overflow
    j dot_continue_loop
dot_continue_loop:
    addi a1, a1, 4                                  # Move to the next element in A
    addi a2, a2, 4                                  # Move to the next element in B
    addi t1, t1, 1                                  # t1++
    j dot_loop                                      # Repeat the loop
dot_end_loop:
    li a0, 0                                        # Set a0 to 0 to indicate success
    mv a1, t0                                       # Move the result into a1 for return
    j dot_end                                       # Jump to the end of the function
overflow:
    li a0, 200                                      # Set a0 to 200 to indicate an overflow error
    j dot_end                                       # Jump to the end of the function
dot_end:
    lw ra, 0(sp)                                    # Restore return address
    addi sp, sp, 4                                  # Deallocate stack space
    ret                                             # Return to the caller

# (in)  a1: pointer to int array
# (in)  a2: array length
# (out) a0: status code
# (out) a1: index of the largest element
argmax:
    # Get the index of the maximum value in A, which is of size SIZE.
    # The result will be stored in a0.
    # If here's a draw, return the smallest index among the maximum values.
    addi sp, sp, -4
    sw ra, 0(sp)                                    # Save return address on the stack
    # Initialize the max value and the index of the max value.
    lw t0, 0(a1)                                    # t0 will hold the max value
    mv t1, zero                                     # t1 will hold the index of the max value
    mv t2, zero                                     # t2 will be our loop index
    # Error checking first: if SIZE < 1, we should return 50 to indicate an error.
    slti t3, a2, 1                                  # t3 = (SIZE < 1)
    beq t3, zero, argmax_loop                       # if SIZE >= 1, we can proceed to the loop
    li a0, 50                                       # set a0 to 50 to indicate an error (invalid size)
    j argmax_end                                    # if SIZE < 1, jump to argmax_end
argmax_loop:
    # The actual loop logic.
    beq t2, a2, argmax_end_loop                     # if t2 == SIZE, we are done
    lw t3, 0(a1)                                    # load A[t2] into t3
    ble t3, t0, argmax_next                         # if A[t2] <= max_value, skip to next
    mv t0, t3                                       # max_value = A[t2]
    mv t1, t2                                       # index_of_max = t2
argmax_next:
    addi a1, a1, 4                                  # move to the next element in A
    addi t2, t2, 1                                  # t2++
    j argmax_loop                                   # repeat the loop
argmax_end_loop:
    mv a1, t1                                       # move the index of the max value into a1 for return
    li a0, 0                                        # set a0 to 0 to indicate success
argmax_end:
    lw ra, 0(sp)                                    # Restore return address
    addi sp, sp, 4                                  # Deallocate stack space
    ret                                             # return to the caller

exit_with_code:
    li a7, CONST_SYSCALL_EXIT2
    ecall

#############################################################################################################
# Helper functions for printing and debugging.
#############################################################################################################

.data
PRINT_HEADER_VOCABULARY:    .string "=== Vocabulary ==="
PRINT_HEADER_INPUT:         .string "=== Input ==="
PRINT_HEADER_INPUT_INDICES: .string "=== Input Indices ==="
PRINT_HEADER_MATRIX:        .string "=== Matrix ==="
PRINT_HEADER_SCORES:        .string "=== Scores ==="
PRINT_HEADER_NEXT_TOKEN:    .string "=== Decision ==="
PRINT_VECTOR_LB:            .string "[ "
PRINT_VECTOR_RB:            .string "]"

.text
# Prints a null-terminated string followed by a newline.
# (in) a0: buffer to print (char*)
println:
    li a7, CONST_SYSCALL_PRINT_STRING
    ecall
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    ret

# Prints the vocabulary buffer.
# (in) a0: address of the vocabulary buffer (char*)
print_vocabulary:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la a0, PRINT_HEADER_VOCABULARY
    jal println
    mv a0, s0
    jal println
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

# Prints the input buffer as a string.
# (in) a0: address of the input buffer (char*)
print_input:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la a0, PRINT_HEADER_INPUT
    jal println
    mv a0, s0
    jal println
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret

# Prints the input indices vector.
# (in) a0: address of the input indices vector (int*)
# (in) a1: size of the input indices vector (int)
print_indices:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    mv s0, a0
    mv s1, a1
    la a0, PRINT_HEADER_INPUT_INDICES
    jal println
    mv a0, s0
    mv a1, s1
    jal print_vector
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret

print_scores:
    addi sp, sp, -4
    sw ra, 0(sp)
    la a0, PRINT_HEADER_SCORES
    jal println
    la a0, SCORES_VECTOR
    lw a1, INPUT_TOTAL_TOKENS
    jal print_vector
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# a0: address of matrix to print (int*)
# a1: number of rows
# a2: number of columns
print_matrix:
    addi sp, sp, -24
    sw ra, 0(sp)                                    # return address
    sw s0, 4(sp)                                    # matrix pointer
    sw s1, 8(sp)                                    # row index
    sw s2, 12(sp)                                   # col index
    sw s3, 16(sp)                                   # number of rows
    sw s4, 20(sp)                                   # number of columns
    mv s0, a0                                       # s0 = pointer to matrix
    mv s3, a1                                       # s3 = number of rows
    mv s4, a2                                       # s4 = number of columns
    li s1, 0                                        # s1 = current row index
    la a0, PRINT_HEADER_MATRIX
    jal println
print_matrix_row_loop:
    beq s1, s3, print_matrix_done
    li s2, 0
print_matrix_col_loop:
    beq s2, s4, print_matrix_next_row
    lw a0, 0(s0)
    li a7, CONST_SYSCALL_PRINT_INT
    ecall
    addi s0, s0, 4
    addi s2, s2, 1
    li a0, CONST_CHAR_SPACE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    j print_matrix_col_loop
print_matrix_next_row:
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    addi s1, s1, 1
    j print_matrix_row_loop
print_matrix_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24
    ret

# a0: address of vector to print (int*)
# a1: number of elements (int)
print_vector:
    addi sp, sp, -8
    sw s0, 0(sp)
    sw s1, 4(sp)
    mv s0, a0                                       # s0 = pointer to vector
    mv s1, a1                                       # s1 = number of elements
    la a0, PRINT_VECTOR_LB                          # Print "[ "
    li a7, CONST_SYSCALL_PRINT_STRING
    ecall
print_vector_loop:
    beq s1, zero, print_vector_done
    lw a0, 0(s0)
    li a7, CONST_SYSCALL_PRINT_INT
    ecall
    li a0, CONST_CHAR_SPACE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    addi s0, s0, 4
    addi s1, s1, -1
    j print_vector_loop
print_vector_done:
    la a0, PRINT_VECTOR_RB                          # Print "]"
    li a7, CONST_SYSCALL_PRINT_STRING
    ecall
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    lw s0, 0(sp)
    lw s1, 4(sp)
    addi sp, sp, 8
    ret

# (in) a0: address of the predicted token (char*)
print_predicted_token:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la a0, PRINT_HEADER_NEXT_TOKEN
    jal println
    # s0 = start of target token, print it char by char until newline or null
print_predicted_token_char:
    lb t0, 0(s0)
    beq t0, zero, print_predicted_token_nl          # null terminator
    li t1, CONST_CHAR_NEWLINE
    beq t0, t1, print_predicted_token_nl            # newline terminator
    mv a0, t0
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    addi s0, s0, 1
    j print_predicted_token_char
print_predicted_token_nl:
    li a0, CONST_CHAR_NEWLINE
    li a7, CONST_SYSCALL_PRINT_CHAR
    ecall
    lw ra, 0(sp)
    lw s0, 4(sp)
    addi sp, sp, 8
    ret
