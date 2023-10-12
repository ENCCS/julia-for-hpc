module heat_diff_eq

import MPI

include("initialization.jl")
include("input_parameter.jl")
include("integration.jl")
include("io.jl")

function main()

# initial temperature on border(high) and inner(low) cells
temp_high_init = 10.0
temp_low_init = 0.0

# diffusion coefficient
k0 = Float64(1)

# define rank of root process
root = 0

# MPI Initialization
MPI.Init()
comm = MPI.COMM_WORLD
my_id = MPI.Comm_rank(comm)
nproc = MPI.Comm_size(comm)

# input simulation parameters
params_int = Array{Int64}(undef, 5)
params_double = Array{Float64}(undef, 2)
if (my_id == root)
    params_int, params_double, output_path = get_sim_params(ARGS)
end

# broadcast parameters to all processes
MPI.Barrier(comm)
MPI.Bcast!(params_int, 5, 0, comm)
MPI.Bcast!(params_double, 2, 0, comm)

size_x    = params_int[1]
size_y    = params_int[2]
nx_domains = params_int[3]
ny_domains = params_int[4]
maxStep   = params_int[5]
dt        = params_double[1]
epsilon   = params_double[2]

# a warning message if dimensions and number of processes don't match
if ((my_id == root) && (nproc != (nx_domains * ny_domains)))
    println("ERROR - Number of processes not equal to number of subdomains")
end

# include ghost cells
size_global_x = size_x + 2
size_global_y = size_y + 2
hx = Float64(1.0 / size_global_x)
hy = Float64(1.0 / size_global_y)
size_total_x = size_x + 2 * nx_domains + 2
size_total_y = size_y + 2 * ny_domains + 2

# 2D solution including ghost cells
u0 = twoDArray(Float64, size_total_x, size_total_y)
u = twoDArray(Float64, size_total_x, size_total_y)

# allocate coordinates of processes (start cell, end cell)
xs = oneDArray(Int, nproc)
xe = oneDArray(Int, nproc)
ys = oneDArray(Int, nproc)
ye = oneDArray(Int, nproc)

# size of each physical domain
xcell = Int(size_x / nx_domains)
ycell = Int(size_y / ny_domains)

# allocate flattened (1D) local/global physical solution
u_local = oneDArray(Float64, xcell * ycell)
u_global = oneDArray(Float64, size_x * size_y)

# find neighboring cells surrounding the central one
my_neighbors = neighbors(my_id, nproc, nx_domains, ny_domains)

# compute coordinates of processes for each sub-domain
process_coordinates!(xs, ys, xe, ye, xcell, ycell, nx_domains, ny_domains, nproc)

# initialize domain
init_values(u0, size_total_x, size_total_y, temp_high_init, temp_low_init)

# update ghost cells
updateBound!(u0, size_total_x, size_total_y, my_neighbors, comm,
            my_id, xs, ys, xe, ye, xcell, ycell, nproc)

# initialize step, simulation time and convergence boolean
step = 0
t = 0.0
converged = false

# recording time
if (my_id==0)
    time_init = time()
end

# main loop until convergence ---> similar to "equilibration" in MD simulations
while (!converged)
    step += 1
    t += dt
    #perform one step and cal difference between two steps
    local_diff = computeNext!(u0, u, size_total_x, size_total_y, dt, hx, hy,
        my_id, xs, ys, xe, ye, nproc, k0)

    # update ghost cells
    updateBound!(u0, size_total_x, size_total_y, my_neighbors, comm,
        my_id, xs, ys, xe, ye, xcell, ycell, nproc)

    MPI.Barrier(comm)

    # sum local_diff to get global difference
    global_diff = MPI.Allreduce(local_diff, MPI.SUM, comm)
    global_diff = sqrt(global_diff)
    # break if convergence reached or step greater than maxStep
    if ((global_diff <= epsilon) || (step >= maxStep))
        converged = true
    end
end

# cal elapsed time
if (my_id == 0)
    println("Elapsed time = ", time()-time_init, " for ", step, " steps.")
end

# solution on sub-domain (as a 1D array)
i = 1
for j = ys[my_id+1]:ye[my_id+1]
    u_local[(i-1)*xcell+1:i*xcell] = u0[xs[my_id+1]:xe[my_id+1],j]
    i = i+1
end

# gather local solution to global solution (as a 1D array)
u_global = MPI.Gather(u_local, root, comm)

# output results to external files
if (my_id == 0)
    write_to_disk(u_global, nx_domains, ny_domains, xcell, ycell, temp_high_init, output_path)
end

MPI.Finalize()

end

#main()

end


