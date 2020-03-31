#include "bootpack.h"
#include <stdio.h>

void init_pic(void)
/* PIC init */
{
	io_out8(PIC0_IMR,  0xff  ); /* forbid all int */
	io_out8(PIC1_IMR,  0xff  ); /* forbid all int */

	io_out8(PIC0_ICW1, 0x11  ); /* edge trigger mode */
	io_out8(PIC0_ICW2, 0x20  ); /* INT20-27 rcv IRQ0-7 */
	io_out8(PIC0_ICW3, 1 << 2); /* IRQ2 connect PIC1 */
	io_out8(PIC0_ICW4, 0x01  ); /* Buffer free mode */

	io_out8(PIC1_ICW1, 0x11  ); /* edge trigger mode */
	io_out8(PIC1_ICW2, 0x28  ); /* INT28-2f rcv IRQ8-15 */
	io_out8(PIC1_ICW3, 2     ); /* IRQ2 connect PIC1 */
	io_out8(PIC1_ICW4, 0x01  ); /* Buffer free mode */

	io_out8(PIC0_IMR,  0xfb  ); /* 11111011 forbid all expect PIC1  */
	io_out8(PIC1_IMR,  0xff  ); /* 11111111 forbid all */

	return;
}

#define PORT_KEYDAT		0x0060

struct FIFO8 keyfifo;
/* KBD */
void inthandler21(int *esp)
{
	unsigned char data;
	io_out8(PIC0_OCW2, 0x61);	/* inform PIC that IRQ-01 has been done */
	data = io_in8(PORT_KEYDAT);
	fifo8_put(&keyfifo, data);
	return;
}

struct FIFO8 mousefifo;
/* Mouse */
void inthandler2c(int *esp)
{
	unsigned char data;
	io_out8(PIC1_OCW2, 0x64);	/* inform PIC1 that IRQ-12 has been done */
	io_out8(PIC0_OCW2, 0x62);	/* inform PIC0 that IRQ-02 has been done */
	data = io_in8(PORT_KEYDAT);
	fifo8_put(&mousefifo, data);
	return;
}

void inthandler27(int *esp)
/* PIC0����̕s���S���荞�ݑ΍� */
/* Athlon64X2�@�Ȃǂł̓`�b�v�Z�b�g�̓s���ɂ��PIC�̏��������ɂ��̊��荞�݂�1�x���������� */
/* ���̊��荞�ݏ����֐��́A���̊��荞�݂ɑ΂��ĉ������Ȃ��ł��߂��� */
/* �Ȃ��������Ȃ��Ă����́H
	��  ���̊��荞�݂�PIC���������̓d�C�I�ȃm�C�Y�ɂ���Ĕ����������̂Ȃ̂ŁA
		�܂��߂ɉ����������Ă��K�v���Ȃ��B									*/
{
	io_out8(PIC0_OCW2, 0x67); /* IRQ-07��t������PIC�ɒʒm */
	return;
}
