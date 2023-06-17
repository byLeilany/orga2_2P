; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"
global start


; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern idt_init
extern IDT_DESC
extern GDT_DESC
extern screen_draw_layout
extern pic_reset
extern pic_enable
extern mmu_init_kernel_dir
extern mmu_init_task_dir
extern copy_page
extern tss_init
extern tasks_screen_draw
extern tss_create_user_task
extern sched_init
extern tasks_init

%define TASK_A_CODE_START 0x00018000
%define TASK_B_CODE_START 0x0001A000
; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0b0000_0000_0000_1000
%define DS_RING_0_SEL 0b0000_0000_0001_1000
%define SELECTOR_TAREA_IDLE 0b0000_0000_0110_0000
%define pilatope  0x25000


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; COMPLETAR - Deshabilitar interrupciones
    CLI

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL
    ; (revisar las funciones definidas en print.mac y los mensajes se encuentran en la
    ; sección de datos)
    print_text_rm start_rm_msg, start_rm_len, 0x5, 1h, 1h

    ; COMPLETAR - Habilitar A20
    ; (revisar las funciones definidas en a20.asm)
    call A20_disable
    call A20_check
    call A20_enable
    call A20_check

    ; COMPLETAR - Cargar la GDT
    LGDT [GDT_DESC] 
    
    ; COMPLETAR - Setear el bit PE del registro CR0
    mov eax, CR0
    or eax, 1
    MOV CR0, eax

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido

BITS 32                     ;target remote localhost:1234
modo_protegido:
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo
    mov ax, word DS_RING_0_SEL
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax

    ; COMPLETAR - Establecer el tope y la base de la pila
    mov eax, dword pilatope
    mov esp, eax
    mov ebp, esp

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, 0x5, 2h, 2h 

    ; COMPLETAR - Inicializar pantalla
    call screen_draw_layout


    ;IDT
    call idt_init
    LIDT [IDT_DESC]

    ;PICS
    call pic_reset  ; remapear PIC
    call pic_enable ; habilitar PIC
    ; sti             ; habilitar interrupciones

    ;Activamos paginacion
    call mmu_init_kernel_dir
    mov cr3, eax

    ; Habilitar CR0.PG
    mov eax, 0x80000000
    mov edx, cr0
    or eax, edx
    mov cr0, eax

    ; CARGAMOS LA TSS INICIAL Y LA IDLE EN GDT
    call tss_init

    ; Cargar tarea inicial
    call tasks_screen_draw
    mov ax, 11 ; GDT_IDX_TASK_INIT
    shl ax, 3
    LTR ax

    ;TEST    
    ;jmp SELECTOR_TAREA_IDLE:0 ; 12 = 0b01100 y 3 bits en 0 por los attrs  (Sel_Idle:0) preguntar

     ; Inicializar Scheduler
    call sched_init

    ; cambiar velocidad PIT
    mov ax, 0x8000
    out 0x40, al
    rol ax, 8
    out 0x40, al

    ; Inicializar tareas
    call tasks_init

    ; Habilitar interrupciones
    sti

    ; Ciclar infinitamente 
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

%include "a20.asm"
