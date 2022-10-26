using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

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

function main()
    num_points = 10^9
    num_jobs = 10
    chunks = [num_points / num_jobs for i in 1:num_jobs]
    
    # distribute work among MPI tasks
    count = div(num_jobs, size)
    remainder = num_jobs % size

    if rank < remainder
        first = rank * (count + 1) + 1
        last = first + count
    else
        first = rank * count + remainder + 1
        last = first + count - 1
    end

    # each rank computes pi for their vector elements
    estimates = []
    for i in first:last
        push!(estimates, estimate_pi(chunks[i]))
    end

    # sum up all estimates and average on root tank
    pi_sum = MPI.Reduce(sum(estimates), +, comm, root=0)
    if rank == 0
        println("pi = $(pi_sum/num_jobs)")
    end
end

using BenchmarkTools

@btime main()
