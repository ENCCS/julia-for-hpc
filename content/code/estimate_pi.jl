function estimate_pi(num_points)
    hits = 0
    for _ in 1:num_points
        x, y = rand(), rand()
        if x^2 + y^2 < 1.0
            hits += 1
        end
    end
    fraction = hits / num_points
    return 4 * fraction
end

