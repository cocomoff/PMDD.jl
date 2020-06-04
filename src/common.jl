# common.jl

mutable struct DDNode
    setV::Set{Int}
    parent::Set{Int}
    children::Dict{Int,DDNode}
    depth::Int
    counter::Int
    index::Int
    
    # constructor
    DDNode(setV::Set{Int}) = new(setV, Set(), Dict(), -1, 1, 0)
    DDNode(parent::Int) = new(Set(), Set([parent]), Dict(), -1, 1, 0)
end

export IntSet
const IntSet = Set{Int}

export Path
const Path = Vector{Int}

export LocMemo
struct LocMemo
    location::Int
    cost::Float64
    perm::Array{Int, 1}
    locP::IntSet
    locS::IntSet
end

function set_index(d::DDNode, i)
    d.index = i
end

function set_depth(d::DDNode, i)
    d.depth = i
end

function increase(d::DDNode)
    d.counter += 1
end

function insert_parent(d::DDNode, np)
    push!(d.parent, np)
end

function comp(a, b)
    if length(a) < length(b)
        return true
    elseif length(a) > length(b)
        return false
    else
        return sort(collect(a)) < sort(collect(b))
    end
end

function comp2(a, b)
    if a > 0 && b > 0
        return a < b
    elseif abs(a) == abs(b)
        return a > b
    else
        return abs(a) < abs(b)
    end
end

export dump_table
function dump_table(table::Dict{Set{Int}, DDNode}; sort=false, show_id=false)
    println("-------------------------")
    println("|table|=$(length(table))")
    if !sort
        for (key, node) in table
            println("$(set2str(key))")
            for (ckey, cnode) in node.children
                println("  $ckey $cnode")
            end
        end
    else
        # println(length(table))
        listkey = collect.(keys(table))
        listkey = [sort!(key) for key in listkey]
        sort!(listkey, lt=(a, b) -> comp(a, b))
        for key in listkey
            node = table[Set{Int}(key)]
            if show_id
                println("[$(node.index)] $node")
            else
                println("$node")
            end
            elekeys = []
            for (key, _) in node.children
                push!(elekeys, key)
            end
            sort!(elekeys, lt=comp2)
            for ckey in elekeys
                cnode = node.children[ckey]
                if show_id
                    println("  $ckey $cnode [$(cnode.index)]")
                else
                    println("   $ckey $cnode")
                end
            end
        end
    end
    println("-------------------------")
end