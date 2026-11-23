#include <stdio.h>

int main(void) {
    int age = 0;
    int day = 0;

    printf("Age:\n");
    if (scanf("%d", &age) != 1 || age < 0) {
        printf("Use a whole number of years, 0 or more.\n");
        return 1;
    }
    printf("Day number (1=Mon ... 7=Sun):\n");
    if (scanf("%d", &day) != 1) {
        printf("Use a whole number for the day.\n");
        return 1;
    }

    int price = 0;
    if (age < 5) {
        price = 0;
    } else if (age < 18) {
        price = 8;
    } else if (age < 65) {
        price = 12;
    } else {
        price = 9;
    }

    switch (day) {
        case 1: printf("Monday\n"); break;
        case 2: printf("Tuesday\n"); break;
        case 3: printf("Wednesday\n"); break;
        case 4: printf("Thursday\n"); break;
        case 5: printf("Friday\n"); break;
        case 6: printf("Saturday\n"); break;
        case 7: printf("Sunday\n"); break;
        default:
            printf("Day must be 1 to 7.\n");
            return 1;
    }

    if ((day == 6 || day == 7) && price > 0) {
        price = price + 2;
        printf("Weekend surcharge: 2\n");
    }
    printf("Ticket price: %d\n", price);
    return 0;
}
