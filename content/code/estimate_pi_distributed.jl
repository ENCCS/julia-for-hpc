using Distributed

@everywhere function estimate_pi(range::UnitRange)
    hits = 0
    for _ in range
        x, y = rand(), rand()
        if x^2 + y^2 < 1.0
            hits += 1
        end
    end
    fraction = hits / length(range)
    return 4 * fraction
end
