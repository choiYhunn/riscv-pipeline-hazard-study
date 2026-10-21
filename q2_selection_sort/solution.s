.data
N:     .word 10              # Number of elements in the array
Array: .word 16, 23, 7, 45, 4, 56, 33, 12, 38, 2
str:   .string "Selection Sorted: "
space: .string " "

.text
.globl main
main:
    lw s0, N                 # Load N to s0
    la s2, Array             # Load address of Array to s2
    li a1, 0                 # i = 0

outer_loop:
    addi t5, s0, -1          # t5 = N - 1
    slt  t0, a1, t5          # t0 = (i < N-1) ? 1 : 0
    beq  t0, zero, printResult # if i >= N-1, exit

    # ---- blank (1): init min_idx and cache Array[min_idx]; precompute &Array[j] ----
    mv   a3, a1              # min_idx = i
    addi a2, a1, 1           # j = i + 1
    slli t1, a3, 2           # byte offset of Array[min_idx]
    add  t1, s2, t1          # t1 = &Array[min_idx]
    lw   t2, 0(t1)           # t2 = Array[min_idx]  (running min value)
    slli t3, a2, 2           # byte offset of Array[j]
    add  t3, s2, t3          # t3 = &Array[j]

inner_loop:
    slt  t0, a2, s0          # t0 = (j < N) ? 1 : 0
    beq  t0, zero, do_swap   # if j >= N, exit inner

    # ---- blank (2): load Array[j]; advance the pointer to space the load-use ----
    lw   t4, 0(t3)           # t4 = Array[j]
    addi t3, t3, 4           # advance &Array[j] now, so t4's consumer is not back-to-back
                             #   with the load (load-use hazard spacing)

    slt  t0, t4, t2          # t0 = (Array[j] < Array[min_idx]) ? 1 : 0
    beq  t0, zero, skip_update # if Array[j] >= Array[min_idx], skip

    mv   a3, a2              # min_idx = j
    mv   t2, t4              # update min value cache

skip_update:
    addi a2, a2, 1           # j++
    j    inner_loop

do_swap:
    # ---- blank (3): swap Array[i] and Array[min_idx] via memory ----
    slli t1, a1, 2           # &Array[i]
    add  t1, s2, t1
    slli t6, a3, 2           # &Array[min_idx]
    add  t6, s2, t6
    lw   t5, 0(t1)           # t5 = Array[i]
    sw   t2, 0(t1)           # Array[i]       = min value (t2)
    sw   t5, 0(t6)           # Array[min_idx] = old Array[i] (t5)

    addi a1, a1, 1           # i++
    j    outer_loop

printResult:
    la a0, str
    li a7, 4
    ecall                    # Print the string "Selection Sorted: "

print_array:
    li s1, 10                # s1 = counter for elements to print
    la s2, Array             # s2 = address of Array

print_loop:
    beqz s1, end             # If s1 is 0, we are done printing
    lw a0, 0(s2)             # Load the next word from Array to a0
    li a7, 1
    ecall                    # Print integer
    la a0, space
    li a7, 4
    ecall                    # Print space
    addi s2, s2, 4           # Move to the next integer in array
    addi s1, s1, -1          # Decrement counter
    j print_loop             # Repeat print_loop

end:
    li a7, 10
    ecall                    # Exit the program
