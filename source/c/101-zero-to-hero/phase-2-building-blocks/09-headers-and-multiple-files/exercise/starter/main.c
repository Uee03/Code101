#include <stdio.h>

#include "temperature.h"

int main(void) {
    printf("212 F = %.1f C\n", fahrenheit_to_celsius(212.0));
    /* TODO: print the line 100 C = 212.0 F using celsius_to_fahrenheit. */
    return 0;
}
