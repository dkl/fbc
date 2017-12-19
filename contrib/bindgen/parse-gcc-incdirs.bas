var f = freefile()
if open cons(for input, as f) <> 0 then
    print "error: can't open stdin"
    end 1
end if

enum
    StateNotYet
    StatePart1
    StatePart2
    StateFinished
end enum
dim state as integer

dim ln as string
while not eof( f )
    line input #f, ln

    select case ln
    case "#include ""..."" search starts here:"
        if state = StateNotYet then
            state = StatePart1
        end if

    case "#include <...> search starts here:"
        if state = StatePart1 then
            state = StatePart2
        end if

    case "End of search list."
        state = StateFinished

    case else
        select case state
        case StatePart1, StatePart2
            if len(ln) > 1 andalso ln[0] = asc(" ") then
                ln = right(ln, len(ln) - 1)
                print ln
            end if
        end select

    end select
wend

close f
