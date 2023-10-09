using Base.Threads

function partial_hits(num_points)
    hits = zero(Int)
    x, y = rand(), rand()
    if x^2 + y^2 < 1.0
        hits += 1
    end
    return hits
end

function threaded_estimate_pi(num_points)
    n = nthreads()
    d, r = divrem(num_points, n)
    chuncks = vcat(fill(d, n-r), fill(d+1, r))
    tasks = map(chunks) do chunk
        @spawn partial_hits(chunk)
    end
    hits = mapreduce(fetch, +, tasks; init=zero(Int))
    return 4 * hits / num_points
end
