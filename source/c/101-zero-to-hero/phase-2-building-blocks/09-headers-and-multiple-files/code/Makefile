CC = gcc
CFLAGS = -std=c17 -Wall -Wextra

app: main.o rectangle.o
	$(CC) $(CFLAGS) -o app main.o rectangle.o

main.o: main.c rectangle.h
	$(CC) $(CFLAGS) -c main.c

rectangle.o: rectangle.c rectangle.h
	$(CC) $(CFLAGS) -c rectangle.c

.PHONY: clean
clean:
	rm -f app app.exe main.o rectangle.o
