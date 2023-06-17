/* ** por compatibilidad se omiten tildes **
================================================================================
 TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Rutinas del controlador de interrupciones.
*/
#include "pic.h"

#define PIC1_PORT 0x20
#define PIC2_PORT 0xA0

static __inline __attribute__((always_inline)) void outb(uint32_t port,
                                                         uint8_t data) {
  __asm __volatile("outb %0,%w1" : : "a"(data), "d"(port));
}
void pic_finish1(void) { outb(PIC1_PORT, 0x20); }
void pic_finish2(void) {
  outb(PIC1_PORT, 0x20);
  outb(PIC2_PORT, 0x20);
}

// COMPLETAR: implementar pic_reset()       MUCHAD DUDAS WTF ¿remapear las interrupciones del PIC1 a partir de la
//                                                              32 (0x20) y del PIC2 a partir de la 40 (0x28)?
void pic_reset() {
  // ; Inicializacion PIC1
  outb(PIC1_PORT, 0x11);   // mov al, 11h   ;ICW1: IRQs activas por flanco, Modo cascada, ICW4 Si.   --    out 20h, al
  outb(PIC1_PORT + 1, 0x20);  // mov al, 8   ;ICW2: INT !!base para el PIC1 Tipo 8.                     --    out 21h, al
  outb(PIC1_PORT + 1, 0x04); // mov al, 04h ;ICW3: PIC1 Master, tiene un Slave conectado a IRQ2      --    out 21h ,al
  outb(PIC1_PORT + 1, 0x01); // mov al, 01h ;ICW4: Modo No Buffered, Fin de Interrupcion Normal      --    out 21h, al ; Deshabilitamos las Interrupciones del PIC1
  outb(PIC1_PORT + 1, 0xFF); // mov al, FFh ;OCW1: Set o Clearel IMR                                 --    out 21h, al

  // ; Inicializacion PIC2
  outb(PIC2_PORT, 0x11);  // mov al, 11h ;ICW1: IRQs activas por flanco, Modo cascada, ICW4 Si.      --    out A0h, al
  outb(PIC2_PORT + 1, 0x28);  // mov al, 70h ;ICW2: INT !!base para el PIC2 Tipo 070h.                 --    out A1h, al
  outb(PIC2_PORT + 1, 0x02);  // mov al, 02h ;ICW3: PIC2 Slave, IRQ2 es la lnea que envia al Master  --    out A1h, al
  outb(PIC2_PORT + 1, 0x01);  // mov al, 01h ;ICW4: Modo No Buffered, Fin de Interrupcion Normal     --    out A1h, al
}

void pic_enable() {
  outb(PIC1_PORT + 1, 0x00);
  outb(PIC2_PORT + 1, 0x00);
}

void pic_disable() {
  outb(PIC1_PORT + 1, 0xFF);
  outb(PIC2_PORT + 1, 0xFF);
}
