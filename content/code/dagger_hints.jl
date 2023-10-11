# HINT: import Distributed and add workers
# HINT: import Dagger and Random on all workers (@everywhere)

using Random

# HINT: define the function f, g, and h for all workers

function f(rng, x::Integer)
    sleep(1)
    rand(rng, one(x):x)
end

function g(rng, x::Integer)
    sleep(1)
    rand(rng, x:x+2)
end

function h(x::Integer, y::Integer)
    map(one(x):x) do i
        # HINT: Remember that we can also nest tasks with Dagger (Dagger.@spawn)
        sleep(1)
        y+i
    end
end

function task_graph()
    # Use determistic random number generators
    # HINT: parallelize the tasks using dagger (Dagger.@spawn, fetch)
    a = f(MersenneTwister(1), 3)
    b = g(MersenneTwister(2), 5)
    c = h(a, b)
    d = reduce(+, c)
    return d
end

println(task_graph())
@time task_graph()
