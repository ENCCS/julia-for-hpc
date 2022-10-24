using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)   

# Rank 0 will broadcast message to all other ranks
if rank == 0
    send_message = "Hello World from rank 0"
else
    send_message = nothing
end

receive_message = MPI.bcast(send_message, comm, root=0)

if rank != 0
    print("rank $rank received message: $receive_message")
end
