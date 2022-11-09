using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

# Check that there are exactly two ranks
if size != 2
    println("This example requires exactly two ranks")
    exit(1)
end

# Call the other rank the neighbour
if rank == 0
    neighbour = 1
else
    neighbour = 0
end

send_message = [i for i in 1:100]

# Send a message to the other rank and then receive
if rank == 0
    MPI.send(send_message, comm, dest=neighbour, tag=0)
    recv_message = MPI.recv(comm, source=neighbour, tag=0)
    print("Message received by rank $rank\n")
end

# Receive the message from the other rank and then send
if rank == 1
    recv_message = MPI.recv(comm, source=neighbour, tag=0)
    print("Message received by rank $rank\n")
    MPI.send(send_message, comm, dest=neighbour, tag=0)
end

