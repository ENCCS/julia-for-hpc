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

    # divide work evenly between ranks
    my_points = floor(Int, num_points / size)
    remainder = num_points % size
    if rank < remainder
        my_points += 1
    end

    # measure time
    t1 = time()

    # each rank computes pi for their points
    pi = estimate_pi(my_points)

    # sum up all estimates and average on root tank
    pi_sum = MPI.Reduce(sum(pi), +, comm, root=0)    

    if rank == 0
        println("pi = $(pi_sum / size)")
    end

    # print time
    t2 = time()
    println("time: $(t2-t1)")
end

main()
