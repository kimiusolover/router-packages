#include <stdint.h>
#include <stdio.h>
#include <sys/random.h>

int main(void) {
    uint8_t id[5];
    if (getrandom(id, sizeof(id), 0) != (ssize_t)sizeof(id)) return 1;
    printf("fd%02x:%02x%02x:%02x%02x::/48\n", id[0], id[1], id[2], id[3], id[4]);
    return 0;
}
