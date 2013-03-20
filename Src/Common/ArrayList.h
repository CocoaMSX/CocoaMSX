/*****************************************************************************
** $Source$
**
** $Revision$
**
** $Date$
**
** More info: http://www.bluemsx.com
**
** Copyright (C) 2003-2013 Daniel Vik, Akop Karapetyan
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
** 
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**
******************************************************************************
*/
#ifndef ARRAY_LIST_H
#define ARRAY_LIST_H

#include "MsxTypes.h"

typedef struct ArrayList ArrayList;
typedef struct ArrayListIterator ArrayListIterator;

// Initialization & cleanup

ArrayList * arrayListCreate();
void        arrayListDestroy(ArrayList *list);

// Manipulation

int         arrayListInsert(ArrayList *list, int insertAt, void *object, int managed);
int         arrayListPrepend(ArrayList *list, void *object, int managed);
int         arrayListAppend(ArrayList *list, void *object, int managed);
int         arrayListRemove(ArrayList *list, int removeAt);

// Information

void *      arrayListGetObject(const ArrayList *list, int elementAt);
int         arrayListGetSize(const ArrayList *list);

// Iteration

ArrayListIterator * arrayListCreateIterator(const ArrayList *list);
void                arrayListDestroyIterator(ArrayListIterator *iterator);

void *              arrayListIterate(ArrayListIterator *iterator);
int                 arrayListCanIterate(const ArrayListIterator *iterator);

#endif
