/* ------------------------
   RAF_OS C Demo program 1
   ------------------------ */

#include "raf.h" 

void main (void) {
    char ime[100];
    char broj[10];

    puts("Kako se zoves? ");
    gets(ime);
    puts(LFS);                              /* LFS = string za novi red (vidi raf.h)*/
    puts("Koliko su 2 i 2? ");
    gets(broj);
    puts(LFS);
    
    if (!strcmp(ime, "Stevan")) {
        puts("Stevane, za tebe je svaki odgovor tacan!");
        return;
    }
    else {
        if (atoi(broj) == 4) {
            puts("Ne, 2 i 2 su 22.");
            return;
        }
        else {
            puts("Ne, 2 i 2 su 4.");
            return;
        }
    }
}

