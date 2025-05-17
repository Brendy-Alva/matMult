
OPTIONS := -g -m32 -Wall -Werror -fno-pie -no-pie
matmult.out: main.o matmult.o
	gcc $(OPTIONS) -o matmult.out main.o matmult.o

matmult.o: matmult.s
	gcc $(OPTIONS) -c -o matmult.o matmult.s

main.o: main.c
	gcc $(OPTIONS) -c -o main.o main.c
	
clean:
	rm -f main.o matmult.o matmult.out
