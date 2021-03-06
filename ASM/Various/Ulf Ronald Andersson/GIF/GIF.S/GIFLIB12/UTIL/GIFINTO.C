/*****************************************************************************
*   "Gif-Lib" - Yet another gif library.				     *
*									     *
* Written by:  Gershon Elber				Ver 0.1, Jul. 1989   *
******************************************************************************
* Program to read stdin, and save it into the specified file iff the result  *
* and inspired by the rle utah tool kit I decided to implement and add it.   *
* -q : quite printing mode.						     *
* -s minsize : the minimum file size to keep it.			     *
* -h : on line help.							     *
******************************************************************************
* History:								     *
* 7 Jul 89 - Version 1.0 by Gershon Elber.				     *
* 22 Dec 89 - Fix problem with tmpnam (Version 1.1).                         *
*****************************************************************************/

#ifdef __MSDOS__
#include <io.h>
#include <stdlib.h>
#include <alloc.h>
#endif /* __MSDOS__ */

#include <fcntl.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "gif_lib.h"
#include "getarg.h"

#define PROGRAM_NAME	"GifInto"

#define DEFAULT_MIN_FILE_SIZE	14     /* More than GIF stamp + screen desc. */
#define	DEFAULT_OUT_NAME	"GifInto.Gif"
#define DEFAULT_TMP_NAME	"TempInto.$$$"

#ifdef __MSDOS__
extern unsigned int
    _stklen = 16384;			     /* Increase default stack size. */
#endif /* __MSDOS__ */

#ifdef SYSV
static char *VersionStr =
        "Gif library module,\t\tGershon Elber\n\
	(C) Copyright 1989 Gershon Elber, Non commercial use only.\n";
static char
    *CtrlStr = "GifInto q%- s%-MinFileSize!d h%- GifFile!*s";
#else
static char
    *VersionStr =
	PROGRAM_NAME
	GIF_LIB_VERSION
	"	Gershon Elber,	"
	__DATE__ ",   " __TIME__ "\n"
	"(C) Copyright 1989 Gershon Elber, Non commercial use only.\n";
static char
    *CtrlStr =
	PROGRAM_NAME
	" q%- s%-MinFileSize!d h%- GifFile!*s";
#endif /* SYSV */

static int
    MinFileSize = DEFAULT_MIN_FILE_SIZE;

/******************************************************************************
* The is simply: read until EOF, then close the output, test its length, and  *
* if non zero then rename it.						      *
******************************************************************************/
void main(int argc, char **argv)
{
    int	Error, NumFiles,
	MinSizeFlag = FALSE, HelpFlag = FALSE;
    char **FileName = NULL,
        TmpName[80], FoutTmpName[80], FullPath[80], DefaultName[80], s[80], *p;
    FILE *Fin, *Fout;

    if ((Error = GAGetArgs(argc, argv, CtrlStr, &GifQuitePrint,
		&MinSizeFlag, &MinFileSize, &HelpFlag,
		&NumFiles, &FileName)) != FALSE ||
		(NumFiles > 1 && !HelpFlag)) {
	if (Error)
	    GAPrintErrMsg(Error);
	else if (NumFiles != 1)
	    GIF_MESSAGE("Error in command line parsing - one GIF file please.");
	GAPrintHowTo(CtrlStr);
	exit(1);
    }

    if (HelpFlag) {
	fprintf(stderr, VersionStr);
	GAPrintHowTo(CtrlStr);
	exit(0);
    }

    /* Open the stdin in binary mode and increase its buffer size: */
#ifdef __MSDOS__
    setmode(0, O_BINARY);		  /* Make sure it is in binary mode. */
    if ((Fin = fdopen(0, "rb")) == NULL ||	   /* Make it into a stream: */
        setvbuf(Fin, NULL, _IOFBF, GIF_FILE_BUFFER_SIZE))/* Incr. stream buf.*/
#else
    if ((Fin = fdopen(0, "r")) == NULL) 	   /* Make it into a stream: */
#endif /* __MSDOS__ */
	GIF_EXIT("Failed to open input.");

    /* Isolate the directory where our destination is, and set tmp file name */
    /* in the very same directory.					     */
    strcpy(FullPath, *FileName);
    if ((p = strrchr(FullPath, '/')) != NULL ||
	(p = strrchr(FullPath, '\\')) != NULL)
	p[1] = 0;
    else if ((p = strrchr(FullPath, ':')) != NULL)
	p[1] = 0;
    else
	FullPath[0] = 0;		  /* No directory or disk specified. */

    strcpy(FoutTmpName, FullPath);   /* Generate destination temporary name. */
    /* Make sure the temporary is made in the current directory: */
    p = tmpnam(TmpName);
    if (strrchr(p, '/')) p = strrchr(p, '/') + 1;
    if (strrchr(p, '\\')) p = strrchr(p, '\\') + 1;
    if (strlen(p) == 0) p = DEFAULT_TMP_NAME;
    strcat(FoutTmpName, p);

#ifdef __MSDOS__
    if ((Fout = fopen(FoutTmpName, "wb")) == NULL ||
	setvbuf(Fout, NULL, _IOFBF, GIF_FILE_BUFFER_SIZE))/*Incr. stream buf.*/
#else
    if ((Fout = fopen(FoutTmpName, "w")) == NULL)
#endif /* __MSDOS__ */
	GIF_EXIT("Failed to open output.");

    while (!feof(Fin)) {
	if (putc(getc(Fin), Fout) == EOF)
	    GIF_EXIT("Failed to write output.");
    }

    fclose(Fin);
    if (ftell(Fout) >= (long) MinFileSize) {
	fclose(Fout);
	unlink(*FileName);
	if (rename(FoutTmpName, *FileName) != 0) {
	    strcpy(DefaultName, FullPath);
	    strcat(DefaultName, DEFAULT_OUT_NAME);
	    if (rename(FoutTmpName, DefaultName) == 0) {
		sprintf(s, "Failed to rename out file - left as %s.",
								DefaultName);
		GIF_MESSAGE(s);
	    }
	    else {
		unlink(FoutTmpName);
		GIF_MESSAGE("Failed to rename out file - deleted.");
	    }
	}
    }
    else {
	fclose(Fout);
	unlink(FoutTmpName);
	GIF_MESSAGE("File too small - not renamed.");
    }
}
