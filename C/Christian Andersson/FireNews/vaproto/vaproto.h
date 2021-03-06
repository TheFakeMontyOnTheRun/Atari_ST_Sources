/*
 * @(#) Gemini\vaproto.h
 * @(#) Stefan Eissing, 21. August 1993
 *
 *
 * Beschreibung: Definition der Nachrichten des Venus <-> Accessory
 * Protokolls
 *
 * 07.12.: AV_PATH_UPDATE, AV_WHAT_IZIT, AV_DRAG_ON_WINDOW eingebaut.
 * 29.04.1993, seitz: removed all docu from the header file
 */
#ifndef __vaproto__
#define __vaproto__

#define ACC_ID		0x400
#define ACC_OPEN	0x401
#define ACC_CLOSE	0x402
#define ACC_ACC		0x403

#define AV_PROTOKOLL		0x4700
#define VA_PROTOSTATUS		0x4701
#define AV_GETSTATUS		0x4703
#define AV_STATUS		0x4704
#define VA_SETSTATUS		0x4705
#define	AV_SENDKEY		0x4710
#define VA_START		0x4711
#define AV_ASKFILEFONT		0x4712
#define VA_FILEFONT		0x4713
#define AV_ASKCONFONT		0x4714
#define VA_CONFONT		0x4715
#define AV_ASKOBJECT		0x4716
#define VA_OBJECT		0x4717
#define AV_OPENCONSOLE		0x4718
#define VA_CONSOLEOPEN		0x4719
#define AV_OPENWIND		0x4720
#define VA_WINDOPEN		0x4721
#define AV_STARTPROG		0x4722
#define VA_PROGSTART		0x4723
#define AV_ACCWINDOPEN		0x4724
#define VA_DRAGACCWIND		0x4725
#define AV_ACCWINDCLOSED	0x4726
#define AV_COPY_DRAGGED		0x4728
#define VA_COPY_COMPLETE	0x4729
#define AV_PATH_UPDATE		0x4730
#define AV_WHAT_IZIT		0x4732
#define VA_THAT_IZIT		0x4733
#define AV_DRAG_ON_WINDOW	0x4734
#define AV_EXIT			0x4736

#define	VA_OB_UNKNOWN	0
#define VA_OB_TRASHCAN  1
#define VA_OB_SHREDDER  2
#define VA_OB_CLIPBOARD 3
#define VA_OB_FILE      4
#define VA_OB_FOLDER	5
#define VA_OB_DRIVE	6
#define VA_OB_WINDOW    7

#endif
