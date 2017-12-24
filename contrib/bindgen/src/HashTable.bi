'' The hash table is an array of items,
'' which associate a string to some user data.
type HashTableItem
    s as const zstring ptr
    hash as ulong     '' hash value for quick comparison
    data as any ptr   '' user data
end type

type HashTable
    items as HashTableItem ptr
    count as integer  '' number of used items
    room as integer  '' number of allocated items

    declare constructor(byval exponent as integer)
    declare constructor(byref as const HashTable) '' unimplemented
    declare operator let(byref as const HashTable) '' unimplemented
    declare destructor()

    declare function lookup(byval s as const zstring ptr, byval hash as ulong) as HashTableItem ptr
    declare function lookupDataOrNull(byval id as const zstring ptr) as any ptr
    declare function contains(byval s as const zstring ptr, byval hash as ulong) as integer
    declare sub add(byval item as HashTableItem ptr, byval hash as ulong, byval s as const zstring ptr, byval dat as any ptr)
    declare function addOverwrite(byval s as const zstring ptr, byval dat as any ptr) as HashTableItem ptr
    #if __FB_DEBUG__
        declare sub dump()
    #endif

private:
    declare sub allocTable()
    declare sub growTable()
end type

declare function hashHash(byval s as const zstring ptr) as ulong
