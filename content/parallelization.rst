Parallelization
===============

.. questions::

   - What parallelization options exist in Julia?
   - What are the canonical ways of parallelizing on shared and distributed memory systems?

.. objectives::

   - Get an overview of parallelization in Julia
   - Learn to use the Threads module
   - Learn to use the Distributed package
   - Know when you can use ``@distributed`` and ``pmap``
   - Learn to work with SharedArrays and Distributed arrays

Overview
--------

WRITEME

Threading
---------

We will now walk through how to use multithreading in Julia. 
In the VSCode REPL, let's see how many threads we have access to:

.. code-block:: julia

   Threads.nthreads()

Hmm, but we need more than one thread to be able to gain any performance 
from multithreading. 

Julia can be started with a given number of threads in two ways:

.. code-block:: bash

   julia -t 4
   # or (can also set the env-var in e.g. .bashrc)
   JULIA_NUM_THREADS = 4 julia

This is not possible to do inside VSCode. Instead, we open up the 
"Extension Settings" for the Julia VSCode extension and set the 
"Julia: Num Threads" setting to the number of CPU cores we have on 
our machines (if you're unsure, just try setting it to 2).
We can make sure we have access to the correct number of threads 
with the ``Threads.nthreads()`` function.

The main multithreading approach is to use the ``Threads.@threads`` macro 
which parallelizes a `for` loop to run with multiple threads:

.. code-block:: julia

   a = zeros(10)
   Threads.@threads for i = 1:10
       a[i] = Threads.threadid()
   end
   println(a)



Note that ``@threads`` currently only works on outermost loops.


Summary
^^^^^^^

WRITEME

Distributed computing
---------------------


WRITEME: General discussion

- MPI.jl
- Distributed.jl
- Kubernetes.jl
- ClusterManagers

.. code-block::
   
   function throw_darts(N)
       n = 0
       for i in 1:N
           if rand()^2 + rand()^2 < 1
           n += 1
           end
       end
       return n
   end

.. code-block::

   function estimate_pi(N, loops)
       n = sum(pmap((x)->darts_in_circle(N), 1:loops))
       return 4 * n / (loops * N)
   end


@distributed
^^^^^^^^^^^^


``pmap``
^^^^^^^^


SharedArrays
^^^^^^^^^^^^


DistributedArrays
^^^^^^^^^^^^^^^^^

notes
^^^^^

example function to distribute:

.. code-block:: julia

   @everywhere function compute_pi(N)
      series = 1.0
      for i in 1:N
         series += (isodd(i) ? -1 : 1) / (2i + 1)
      end
      return 4*series
   end

Summary
^^^^^^^

One should choose a distributed mechanism that fits with the 
time and memory parameters of your problem

- @distributed is good for reductions and even relatively fast inner loops with limited explicit data transfer
- pmap is good for expensive inner loops that return a value
- SharedArrays can be an easier drop-in replacement for threading-like behaviors (on a single machine)
- DistributedArrays lets the data do the work splitting



Exercises
---------

.. exercise:: Multithreading HeatEquation.jl

   Consider the double for loop in the ``evolve!`` function. 
   Can it safely be threaded, i.e. is there any risk of race 
   conditions?

   - Insert the ``Threads.@threads`` macro in the right location.
   - Measure its effects with ``@benchmark``.
     Since it's cumbersome to change the "Julia: Num Threads" option 
     in VSCode and relaunch the Julia REPL over and over, use the 
     `example.jl` script instead: comment out the visualization and 
     insert something like:

     .. code-block:: julia

        bench_results = @benchmark simulate!(curr, prev, nsteps)
        println(minimum(bench_results.times))

   - Now run with different number of threads from a terminal using 
     ``julia --project=. -t N example.jl`` and observe the scaling.
   - Try increasing the problem size (e.g. ``nx=ny=10_000``) while lowering the 
     number of time steps (e.g. ``nsteps = 20``). Does it scale better?


.. exercise:: Using SharedArrays with Heatequation

   Open up the Heatequation.jl package in VSCode and read the "SharedArrayHint"
   comments. Think about what you should do, and then try doing it.
   After you're done, benchmark a few test runs. 

   .. solution:: 

      Switch to the `SharedArrays` branch of the repository (``git checkout SharedArrays``)
      and have a look at the code.

.. exercise:: Using DistributedArrays with Heatequation

   Open up the Heatequation.jl package in VSCode and read the "DistributedArrayHint"
   comments. Think about what you should do, and then try doing it.
   After you're done, benchmark a few test runs.

   .. solution:: 

      Switch to the `DistributedArrays` branch of the repository (``git checkout DistributedArrays``)
      and have a look at the code.




See also
--------

- https://docs.julialang.org/en/v1/manual/multi-threading/
- https://julialang.org/blog/2019/07/multithreading/
- https://docs.julialang.org/en/v1/manual/performance-tips/
- https://docs.julialang.org/en/v1/manual/distributed-computing/

