Distributed computing
=====================

.. questions::

   - How is multiprocessing used?
   - What are SharedArrays?

.. instructor-note::

   - 15 min teaching
   - 20 min exercises


Distributed computing
---------------------

Julia's main implementation of message passing for distributed-memory systems is contained in 
the ``Distributed`` module. Its approach is different from other frameworks like MPI in 
that communication is generally "one-sided", meaning that the programmer needs to explicitly 
manage only one process in a two-process operation. 
 
Julia can be started with a given number of `local` processes using the ``-p``:

.. code-block:: bash

   julia -p 4

The ``Distributed`` module is automatically loaded if the ``-p`` flag is used.  
But we can also dynamically add processes in a running Julia session:

.. code-block:: julia

   using Distributed
   
   println(nprocs())
   addprocs(4)         # add 4 workers
   println(nprocs())   # total number of processes
   println(nworkers()) # only worker processes
   rmprocs(workers())  # remove worker processes


Note what happens here: there is one `master` process which can create 
additional `worker` processes, and as we shall see it can also distribute work to these 
workers.

For running on a cluster, we instead need to provide the ``--machine-file`` option 
and the name of a file containing a list of machines that are accessible via 
password-less ``ssh``. Support for running on clusters with various schedulers 
(including SLURM) can be found in the 
`ClusterManagers.jl <https://github.com/JuliaParallel/ClusterManagers.jl>`_ 
package.

Each process has a unique identifier accessible via the ``myid()`` function (`master` 
has ``myid() = 1``). The ``@spawn`` and ``@spawnat`` macros can be used to transfer 
work to a process, and then return the resulting ``Future`` to the `master` process 
using the ``fetch`` function (``@spawn`` selects the process automatically while 
``@spawnat`` lets you choose: 

.. code-block:: julia

   # execute myid() and rand() on process 2
   r = @spawnat 2 (myid(), rand())
   # fetch the result
   fetch(r)

One use case could be to manually distribute expensive function calls 
between processes,
but there are higher-level and simpler constructs than ``@spawn`` / ``@spawnat``:

- the ``@distributed`` macro for ``for`` loops. Can be used with a 
  reduction operator to gather work performed by the independent tasks.
- the ``pmap`` function which maps an array or range to a given function.

To illustrate the difference between these approaches we revisit the 
``sum_sqrt`` function from above. To use ``pmap`` we need to modify our 
function to accept a range so we will use this modified version.
Note that to make any function available to all processes it needs to 
be decorated with the ``@everywhere`` macro:

.. code-block:: julia

   @everywhere function sqrt_sum_range(A, r)
       s = zero(eltype(A))
       for i in r
           @inbounds s += sqrt(A[i])
       end
       return s
   end

Let us look at and discuss example implementations using each of these 
techniques:

.. tabs:: 

   .. tab:: @distributed (+)

      .. code-block:: julia
      
         batch = length(A) / 10

         @distributed (+) for r in [(1:batch) .+ offset for offset in 0:batch:length(A)-1]
             sqrt_sum_range(A, r)
         end


   .. tab:: pmap

      .. code-block:: julia
      
         batch = length(A) / 10

         sum(pmap(r -> sqrt_sum_range(A, r), [(1:batch) .+ offset for offset in 0:batch:length(A)-1]))


   .. tab:: @spawnat

      .. code-block::  julia
      
         futures = Array{Future}(undef, nworkers())
      
         @time begin
             for (i, id) in enumerate(workers())
                 batch = floor(Int, length(A) / nworkers())
                 remainder = length(A) % nworkers()
                 if (i-1) < remainder
                     start = 1 + (i - 1) * (batch + 1)
                     stop = start + batch
                 else 
                     start = 1 + (i - 1) * batch + remainder
                     stop = start + batch - 1
                 end
                 futures[i] = @spawnat myid() sqrt_sum_range(A, start:stop)
             end
             p = sum(fetch.(futures))
         end

The ``@spawnat`` version is cumbersome to use in this case and the algorithm 
required to partition the array reminds of MPI. 
The ``@distributed (+)`` parallel for loop and the ``pmap`` mapping are much simpler,
but which one is preferable for a given use case?

- ``@distributed`` is appropriate for reductions. It does not load-balance and 
  simply divides the work evenly between processes. It is best in cases where 
  each loop iteration is cheap.
- ``pmap`` can handle reductions as well as other algorithms. It performs load-balancing
  and since dynamic scheduling introduces some overhead it's best to use ``pmap`` 
  for computationally heavy tasks.

It should be emphasized that a common use case of ``pmap`` involves heavy 
computations inside functions defined in user-imported packages. 
For example, computing the singular value decomposition of many matrices:

.. code-block:: julia

   @everywhere using LinearAlgebra
   x=[rand(100,100) for i in 1:10]
   @btime map(LinearAlgebra.svd, x);
   @btime pmap(LinearAlgebra.svd, x);


SharedArrays
^^^^^^^^^^^^

Shared arrays, supplied by the ``SharedArrays`` module in base Julia, are 
arrays that are shared across multiple processes on the same machine. They 
can be used to distribute operations on an array across processes.

Let us revisit the ``sqrt_array`` function and modify it to mutate the 
argument passed to it, and also add a method to it for 
SharedArrays which has the required ``@distributed`` and ``@sync`` macros  
(``@sync`` is needed to wait for all processes to finish):

.. tabs::

   .. tab:: Serial

      .. code-block:: julia
      
         function sqrt_array!(A)
             for i in eachindex(A)
                 @inbounds A[i] = sqrt(A[i])
             end
         end

   .. tab:: SharedArray

      .. code-block:: julia

         function sqrt_array!(A::SharedArray)
             @sync @distributed for i in eachindex(A)
                 @inbounds A[i] = sqrt(A[i])
             end
         end


Remember that Julia always selects the most specialized method for 
dispatch based on the argument type. We can now time these two methods 
using ``@time`` instead of ``@btime``, this time: 

.. code-block:: julia

   A = rand(100_000_000);
   @time sqrt_array!(A)

   SA = SharedArray(A);
   @time sqrt_array!(SA)

Bonus questions:

- Should the ``@time`` expression be called more than once?
- How can we check which method is being dispatched for ``A`` and ``SA``?

We should keep in mind however that every change to a SharedArray causes message 
passing to keep them in sync between processes, and this can affect performance.


DistributedArrays
^^^^^^^^^^^^^^^^^

Another way to approach parallelization over multiple machines is through 
`DistributedArrays.jl <https://github.com/JuliaParallel/DistributedArrays.jl>`_, 
which implements a *Global Array* interface. A DArray is distributed across a 
set of workers. Each worker can read and write from its local portion of the 
array and each worker has read-only access to the portions of the array held 
by other workers.

Currently, distributed arrays do not have much functionality 
and they requires significant book-keeping of array indices. 


MPI
^^^

`MPI.jl <https://github.com/JuliaParallel/MPI.jl>`_ is a Julia interface to 
the Message Passing Interface, which has been the standard workhorse of 
parallel computing for decades. Like ``Distributed``, MPI belongs to the 
distributed-memory paradigm.

The idea behind MPI is that:

- Tasks have a rank and are numbered 0, 1, 2, 3, ...
- Each task manages its own memory
- Each task can run multiple threads
- Tasks communicate and share data by sending messages.
- Many higher-level functions exist to distribute information to other tasks
  and gather information from other tasks.
- All tasks typically *run the entire code* and we have to be careful to avoid
  that all tasks do the same thing.

``MPI.jl`` provides Julia bindings for the Message Passing Interface (MPI) standard.
This is how a hello world MPI program looks like in Python:

.. code-block:: julia

   using MPI
   MPI.Init()
   comm = MPI.COMM_WORLD
   rank = MPI.Comm_rank(comm)
   size = MPI.Comm_size(comm)
   println("Hello from process $(rank) out of $(size)")
   MPI.Barrier(comm)

- ``MPI.COMM_WORLD`` is the `communicator` - a group of processes that can talk to each other
- ``Comm_rank`` returns the individual rank (0, 1, 2, ...) for each task that calls it
- ``Comm_size`` returns the total number of ranks.

To run this code with a specific number of processes we use the ``mpirun`` command which 
comes with the MPI library:

.. code-block:: console

   # on some HPC systems you might need 'srun -n 4' instead of 'mpirun -np 4'
   # on Vega, add this module for MPI libraries: ml add foss/2020b  
   $ mpirun -np 4 julia hello.py

   # Hello from process 1 out of 4
   # Hello from process 0 out of 4
   # Hello from process 2 out of 4
   # Hello from process 3 out of 4

Point-to-point and collective communication
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The MPI standard contains a `lot of functionality <https://juliaparallel.org/MPI.jl/stable/refindex/>`__, 
but in principle one can get away with only point-to-point communication (:meth:`MPI.send` and 
:meth:`MPI.recv`). However, collective communication can sometimes require less effort as you 
will learn in an exercise below.
In any case, it is good to have a mental model of different communication patterns in MPI.

.. figure:: img/send-recv.png
   :align: center
   :scale: 100 %

   ``send`` and ``recv``: blocking point-to-point communication between two ranks.    

.. figure:: img/gather.png
   :align: right
   :scale: 80 %

   ``gather``: all ranks send data to rank ``root``.

.. figure:: img/scatter.png
   :align: center
   :scale: 80 %

   ``scatter``: data on rank 0 is split into chunks and sent to other ranks


.. figure:: img/broadcast.png
   :align: left
   :scale: 80 %

   ``bcast``: broadcast message to all ranks


.. figure:: img/reduction.png
   :align: center
   :scale: 100 %

   ``reduce``: ranks send data which are reduced on rank ``root``


Examples
~~~~~~~~

.. tabs::
 
   .. tab:: send/recv

      .. code-block:: julia

         using MPI
         MPI.Init(   )

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

   .. tab:: broadcast

      .. code-block:: julia
            
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

   .. tab:: gather
      
      .. code-block:: julia

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

   .. tab:: scatter

      .. code-block:: julia

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

   .. tab:: reduce

      .. code-block:: julia

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



.. callout:: Serialised vs buffer-like objects

   Lower-case methods (e.g. :meth:`send` and :meth:`recv`) are used to communicate generic 
   objects between MPI processes. It is also possible to send buffer-like ``isbits`` objects 
   which provides faster communication, but require the memory space to be allocated for the 
   receiving buffer prior to communication. These methods start with uppercase letters, 
   e.g. :meth:`Send`, :meth:`Recv`, :meth:`Gather` etc.   

.. callout:: Mutating vs non-mutating 

   For communication operations which receive data, MPI.jl typically
   defines two separate functions:

   - One function in which the output buffer is supplied by the user.
     as it mutates this value, it adopts the Julia convention of suffixing
     with ``!`` (e.g. :meth:`MPI.Recv!`, :meth:`MPI.Reduce!`).
   - One function which allocates the buffer for the output
     (:meth:`MPI.Recv`, :meth:`MPI.Reduce`).

Blocking and non-blocking communication
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Point-to-point communication can be *blocking* or *non-blocking*: 
:meth:`MPI.Send` will only return when the program can safely modify the send buffer and 
:meth:`MPI.Recv` will only return once the data has been received and written to the receive 
buffer.

Consider the following example of a **deadlock** caused by blocking communication. 
The problem can be circumvented by introducing sequential sends and receives, but 
it's more conveniently solved by using non-blocking send and receive.

.. tabs:: 

   .. tab:: Blocking communication deadlock

      .. code-block:: julia

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
         MPI.send(send_message, comm, dest=neighbour, tag=0)

         # Receive the message from the other rank
         recv_message = MPI.recv(comm, source=neighbour, tag=0)

         print("Message received by rank $rank")

   .. tab:: Workaround with blocking communication

      .. code-block:: julia

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

         if rank == 0
             MPI.send(send_message, comm, dest=neighbour, tag=0)
         end

         # Receive the message from the other rank
         if rank == 1
             recv_message = MPI.recv(comm, source=neighbour, tag=0)
             print("Message received by rank $rank")
         end

         if rank == 1
             MPI.send(send_message, comm, dest=neighbour, tag=0)
         end

         if rank == 0
             recv_message = MPI.recv(comm, source=neighbour, tag=0)
             print("Message received by rank $rank")
         end
    
   .. tab:: Non-blocking solution

      .. code-block:: julia

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

         print("Message received by rank $rank")


         

.. challenge:: From blocking to non-blocking

   Consider the following two examples where data is sent around "in a circle" 
   (0->1, 1->2, ..., N->0). Will it work as intended? 

      .. code-block:: julia
      
         using MPI
         MPI.Init()

         comm = MPI.COMM_WORLD
         rank = MPI.Comm_rank(comm)
         size = MPI.Comm_size(comm)

         # where to send to
         dst = mod(rank+1, size)
         # where to receive from
         src = mod(rank-1, size)

         # unititalised send and receive buffers
         send_mesg = Array{Float64}(undef, 5)
         recv_mesg = Array{Float64}(undef, 5)

         # fill the send array
         fill!(send_mesg, Float64(rank))

         print("$rank: Sending   $rank -> $dst = $send_mesg\n")
         MPI.Send(send_mesg, comm, dest=dst, tag=rank+32)

         print("$rank: Received $src -> $rank = $recv_mesg\n")
         MPI.Recv!(recv_mesg, comm, source=src,  tag=src+32)

         MPI.Barrier(comm)

   Try running this program. Were the arrays received successfully? 
   Introduce non-blocking communication to solve the problem.

   .. solution:: 

      .. code-block:: julia
            
         using MPI
         MPI.Init()

         comm = MPI.COMM_WORLD
         rank = MPI.Comm_rank(comm)
         size = MPI.Comm_size(comm)

         # where to send to
         dst = mod(rank+1, size)
         # where to receive from
         src = mod(rank-1, size)

         send_mesg = Array{Float64}(undef, 5)
         recv_mesg = Array{Float64}(undef, 5)

         # fill the send array
         fill!(send_mesg, Float64(rank))

         print("$rank: Sending   $rank -> $dst = $send_mesg\n")
         sreq = MPI.Isend(send_mesg, comm, dest=dst, tag=rank+32)

         rreq = MPI.Irecv!(recv_mesg, comm, source=src,  tag=src+32)

         stats = MPI.Waitall!([rreq, sreq])

         print("$rank: Received $src -> $rank = $recv_mesg\n")

         MPI.Barrier(comm)





Exercises
---------

.. exercise:: Using SharedArrays with the Laplace function

   Look again at the double for loop in the ``lap2d!`` function 
   and think about how you could use SharedArrays.

   - Create a new script where you import ``Distributed``, ``SharedArrays`` and 
     ``BenchmarkTools`` and define the ``lap2d!`` function.
   - Benchmark the original version:

   .. code-block:: julia

      u, unew = setup()
      @btime lap2d!(u, unew)

   - Now create a new method for this function which accepts SharedArrays. 
   - Add worker processes with ``addprocs`` and benchmark your new method 
     when passing in SharedArrays. Is there any performance gain? 

   - The overhead in managing the workers will probably far outweigh the 
     parallelization benefit because the computation in the inner loop is 
     very simple and fast.
   - Try adding ``sleep(0.001)`` to the **outermost** loop to simulate the effect 
     of a more demanding calculation, and rerun the benchmarking. Can you see a 
     speedup now?
   - Remember that you can remove worker processes with ``rmprocs(workers())``.


   .. solution:: 

      .. code-block:: Julia

         using BenchmarkTools
         using Distributed
         using SharedArrays
         
         function lap2d!(u, unew)
             M, N = size(u)
             for j in 2:N-1
                 for i in 2:M-1
                     @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
                 end 
             end
         end
         
         function lap2d!(u::SharedArray, unew::SharedArray)
             M, N = size(u)
             @sync @distributed for j in 2:N-1
                 for i in 2:M-1
                     @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
                 end 
             end
         end


         u, unew = setup()
         u_s = SharedArray(u);
         unew_s = SharedArray(unew);

         # test for correctness:
         lap2d!(u, unew) 
         lap2d!(u_s, unew_s) 
         # element-wise comparison, should give "true"
         all(u .≈ u_s)

         # benchmark
         @btime lap2d!(u, unew) 
         #   WRITEME

         @btime lap2d!(u_s, unew_s)
         #   WRITEME


.. exercise:: Parallel mapping

   .. figure:: img/pi_with_darts.png
      :scale: 7 %
      :align: right

   Consider the following function which estimates π by "throwing darts", 
   i.e. randomly sampling (x,y) points in the interval [0.0, 1.0] and checking 
   if they fall within the unit circle.

   .. code-block:: julia

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

      num_points = 100_000_000
      estimate_pi(num_points)  # 3.14147572...

   - Rewrite the function to accept a UnitRange (``1:10`` is a UnitRange{Int64})
     and decorate it with ``@everywhere``.
   - Use a list comprehension to split up ``num_points`` into evenly sized chunks
     (Hint: ``[(___:___) .+ ___ for ___ in ___:___:___]``).
   - Add worker processes as needed.
   - Use ``mean(pmap(___, ___))`` to get the mean from a parallel mapping 
     distributed among the workers.
   - Do some benchmarking, and try varying the chunk size from small (each process 
     gets a small task and there's more communication) to large (larger amount of work 
     for each worker and smaller communication).

     .. solution::

        .. code-block:: julia

           using Distributed
           using BenchmarkTools
   
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
           
           @everywhere function estimate_pi(range::UnitRange)
               hits = 0
               for _ in range
                   x, y = rand(), rand()
                   if x^2 + y^2 < 1.0
                       hits += 1
                   end
               end
               fraction = hits / length(range)
               return 4 * fraction
           end
           
           
           num_points = 100_000_000
           @btime estimate_pi(num_points)
           # 366.751 ms (1 allocation: 16 bytes)
           
           # splitting into ~10-50 chunks seems to be close to a sweet spot for 4 workers
           # chunk = 100_000  # too much communication overhead
           chunk = 10_000_000
           ranges = [(1:chunk) .+ offset for offset in 0:chunk:num_points-1]
           
           @btime mean(pmap(estimate_pi, ranges))
           # 151.578 ms (572 allocations: 20.61 KiB)

See also
--------

- The `Julia Parallel <https://github.com/JuliaParallel>`_ organization collects 
  packages developed for parallel computing in Julia.
- `MPI.jl <https://github.com/JuliaParallel/MPI.jl>`__
- `Distributed computing in Julia docs <https://docs.julialang.org/en/v1/manual/distributed-computing/>`__
- `Distributed API <https://docs.julialang.org/en/v1/stdlib/Distributed/>`__
- Valentin Churavy, `Levels of Parallelism <https://slides.com/valentinchuravy/julia-parallelism>`__

.. keypoints::

   - One should choose a distributed mechanism that fits with the 
     time and memory parameters of your problem   
   - ``Threads`` is as easy as decorating for loops with ``@threads``, but data 
     dependencies (race conditions) need to be avoided.
   - ``@distributed`` is good for reductions and fast inner loops with limited 
     data transfer.
   - ``pmap`` is good for expensive inner loops that return a value.
   - ``SharedArrays`` can be an easier drop-in replacement for threading-like 
     behaviors on a single machine.
