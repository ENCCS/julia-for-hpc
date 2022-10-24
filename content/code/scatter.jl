using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

# Only upper-case Scatter exists so message must be buffer-like of isbitstype
if rank == 0
    sendbuf = [i^3 for i in 1:size]
else
    sendbuf = nothing
end

recvbuf = MPI.Scatter(sendbuf, Int64, comm, root=0)
println("rank $rank received message: $recvbuf")
