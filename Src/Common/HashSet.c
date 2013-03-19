/*****************************************************************************
 ** File:        HashSet.c
 **
 ** Author:      Akop Karapetyan
 **
 ** Description: Generic HashSet implementation for C
 ** Adapted from https://github.com/avsej/hashset.c
 **
 ** More info:   www.bluemsx.com
 **
 ** Copyright (C) 2013 Akop Karapetyan
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
#include <stdlib.h>

#include "HashSet.h"

struct HashSet
{
    size_t nbits;
    size_t mask;
    
    size_t capacity;
    size_t *items;
    size_t nitems;
    
    HashSetHashComputeCallback callback;
};

static const unsigned int prime_1 = 73;
static const unsigned int prime_2 = 5009;

HashSet *hashSetCreate(HashSetHashComputeCallback callback)
{
    HashSet *set = calloc(1, sizeof(HashSet));
    if (set == NULL)
        return NULL;
    
    set->nbits = 3;
    set->capacity = (size_t)(1 << set->nbits);
    
    set->items = calloc(set->capacity, sizeof(size_t));
    if (set->items == NULL)
    {
        free(set);
        return NULL;
    }
    
    set->callback = callback;
    set->mask = set->capacity - 1;
    set->nitems = 0;
    
    return set;
}

void hashSetDestroy(HashSet *set)
{
    if (set)
        free(set->items);
    
    free(set);
}

static int hashSetAddMember(HashSet *set, size_t value)
{
    size_t ii;
    
    if (value == 0 || value == 1)
        return -1;
    
    ii = set->mask & (prime_1 * value);
    
    while (set->items[ii] != 0 && set->items[ii] != 1)
    {
        if (set->items[ii] == value)
        {
            return 0;
        }
        else
        {
            /* find a free slot */
            ii = set->mask & (ii + prime_2);
        }
    }
    
    set->nitems++;
    set->items[ii] = value;
    
    return 1;
}

static void hashSetRehashIfNeeded(HashSet *set)
{
    size_t *old_items;
    size_t old_capacity, ii;
    
    
    if ((float)set->nitems >= (size_t)((double)set->capacity * 0.85))
    {
        old_items = set->items;
        old_capacity = set->capacity;
        
        set->nbits++;
        set->capacity = (size_t)(1 << set->nbits);
        set->mask = set->capacity - 1;
        set->items = calloc(set->capacity, sizeof(size_t));
        set->nitems = 0;
        
        for (ii = 0; ii < old_capacity; ii++)
            hashSetAddMember(set, old_items[ii]);
        
        free(old_items);
    }
}

int hashSetAdd(HashSet *set, const void *item)
{
    int rv = hashSetAddMember(set, set->callback(item));
    hashSetRehashIfNeeded(set);
    
    return rv;
}

int hashSetGetSize(HashSet *set)
{
    return set->nitems;
}

int hashSetRemove(HashSet *set, const void *item)
{
    size_t value = set->callback(item);
    size_t ii = set->mask & (prime_1 * value);
    
    while (set->items[ii] != 0)
    {
        if (set->items[ii] != value)
        {
            ii = set->mask & (ii + prime_2);
        }
        else
        {
            set->items[ii] = 1;
            set->nitems--;
            
            return 1;
        }
    }
    
    return 0;
}

int hashSetContains(HashSet *set, const void *item)
{
    size_t value = set->callback(item);
    size_t ii = set->mask & (prime_1 * value);
    
    while (set->items[ii] != 0)
    {
        if (set->items[ii] == value)
            return 1;
        else
            ii = set->mask & (ii + prime_2);
    }
    
    return 0;
}

size_t hashSetComputeStringHash(const void *ptr)
{
    const char *string = ptr;
    size_t hash = 0;
    int c;
    
    while ((c = *string++) != 0)
        hash = c + (hash << 6) + (hash << 16) - hash;
    
    return hash;
}