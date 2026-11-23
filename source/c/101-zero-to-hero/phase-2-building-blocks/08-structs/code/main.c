#include <stdio.h>

typedef struct {
    char name[20];
    int quantity;
    double price;
} Item;

void print_item(const Item *item);
void restock(Item *item, int amount);

int main(void) {
    Item pen = {"Pen", 10, 1.50};
    print_item(&pen);
    restock(&pen, 5);
    print_item(&pen);

    Item shelf[3] = {
        {"Notebook", 4, 3.25},
        {"Ruler", 6, 0.80},
        {"Eraser", 12, 0.50}
    };
    double value = 0.0;
    for (int i = 0; i < 3; i++) {
        print_item(&shelf[i]);
        value += shelf[i].quantity * shelf[i].price;
    }
    printf("Shelf value: %.2f\n", value);

    Item copy = pen;
    snprintf(copy.name, sizeof copy.name, "%s", "Spare");
    copy.quantity = 0;
    print_item(&copy);
    print_item(&pen);
    return 0;
}

void print_item(const Item *item) {
    printf("%s: %d at %.2f each = %.2f\n", item->name, item->quantity, item->price,
           item->quantity * item->price);
}

void restock(Item *item, int amount) {
    item->quantity += amount;
}
