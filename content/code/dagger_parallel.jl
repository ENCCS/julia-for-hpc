using Distributed
addprocs(1; exeflags="--threads=2")

@everywhere using Dagger, Random

@everywhere function f(rng, x::Integer)
    sleep(1)
    rand(rng, one(x):x)
end

@everywhere function g(rng, x::Integer)
    sleep(1)
    rand(rng, x:x+2)
end

@everywhere function h(x::Integer, y::Integer)
    map(one(x):x) do i
        Dagger.@spawn begin
            sleep(1)
            y+i
        end
    end
end

@everywhere function task_graph()
    # Use determistic random number generators
    a = Dagger.@spawn f(MersenneTwister(1), 3)
    b = Dagger.@spawn g(MersenneTwister(2), 5)
    c = Dagger.@spawn h(fetch(a), fetch(b))
    d = Dagger.@spawn mapreduce(fetch, +, fetch(c))
    return fetch(d)
end

println(task_graph())
@time task_graph()
