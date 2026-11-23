#include <stdio.h>

#include "temperature.h"

int main(void) {
    printf("212 F = %.1f C\n", fahrenheit_to_celsius(212.0));
    printf("100 C = %.1f F\n", celsius_to_fahrenheit(100.0));
    return 0;
}
