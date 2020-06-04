export DD, build

mutable struct DD
    index::Int
    table::Dict{Set{Int}, DDNode}
    n::Int
    N::Array{Int, 1}
    setN::Set{Int}
    terminal::DDNode

    # constructor
    function DD(n::Int)
        # terminal node
        terminal = DDNode(Set{Int}())
        table = Dict{Set{Int}, DDNode}()
        table[Set{Int}()] = terminal
        new(1, table, n, collect(1:n), Set(collect(1:n)), terminal)
    end
end

function table_insert!(pmdd::DD, node::DDNode)
    node.index = pmdd.index
    pmdd.index += 1
    pmdd.table[node.setV] = node
end

function make!(pmdd::DD, G::Graph, V::Set{Int}; c::Int=0)
    isempty(V) && return pmdd.terminal
    haskey(pmdd.table, V) && return pmdd.table[V]

    # construct new node and register
    node = DDNode(V)
    fV0 = [v for v in G.nodes if degree(G, v) == 0]
    for v in fV0
        es = [n for n in G.nodes if v in G.adj[n]]
        remove_node!(G, v)
        πMDDv = make!(pmdd, G, setdiff(V, v), c=c+1)
        node.children[v] = πMDDv
        add_node!(G, v)
        for e in es
            add_edge!(G, e, v)
        end
    end
    table_insert!(pmdd, node)
    return node
end

function build(G::Graph)
    n = G.nV
    pmdd = DD(n)
    make!(pmdd, G, pmdd.setN, c=0)
    pmdd
end

struct DiagramInfo
    all_index::Set{Int}
    index2set::Dict{Int, Set{Int}}
    set2index::Dict{Set{Int}, Int}
    edge_map::Dict{Int, Dict{Int, Int}}
    map_parent::Dict{Int, Set{Int}}
    map_children::Dict{Int, Set{Int}}
    index_root::Int
    index_terminal::Int
end

# functions
export compute_dd_graph

compute_dd_graph(dd::DD) = _compute_dd_graph(dd.table, dd.setN)
function _compute_dd_graph(table::Dict{Set{Int}, DDNode}, setN::Set{Int})
    # root & terminal index
    i_r = table[setN].index
    i_t = table[Set{Int}()].index
    all_index = Set{Int}()
    index2set = Dict{Int, Set{Int}}()
    set2index = Dict{Set{Int}, Int}()
    for (key, node) in table
        set2index[key] = node.index
        index2set[node.index] = key
        push!(all_index, node.index)
    end

    map_p = Dict{Int, Set{Int}}(n => Set{Int}() for n in all_index)
    map_c = Dict{Int, Set{Int}}(n => Set{Int}() for n in all_index)

    # build edge map
    edge_map = Dict{Int, Dict{Int, Int}}(n => Dict{Int, Int}() for n in all_index)
    for (key, node) in table
        for (val, child) in node.children
            cid = set2index[child.setV]
            edge_map[node.index][val] = cid
            push!(map_p[cid], node.index)
            push!(map_c[node.index], cid)
        end
    end
    DiagramInfo(all_index, index2set, set2index, edge_map, map_p, map_c, i_r, i_t)
end


export traverse
function traverse(info::DiagramInfo; debug_print=false)
    ans = Dict{Int, Set{Path}}()
    _traverse(info, ans, info.index_root)

    # debug
    if debug_print
        for v in 0:maximum(info.all_index)
            println("Index $v ($(set2str(info.index2set[v])))")
            pathV = ans[v]
            for path in pathV
                println("   $path")
            end
        end
    end
    return ans[info.index_root]
end

function _traverse(info::DiagramInfo, ans::Dict{Int, Set{Path}}, node::Int)
    if !haskey(ans, node)
        # call children and concatenate paths
        path_children = Set{Path}()
        for (v, vindex) in info.edge_map[node]
            pathC = _traverse(info, ans, vindex)
            if isempty(pathC)
                if v > 0
                    push!(path_children, Vector{Int}([v]))
                else
                    push!(path_children, Vector{Int}([]))
                end
            else
                if v < 0
                    union!(path_children, pathC)
                else
                    union!(path_children, [vcat(path, v) for path in pathC])
                end
            end
        end
        ans[node] = path_children
    end
    return ans[node]
end