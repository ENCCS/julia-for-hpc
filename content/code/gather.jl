using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

# Only upper-case Gather exists so message must be buffer-like of isbitstype
send_message = rank^3
# data from all ranks are gathered on root rank
receive_message = MPI.Gather(send_message, comm, root=0)

if rank == 0
    for i in 1:size
        println("Received $(receive_message[i]) from rank $(i-1)")
    end
end
