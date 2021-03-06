#include "rs2.h"	/* defines portable variable types */

#define NULL	(0L)

 /**********************************************************************
 *	Driver for MVME400 Dual RS-232C Serial Port Module
 ************************************************************************

 *	WARNING:  DO NOT OPTIMIZE THIS DRIVER !!!!!!!
 *	It contains redundant stores to the serial controller
 *	that are necessary for proper operation.
 */


/* 7201 control register 0 operations */

#define SELREG1		1
#define SELREG2		2
#define SELREG3		3
#define SELREG4		4
#define SELREG5		5
#define SELREG6		6
#define SELREG7		7
#define ABRTSDLC	8
#define REXSTINT	0x10
#define CHANRST		0x18
#define INTNXTRC	0x20
#define RSTTXINT	0x28
#define ERRRST		0x30
#define EOINT		0x38
#define RSTRXCRC	0x40
#define RSTTXCRC	0x80
#define RSTTXUR		0xC0

/* 7201 control register 1 operations */

#define EXINTEN		1
#define TXINTEN		2
#define STATAFV		4
#define RXINTDS		0
#define RXINT1		8
#define RXINTALP	0x10
#define RXINTANP	0x18
#define WAITRXTX	0x20
#define WAITEN		0x80
#define INTDSMSK	0xE4

/* 7201 control register 2A operations (2B is int vector) */

#define BOTHINT		0
#define ADMABINT	1
#define BOTHDMA		2
#define PRIAGB		0
#define PRIRGT		4
#define M8085M		0
#define M8085S		8
#define M8086		0x10
#define NONVEC		0
#define INTVEC		0x20
#define RTSBP10		0
#define SYNCBP10	0x80

/* 7201 control register 3 operations */

#define RXENABLE	1
#define SYNLDIN		2
#define ADRSRCH		4
#define RXCRCEN		8
#define ENTHUNT		0x10
#define AUTOENA		0x20
#define RX5BITS		0
#define RX7BITS		0x40
#define RX6BITS		0x80
#define RX8BITS		0xC0
#define RXSZMSK		0x3F

/* 7201 control register 4 operations */

#define PARENAB		1
#define EVENPAR		2
#define ODDPAR		0
#define SYNCMODE	0
#define SBIT1		4
#define SBIT1P5		8
#define SBIT2		0xC
#define SBITMSK		0xF3
#define SYN8BIT		0
#define	SYN16BIT	0x10
#define SDLCMODE	0x20
#define EXTSYNC		0x30
#define CLKX1		0
#define CLKX16		0x40
#define CLKX32		0x80
#define CLKX64		0xC0

/* 7201 control register 5 operations */

#define TXCRCEN		1
#define RTS		2
#define CRC16		4
#define CRCCCITT	0
#define TXENABLE	8
#define SENDBRK		0x10
#define TX5BITS		0
#define TX7BITS		0x20
#define TX6BITS		0x40
#define TX8BITS		0x60
#define TXSZMSK		0x9F
#define DTR		0x80

/* 7201 control register 6 = sync bits 0-7 */
/* 7201 control register 7 = sync bits 8-15 */

/* 7201 status register 0 */

#define RXCHAR		1		/*Recieve character available */
#define INTPNDNG	2
#define TXBUFEMP	4		/*Transmit register is empty  */
#define DCD		8
#define SYNCHUNT	0x10
#define CTS		0x20
#define TXUNDER		0x40
#define BRKABRT		0x80

/* 7201 status register 1 */

#define PARERR		0x10
#define RXOVRUN		0x20
#define CRCFRMER	0x40
#define EOFRAME		0x80

/* 7201 status register 2 = int vector */

#define FALSE		0
#define TRUE		1

/* Macro to WRITE information to the 7201's control registers		*/

#define WRITE(y,x,z,w)	*y = x;\
			*y = aux_state[z].w

#define M400_1		0	/* table indices for the 2 auxillary ports */
#define M400_2		1
#define AUX 		M400_1	/* Auxllary Serial Device		*/
#define LST 		M400_2	/* List Device (line printer)		*/


                               		/* baud rate control values
	 0 for   0 ,	 0 for  50 ,	 1 for  75 ,	 2 for 110 ,
	 3 for 134 ,	 4 for 150 ,	 4 for 200 ,	 5 for 300 ,
	 6 for 600 ,	 7 for1200 ,	 8 for1800 ,	10 for2400 ,
	12 for4800 ,	14 for9600 ,	15 forEXTA ,	15 forEXTB 
					      EXTA & EXTB = 19.2K  */
typedef struct
   {
   BYTE		cr1;
   BYTE		cr2;
   BYTE		cr3;
   BYTE		cr4;
   BYTE		cr5;
   BYTE		baud;			/*baud rate for the port */
   BYTE		char_size;		/*size of character: 0x20 = 7
							     0x40 = 6
							     0x60 = 8 */
   } mstate;

		/*following is the actual variable which holds the state
		  of the MVME400 board. It is referenced in the code below
		  using the pointer variable "aux_state" defined above.
		  The array dimesion expression forces even byte alignment
		  at the end of each element of mstate(of which there are
		  2).  All of this foolishness is necessary because the
		  C compiler will not initialize char variables.	*/

BYTE		init_state[] = {
		(0),      	  		/* A cr1 */
		(BOTHINT|PRIRGT|M8086|RTSBP10),	/* A cr2 */
		(AUTOENA|RX8BITS|RXENABLE),    	/* A cr3 */
		(SBIT1|CLKX16), 		/* A cr4 */
		(TXENABLE|TX8BITS|RTS|DTR),    	/* A cr5 */
		(14), 				/* A baud rate = 9600*/
		(TX8BITS),     			/* A character size */
		(0), 				/* Dummy fill char  */
		(STATAFV),       		/* B cr1 */
		(0), 				/* B cr2 */
		(AUTOENA|RX8BITS|RXENABLE),    	/* B cr3 */
		(SBIT1|CLKX16), 		/* B cr4 */
		(TXENABLE|TX8BITS|RTS|DTR),    	/* B cr5 */
		(7), 				/* A baud rate = 1200*/
		(TX8BITS), 			/* A character size */
		0				/* Dummy fill char  */
};

		/* State of the MVME400 board; one set of information
		   for each of the ports on the board		     	*/

mstate		*aux_state = (mstate *)init_state;

/*
 *	Structure of MVME400 hardware registers.
 *	Assumes an odd starting address.
 */
typedef struct
   {
	BYTE		m4_piaad;	/* pia a data */
	BYTE		m4_fill0;	/* fill */
	BYTE		m4_piaac;	/* pia a control */
	BYTE		m4_fill1;	/* fill */
	BYTE		m4_piabd;	/* pia b data */
	BYTE		m4_fill2;	/* fill */
	BYTE		m4_piabc;	/* pia b control */
	BYTE		m4_fill3;	/* fill */
	BYTE		m4_7201d[3];	/* 7201 a data */
/*	BYTE		m4_fill4;	   fill */
/*	BYTE		m4_72bd;	   7201 b data */
	BYTE		m4_fill5;	/* fill */
	BYTE		m4_7201c[3];	/* 7201 a control */
/*	BYTE		m4_fill6;	   fill */
/*	BYTE		m4_72bc;	   7201 b control */
   } m4_map;

/* MVME400 BASE ADDRESS							*/

#define	M400_ADDR	((m4_map *)0xf1c1c1)	

/* Macro to dereference VME/10 control register #6 */

#define IOCHANRG	(*(BYTE *)0xF19F11)
#define CNH4EN		0x80

/*********************************************************************
** Initialize both ports on the mvme400 card 
**********************************************************************/

extern LONG trap();

m400init()
   {
   REG BYTE		*caddra, *caddrb;
   REG m4_map 		*addr;
   LONG super_stack;

   super_stack = trap(0x20, 0L);

   IOCHANRG &= ~CNH4EN;		/* disable I/O channel 3 interrupts */

   aux_state = (mstate *)init_state;/*aux_state points at initialized array*/

   addr = M400_ADDR;
   caddra = &addr->m4_7201c[0];	/* address of A side control register*/
   caddrb = &addr->m4_7201c[2];	/* address of B side control register*/
   addr->m4_piaac = 0;		/* set up pia data direction regs */
   addr->m4_piaad = 0x18;
   addr->m4_piaac = 4;
   addr->m4_piabc = 0;
   addr->m4_piabd = 0xff;
   addr->m4_piabc = 4;
   addr->m4_piaad = 0;		/* fail led off */

				/* set the baud rate for both ports	*/
				
   addr->m4_piabd = (aux_state[M400_1].baud << 4) 	/* A port */
			| aux_state[M400_2].baud;	/* B port */

   *caddra = CHANRST;		/* reset channels */
linit1:				/* label to force generation of next line */
   *caddra = CHANRST;		/* write twice so */
   *caddrb = CHANRST;		/* it is sure to be */
linit2:			
   *caddrb = CHANRST;		/* written to cr0 */
				/* Initialize the control registers NEC 7201
				   Communiciations controller chip	*/

   WRITE(caddra,SELREG2,M400_1,cr2);
   WRITE(caddrb,SELREG2,M400_2,cr2);
   WRITE(caddra,SELREG4,M400_1,cr4);
   WRITE(caddra,SELREG3,M400_1,cr3);
   WRITE(caddra,SELREG5,M400_1,cr5);
   WRITE(caddra,SELREG1|RSTTXINT,M400_1,cr1);
   WRITE(caddrb,SELREG4,M400_2,cr4);
   WRITE(caddrb,SELREG3,M400_2,cr3);
   WRITE(caddrb,SELREG5,M400_2,cr5);
   WRITE(caddrb,SELREG1|RSTTXINT,M400_2,cr1);

   trap(0x20, super_stack);
}
