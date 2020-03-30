; haribote-ipl
; TAB=4

CYLS	EQU		10				; �ǂ��܂œǂݍ��ނ�

		ORG		0x7c00			; address of this program

; FAT12 special code
		JMP		entry
		DB		0x90
		DB		"ZHOSBOOT"		; the name of bootloader (8 byte)
		DW		512				; size of sector(扇区)
		DB		1				; size of cluster(簇)
		DW		1				; the beginning of FAT
		DB		2				; the num of FAT 
		DW		224				; the size of root dir
		DW		2880			; the size of disk
		DB		0xf0			; the type of disk
		DW		9				; the length of FAT
		DW		18				; the num of sector of one track
		DW		2				; the num of disk head
		DD		0				; no prartition
		DD		2880			; rewrite the disk size once
		DB		0,0,0x29		; unknown
		DD		0xffffffff		; unknown
		DB		"ZHOSDISK   "	; the name of disk (11 byte)
		DB		"FAT12   "		; the name of disk type (8 byte)
		RESB	18				; unknown

; program main

entry:
		MOV		AX,0			; init register
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; read disk

		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; cylinders(柱面) 0
		MOV		DH,0			; disk head 0
		MOV		CL,2			; sector 2
readloop:
		MOV		SI,0			; register record the failed count 
retry:
		MOV		AH,0x02			; AH=0x02 : read disk
		MOV		AL,1			; 1 of sector
		MOV		BX,0
		MOV		DL,0x00			; A Driver
		INT		0x13			; call disk BIOS
		JNC		next			; goto next if correct
		ADD		SI,1			; SI + 1
		CMP		SI,5			; cmp SI and 5
		JAE		error			; if SI >= 5 goto error
		MOV		AH,0x00
		MOV		DL,0x00			; A Driver
		INT		0x13			; call disk BIOS
		JMP		retry
next:
		MOV		AX,ES			; Move back memory address 0x200
		ADD		AX,0x0020
		MOV		ES,AX			
		ADD		CL,1			
		CMP		CL,18			
		JBE		readloop		; if CL <= 18 goto readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2
		JB		readloop		; if DH < 2 goto readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS
		JB		readloop		; if CH < CYLS goto readloop

; �ǂݏI������̂�haribote.sys�����s���I

		MOV		[0x0ff0],CH		; IPL���ǂ��܂œǂ񂾂̂�������
		JMP		0xc200

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; SI + 1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; show a word
		MOV		BX,15			; color of word
		INT		0x10			; call graphics(GPU) BIOS
		JMP		putloop
fin:
		HLT						; stop CPU ,waiting for command
		JMP		fin				; looooop
msg:
		DB		0x0a, 0x0a		; 2 newline
		DB		"load error"
		DB		0x0a			; newline
		DB		0

		RESB	0x7dfe-$		; fill 0x00 until 0x7dfe

		DB		0x55, 0xaa
