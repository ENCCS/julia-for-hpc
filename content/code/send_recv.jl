using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

if rank != 0
    # All ranks other than 0 should send a message
    local message = "Hello World, I'm rank $rank"
    MPI.send(message, comm, dest=0, tag=0)
else
    # Rank 0 will receive each message and print them
    for sender in 1:(size-1)
        message = MPI.recv(comm, source=sender, tag=0)
        println(message)
    end
end   