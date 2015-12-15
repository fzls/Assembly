#include <dos.h>
#include <bios.h>
main()
{
   unsigned char far *p;
   int x, y;
   p = (unsigned char far *)0xA0000000; /* A000:0000 */
   _AX = 0x0013;
   geninterrupt(0x10);
   for (y = 100 - 20; y <= 100 + 20; y++)
   {
      for (x = 160 - 20; x <= 160 + 20; x++)
      {
         *(p + y * 320 + x) = 4;
      }
   }
   bioskey(0); /* mov ah,0; int 16h; */
   _AX = 0x0003;
   geninterrupt(0x10);
}

