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
#ifndef HASHSET_H
#define HASHSET_H

typedef struct HashSet HashSet;

typedef size_t (*HashSetHashComputeCallback)(const void *);

HashSet *hashSetCreate(HashSetHashComputeCallback callback);
void hashSetDestroy(HashSet *set);

int hashSetGetSize(HashSet *set);

/* add item into the hashset.
 *
 * @note 0 and 1 is special values, meaning nil and deleted items. the
 *       function will return -1 indicating error.
 *
 * returns zero if the item already in the set and non-zero otherwise
 */
int hashSetAdd(HashSet *set, const void *item);

/* remove item from the hashset
 *
 * returns non-zero if the item was removed and zero if the item wasn't
 * exist
 */
int hashSetRemove(HashSet *set, const void *item);

/* check if existence of the item
 *
 * returns non-zero if the item exists and zero otherwise
 */
int hashSetContains(HashSet *set, const void *item);

/* Generic hashing algorithm for strings.
 * Based on sdbm: http://www.cse.yorku.ca/~oz/hash.html
 *
 */
size_t hashSetComputeStringHash(const void *ptr);

#endif
