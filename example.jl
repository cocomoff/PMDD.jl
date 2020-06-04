# how to use

using PMDD

function main()
    g = Graph([(1, 2), (1, 5), (2, 4), (2, 5), (2, 6), (3, 5), (4, 5), (5, 6)])
    dd = build(g)
    println(length(dd.table))
    # dump_table(dd.table, sort=true)
    info = compute_dd_graph(dd)
    pi = traverse(info, debug_print=false)
    for perm in pi
        println(perm)
    end
end

main()