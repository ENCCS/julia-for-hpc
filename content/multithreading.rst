Multithreading
==============

.. questions::

   - What parallelization options exist in Julia?
   - What is multithreading?

.. instructor-note::

   - 30 min teaching
   - 30 min exercises


Parallel computing
------------------
Julia supports four main types of parallel programming:

- **Asynchronous tasks or coroutines**: Tasks allow suspending and resuming 
  computations for I/O, event handling and similar patterns. Not really HPC and 
  outside the scope of the this lesson. 

- **Multi-threading**: Provides the ability to schedule Tasks simultaneously 
  on more than one thread or CPU core, sharing memory. The easiest way to parallelize 
  on shared-memory systems. Contained in the ``Threads`` standard library.

- **Distributed computing**: Runs multiple Julia processes with separate memory 
  spaces on the same or multiple computers. Useful high-level constructs are implemented 
  in the standard library ``Distributed`` module. For those that like MPI there is 
  `MPI.jl <https://github.com/JuliaParallel/MPI.jl>`_.

- **GPU computing**: Ports computation to a graphical processing unit (GPU) via either high-level 
  or low-level programming. 


Linear algebra threading
------------------------
OpenBLAS is the default linear algebra backend in Julia.
Because it is an external library, it manages threading by itself independent of the Julia threads.
We can manage the thread count for OpenBLAS inside Julia session using the :code:`BLAS.set_num_threads()` function or by setting an environment variable as follows:

.. code-block:: bash

   export OPENBLAS_NUM_THREADS=4

Consider the multiplication of two large arrays and compare the execution time.

.. code-block:: julia

   using LinearAlgebra

   A = rand(2000, 2000)
   B = rand(2000, 2000)

   # Precompile the matrix multiplication
   A*B

   # Single thread
   begin
       BLAS.set_num_threads(1)
       @show BLAS.get_num_threads()
       @time A*B
   end

   # All threads on the machine
   begin
       BLAS.set_num_threads(Sys.CPU_THREADS)
       @show BLAS.get_num_threads()
       @time A*B
   end

We should see a difference between using single and all threads.


Julia threading
---------------
We start by walking through how to use multithreading in Julia.
We can set the :code:`JULIA_NUM_THREADS` environment variable such that Julia will start the set thread count.

.. code-block:: bash

   export JULIA_NUM_THREADS=4

Alternatively, we can also use the :code:`-t/--threads` option to supply the thread count.
Using an option will override the value in the environment variable.

.. code-block:: bash

   # Short form
   julia -t 4

   # Long form
   julia --threads=4

..
   Hmm, but we need more than one thread to be able to gain any performance 
   from multithreading. 
   This is not possible to do inside VSCode. Instead, we open up the 
   "Extension Settings" for the Julia VSCode extension and set the 
   "Julia: Num Threads" setting to the number of CPU cores we have on 
   our machines (if you're unsure, just try setting it to 2).
   After updating the number of threads we need to restart the VSCode REPL.
   We can make sure we have access to the correct number of threads 
   with the ``Threads.nthreads()`` function.

In Julia, we can import the Threads module for easier usage.

.. code-block:: julia

   # nthreads, threadid, @threads, @sync, @spawn, fetch
   using Base.Threads

The ``nthreads`` function show us how many threads we have available:

.. code-block:: julia

   n = nthreads()

There are three main ways of approaching multithreading:

1) Using ``@threads`` to parallelize a for loop to run in multiple threads.
2) Using ``@spawn`` and ``@sync`` to spawn tasks in threads and synchronize them at the end of the block.
3) Using ``@spawn`` and ``fetch`` to spawn tasks and fetch their return values once they are complete.

Choosing the most suitable method depends on the problem.

.. tabs::

   .. tab:: @threads

      .. code-block:: julia

         # Using @threads macro with dynamic scheduling
         a = zeros(Int, 2n)
         @threads :dynamic for i in eachindex(a)
             a[i] = threadid()
         end
         println(a)

   .. tab:: @sync and @spawn

      .. code-block:: julia

         # Using @sync and @spawn macros (also dynamic scheduling)
         b = zeros(Int, 2n)
         @sync for i in eachindex(b)
             @spawn b[i] = threadid()
         end
         println(b)

   .. tab:: @spawn and fetch

      .. code-block:: julia

         # Using @spawn and fetch
         t = [@spawn threadid() for _ in 1:2n]
         c = fetch.(t)

Let's see if we can achieve any speed gain when performing a 
costly calculation.

.. tabs::

   .. tab:: Serial

      .. code-block:: julia

         function sqrt_array(A)
             B = similar(A)
             for i in eachindex(A)
                 @inbounds B[i] = sqrt(A[i])
             end
             B
         end

   .. tab:: Threaded (@threads)

      .. code-block:: julia

         function threaded_sqrt_array(A)
             B = similar(A)
             @threads :dynamic for i in eachindex(A)
                 @inbounds B[i] = sqrt(A[i])
             end
             B
         end

   .. tab:: Threaded (@spawn and @sync)

      .. code-block:: julia

         function sqrt_array!(A, B, chunk)
             for i in chunk
                 @inbounds B[i] = sqrt(A[i])
             end
         end

         function threaded_sqrt_array(A)
             B = similar(A)
             chunks = Iterators.partition(eachindex(A), length(A) ÷ Threads.nthreads())
             @sync for chunk in chunks
                 @spawn sqrt_array!(A, B, chunk)
             end
             B
         end

We can now compare the performance:

.. code-block:: julia

   A = rand(1000, 1000)
   @btime sqrt_array(A);
   @btime threaded_sqrt_array(A);

   # make sure we're getting the correct value
   sqrt_array(A) ≈ threaded_sqrt_array(A)

With 4 threads, the speedup could be about a factor of 3.   

.. callout:: Threading overhead

   Using ``Threads.@threads`` has an overhead of a few microseconds (equivalent to thousands of computations), 
   so threading is most efficient for time consuming jobs.


Pitfalls
--------
Just like with multithreading in other languages, one needs to be 
aware of possible `race conditions <https://en.wikipedia.org/wiki/Race_condition>`_, 
i.e. when the order in which threads read from and write to memory 
can change the result of a computation. 

We can illustrate this with an example where we sum up the square 
root of elements of an array. The serial version provides the correct 
value and reference execution time. The "race condition" version illustrates 
how a naive implementation can lead to problems. The "atomic" version shows 
how we can ensure a correct results by using `atomic operations`.
The "workaround" version shows how we can refactor the code to get both 
correct result and speedup.

FIXME: do not use threadid for indexing!!!

.. tabs:: 

   .. tab:: Serial

      .. code-block:: julia

         function sqrt_sum(A)
             s = zero(eltype(A))
             for i in eachindex(A)
                 @inbounds s += sqrt(A[i])
             end
             return s
         end


   .. tab:: Race condition

      .. code-block:: julia

         function threaded_sqrt_sum(A)
             s = zero(eltype(A))
             @threads for i in eachindex(A)
                 @inbounds s += sqrt(A[i])
             end
             return s
         end

   .. tab:: Atomic

      .. code-block:: julia

         function threaded_sqrt_sum_atomic(A)
             s = Atomic{eltype(A)}(zero(eltype(A)))
             @threads for i in eachindex(A)
                 @inbounds atomic_add!(s, sqrt(A[i]))
             end
             return s[]
         end

   .. tab:: Workaround

      .. code-block:: julia

         function threaded_sqrt_sum_workaround(A)
             partial = zeros(eltype(A), nthreads())
             @threads for i in eachindex(A)
                 @inbounds partial[threadid()] += sqrt(A[i])
             end
             s = zero(eltype(A))
             for i in eachindex(partial)
                 s += partial[i]
             end     
             return s
         end         

We will observe that:

- The serial version is slow but correct.
- The race condition version is both slow and wrong.
- The atomic version is correct but extremely slow.
- The workaround is fast and correct, but required refactoring.

Bonus questions: 

- What does :meth:`eltype` do?
- What does :meth:`eachindex` do?

Threading with ``Threads.@threads`` is quite straightforward, 
but one needs to be careful not to introduce race conditions 
and sometimes that requires code refactorization. Using atomic operations 
adds significant overhead and thus only makes sense if each iteration 
of the loop takes significant time to compute.

..
   FLoops
   ^^^^^^

   `FLoops.jl <https://github.com/JuliaFolds/FLoops.jl>`__ is a a more recent  
   package for threading. It provides a macro ``@floop`` which is a superset of ``Threads.@threads``
   and can be used to generate fast generic sequential and parallel iteration over more 
   complex collections than what can be done with ``Threads.@threads``.
   ``@floop`` can also do reductions and supports multiple threading backends through 
   `FoldsThreads.jl <FoldsThreads.jl>`_ and even `FoldsCUDA.jl 
   <https://github.com/JuliaFolds/FoldsCUDA.jl>`__ for running on GPUs.


Exercises
---------

Multithreading the Laplace function
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Consider the double for loop in the :meth:`lap2d!` function:

.. literalinclude:: code/lap2d_inbounds.jl
   :language: julia

Can it safely be threaded, i.e. is there any risk of race 
conditions?

.. solution:: Is it thread-safe?

   Yes, this function is thread-safe since each iteration of the loop accesses a different memory location.

- Insert the ``Threads.@threads`` macro in the right location - 
  note that ``@threads`` currently only works on outermost loops!
- Measure its effects with ``@benchmark``.
  Since it's cumbersome to change the "Julia: Num Threads" option 
  in VSCode and relaunch the Julia REPL over and over, create a script instead 
  which imports `BenchmarkTools` and prints benchmark results:      

  .. code-block:: julia

     bench_results = @benchmark lap2d!(u, unew)
     println(minimum(bench_results.times))

- Now run with different number of threads from a terminal using 
  ``julia -t <N> laplace.jl`` and observe the scaling.
- Try increasing the problem size (e.g. ``M=N=8192``). Does it scale better?

.. solution:: 

   Multithreaded version:

   .. literalinclude:: code/threaded_lap2d.jl
      :language: julia

   Benchmarking:

   .. code-block:: julia

      function setup(N=4096, M=4096)
          u = zeros(M, N)
          # set boundary conditions
          u[1,:] = u[end,:] = u[:,1] = u[:,end] .= 10.0
          unew = copy(u);
          return u, unew
      end    

      using BenchmarkTools

      u, unew = setup()
      bench_results = @benchmark lap2d!($u, $unew)
      println("time = $(minimum(bench_results.times)/10^6)")     

   .. code-block:: console

      $ julia -t 1 laplace.jl
      # time = 7.440875

      $ julia -t 2 laplace.jl
      # time = 4.559292

      $ julia -t 4 laplace.jl
      # time = 3.802625


   Increasing the problem size will not improve the parallel efficiency as it does not 
   increase the computational cost in the loop.


Multithread the computation of π
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. figure:: img/pi_with_darts.png
   :scale: 7 %
   :align: right

Consider the following function which estimates π by "throwing darts", 
i.e. randomly sampling (x,y) points in the interval [0.0, 1.0] and checking 
if they fall within the unit circle.

.. literalinclude:: code/estimate_pi.jl
   :language: julia

.. code-block:: julia

   num_points = 100_000_000
   estimate_pi(num_points)  # 3.14147572...

Can this function be safely threaded, i.e. is there any risk of race 
conditions?

.. solution:: Is it thread-safe?

   No, this function is not thread-safe! The algorithm needs to be rewritten.

- Define a new function :meth:`threaded_estimate_pi` where you implement the necessary changes 
  to multithread the loop.
- Run some benchmarks to explore the parallel efficiency.

.. solution:: Hint

   You need to make sure that the different threads are not incrementing the same memory address.
   One can for example define a ``partial_hits`` array and increment its indices in the for loop:

   .. code-block:: julia

      partial_hits = zeros(Int, nthreads())

.. solution:: 

   Here is a threaded version:

   .. literalinclude:: code/threaded_estimate_pi.jl
      :language: julia

   To benchmark it:

   .. code-block:: julia

      using BenchmarkTools

      num_points = 100_000_000
      # make sure we get an accurate estimate:
      println("pi = $(threaded_estimate_pi(num_points))")

      bench_results = @benchmark threaded_estimate_pi($num_points)
      println("time = $(minimum(bench_results.times)/10^6)")

   Results:

   .. code-block:: console

      $ julia -t 1 threaded_estimate_pi.jl
      # pi = 3.14147464
      # time = 496.935583

      $ julia -t 2 threaded_estimate_pi.jl
      # pi = 3.1417046
      # time = 255.328

      $ julia -t 4 threaded_estimate_pi.jl
      # pi = 3.14172796
      # time = 132.892833

   Parallel scaling seems decent, but comparing to the unthreaded version reveals the overhead 
   from creating and managing threads:

   .. code-block:: console

      $ julia estimate_pi.jl
      # pi = 3.14147392
      # time = 228.434583     


See also
--------

- The `Julia Parallel <https://github.com/JuliaParallel>`_ organization collects 
  packages developed for parallel computing in Julia.
- `Multi-threading docs <https://docs.julialang.org/en/v1/manual/multi-threading/>`__

.. keypoints::

   - One should choose a distributed mechanism that fits with the 
     time and memory parameters of your problem   
   - ``Threads`` is as easy as decorating for loops with ``@threads``, but data 
     dependencies (race conditions) need to be avoided.
