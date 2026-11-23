CC = gcc
CFLAGS = -std=c17 -Wall -Wextra

app: main.o expense.o
	$(CC) $(CFLAGS) -o app main.o expense.o

main.o: main.c expense.h
	$(CC) $(CFLAGS) -c main.c

expense.o: expense.c expense.h
	$(CC) $(CFLAGS) -c expense.c

.PHONY: clean
clean:
	rm -f app app.exe main.o expense.o
