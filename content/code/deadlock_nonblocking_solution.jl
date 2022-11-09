using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

# Check that there are exactly two ranks
if size != 2
    print("This example requires exactly two ranks")
    exit(1)
end

# Call the other rank the neighbour
if rank == 0
    neighbour = 1
else
    neighbour = 0
end

# Send a message to the other rank
send_message = [i for i in 1:100]
recv_message = similar(send_message)

# non-blocking send
sreq = MPI.Isend(send_message, comm, dest=neighbour, tag=0)

# non-blocking receive into receive buffer
rreq = MPI.Irecv!(recv_message, comm, source=neighbour, tag=0)

stats = MPI.Waitall!([rreq, sreq])

print("Message received by rank $rank\n")
