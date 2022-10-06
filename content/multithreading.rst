Multithreading
==============

.. questions::

   - What parallelization options exist in Julia?
   - What is multithreading?

.. instructor-note::

   - 15 min teaching
   - 20 min exercises


Overview
--------

Julia has inbuilt automatic parallelism which is useful to know about.
Consider the multiplication of two large array:

.. code-block:: julia

   A = rand(10000,10000)
   B = rand(10000,10000)
   A*B

If we run this in a Julia session and monitor the resource usage (e.g. via ``top``) 
we can see that all cores on our computers are used! 

But to beyond that, Julia supports four main types of parallel programming:

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
- **GPU computing**: Covered in the next episode!   
  
Threading
---------

We start by walking through how to use multithreading in Julia. 
In the VSCode REPL, let's see how many threads we have access to:

.. code-block:: julia

   Threads.nthreads()

Hmm, but we need more than one thread to be able to gain any performance 
from multithreading. 

Julia can be started with a given number of threads in two ways:

.. code-block:: bash

   julia -t 4  
   julia -t auto
   # or (can also set the env-var in e.g. .bashrc)
   JULIA_NUM_THREADS=4 julia

This is not possible to do inside VSCode. Instead, we open up the 
"Extension Settings" for the Julia VSCode extension and set the 
"Julia: Num Threads" setting to the number of CPU cores we have on 
our machines (if you're unsure, just try setting it to 2).
After updating the number of threads we need to restart the VSCode REPL.
We can make sure we have access to the correct number of threads 
with the ``Threads.nthreads()`` function.

The main multithreading approach is to use the ``Threads.@threads`` macro 
which parallelizes a `for` loop to run with multiple threads:

.. code-block:: julia

   using .Threads
   a = zeros(10)
   @threads for i = 1:10
       a[i] = threadid()
   end
   println(a)

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
   
   .. tab:: Threaded
   
      .. code-block:: julia

         function threaded_sqrt_array(A)
             B = similar(A)
             @threads for i in eachindex(A)
                 @inbounds B[i] = sqrt(A[i])
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

With 4 threads, the speedup could be between a factor 2 or 3.   


Pitfalls
^^^^^^^^

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

- What does ``eltype`` do?
- What does ``eachindex`` do?

Threading with ``Threads.@threads`` is quite straightforward, 
but one needs to be careful not to introduce race conditions 
and sometimes that requires code refactorization. Using atomic operations 
adds significant overhead and thus only makes sense if each iteration 
of the loop takes significant time to compute.

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

.. exercise:: Multithreading HeatEquation.jl

   Consider the double for loop in the ``evolve!`` function. 
   Can it safely be threaded, i.e. is there any risk of race 
   conditions?

   - Insert the ``Threads.@threads`` macro in the right location - 
     note that ``@threads`` currently only works on outermost loops!
   - Measure its effects with ``@benchmark``.
     Since it's cumbersome to change the "Julia: Num Threads" option 
     in VSCode and relaunch the Julia REPL over and over, create a script instead 
     which imports `HeatEquation` and `BenchmarkTools` and prints benchmark 
     results:      

     .. code-block:: julia

        bench_results = @benchmark simulate!(curr, prev, nsteps)
        println(minimum(bench_results.times))

   - Now run with different number of threads from a terminal using 
     ``julia --project=. -t <N> benchmarking.jl`` and observe the scaling.
   - Try increasing the problem size (e.g. ``nx=ny=10_000``) while lowering the 
     number of time steps (e.g. ``nsteps = 20``). Does it scale better?

   .. solution::

      Threaded version of ``evolve!``:

      .. code-block:: julia

         function evolve!(curr::Field, prev::Field, a, dt)
             Threads.@threads for j = 2:curr.ny+1
                 for i = 2:curr.nx+1
                     @inbounds xderiv = (prev.data[i-1, j] - 2.0 * prev.data[i, j] + prev.data[i+1, j]) / curr.dx^2
                     @inbounds yderiv = (prev.data[i, j-1] - 2.0 * prev.data[i, j] + prev.data[i, j+1]) / curr.dy^2
                     @inbounds curr.data[i, j] = prev.data[i, j] + a * dt * (xderiv + yderiv)
                 end 
             end
         end

      Script to run benchmarking:

      .. code-block:: julia
 
         using HeatEquation
         using BenchmarkTools
         
         ncols, nrows, nsteps = 10_000, 10_000, 20
         curr, prev = initialize(ncols, nrows)
         
         bench_results = @benchmark simulate!(curr, prev, nsteps)
         # minimum runtime in seconds
         println(minimum(bench_results.times)/1e9)

      Running benchmarking from terminal:

      .. code-block:: bash

         $ julia --project -t 1 run_benchmarking.jl
         # 5.314849396
         $ julia --project -t 2 run_benchmarking.jl
         # 3.236433742
         $ julia --project -t 4 run_benchmarking.jl
         # 3.311189835
       
      The scaling isn't very good because the loops in ``evolve!`` are very cheap, 
      but it seems to scale better with larger arrays.


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
