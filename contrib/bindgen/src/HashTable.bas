''
'' Generic hash table (open addressing/closed hashing), based on GCC's libcpp's
'' hash table.
''
'' Note: No deletions possible due to the collision resolution adding duplicates
'' to other entries in the table, instead of adding to the same bucket.
'' Each duplicate can be reached by following through the chain of steps
'' indicated by hashHash2(), the first free entry reached indicates the end of
'' the chain -- that's where duplicates are inserted. Removing an entry from
'' this chain would cause the following entries to become unreachable/lost,
'' as the free item in the middle would appear as the end of the chain now.
''
'' If the hash table owns the strings then hashAdd() will duplicate them and
'' then never change them again until hashEnd() which frees them.
''

#include once "HashTable.bi"
#include once "crt/mem.bi"

function hashHash(byval s as const zstring ptr) as ulong
    dim as long hash = 5381
    while (*s)[0]
        hash = (*s)[0] + (hash shl 5) - hash
        s += 1
    wend
    function = hash
end function

private function hashHash2(byval s as const zstring ptr) as ulong
    dim as ulong hash = 0
    while (*s)[0]
        hash = (*s)[0] + (hash shl 6) + (hash shl 16) - hash
        s += 1
    wend
    function = hash
end function

sub HashTable.allocTable()
    '' They must be zeroed, because NULL instead of a string indicates
    '' unused items
    items = callocate(room * sizeof(HashTableItem))
end sub

sub HashTable.growTable()
    var olditems = items
    var oldroom = room

    room shl= 1
    allocTable()

    '' Insert all used items from the old table into the new one.
    '' This will redistribute everything using the new h->room.
    for item as HashTableItem ptr = olditems to (olditems + (oldroom - 1))
        if item->s then
            '' Yep, this is recursive, but since the table is
            '' larger by now, we won't recurse in here again.
            *lookup(item->s, item->hash) = *item
        end if
    next

    deallocate(olditems)
end sub

function HashTable.lookup(byval s as const zstring ptr, byval hash as ulong) as HashTableItem ptr
    '' Enlarge the hash map when >= 75% is used up, for better lookup
    '' performance (it's easier to find free items if there are many; i.e.
    '' less collisions), and besides there always must be free slots,
    '' otherwise a lookup could end up in an infinite loop.
    if (count * 4) >= (room * 3) then
        growTable()
    end if

    dim as uinteger roommask = room - 1

    '' First probe
    var i = hash and roommask
    var item = @items[i]

    '' Found unused item with first probe?
    if item->s = NULL then
        return item
    end if

    '' Item is used. Is it the correct string?
    if item->hash = hash then
        if *item->s = *s then
            return item
        end if
    end if

    '' The first probe reached an item containing the wrong string.
    '' The collision is resolved by stepping through items until a
    '' free item or the look-for string is found.
    ''
    '' The step size is calculated based on a 2nd hash value. It is or'ed
    '' with 1 to make sure it's odd, so all items will eventually be
    '' reached, because h->room always is a power of 2.
    var stepsize = (hashHash2(s) and roommask) or 1

    do
        i = (i + stepsize) and roommask
        item = @items[i]

        '' Found unused item?
        '' The string is not in the hash, or it would have been found before.
        if item->s = NULL then
            exit do
        end if

        '' Item is used. Is it the correct string?
        if item->hash = hash then
            if *item->s = *s then
                exit do
            end if
        end if
    loop

    function = item
end function

function HashTable.lookupDataOrNull(byval id as const zstring ptr) as any ptr
    var item = lookup(id, hashHash(id))
    if item->s then
        function = item->data
    end if
end function

function HashTable.contains(byval s as const zstring ptr, byval hash as ulong) as integer
    function = (lookup(s, hash)->s <> NULL)
end function

sub HashTable.add(byval item as HashTableItem ptr, byval hash as ulong, byval s as const zstring ptr, byval dat as any ptr)
    item->s = s
    item->hash = hash
    item->data = dat
    count += 1
end sub

'' Add entry, overwriting previous user data stored in that slot
function HashTable.addOverwrite(byval s as const zstring ptr, byval dat as any ptr) as HashTableItem ptr
    var hash = hashHash(s)
    var item = lookup(s, hash)

    if item->s then
        '' Already exists
        assert(*item->s = *s)
        assert(item->hash = hash)
    else
        '' New entry
        item->s = s
        item->hash = hash
        count += 1
    end if

    item->data = dat

    function = item
end function

constructor HashTable(byval exponent as integer)
    count = 0
    room = 1 shl exponent
    allocTable()
end constructor

destructor HashTable()
    deallocate(items)
end destructor

#if __FB_DEBUG__
sub HashTable.dump()
    print "hash: " & count & "/" & room & " slots used"
    for i as integer = 0 to room - 1
        with items[i]
            if .s then
                print "  " & i & ": hash=" + hex(.hash) + ", s=""" + *.s + """, data=" + hex(.data)
            end if
        end with
    next
end sub
#endif
