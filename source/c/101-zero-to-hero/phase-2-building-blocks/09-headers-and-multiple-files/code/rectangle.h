#ifndef RECTANGLE_H
#define RECTANGLE_H

typedef struct {
    int width;
    int height;
} Rectangle;

int rectangle_area(const Rectangle *r);
int rectangle_perimeter(const Rectangle *r);
int rectangle_is_square(const Rectangle *r);

#endif
