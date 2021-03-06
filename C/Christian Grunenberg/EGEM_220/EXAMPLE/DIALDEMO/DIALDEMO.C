
/* DialogDemo (PRG): ausf�hrliches u. kommentiertes Dialog-Beispielprogramm
   (u.a. Slider, Z�hlboxen, (Sub-) Popups, Alertboxen, (Fenster-/Sub-) Men�s, usw.),
   l�uft i.A. ab 640x200 */

#include <e_gem.h>
#include <string.h>
#include <time.h>
#include "text.c"
#include "dialdemo.h"

char entry[] = "  DialogDemo",			/* Men�-Eintrag unter MTOS */
	 *x_name = &entry[2],				/* (Xacc-) Programmname */
	 *av_name = "DIALDEMO",				/* AV-  - " - */
	 path[MAX_PATH],fname[MAX_PATH];	/* Pfad-/Dateiname f�r Fileselector */

/* ben�tigte Prototypen */
void HandleDialog(void);
void do_alert(SLINFO*,OBJECT*,int,int,int,int,int);
void do_count(SLINFO*,OBJECT*,int,int,int,int,int);
int sub_popup(POPUP*,int,int);

/* System-Zeit bei Programmstart */
long start_time;

/* Buffer u. Position f�r Text-Scroller */
char scroller[] = "                                     ",*scroll_pos=scroll_text;

/* Zeiger auf Objektb�ume sowie DIAINFO-Strukturen f�r Dialoge */
typedef enum {MAIN_DIAL,HELP_DIAL,TEXT_DIAL,DEMO_DIAL,ALERTS_DIAL,
              FRAMES_DIAL,EDIT_DIAL,XACC_DIAL,MAX_DIALOGS} list;

DIAINFO *dials[MAX_DIALOGS];
#define alerts_dial	dials[ALERTS_DIAL]
#define main_dial	dials[MAIN_DIAL]
#define xacc_dial	dials[XACC_DIAL]
#define demo_dial	dials[DEMO_DIAL]

OBJECT *main_tree,*help_tree,*text_tree,*demo_tree,*alerts_tree,*frames_tree,*edit_tree,*xacc_tree,*icon_tree,*menu;

/* Struktur f�r FontSelector */
FONTSEL fsel = {NULL,NULL,NULL,NULL,0,NORMAL,FS_GADGETS_ALL,FS_FNT_ALL,FAIL,FAIL,{0,0},{TRUE,DIA_MOUSEPOS,FALSE,TRUE,TRUE,FS_ACT_NONE},NULL,NULL,0,0,0,BLACK};

/* Strukturen f�r (Sub-) Popup-/Fenster-Men�s */
XPOPUP pop = {{0l,0l,POPINFO,POPBTN,POPCYCLE,TRUE,TRUE,0l},1,POPUP_BTN_CHK,POPUP_CYCLE_CHK,OBJPOS,0,0,0,1,0},*pop_list[] = {&pop,NULL};
POPUP sub={NULL,NULL,0,0,0,TRUE,FALSE,0l};

/* Anmerkung: Diese L�sung ist provisorisch, d.h. "richtige" Fenstermen�s
   werden in einer zuk�nftigen Version realisiert */
XPOPUP menu_pop = {{0l,0l,PULLDOWN,PULLDOWN,FAIL,FALSE,FALSE,sub_popup},2,POPUP_BTN|POPUP_MENU|POPUP_NO_SHADOW|POPUP_PARENT,FAIL,MENUPOS,0,0,FAIL,FAIL,0},*menu_list[] = {&menu_pop,NULL};

/* Strukturen f�r autom. verwaltete Fenster-Men�eintr�ge u. -Hotkeys */
static MITEM
Close = {CLOSE,key(0,'U'),K_CTRL,W_CLOSE,WM_CLOSED}, /* schlie�en */
CloseAll = {CLOSEALL,key(0,'U'),K_CTRL|K_SHIFT,W_CLOSEALL,FAIL}, /* alle schlie�en */
Cycle = {CYCLE,key(0,'W'),K_CTRL,W_CYCLE,FAIL}, /* wechseln */
InvCycle = {INVCYCLE,key(0,'W'),K_CTRL|K_SHIFT,W_INVCYCLE,FAIL},	/* invers wechseln */
GlobalCycle = {GLOCYCLE,key(0,'W'),K_CTRL|K_ALT,W_GLOBALCYCLE,FAIL},	/* global wechseln */
Full = {FULL,key(0,'*'),K_CTRL,W_FULL,FAIL},	/* max. Gr��e */
Bottom = {BACKGRND,key(0,'/'),K_CTRL,W_BOTTOM,FAIL},	/* Hintergrund */
Iconify = {ICONIFY,key(0,' '),K_CTRL,W_ICONIFY,FAIL}, /* ikonifizieren */
IconifyAll = {ICONALL,key(0,' '),K_CTRL|K_SHIFT,W_ICONIFYALL,FAIL}; /* alle ikonifizieren */

/* Hotkeys (SLKEY) sowie SLINFO-Strukturen f�r Hilfe/Alert-Slider sowie Z�hlbox */
SLKEY sl_help_keys[] = 
{{key(SCANUP,0),0,SL_UP},{key(SCANDOWN,0),0,SL_DOWN},
{key(SCANUP,0),K_RSHIFT|K_LSHIFT,SL_PG_UP},{key(SCANDOWN,0),K_RSHIFT|K_LSHIFT,SL_PG_DN},
{key(SCANUP,0),K_CTRL,SL_START},{key(SCANDOWN,0),K_CTRL,SL_END},
{key(SCANHOME,0),0,SL_START},{key(SCANHOME,0),K_RSHIFT|K_LSHIFT,SL_END}};

SLKEY sl_alert_keys[] =
{{key(SCANLEFT,0),0,SL_UP},{key(SCANRIGHT,0),0,SL_DOWN},
 {key(CTRLLEFT,0),K_CTRL,SL_START},{key(CTRLRIGHT,0),K_CTRL,SL_END}};

SLKEY sl_count_keys[] = {{key(0,'-'),K_CTRL,SL_UP},{key(0,'+'),K_CTRL,SL_DOWN}};

SLINFO sl_help = {NULL,HELPVIEW,0,HELPPAR,HELPSLID,0,HELPUP,HELPDOWN,0,0,0,FAIL,VERT_SLIDER,SL_LINEAR,100,0,NULL,&sl_help_keys[0],8},*sl_help_list[] = {&sl_help,NULL},
	   sl_alert = {NULL,0,0,PARENT,SLIDE,0,LEFT,RIGHT,X_ICN_MAX+2,1,X_ICN_MAX+3,FAIL,HOR_SLIDER,SL_LINEAR,50,0,do_alert,&sl_alert_keys[0],4},*sl_alert_list[] = {&sl_alert,NULL},
	   sl_count = {NULL,0,0,CNTPARNT,COUNT,0,CNTMINUS,CNTPLUS,0,1,1000,FAIL,HOR_SLIDER,SL_LOG,0,300,do_count,&sl_count_keys[0],2},
	   sl_edit = {NULL,0,0,EDITPART,EDITSLID,0,EDITLEFT,EDITRGHT,0,11,111,FAIL,HOR_SLIDER,SL_LINEAR,50,0,do_count,NULL,0},
	   *sl_main_list[] = {&sl_count,&sl_edit,NULL};

/* Struktur, welche Men�punkte, Hotkeys und Dialoge in Verbindung setzt */

typedef struct
{
	int	object,shortcut,state;	/* Men�eintrag, Hotkeytaste, -status */
	int index;					/* Index der DIAINFO-Struktur */
	OBJECT **tree;				/* Zeiger auf Objektbaum */
	int mode,center;			/* Dialog-Modus/Zentrierung */
	char *title;				/* Fenster-Titel */
} MENUITEM;

char demo[]="*Demonstration";

MENUITEM items[] = {
{QUIT,	  'Q',K_CTRL,0,NULL,0,0,NULL},
{ASCIMENU,'B',K_CTRL,0,NULL,0,0,NULL},
{FONTMENU,'F',K_CTRL,0,NULL,0,0,NULL},
{INFOBOX, 'I',K_CTRL,DEMO_DIAL,&demo_tree,AUTO_DIAL,DIA_LASTPOS," Information"},
{ATTRMENU,'T',K_CTRL,TEXT_DIAL,&text_tree,AUTO_DIAL,DIA_MOUSEPOS," Text-Effekte"},
{EDITMENU,'E',K_CTRL,EDIT_DIAL,&edit_tree,AUTO_DIAL,DIA_MOUSEPOS,"*Eingabefelder"},
{ALRTMENU,'A',K_CTRL,ALERTS_DIAL,&alerts_tree,WIN_DIAL,DIA_MOUSEPOS,"*Alert-Boxen"},
{XACCMENU,'X',K_CTRL,XACC_DIAL,&xacc_tree,WIN_DIAL,DIA_LASTPOS," XAcc-/AV-Info"},
{TITLMENU,'R',K_CTRL,FRAMES_DIAL,&frames_tree,AUTO_DIAL,DIA_MOUSEPOS," �berschriften"},
{FLYMENU, 'G',K_CTRL,MAIN_DIAL,&main_tree,FLY_DIAL|DDD_DIAL,DIA_MOUSEPOS,NULL},
{WINMENU, 'D',K_CTRL,MAIN_DIAL,&main_tree,WIN_DIAL,DIA_MOUSEPOS,&demo[0]},
{SIZEMENU,'Z',K_CTRL,MAIN_DIAL,&main_tree,WIN_DIAL|WD_SIZER|WD_FULLER|WD_TREE_SIZE|WD_SET_SIZE,DIA_MOUSEPOS,&demo[0]},
{FRAMMENU,'R',K_CTRL,MAIN_DIAL,&main_tree,WIN_DIAL|FRAME,DIA_MOUSEPOS,&demo[0]},
{SMALMENU,'N',K_CTRL,MAIN_DIAL,&main_tree,WIN_DIAL|SMALL_FRAME,DIA_MOUSEPOS,&demo[0]},
{MIDMENU,'L',K_CTRL,MAIN_DIAL,&main_tree,WIN_DIAL|SMART_FRAME,DIA_MOUSEPOS,&demo[0]},
{MODMENU, 'M',K_CTRL,MAIN_DIAL,&main_tree,WIN_DIAL|MODAL,DIA_MOUSEPOS,&demo[0]},
{HELPMENU,'H',K_CTRL,HELP_DIAL,&help_tree,WIN_DIAL|WD_INFO,DIA_LASTPOS," Hilfe"},
{PAULA,'P',K_CTRL,0,NULL,0,0,NULL}};

#define ITEMS		18
#define XACC_ITEM	7
#define HELP_ITEM	16

/* Darstellungsmodi der Alertboxen */
int modal[]={WIN_DIAL,FLY_DIAL,AUTO_DIAL|MODAL|NO_ICONIFY};

/***********************************************************************
 Zeichnen des Hilfetext-Ausschnitts
************************************************************************/

/* H�he einer Zeile, Anzahl der sichtbaren Zeilen, Anzahl der Zeilen */
int line_help_h,view_help_lines,help_lines = (int) sizeof(help)>>2;

int cdecl draw_help(PARMBLK *pb)	
{
	GRECT work=*(GRECT *) &pb->pb_x;
	if (rc_intersect((GRECT *) &pb->pb_xc,&work))
	{
		char **ptr;
		int x=pb->pb_x,y=pb->pb_y,start_line=(work.g_y-y)/line_help_h;

		v_set_mode(MD_TRANS);
		v_set_text(small_font_id,small_font,BLACK,0,0,NULL);
		rc_sc_clear(&work);

		y += start_line*line_help_h;
		ptr = &help[start_line+=sl_help.sl_pos];
		start_line = min((work.g_y-y+work.g_h+line_help_h-1)/line_help_h,help_lines-start_line);
		for (;--start_line>=0;y+=line_help_h)
			v_gtext(x_handle,x,y,*ptr++);
	}
	return(0);
}

USERBLK	helpblk = {draw_help,0};

/***********************************************************************
 (Timer-) Routinen f�r (verz�gertes) Aufklappen des Submen�s
************************************************************************/

void open_sub(POPUP *p)
{
	int x,y;
	objc_offset(p->p_menu,COLOR,&x,&y);
	x += p->p_menu[COLOR].ob_width;
	Popup(&sub,POPUP_BTN_CHK|POPUP_NO_SHADOW|POPUP_SUB,XYPOS,x,y,NULL,FAIL);
}

long sub_id;

long sub_timer(long p,long t,MKSTATE *m)
{
	sub_id = 0;
	open_sub((POPUP *) p);
	return(STOP_TIMER);
}

/***********************************************************************
 Funktion wird aufgerufen, sobald sich der aktuelle Eintrag des Popups
 ge�ndert hat
************************************************************************/
int sub_popup(POPUP *p,int ob,int mode)
{
	/* Submen� nicht mehr �ffnen (neuer aktueller Eintrag!) */
	if (sub_id)
		KillTimer(sub_id);
	sub_id = 0;
	/* evtl. Submen� nach kleiner Pause (Men� wird nicht w�hrend
	   Mausbewegung ge�ffnet) �ffnen */
	if (ob==COLOR)
	{
		if (mode&POPUP_EXITENTRY)
			open_sub(p);
		else if (mode&POPUP_MOUSE)
			sub_id = NewTimer(250,(long) p,sub_timer);
		mode = 0;
	}
	return((mode&POPUP_EXITENTRY) ? POPUP_EXIT : POPUP_CONT);
}

/***********************************************************************
 Funktion wird von graf_rt_slider() intern aufgerufen, sobald sich die
 Sliderposition ge�ndert hat.
************************************************************************/
void do_alert(SLINFO *sl,OBJECT *tree,int pos,int prev,int max_pos,int crs,int prev_crs)
{
	/* Slider-Wert in String umrechnen */
	char *text=ob_get_text(tree,sl->sl_slider,0);
	if (pos==0)
		strcpy(text,"None");
	else if (pos==(X_ICN_MAX+2))
		strcpy(text,"User");
	else
		int2str(text,pos,0);
}

void do_count(SLINFO *sl,OBJECT *tree,int pos,int prev,int max_pos,int crs,int prev_crs)
{
	int2str(ob_get_text(tree,sl->sl_slider,0),pos,0);
}

/***********************************************************************
 Dialoge schlie�en sowie optional Applikation beenden
***********************************************************************/
void ExitExample(int all)
{
	if (all)
		close_rsc(TRUE,0);	/* Men�leiste entfernen, Resource freigeben,
							   Abmeldung bei AES, VDI und Protokollen sowie
							   Programm beenden */
	else
		close_all_dialogs();/* ge�ffnete Dialoge/Fenster schlie�en */
}

/***********************************************************************
 Resource & Objektb�ume initialsieren
***********************************************************************/
void init_resource(void)
{
    X_TEXT *text;
	OBJECT *obj,*ob1,*ob2;
	int i;

/* Adressen der Objektb�ume (Dialoge,Men�s,Popups) ermitteln */
	rsrc_gaddr(R_TREE, POP, &pop.popup.p_menu);
	rsrc_gaddr(R_TREE, MENUPOP, &menu_pop.popup.p_menu);
	rsrc_gaddr(R_TREE, MENU, &menu);
	rsrc_gaddr(R_TREE, EGEMICON, &iconified);
	rsrc_gaddr(R_TREE, INFODIAL, &demo_tree);
	rsrc_gaddr(R_TREE, DIALOG, &main_tree);
	rsrc_gaddr(R_TREE, TEXTDIAL, &text_tree);
	rsrc_gaddr(R_TREE, ALERTS, &alerts_tree);
	rsrc_gaddr(R_TREE, RAHMEN, &frames_tree);
	rsrc_gaddr(R_TREE, EDITDEMO, &edit_tree);
	rsrc_gaddr(R_TREE, HELPDIAL, &help_tree);
	rsrc_gaddr(R_TREE, ALERTICN, &icon_tree);
	rsrc_gaddr(R_TREE, XACCDEMO, &xacc_tree);
	rsrc_gaddr(R_TREE, SUB, &sub.p_menu);

/* erweiterte Objekte sowie Images/Icons anpassen */
	for (i=0;i<=XACCDEMO;i++)
	{
		rsrc_gaddr(R_TREE,i,&obj);
		fix_objects(obj,TEST_SCALING|DARK_SCALING,8,16);
	}

/*	Zeichensatz und Gr��e des GDOS-Attribut-Texts setzen */
	text = get_xtext(text_tree,GDOSTEXT);
	text->font_id = 0;
	text->font_size = -9;

/*	VDI-Schreibmodus des XOR-Textes setzen */
	get_xtext(text_tree,XORTEXT)->mode = MD_XOR;

/*	inversen & kursiven Text setzen */
	get_xtext(text_tree,TXTINV)->effect |= X_INVERS;

/*	Text-Scroller setzen */
	obj = &demo_tree[SCROLLER];
	obj->ob_type = colors>4 ? G_BOXTEXT : G_TEXT;
	if (colors<=4)
		obj->ob_state &= ~DRAW3D;
	ob_set_text(obj,0,scroller);

/*	Erstellungsdatum und Versionsnummer im Informationsdialog setzen */
	ob_set_text(demo_tree,DATE,__DATE__);
	strcpy(ob_get_text(demo_tree,VERS,FALSE)+8,E_GEM_VERSION);

/*	Hilfe-Dialog auf benutzerdefiniertes Objekt setzen */
	obj = &help_tree[HELPVIEW];
	obj->ob_type = G_USERDEF;
	obj->ob_spec.userblk = &helpblk;

/*	Slider-Struktur und ben�tigte Variablen zur Darstellung setzen  */
	sl_help.sl_line = line_help_h = gr_sh+2;
	sl_help.sl_page = view_help_lines = ((i=obj->ob_height)/line_help_h)-1;
	sl_help.sl_max = help_lines;

/*	Koordinaten des Fenster-Objektes anpassen */
	obj->ob_y += (i-(obj->ob_height=view_help_lines*line_help_h))>>1;

/*	Koordinaten der Slider-Objekte anpassen */
	ob1 = &help_tree[HELPUP];ob1->ob_x -= 2;ob1->ob_y += 2;
	ob2 = &help_tree[HELPDOWN];ob2->ob_x -= 2;ob2->ob_y -= 2;
	obj = &help_tree[HELPPAR];obj->ob_x -= 2;
	obj->ob_y = ob1->ob_y+ob1->ob_height+1;obj->ob_height = ob2->ob_y-obj->ob_y-1;

/*  minimale Breite diverser Slider und der Z�hlbox setzen */
	sl_edit.sl_min_size = sl_count.sl_min_size = gr_cw*4;
	sl_alert.sl_min_size = gr_cw*5;
			
/*	XAcc/AV-Dialogobjekte initialisieren (Dialog in linker oberer Desktop-Ecke �ffnen)*/
	xacc_tree->ob_x = desk.g_x+2;
	xacc_tree->ob_y = desk.g_y+2;

/*	(Eingabe-) Felder in verschiedenen Dialogen zur�cksetzen */
	ob_clear_edit(main_tree);
	ob_clear_edit(edit_tree);
	ob_set_text(xacc_tree,TIMEDEMO,"    0");
}

/***********************************************************************
 Timer-Routinen f�r periodische Vorg�nge
***********************************************************************/
long XAccTimer(long p,long time,MKSTATE *m)
{
	if (xacc_dial) /* Protokoll-Dialog noch ge�ffnet? */
	{
		/* Objekt aktualisieren und ausgeben */
		int2str(ob_get_text(xacc_tree,TIMEDEMO,0),(int) ((time-start_time)/1000l),5);
		ob_draw(xacc_dial,TIMEDEMO);
		return(CONT_TIMER); /* Timer periodisch fortsetzen */
	}
	else
		return(STOP_TIMER); /* Timer freigeben */
}

long DemoTimer(long p,long t,MKSTATE *m)
{
	if (demo_dial)
	{
		/* Fliegender Dialog oder Fenster nicht ikonifiziert? */
		if (demo_dial->di_flag<WINDOW || !demo_dial->di_win->iconified)
		{
			strcpy(&scroller[0],&scroller[1]);
			scroller[sizeof(scroller)-2] = *scroll_pos++;
			if (*scroll_pos=='\0') /* Ende des Scroll-Textes? */
				scroll_pos = scroll_text; /* dann wieder von vorne */
			ob_draw(demo_dial,SCROLLER);
		}
		return(CONT_TIMER);
	}
	else
		return(STOP_TIMER);
}

/***********************************************************************
 (De-) aktiviert einzelne Men�punkte in Abh�ngigkeit davon, ob der
 Hauptdialog bereits ge�ffnet ist
***********************************************************************/
void SetMenu(void)
{
	static int objects[]={FLYMENU,WINMENU,SIZEMENU,MODMENU,FRAMMENU,SMALMENU,MIDMENU,0},last=1;
	int *mn=objects,new = main_dial ? 0 : 1;

	if (new!=last)
	{
		beg_update(FALSE,FALSE);	/* aus Geschwindigkeitsgr�nden */
		while (*mn!=0)
			menu_item_enable(*mn++,new);
		last = new;
		end_update(FALSE);
	}
}

/***********************************************************************
 Fehlermeldung in Alertbox ausgeben
***********************************************************************/
void error(int icn,char *err)
{
	xalert(1,1,icn,NULL,SYS_MODAL,BUTTONS_CENTERED,TRUE,x_name,err,NULL);
}

/***********************************************************************
 Dialog �ffnen bzw. in den  Vordergrund bringen, falls schon ge�ffnet
***********************************************************************/
void OpenDialog(MENUITEM *item)
{
	int edit=0,idx=item->index;
	DIAINFO **info=&dials[idx],*dial=*info;
	SLINFO **slider=NULL;
	XPOPUP **popup=NULL;

	if (dial==NULL)	/* Dialog nicht ge�ffnet? */
	{
		switch (idx)
		{
		case HELP_DIAL:
			slider = sl_help_list;break;
		case XACC_DIAL:
			popup = menu_list;break;
		case ALERTS_DIAL:
			slider = sl_alert_list;break;
		case MAIN_DIAL:
			popup = pop_list;
			slider = sl_main_list;
			edit = DATEI;
		}

		/* automatischen 3D-Look bei Eingabefeldern ausschalten, wei�er
		   Hintergrund im Hilfe-Dialog */
		dial_colors(7,idx!=HELP_DIAL ? FAIL : WHITE,BLACK,RED,RED,BLACK,BLACK,BLACK,BLACK,FAIL,FAIL,FAIL,FAIL,FALSE,TRUE);

		/* Dialog �ffnen (keine Grow-Boxen) */
		dial = open_dialog(*item->tree,item->title+1,NULL,NULL,item->center,FALSE,item->mode,edit,slider,popup);

		dial_colors(7,FAIL,BLACK,RED,RED,BLACK,BLACK,BLACK,BLACK,FAIL,FAIL,FAIL,FAIL,FALSE,TRUE);

		if (dial==NULL)
			error(X_ICN_ERROR,"Konnte Dialog nicht �ffnen!");
		else
		{
			*info = dial;
			switch (idx)
			{
			case HELP_DIAL:	/* Info-Zeile des Hilfe-Dialogs setzen */
				window_info(dial->di_win,"Ein Dialog mit Infozeile u. Echtzeitschieber!");break;
			case MAIN_DIAL:	/* Men�leiste aktualisieren */
				SetMenu();break;
			case XACC_DIAL:	/* periodische Timer starten */
				NewTimer(1000,0,XAccTimer);break;
			case DEMO_DIAL:
				NewTimer(80,0,DemoTimer);
			}
		}
	}
	else if (dial->di_flag>=WINDOW)
		window_top(dial->di_win);	/* Fensterdialog in den Vordergrund */

	/* Verwaltung der ge�ffneten Dialoge u. Auswertung der Benutzeraktionen */
	HandleDialog();
}

/***********************************************************************
 Men�auswertungsroutine, welche bei Bedarf den zu einem Hotkey geh�renden
 Men�punkt ermittelt und die zu diesem Men�punkt geh�rende Funktion aus-
 f�hrt
***********************************************************************/
int MenuSelect(int object,int scan,int state)
{
	WIN *win;
	char mod[MAX_PATH];
	DIAINFO *ed=NULL;
	MENUITEM *item=items;
	int index,key;

	for (key=scan_2_ascii(scan,state),index=ITEMS;--index>=0;item++)
		/* Eintrag zu Men�punkt ermitteln */
		if (object>0)
		{
			if (item->object==object)
				break;
		}
		/* Eintrag zu Tastatur-Ereignis ermitteln */
		else if (item->shortcut==key && item->state==state)
			break;

	if (index<0)
		return(FALSE);	/* kein entsprechender Eintrag gefunden */

	/* Fenster-Men�punkte&Hotkeys werden von der Library gesetzt u. ausgewertet */

	switch (item->object)
	{
	case QUIT:
		ExitExample(1);break;	/* Applikation beenden */
	case ASCIMENU:
		/* Obersten Fensterdialog ermitteln */
		if ((win=get_window_list(TRUE))!=NULL)
			ed = win->dialog;
		ascii_box(ed,NULL);		/* ASCII-Zeicheneingabebox (f�r obersten Dialog) */
		break;
	case FONTMENU:
		FontSelect(FSEL_WIN,&fsel);break; /* FontSelector aufrufen */
	case PAULA:
		if (AppLoaded("PAULA")>=0)
			switch (xalert(4,4,X_ICN_QUESTION,NULL,APPL_MODAL,BUTTONS_CENTERED,FALSE,NULL,paula_text,paula_button))
			{
			case 0:
				/* Paula beenden */
				PaulaShutDown();break;
			case 1:
				/* Musikwiedergabe stoppen */
				PaulaStop();break;
			case 2:
				/* Musikst�ck an Paula �bergeben */
				if (FileSelect("MOD-file abspielen...",path,fname,NULL,FALSE,0,0l)>0)
					PaulaStart(MakeFullpath(mod,path,fname));
			}
		else
			error(X_ICN_ALERT,"Paula>=V2.4 nicht installiert!");
		break;
	default:
		OpenDialog(item);		/* Dialog �ffnen */
	}
	return(TRUE);
}

/***********************************************************************
 Verwaltung der ge�ffneten Dialoge und Auswertung der Benutzeraktionen
***********************************************************************/
void HandleDialog(void)
{
	static int already=0;
	ALERT *al;
	BITBLK *user;
	DIAINFO *info;
	int i,icon;
	char *but,*txt;

	if (already)	/* Wird die Verwaltung bereits �bernommen? */
		return;		/* verhindert Rekursion und spart somit Speicher */
	else
		already++;

	do
	{
		/* Auf Benutzeraktionen warten:
			i: angew�hltes Objekt (>=0), Fenster-Closer/Kein Objekt (AC_CLOSE/AP_TERM) (<0)
			info: Zeiger auf DIAINFO-Struktur des angew�hlten Dialogs */
		if ((i=XFormObject(&info,NULL))>=0)
		{
			ob_select(info,info->di_tree,i,FALSE,TRUE); /* Objekt deselektieren */
			if (info==main_dial) /* Demonstrations-Dialog */
			{
				switch (i)
				{
				/* Hilfe-Button -> Hilfe-Dialog �ffnen */
				case QUESTION:
				case HELP:
					OpenDialog(&items[HELP_ITEM]);continue;
				/* Suchen-Button -> Warnung (Disketten-Fehler) ausgeben */
				case SEARCH:
					error(X_ICN_DISC_ERR,"Keine Datei gefunden!");
					continue;
				}
			}
			else if (info==alerts_dial && i==DOALERT) /* Alert-Boxen */
			{
				user = NULL;
				but = al_button;txt = al_text;

				icon = sl_alert.sl_pos-1; /* gew�nschtes Icon */
				if (icon>X_ICN_MAX)	/* benutzerdefiniertes Icon */
				{
					user = icon_tree[USERICON].ob_spec.bitblk;
					but = ci_button;txt = ci_text;
				}

				/* Alertbox entsprechend den Einstellungen darstellen */
				if ((al=MakeAlert(2,1,icon,user,SYS_MODAL,ob_radio(alerts_tree,ALERTOPT,-1),ob_isstate(alerts_tree,BTNWIDTH,SELECTED),NULL,txt,but))!=NULL)
				{
					DIAINFO *alert;
					if ((alert=open_dialog(al->tree,x_name,NULL,NULL,DIA_MOUSEPOS,FALSE,modal[ob_radio(alerts_tree,ALMODAL,-1)],0,NULL,NULL))!=NULL)
						alert->di_alert = al;
					else
					{
						free(al);
						error(X_ICN_ERROR,"Konnte Alertbox nicht �ffnen!");
					}
				}
				continue;
			}
		}
		close_dialog(info,FALSE);	/* Dialog schlie�en */
		for (i=MAX_DIALOGS;--i>=0;)
			if (info==NULL || dials[i]==info)
				dials[i] = NULL;
		SetMenu();
	} while (info!=NULL);
	already--;
}

/***********************************************************************
 Sliderposition an neuen Wert in Eingabefeld anpassen
***********************************************************************/
void SetSlider(SLINFO *sl)
{
	sl->sl_do = NULL;
	sl->sl_pos = atoi(ob_get_text(main_tree,sl->sl_slider,0));
	graf_set_slider(sl,main_tree,GRAF_DRAW);
	sl->sl_do = do_count;
}

/***********************************************************************
 Initialisierungs-Routine, welche von Event_Multi aufgerufen wird und die
 Event-Struktur setzt sowie die gew�nschten Ereignisse zur�ckgibt
***********************************************************************/
int InitMsg(XEVENT *evt,int available)
{
	/* auf Nachrichten und Tastendr�cke warten, falls verf�gbar */
	return((MU_MESAG|MU_KEYBD)&available);
}

/***********************************************************************
 Ereignisauswertung (AES-Nachrichten, Tastendr�cke), welche von
 Event_Multi() aufgerufen wird
***********************************************************************/
int Messag(XEVENT *evt)
{
	DIAINFO *info;
	int ev=evt->ev_mwich,*msg=evt->ev_mmgpbuf,ed;
	char *name;

	/* Nachricht-Ereignis */
	if (ev & MU_MESAG)
	{
		switch (*msg)
		{
		/* Men�eintrag angeklickt ? */
		case MN_SELECTED:
			/* Men�eintrag deselektieren (bei Fenster-Men�s ist msg[3]
			   negativ, wodurch menu_select ohne Aktion zur�ckkehrt) */
			menu_select(msg[3],0);
			if (*(OBJECT **) &msg[5]==menu)	/* Men�-Leiste? */
				MenuSelect(msg[4],0,0);	/* gew�nschte Funktion ausf�hren */
			else if (msg[4]==QUITPOP)		/* ansonsten Fenster-Men� */
				ExitExample(1);			/* Programm beenden */
			break;
		/* Applikation beenden/r�cksetzen */
		case AP_TERM:
			ExitExample(1);break;
		/* Applikation hat sich an- oder abgemeldet */
		case XACC_AV_INIT:
		case XACC_AV_EXIT:
		case XACC_AV_CLOSE:
			{
				XAcc *xacc;
				int first,xacc_cnt=0,av_cnt=0;
				static int list[]={XACCCNT,AVCNT,AVSERVER,0};

				first = 1;	/* erste Applikation suchen */
				while ((xacc=find_app(first))!=NULL)
				{
					if (xacc->flag & XACC)	/* XAcc-Applikation? */
						xacc_cnt++;
					if (xacc->flag & AV)	/* AV-Applikation? */
						av_cnt++;
					first=0;	/* n�chste Applikation suchen */
				}

				int2str(ob_get_text(xacc_tree,XACCCNT,0),xacc_cnt,0);
				int2str(ob_get_text(xacc_tree,AVCNT,0),av_cnt,0);

				ob_set_text(xacc_tree,AVSERVER,AvServer>=0 ? find_id(AvServer)->name : "");

				/* Objekte neuzeichnen, sofern Dialog ge�ffnet */
				ob_draw_list(xacc_dial,list,NULL);
			}
			break;
		/* Position eines Sliders hat sich ge�ndert */
		case SLIDER_CHANGED:
			info = (*(SLINFO **) &msg[4])->sl_info;goto user_action;
		/* Popup-Men� wurde ver�ndert */
		case POPUP_CHANGED:
			info = (*(XPOPUP **) &msg[4])->popup.p_info;goto user_action;
		/* Objekt wurde (de-) selektiert */
		case OBJC_CHANGED:
			/* gew�nschten Popup-Rand einstellen */
			pop.mode = POPUP_BTN_CHK|(ob_radio(main_tree,POPUPBOX,-1)*POPUP_3D);
		/* Eingabefeld wurde ver�ndert */
		case OBJC_EDITED:
			info = *(DIAINFO **) &msg[4];
			user_action:
			if (info && info->di_flag>=WINDOW && *(name=info->di_win->name)!='*' && *--name=='*')
				window_name(info->di_win,name,NULL); /* neue Titelzeile des Fensterdialogs setzen */
			if (*msg==OBJC_EDITED && info==main_dial)
			{
				if ((ed=msg[3])==EDITSLID || ed<0)
					SetSlider(&sl_edit);
				if (ed==COUNT || ed<0)
					SetSlider(&sl_count);
			}
			break;
		default:
			ev &= ~MU_MESAG; /* unbekannte Nachricht nicht ausgewertet  */
		}
	}

	/* Tastatur-Ereignis */
	if ((ev & MU_KEYBD) && !MenuSelect(FAIL,evt->ev_mkreturn,evt->ev_mmokstate))
		ev &= ~MU_KEYBD;	/* Tastaturereignis nicht ausgewertet */

	return(ev);
}

void main()
{
	if (_app)	/* Wurde die Demo als Programm gestartet? */
	{
		/* Resource-File laden und Bibliothek sowie AES und VDI initialisieren
		   (keine anwendungspezifische AV/VA/XAcc-Nachrichtenauswertung) */
		if (open_rsc("dialdemo.rsc","EGEM",entry,x_name,av_name,0,0,0)==TRUE)
		{
			start_time = clock()*5;	/* Start-Zeit setzen */
			init_resource();		/* Objektb�ume initialisieren */

			/* Routinen zur Ereignisauswertung anmelden */
			Event_Handler(InitMsg,Messag);

			/* Hotkeys und Men�punkte f�r Fenster anmelden */
			MenuItems(&Close,&CloseAll,&Cycle,&InvCycle,&GlobalCycle,&Full,&Bottom,&Iconify,&IconifyAll,NULL,0);

			/* Dialog-Optionen setzen, u.a. Hintergrundbedienung von
			  Fensterdialogen u. Tastendr�cke an Dialog unter Mauszeiger,
			  Return selektiert DEFAULT-Objekt bei letztem Eingabefeld,
			  Fliegen/Verschieben von Dialogen durch Anklicken eines nicht
			  selektierbaren Objekts */
			dial_options(TRUE,TRUE,FALSE,RETURN_LAST_DEFAULT,ALWAYS_BACK,TRUE,KEY_STD,TRUE,TRUE,3);

			menu_install(menu,TRUE);		/* Pull-Down-Men� anmelden */

			/* XAcc/AV-Info-Dialog �ffnen */
			OpenDialog(&items[XACC_ITEM]);

	        /* Auf Ereignis (Nachrichten/Tastendr�cke) warten und dieses
	           auswerten. In diesem Fall werden die ben�tigten Events be-
	           reits durch die Funktionen InitMsg() und Messag() gesetzt und
	           ausgewertet. Zus�tzlich k�nnte man nat�rlich hier noch wei-
	           tere Events angeben, die speziell ausgewertet werden, oder
	           den Event_Handler abmelden und alle Ereignisse hier auswerten.
	           Dann m��te man allerdings die Funktion Event_Multi in eine
	           Endlosschleife integrieren */
			Event_Multi(NULL);
		}
	}
	exit(-1); /* ansonsten Demo beenden */
}
