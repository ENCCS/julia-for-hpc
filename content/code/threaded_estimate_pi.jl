using .Threads

function threaded_estimate_pi(num_points)
    partial_hits = zeros(Int, nthreads())

    @threads for _ in 1:num_points
        x, y = rand(), rand()
	if x^2 + y^2 < 1.0
            partial_hits[threadid()] += 1
	end
    end

    hits = sum(partial_hits)

    fraction = hits / num_points
    return 4 * fraction
end
