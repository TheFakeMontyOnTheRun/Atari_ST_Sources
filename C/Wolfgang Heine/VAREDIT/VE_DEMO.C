/*****************************************************************/
/* Var_edit produces Dialogue-boxes with Edit fields of          */
/*  variable length.                                             */
/*             Author: Wolfgang Heine, 8111 Urfeld               */
/*         (c) 1992 MAXON Computer GmbH                          */
/*****************************************************************/

#include  <stdio.h>
#include  <string.h>
#include <aes.h>
#include "var_edit.h"

#define TITLE     1
#define TXT_1     2
#define TXT_2     3
#define TXT_3     4
#define OUT       5
#define OK        6

int contrl[12], intin[128], intout[128], ptsin[128], ptsout[128];

typedef char STRING[80];

STRING s[] = 
  {
    "",                                   /* s[ 0]                        */
    "",                                   /* s[ 1]                        */
    "",                                   /* s[ 2]                        */
    "",                                   /* s[ 3]                        */
    "",                                   /* s[ 4]                        */
    "",                                   /* s[ 5]                        */ 
    "",                                   /* s[ 6]                        */
    "",                                   /* s[ 7]                        */
    "",                                   /* s[ 8]                        */ 
    "",                                   /* s[ 9]                        */
    "",                                   /* s[10]                        */
    "",                                   /* s[11]                        */ 
    "End",                                /* s[12]                        */
    "OK"                                  /* s[13]                        */
  };

TEDINFO ted[] = 
  {
    s[ 0], s[ 1], s[ 2],  3, 6, 2, 0x1180, 0x0, -4,  -2,  -2,
    s[ 3], s[ 4], s[ 5],  3, 6, 0, 0x1180, 0x0, -1,  -2,  -2,
    s[ 6], s[ 7], s[ 8],  3, 6, 0, 0x1180, 0x0, -1,  -2,  -2,
    s[ 9], s[10], s[11],  3, 6, 0, 0x1180, 0x0, -1,  -2,  -2
  }; 
  
OBJECT tree[] = 
  {
   -1, 1, 6, G_BOX,     NONE,     OUTLINED, 0x21100L,  0,  0,  -2,  200,
    2,-1,-1, G_BOXTEXT, NONE,     OUTLINED|SHADOWED, 
                                            &ted[0],  -2,  20,  -2,  18,
    3,-1,-1, G_FTEXT,   EDITABLE, NORMAL,   &ted[1],  -2,  60,  -2,  18,
    4,-1,-1, G_FTEXT,   EDITABLE, NORMAL,   &ted[2],  -2,  80,  -2,  18,
    5,-1,-1, G_FTEXT,   EDITABLE, NORMAL,   &ted[3],  -2, 100,  -2,  18,
    6,-1,-1, G_BUTTON,  SELECTABLE|EXIT|OUTLINED,  
                                  NORMAL,   s[12],    -2, 130,  70,  20,
    0,-1,-1, G_BUTTON,  SELECTABLE|EXIT|DEFAULT|LASTOB,
                                  NORMAL,   s[13],    -2, 130,  70,  20
  };
  
/**************************************************************************/

main()
{
char help[80];
  int n;                                  /* Letters in the Editfield field */
  char *txt1_adr, *txt2_adr, *txt3_adr;   /* Addresses of the Texts       */

  appl_init();                            /* Register Application         */
  for ( n = 25; n < 85 ; n += 10)         /* Test for different  n        */
  {
    tree[0].ob_width = n*8+60;            /* Width of the father objects  */

    tree[OUT].ob_x=tree[0].ob_width/2     /* End-Button and OK-Button    */
              - 10-tree[OUT].ob_width;    /* symmetrical to the middle   */
    tree[OK].ob_x=tree[0].ob_width/2+10;  /* arrange                     */
    
    /* 3 Edit fields of length  n furnished and Texts entered             */
    sprintf(help,"%s %d %s"," Editfields with", n, "Letters ");   
    var_edit(tree, TITLE, strlen(help),"",help,"X");
    txt1_adr = var_edit(tree, TXT_1, 18, "Date  : __.__.19__","310790","9");
    txt2_adr = var_edit(tree, TXT_2, n, "Line  1: ","Edit-","X");
    txt3_adr = var_edit(tree, TXT_3, n, "Line  2: ","fields","X");

    /* Dialogue-field calls, Program quit, if End-Button is pressed*/

    if ( hndl_dial(tree, TXT_1, 0,0,0,0) == OUT )
      break;
    printf("\033Y  ");                    /* or "\033Y%c%c",y+' ',x+' '   */
    printf("\033K%s\n",txt1_adr);         /* Free up lines and pick       */
    printf("\033K%s\n",txt2_adr);         /* out Texts written up         */
    printf("\033K%s\n",txt3_adr);
    puts("            Press a Key!");
  }
  appl_exit();                            /* Program quit            */
  return(0);
}


