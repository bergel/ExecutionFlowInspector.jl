module ExecutionFlowInspector

using MacroTools

macro code_location()
    return quote
        println("Running function at ",$("$(__source__.file)"),":",$("$(__source__.line)"))
    end
end

# Take a function as argument
macro ef_body(body)
    #@capture(fun, function f_(args__) body__ end) || error("must provide a function")

    return MacroTools.postwalk(body) do x
        @capture(x, f_(xs__)) || return x
        return :( @info($f) ; $f($(xs...)))
    end
end

macro ef(fun)
    @capture(fun, function f_(args_) body_ end) || error("must provide a function")
    return :( function $f($args) @ef_body $(esc(body)) end )
end

end # module
