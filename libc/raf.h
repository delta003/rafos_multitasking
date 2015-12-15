#define  NULL 0
#define  EOF  (-1)
#define  LFS 0x0A00
#define  RAND_MAX 0x7FFF       

/* stdio.h */
/* ------- */
; int printf(const char *format, ...);
int puts(char *string);
char *gets(char *bafer);


/* stdlib.h */
/* ------- */
int atoi(const char *string);
void srand(unsigned int seed);
int rand(void);


/* string.h */
/* -------- */
int strlen(const char *string);
char *strchr(const char *string, int znak);
int strcmp(const char *string1, const char *string2);
int strncmp(const char *string1, const char *string2, int n);
char *strcpy(const char *string1, const char *string2);
char *strcat(const char *string1, const char *string2);