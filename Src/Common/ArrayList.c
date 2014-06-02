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

#include "ArrayList.h"

#include <stdlib.h>

struct ArrayListNode
{
    struct ArrayListNode *next;
    void  *object;
    int    managed;
};

typedef struct ArrayListNode ArrayListNode;

struct ArrayList
{
    ArrayListNode *head;
    ArrayListNode *tail;
    int size;
};

struct ArrayListIterator
{
    const ArrayListNode *current;
    const ArrayList *list;
};

static ArrayListNode *arrayListCreateNode(void *object, int managed);
static ArrayListNode *arrayListDestroyNode(ArrayListNode *node);
static ArrayListNode *arrayListFindNodeAtIndex(const ArrayList *list, int elementAt);

ArrayList *arrayListCreate()
{
    ArrayList *list = (ArrayList *)malloc(sizeof(ArrayList));
    
    list->head = NULL;
    list->tail = NULL;
    list->size = 0;
    
    return list;
}

void arrayListDestroy(ArrayList *list)
{
    ArrayListNode *node = list->head;
    while (node)
        node = arrayListDestroyNode(node);
    
    free(list);
}

static ArrayListNode *arrayListFindNodeAtIndex(const ArrayList *list, int elementAt)
{
    int index = 0;
	ArrayListNode *current;

    if (elementAt < 0 || elementAt >= list->size)
        return NULL;
    
    for (current = list->head; current; current = current->next, index++)
        if (index == elementAt)
            return current;
    
    return NULL;
}

static ArrayListNode *arrayListCreateNode(void *object, int managed)
{
    ArrayListNode *node = (ArrayListNode *)malloc(sizeof(ArrayListNode));
    
    if (node)
    {
        node->next = NULL;
        node->object = object;
        node->managed = managed;
    }
    
    return node;
}

static ArrayListNode *arrayListDestroyNode(ArrayListNode *node)
{
    ArrayListNode *next;

    if (!node)
        return NULL;
    
    next = node->next;
    if (node->managed)
        free(node->object);
    
    free(node);
    
    return next; // Return the next node
}

int arrayListInsert(ArrayList *list, int insertAt, void *object, int managed)
{
    ArrayListNode *newNode;

    if (insertAt < 0 || insertAt > list->size)
        return 0;
    
    newNode = arrayListCreateNode(object, managed);
    if (!newNode)
        return 0;
    
    if (insertAt == list->size)
    {
        // Append
        if (list->tail)
            list->tail->next = newNode;
        
        list->tail = newNode;
    }
    else if (insertAt == 0)
    {
        // Prepend
        newNode->next = list->head;
        list->head = newNode;
    }
    else
    {
		ArrayListNode *nextNode;
		ArrayListNode *precedingNode;

        // Find the node previous to the location we're inserting
        precedingNode = arrayListFindNodeAtIndex(list, insertAt - 1);
        if (!precedingNode)
        {
            arrayListDestroyNode(newNode);
            return 0;
        }
        
        // Get a reference to the current next node
        nextNode = precedingNode->next;
        
        // Insert the element
        precedingNode->next = newNode;
        newNode->next = nextNode;
    }
    
    if (!list->head)
        list->head = newNode;
    
    if (!list->tail)
        list->tail = newNode;
    
    list->size++;
    
    return 1;
}

int arrayListPrepend(ArrayList *list, void *object, int managed)
{
    return arrayListInsert(list, 0, object, managed);
}

int arrayListAppend(ArrayList *list, void *object, int managed)
{
    return arrayListInsert(list, list->size, object, managed);
}

int arrayListRemove(ArrayList *list, int removeAt)
{
    if (removeAt < 0 || removeAt >= list->size)
        return 0;
    
    if (removeAt == 0)
    {
        // Remove head
        ArrayListNode *next = arrayListDestroyNode(list->head);
        
        if (list->tail == list->head)
            list->tail = NULL;
        
        list->head = next;
    }
    else
    {
		ArrayListNode *nodeToRemove;
		ArrayListNode *precedingNode;

        // Find the node previous to the one we're removing
        precedingNode = arrayListFindNodeAtIndex(list, removeAt - 1);
        if (!precedingNode)
            return 0;
        
        nodeToRemove = precedingNode->next;
        if (!nodeToRemove)
            return 0;
        
        precedingNode->next = nodeToRemove->next;
        if (list->tail == nodeToRemove)
            list->tail = precedingNode;
        
        arrayListDestroyNode(nodeToRemove);
    }
    
    list->size--;
    
    return 1;
}

int arrayListGetSize(const ArrayList *list)
{
    return list->size;
}

void *arrayListGetObject(const ArrayList *list, int elementAt)
{
    ArrayListNode *node = arrayListFindNodeAtIndex(list, elementAt);
    if (!node)
        return NULL;
    
    return node->object;
}

ArrayListIterator *arrayListCreateIterator(const ArrayList *list)
{
    ArrayListIterator *iterator = (ArrayListIterator *)malloc(sizeof(ArrayListIterator));
    if (iterator)
    {
        iterator->list = list;
        iterator->current = list->head;
    }
    
    return iterator;
}

void arrayListDestroyIterator(ArrayListIterator *iterator)
{
    free(iterator);
}

void *arrayListIterate(ArrayListIterator *iterator)
{
	void *object;

    if (!iterator->current)
        return NULL;
    
    object = iterator->current->object;
    iterator->current = iterator->current->next;
    
    return object;
}

int arrayListCanIterate(const ArrayListIterator *iterator)
{
    return (iterator->current != NULL);
}