# And struct to handle moving accross the context tree
struct ContextTree
    tree::Dict                         # current id tree
    curr::OrderedDict{String, Any}     # current context
    ContextTree() = new(Dict(), OrderedDict{String, Any}())
end