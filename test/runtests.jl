#using ExecutionFlowInspector
using Test
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


macroexpand(Main, :( @ef function foo(x)
    t1 = sin(x)
    t2 = cos(x)
    return t1 + t2
end ))

@testset "B" begin
    @ef function foo(x)
        t1 = sin(x)
        t2 = cos(x)
        return t1 + t2
    end

    foo(5)
end

#= @testset "Basic" begin
    @ef function foo(x)
        y = x * 10
        if y > 100
            return "A"
        else
            return "B"
        end
    end

    @test foo(5) == "B"
    @test foo(100) == "A"
end
 =#

 # -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

 # tracing_function should take function name and arguments as parameters
using MacroTools
macro mt(tracing_function, fun)
    @capture(fun, function f_(args2__) body_ end) || error("must provide a function")
    @capture(fun, function f_(args_) body_ end) || error("must provide a function")
    return :( function $f($args)
                $tracing_function(string($f), string($args2))
                $body end )
end
global function_counters
function reset_function_counters()
    global function_counters = Dict{String,Int64}()
end
reset_function_counters()

function increase_call(f_name::String)
if(!haskey(function_counters, f_name))
    function_counters[f_name] = 0
end
function_counters[f_name] = function_counters[f_name] + 1
end
macro mtt(fun)
@capture(fun, function f_(args_) body_ end) || error("must provide a function $fun")
return :(
        @mt (fun_name, fun_args)-> increase_call(string(fun_name, "@", fun_args)) function $f($args)
            $body
        end )
end


@mtt function add5(x::Int64)
    return x + 5
end

@mtt function add5(x::Float64)
    return x + 5.0
end


@mtt function qwe(::Int64)
    return 10
end

macroexpand(Main, :( @mtt function qwe(::Int64)
    return 10
end ))
