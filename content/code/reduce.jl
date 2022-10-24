using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

# Only upper-case Reduce exists so message must be buffer-like of isbitstype
data = rank
recvbuf = MPI.Reduce(data, +, comm, root=0)

if rank == 0
    println(recvbuf)
end

