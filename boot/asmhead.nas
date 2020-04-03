; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpack�̃��[�h��
DSKCAC	EQU		0x00100000		; �f�B�X�N�L���b�V���̏ꏊ
DSKCAC0	EQU		0x00008000		; �f�B�X�N�L���b�V���̏ꏊ�i���A�����[�h�j

; BOOT_INFO
CYLS	EQU		0x0ff0		
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			
SCRNX	EQU		0x0ff4			
SCRNY	EQU		0x0ff6			
VRAM	EQU		0x0ff8			

		ORG		0xc200			; address of this program

; ��ʃ��[�h��ݒ�

		MOV		AL,0x13			; VGA GPU 320x200x8bit
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; use BIOS get status of LEDs

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; 	PIC close all interrupts
;	on AT machine, init PIC 
;	must before CLI, otherwise 
;	will be hang up sometimes

		MOV		AL,0xff
		OUT		0x21,AL
		NOP	 
		OUT		0xa1,AL

		CLI						; forbid CPU level interrupt

; set A20GATE for CPU access more than 1MB RAM 

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; switch to protect mode

[INSTRSET "i486p"]			

		LGDT	[GDTR0]			; set GDT temporary
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; set bit31 0
		OR		EAX,0x00000001	; set bit0  1 ; for switch to protect mode
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			; RW segment 32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack transmit

		MOV		ESI,bootpack	; transmit src
		MOV		EDI,BOTPAK		; transmit addr
		MOV		ECX,512*1024/4
		CALL	memcpy

; transmit disk data to where it should be

; first, boot sector

		MOV		ESI,0x7c00		; transmit src
		MOV		EDI,DSKCAC		; transmit addr
		MOV		ECX,512/4
		CALL	memcpy

; all last

		MOV		ESI,DSKCAC0+512	; transmit src
		MOV		EDI,DSKCAC+512	; transmit addr
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; cylinder num to byte num/4
		SUB		ECX,512/4		; subtract IPL
		CALL	memcpy

; asmhead work finish
; bootpack finish last work

; bootpack boot

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; nothing to transmit
		MOV		ESI,[EBX+20]	; transmit src
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; transmit addr
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; stack init value
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		AL,0x64
		AND		AL,0x02			;########################
		IN 		AL,0x60			; read null for clear rubbish in buffer(add)
		JNZ		waitkbdout		; if AND!=0 jmp to waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			
		RET
; memcpy

		ALIGNB	16
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; RW segment 32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; RW segment 32bit for bootpack

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
