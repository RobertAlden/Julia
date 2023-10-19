
function isfuzzymatch(needle, haystack)
  n = 1
  for h in eachindex(haystack)
    if needle[n] == haystack[h]
      n == length(needle) && return true
      n += 1
    end
  end
  return false
end

function main()
  while (true)
    println("Cast a spell!")
    spell = readline()
    print("You attempt to cast: $spell")
    for i in 1:3
      print(".")
      sleep(1)
    end
    println("")
    println("It fizzles!")
  end
end
