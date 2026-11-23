#include "rectangle.h"

int rectangle_area(const Rectangle *r) {
    return r->width * r->height;
}

int rectangle_perimeter(const Rectangle *r) {
    return 2 * (r->width + r->height);
}

int rectangle_is_square(const Rectangle *r) {
    return r->width == r->height;
}
