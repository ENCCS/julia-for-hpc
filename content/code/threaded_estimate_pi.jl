using Random
using Base.Threads

function partial_hits(rng, num_points)
    hits = zero(Int)
    for _ in 1:num_points
        x, y = rand(rng), rand(rng)
        if x^2 + y^2 < 1.0
            hits += 1
        end
    end
    return hits
end

function partition(v::Integer, n::Integer)
    d, r = divrem(v, n)
    c = vcat(fill(d, n-r), fill(d+1, r))
    return c
end

function threaded_estimate_pi(num_points)
    n = nthreads()
    rngs = [MersenneTwister(seed) for seed in 1:n]
    chunks = partition(num_points, n)
    tasks = map(zip(rngs, chunks)) do (rng, chunk)
        @spawn partial_hits(rng, chunk)
    end
    hits = mapreduce(fetch, +, tasks; init=zero(Int))
    return 4 * hits / num_points
end
