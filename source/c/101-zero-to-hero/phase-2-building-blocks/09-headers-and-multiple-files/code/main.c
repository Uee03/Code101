#include <stdio.h>

#include "rectangle.h"

int main(void) {
    Rectangle desk = {120, 60};
    Rectangle tile = {30, 30};
    printf("Desk area: %d\n", rectangle_area(&desk));
    printf("Desk perimeter: %d\n", rectangle_perimeter(&desk));
    printf("Desk is square: %d\n", rectangle_is_square(&desk));
    printf("Tile is square: %d\n", rectangle_is_square(&tile));
    return 0;
}
