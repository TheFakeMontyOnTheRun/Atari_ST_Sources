/*
   Modul: M_RSC (Headerdatei)

   geschrieben von Thomas K�nneth
   Friedrich-Neuper-Str. 2b
   90552 R�thenbach

   Diese Datei ist Bestandteil der C-Version von Magic 4.0 von
   Peter Hellinger und Thomas K�nneth und darf nur gem�� den
   Nutzungsbedingungen von Magic f�r C verwendet werden

   Alle Rechte beim Autor
*/

#ifndef _MPRSC_
#define _MPRSC_

#ifndef _MAGICTYP_
#include <magic\m_types.h>
#endif

BOOLEAN LoadRsc(char *name,void **rsc);
BOOLEAN RelocRsc(void *address,OBJECT **rsc);
void FreeRsc(void **rsc);
void *GaddrRsc(void *rsc,int typ,int item);
void SaddrRsc(void *rsc,int typ,int item,OBJECT *tree);
void ObfixRsc(void *rsc,OBJECT *tree,int objc);

#endif