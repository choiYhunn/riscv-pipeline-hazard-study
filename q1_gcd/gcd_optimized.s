.data
str1:     .string "GCD of "
str2:     .string " and "
str3:     .string " is "
a_val:    .word 48
b_val:    .word 18

.text
.globl main
main:
        lw   a0, a_val        # a0 = a = 48
        lw   a1, b_val        # a1 = b = 18
        li   s2, 0            # s2 = iteration counter
        li   s3, 0            # s3 = sum accumulator (디버깅용)

gcd:
        li   t0, 0

loop:
        beq  a1, t0, done
        div  t1, a0, a1       
        addi s2, s2, 1        # 1. div-mul 사이 간격 벌리기 (1 Stall 은닉)
        mul  t2, t1, a1       
        # mul-sub 사이는 끼울 명령어가 없으므로 2 Stall 감수
        sub  t3, a0, t2       
        mv   a0, a1           # 2. sub-add 사이 간격 벌리기! (sub가 끝났으니 a0 갱신 안전)
        add  s3, s3, t3       # 1 Stall 은닉
        mv   a1, t3           
        j    loop

done:
        mv   s1, a0           # save GCD

printGcd:
        la   a0, str1
        li   a7, 4
        ecall
        lw   a0, a_val
        li   a7, 1
        ecall
        la   a0, str2
        li   a7, 4
        ecall
        lw   a0, b_val
        li   a7, 1
        ecall
        la   a0, str3
        li   a7, 4
        ecall
        mv   a0, s1
        li   a7, 1
        ecall
        li   a7, 10
        ecall