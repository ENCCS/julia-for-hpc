Writing performant Julia code
=============================

.. questions::

   - How should performance be measured?
   - How can I profile my code?
   - Are there any performance pitfalls in Julia?

.. objectives::

   - Learn several methods for writing fast Julia code


Introducing Heatequation
------------------------

We will need a realistic Julia package to work on from now on.
For this purpose we will use a minimal heat equation solver, inspired by 
`this educational repository containing C/C++ versions with different 
parallelization strategies <https://github.com/cschpc/heat-equation>`_ (credits to 
CSC Finland). The Julia version of this package can be found at 
https://github.com/enccs/heatequation.jl but the source files are also displayed 
below.

.. tabs:: 

   .. tab:: HeatEquation.jl

      .. literalinclude:: code/HeatEquation/src/HeatEquation.jl
         :language: julia

   .. tab:: setup.jl

      .. literalinclude:: code/HeatEquation/src/setup.jl
         :language: julia

   .. tab:: io.jl

      .. literalinclude:: code/HeatEquation/src/io.jl
         :language: julia

   .. tab:: core.jl

      .. literalinclude:: code/HeatEquation/src/core.jl
         :language: julia

   .. tab:: Project.toml

      .. literalinclude:: code/HeatEquation/Project.toml
         :language: julia         


Benchmarking
------------

Base Julia already has the ``@time`` macro to print the time it takes to 
execute an expression. However, to get more accurate values it is better to 
rely on the `BenchmarkTools.jl <https://juliaci.github.io/BenchmarkTools.jl/dev/manual/>`_ 
framework, which provides convenient macros to perform benchmarking:

- ``@btime``: for quick sanity checks, prints the time an expression takes and the memory allocated 
- ``@benchmark``: runs a fuller benchmark on a given expression.

As with `Revise.jl` and `Test.jl`, `BenchmarkTools.jl` should be installed in the base environment:

.. code-block::

   Pkg.activate()
   Pkg.add("BenchmarkTools")

Let us all try it out on the HeatEquation package in the REPL. 
We could use the ``Pkg.develop()`` function to clone the repository 
into our `~/.julia/dev` folder, which is a good way to work on existing 
Julia packages. Here, we instead imagine that we wrote this package and it 
exists on our computer, so we start by cloning the repository (or download and 
unpack a zip archive) to a new folder:

.. type-along:: Benchmarking

   .. code-block:: shell

      cd $HOME/julia
      git clone https://github.com/enccs/HeatEquation.jl
      cd HeatEquation

   Next open a new VSCode window and navigate to the new directory. 
   Open up a Julia REPL and activate the `HeatEquation` environment.

   When everything has been set up, we can import `HeatEquation` and start 
   benchmarking. We should also not forget to import `Revise`!

   .. code-block:: julia

      using HeatEquation
      using Revise
      using BenchmarkTools

      ncols, nrows, nsteps = 1000, 1000, 500
      curr, prev = initialize(ncols, nrows)

      @benchmark simulate!(curr, prev, nsteps)

   We can also capture the output of ``@benchmark``:

   .. code-block:: julia

      bench_results = @benchmark simulate!(curr, prev, nsteps)
      typeof(bench_results)
      println(minimum(bench_results.times))


Profiling
---------

The `Profile module <https://docs.julialang.org/en/v1/manual/profile/>`_, part of ``Base``, 
provides tools to help improve 
the performance of Julia code. It relies on `sampling` code at runtime 
and thus gathering statistical information on where time is spent. 
Profiling is particularly useful for identifying bottlenecks in code - 
we should remember that "premature optimization is the root of all evil" (Donald Knuth).

Let's go ahead and profile the `HeatEquation` code:

.. type-along:: Profiling

   This is how we can profile the ``simulate!`` function and 
   print its results in a tree structure:

   .. code-block:: julia

      using Profile

      Profile.clear() # clear backtraces from earlier runs
      curr, prev = initialize(1000, 1000)
      @profile simulate!(curr, prev, 500)
      Profile.print()

   The information shown is not that easily digestible. Fortunately, the Julia extension 
   for VSCode includes a ``@profview`` macro which provides a clearer graphical view:

   .. code-block:: julia

      @profview simulate!(curr, prev, 500)

   We can also look at the same information in a flamegraph by clicking the little fire 
   button next to the search area. 
   We should now be able to conclude that ``setindex!`` and ``getindex`` functions 
   inside ``evolve!`` take most of the time.

Several packages are available for more advanced visualization of profiling results:

- `ProfileView.jl <https://github.com/timholy/ProfileView.jl>`_ is a stand-alone visualizer 
  based on GTK.
- `ProfileVega.jl <https://github.com/davidanthoff/ProfileVega.jl>`_ 
  uses VegaLight and integrates well with Jupyter notebooks.
- `StatProfilerHTML.jl <https://github.com/tkluck/StatProfilerHTML.jl>`_ 
  produces HTML and presents some additional summaries, 
  and also integrates well with Jupyter notebooks.
- `PProf.jl <https://github.com/JuliaPerf/PProf.jl>`_ an interactive, web-based profile 
  GUI explorer, implemented as a wrapper around google/pprof. 



Optimization options
--------------------

Column-major vs row-major order
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Multidimensional arrays in Julia are stored in column-major order, i.e. 
arrays are stacked one column at a time in memory. This is the same order 
as in Fortran, Matlab and R, but opposite to that of C/C++ and Python (numpy). 
To avoid cache-misses it is  crucial to order one's loops such that memory is 
accessed in a contiguous way!

We can verify this by swapping the loop order in the ``evolve!`` function and 
measure the performance:

.. code-block:: julia

   function evolve!(curr::Field, prev::Field, a, dt)
       for i = 2:curr.nx+1
           for j = 2:curr.ny+1
               xderiv = (prev.data[i-1, j] - 2.0 * prev.data[i, j] + prev.data[i+1, j]) / curr.dx^2
               yderiv = (prev.data[i, j-1] - 2.0 * prev.data[i, j] + prev.data[i, j+1]) / curr.dy^2
               curr.data[i, j] = prev.data[i, j] + a * dt * (xderiv + yderiv)
         end 
      end
   end

.. code-block:: julia

   curr, prev = initialize(1000, 1000)
   @benchmark simulate!(curr, prev, 500)

In a set of tests this more than doubled the execution time!   

@inbounds
^^^^^^^^^

The ``@inbounds`` macro eliminates array bounds checking within expressions which 
can save considerable time. This should only be used if you are sure that no out-of-bounds 
indices are used!

Let us add ``@inbounds`` to the three lines in the inner loop in ``evolve!`` 
and benchmark it:

.. code-block:: julia

   for j = 2:curr.ny+1
       for i = 2:curr.nx+1
           @inbounds xderiv = (prev.data[i-1, j] - 2.0 * prev.data[i, j] + prev.data[i+1, j]) / curr.dx^2
           @inbounds yderiv = (prev.data[i, j-1] - 2.0 * prev.data[i, j] + prev.data[i, j+1]) / curr.dy^2
           @inbounds curr.data[i, j] = prev.data[i, j] + a * dt * (xderiv + yderiv)
       end 
    end

.. code-block:: julia

   curr, prev = initialize(1000, 1000)
   @benchmark simulate!(curr, prev, 500)

Significant speedup should be seen! In a set of tests the execution time as  
well as memory consumption were reduced by 50\%.


StaticArrays
^^^^^^^^^^^^

For applications involving *many small arrays*, significant performance can 
be gained by using `StaticArrays <https://github.com/JuliaArrays/StaticArrays.jl>`__
instead of normal Arrays. The package provides a range of built-in ``StaticArray``
types, including mutable and immutable arrays, with a *static size known at 
compile time*.

Example:

.. code-block:: julia

   m1 = rand(10,10)
   m2 = @SArray rand(10,10)

   @btime m1*m1
   # 311.808 ns (1 allocation: 896 bytes)

   @btime m2*m2
   # 99.902 ns (1 allocation: 816 bytes)

``StaticArrays`` provide 
`many additional features <https://juliaarrays.github.io/StaticArrays.jl/stable/pages/quickstart/>`__,
but unfortunately they can only be used for vectors, matrices and arrays with up 
to around 100 elements.


Other performance considerations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Julia's official documentation has an important page on 
`Performance tips <https://docs.julialang.org/en/v1/manual/performance-tips/>`_.
Before embarking on any research software project in Julia you 
should carefully read this page!

Summary
-------

- Optimize your serial code before you parallelize! There's a lot to think about.


  
See also
--------

- https://slides.com/valentinchuravy/julia-parallelism#/1/1
- https://docs.julialang.org/en/v1/manual/performance-tips/     
