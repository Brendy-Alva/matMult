
.global matMult
.equ ws, 4

.text 

matMult:
    //how stack looks like
    #esp + 7 * ws: num_cols_b 
    #esp + 6 * ws: num_rows_b 
    #esp + 5 * ws: B
    #esp + 4 * ws: num_cols_a
    #esp + 3 * ws: num_rows_a 
    #esp + 2 * ws: A 
    #ebp + 1 * ws: return address
    #ebp + 0 * ws: old stack frame ptr
    #ebp - 1 * ws: C
    #ebp - 2 * ws: i
    #ebp - 3 * ws: j
    #ebp - 4 * ws: sum
    #ebp - 5 * ws: k
    #ebp - 6 * ws: old_ebx
    #ebp - 7 * ws: old_esi
    #ebp - 8 * ws: old_edi
    #ebp - 9 * ws: old_edx
    #ebp - 10 * ws: old_eax

    .equ A, (2 * ws) # (%ebp)
    .equ num_rows_a, (3 * ws) # (%ebp)
    .equ num_cols_a, (4 * ws) # (%ebp)
    .equ B, (5 * ws) # (%ebp)
    .equ num_rows_b, (6 * ws) # (%ebp)
    .equ num_cols_b, (7 * ws) # (%ebp)

    .equ C, (-1 * ws) # (%ebp)
    .equ i, (-2 * ws) # (%ebp)
    .equ j, (-3 * ws) # (%ebp)
    .equ sum, (-4 * ws) # (%ebp)
    .equ k, (-5 * ws) # (%ebp)
    .equ old_ebx, (-6 * ws) # (%ebp)
    .equ old_esi, (-7 * ws) # (%ebp)
    .equ old_edi, (-8 * ws) # (%ebp)

    .equ old_edx, (-9 * ws) # (%ebp)
    .equ old_eax, (-10 * ws) # (%ebp)

	.equ num_locals, 5 # C, i, j, sum, k
	.equ used_ebx, 1 
	.equ used_esi, 1
	.equ used_edi, 1
	.equ num_saved_registers, (used_ebx + used_esi + used_edi)

    prologue_start:
        push %ebp # save previous stack frame pointer
        movl %esp, %ebp # establish this functions stack frame
        //before calling need to save any local regs and make space for local vars
        subl $32, %esp #make space for locals and saved regs
        movl %ebx, -24(%ebp)
        movl %esi, -28(%ebp)
        movl %edi, -32(%ebp)
        #save any callee regs
    prologue_end:  


    #int  **C = (int**)malloc(num_rows_a, sizeof(int*));
    #1st do num_rows_a, sizeof(int*)
    movl 12(%ebp), %eax #eax = num_rows_a
    shll $2, %eax # eax = numrows_a * size(int*) same thing as doing eax * 4
    push %eax #to set malloc's arg
    call malloc
    addl $1 * ws, %esp # cleaning up malloc's arg

    movl %eax, C(%ebp) # C = eax aka malloc's return value

    # for(int i = 0; i < num_rows_a; ++i){
    movl $0, %ecx # i = 0
    malloc_for_start:
        #i < num_rows_a;
        #i - num_rows_a < 0
        #negaition: i - num_rows_a => 0
        cmpl num_rows_a(%ebp), %ecx # i - num_rows_a
        jge malloc_for_end
        #C[i]=(int*)malloc(num_cols_b, sizeof(int));
        #do this 1st (num_cols_b, sizeof(int))
        movl num_cols_b(%ebp), %edx #edx = num_cols_b
        shll $2, %edx # 4 * edx
        // save ecx i bc calling another f(x) and we are the caller
        movl %ecx, i(%ebp) #saving i
        push %edx
        call malloc
        #malloc will put return value in eax
        addl $1 * ws, %esp # cleaning up malloc's arg

        //need to restore ACD
        movl C(%ebp), %edx # edx = C
        movl i(%ebp), %ecx #restoring i 
        movl %eax, (%edx,%ecx,ws) #C[i] = malloc's return value

        incl %ecx # ++i 
        jmp malloc_for_start
    malloc_for_end:

    #for(int i = 0; i < num_rows_a; ++i){
    #resetting i to 0 
        movl $0, %ecx
    for_start_1:
        #i < num_rows_a;
        # i - num_rows_a < 0
        #negation: i - num_rows_a >= 0
        cmpl num_rows_a(%ebp), %ecx # i - num_rows_a
        jge for_end_1

        #for(int j = 0; j < num_cols_b; ++j)
        movl $0, %edx # edx = 0 = j
        for_start_2:
            #j < num_cols_b
            #j - num_cols_b < 0
            #negation: j - num_cols_b >= 0
            cmpl num_cols_b(%ebp), %edx # j - num_cols_b
            jge for_end_2 #jmp when j - num_cols_b >= 0

            # int sum = 0;
            movl $0, sum(%ebp) # sum = 0

            #for( int k=0; k < num_rows_b; ++k){
            //might have to use another reg for k 
            movl $0, %ebx #  ebx = k = 0
            for_start_3:
            #k < num_rows_b
            #k - num_rows_b < 0
            #negation: k - num_rows_b >= 0
            cmpl num_rows_b(%ebp), %ebx
            jge for_end_3
                #sum += matrix_a[i][k] * matrix_b[k][j];
                #sum+= *( *(matrix_a + i) + k) *  *( *(matrix_b + k) + j)
                # *( *(matrix_b + k) + j)
                # esi = matrix_b[k][j]
                movl B(%ebp), %esi # esi = B
                movl (%esi, %ebx, ws), %esi # esi = matrix_b[k]
                movl (%esi, %edx, ws), %esi # esi = matrix_b[k][j]

                #now do A
                # A[i][k]
                movl A(%ebp), %edi # edi = A
                movl (%edi, %ecx, ws), %edi # edi = matrix_a[i]
                movl (%edi, %ebx, ws), %edi # edi = matrix_a[i][k]

                //push eax and edx into stack
                //call 
                push %edx # saving edx on to the stack 
                push %eax # savinf eax on to the stack

                movl %esi, %eax # eax = matrix_b[k][j]
                imull %edi # eax = eax * edi 
                #add src, dest 
                addl %eax, sum(%ebp) #moving the result into sum
                #should pop
                pop %eax #restore eax 
                pop %edx #restoring edx

            incl %ebx # ++k
            jmp for_start_3
            for_end_3:
            # C[i][j]=sum; NEED TO TRANSLATE THIS
            #eax has c[i]
            # *(*(C + i) + j)
            #already have sum
            #might be dangerous bc idk if this can happen all in the same line
            #mightve have to get C[i] to be C[i][j]
            movl (%eax, %edx, ws), %eax # C[i][j]
            movl sum(%ebp), %eax # C[i][j] = sum
            incl %edx # ++j
            jmp for_start_2
        for_end_2:

        incl %ecx #++i
        jmp for_start_1
    for_end_1:

    #return C;
    #place C into eax 
    movl C(%ebp), %eax

    epilogue:

    #restore regs 
    #ebp - 6 * ws: old_ebx
    #ebp - 7 * ws: old_esi
    #ebp - 8 * ws: old_edi
    #1st one in last one out
    movl old_edi(%ebp), %edi
    movl old_esi(%ebp), %esi
    movl old_ebx(%ebp), %ebx

    movl %ebp,%esp
    pop %ebp
    ret
