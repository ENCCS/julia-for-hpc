Exercises
=========

.. instructor-note::

   - 0 min teaching
   - 30 min exercises

Introducing HeatEquation.jl
---------------------------

This series of exercises uses a realistic Julia package
based on a minimal heat equation solver, inspired by 
`this educational repository containing C/C++/Fortran versions with different 
parallelization strategies <https://github.com/cschpc/heat-equation>`_ (credits to 
CSC Finland). The Julia version of this package can be found at 
https://github.com/enccs/HeatEquation.jl but the source files are also displayed 
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


.. challenge:: Download and run HeatEquation.jl 

   - Clone the repository at https://github.com/enccs/HeatEquation.jl into a new directory.
   - Activate the environment found in the Project.toml file

   If you don't have Git installed, you can also 
   `download a zipfile <https://github.com/ENCCS/HeatEquation.jl/archive/refs/heads/main.zip>`__.

   - Next open a new VSCode window and navigate to the new directory. 
   - Open up a Julia REPL inside VSCode and activate the `HeatEquation` environment.

   When everything has been set up, import `HeatEquation` and begin by 
   testing the package: 

   .. code-block:: julia

      using HeatEquation
      using BenchmarkTools

      ncols, nrows, nsteps = 1000, 1000, 500
      curr, prev = initialize(ncols, nrows)
      visualize(curr)

      simulate!(curr, prev, nsteps)

      visualize(curr)

   .. solution::

      .. code-block:: shell

         cd $HOME/julia
         git clone https://github.com/enccs/HeatEquation.jl
         cd HeatEquation
   
      In a new VSCode window (or in the Julia REPL), activate the environment:

      .. code-block:: julia

         Pkg.activate(".")

.. challenge:: Optimise and benchmark

   - Benchmark the :meth:`evolve!` function.
   - Add the ``@inbounds`` macro to the innermost loop.
   - Benchmark again and estimate the performance gain.


.. challenge:: Multithread 

   - Multithread the :meth:`evolve!` function
   - Benchmark HeatEquation with different number of threads. How does it scale?

   .. solution::

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


.. exercise:: Using SharedArrays with HeatEquation

   Look again at the double for loop in the ``evolve!`` function 
   and think about how you could use SharedArrays.

   The best approach might be to start by refactoring the package a bit and change 
   the ``evolve!`` function to accept arrays instead of ``Field`` structs, like this:

   .. code-block:: julia

      function evolve!(currdata::AbstractArray, prevdata::AbstractArray, dx, dy, a, dt)
          nx, ny = size(currdata) .- 2
          for j = 2:ny+1
              for i = 2:nx+1
                  @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                  @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                  @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
              end 
          end
      end 

   - Create a new script where you import ``Distributed``, ``SharedArrays`` and 
     ``BenchmarkTools`` and define the ``evolve!`` function above.
   - Benchmark the original version:

   .. code-block:: julia

      dx = dy = 0.01
      a = 0.5
      dt = dx^2 * dy^2 / (2.0 * a * (dx^2 + dy^2))
      M1 = rand(1000, 1000);
      M2 = rand(1000, 1000);
      @btime evolve!(M1, M2, dx, dy, a, dt)

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

         function evolve!(currdata::AbstractArray, prevdata::AbstractArray, dx, dy, a, dt)
             nx, ny = size(currdata) .- 2
             for j = 2:ny+1
                 for i = 2:nx+1
                     @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                     @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                     @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
                 end 
                 sleep(0.001)
             end
         end

         function evolve!(currdata::SharedArray, prevdata::SharedArray, dx, dy, a, dt)
             nx, ny = size(currdata) .- 2
             @sync @distributed for j = 2:ny+1
                 for i = 2:nx+1
                     @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                     @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                     @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
                 end 
                 sleep(0.001)
             end
         end

         dx = dy = 0.01
         a = 0.5
         dt = dx^2 * dy^2 / (2.0 * a * (dx^2 + dy^2))
         M1 = rand(1000, 1000);
         M2 = rand(1000, 1000);
         S1 = SharedArray(M1);
         S2 = SharedArray(M2);

         # test for correctness:
         evolve!(M1, M2, dx, dy, a, dt) 
         evolve!(S1, S2, dx, dy, a, dt) 
         # element-wise comparison, should give "true"
         all(M1 .≈ S1)

         # benchmark
         @btime evolve!(M1, M2, dx, dy, a, dt) 
         #   2.379 s (5031 allocations: 152.52 KiB)

         @btime evolve!(S1, S2, dx, dy, a, dt)
         #   578.060 ms (722 allocations: 32.72 KiB)


.. exercise:: Port HeatEquation.jl to GPU

   Write a kernel for the ``evolve!`` function!

   Start with this refactored function which accepts arrays:

   .. code-block:: julia

      function evolve!(currdata::AbstractArray, prevdata::AbstractArray, dx, dy, a, dt)
          nx, ny = size(currdata) .- 2
          for j = 2:ny+1
              for i = 2:nx+1
                  @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx^2
                  @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy^2
                  @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
              end 
          end
      end

   Now start implementing a GPU kernel version ``evolve_gpu!``.

   1. The kernel function needs to end with ``return`` or ``return nothing``.

   2. The arrays are two-dimensional, so you will need both the ``.x`` and ``.y`` 
      parts of ``threadIdx()``, ``blockDim()`` and ``blockIdx()``.

      - Does it matter how you match the ``x`` and ``y`` dimensions of the 
        threads and blocks to the dimensions of the data (i.e. rows and columns)? 

   3. You also need to specify tuples 
      for the number of threads and blocks in the ``x`` and ``y`` dimensions, 
      e.g. ``threads = (32, 32)`` and similarly for ``blocks`` (using ``cld``).

      - Note the hardware limitations: the product of x and y threads cannot 
        exceed it.

   4. For debugging, you can print from inside a kernel using ``@cuprintln`` 
      (e.g. to print thread numbers). It will only print during the first 
      execution - redefine the function again to print again.
      If you get warnings or errors relating to types, you can use the code 
      introspection macro ``@device_code_warntype`` to see the types inferred 
      by the compiler.

   5. Check correctness of your results! To test that ``evolve!`` and ``evolve_gpu!`` 
      give (approximately) the same results, for example:

      .. code-block:: julia

         dx = dy = 0.01
         a = 0.5
         nx = ny = 10000
         dt = dx^2 * dy^2 / (2.0 * a * (dx^2 + dy^2))
         A1 = rand(nx, ny);
         A2 = rand(nx, ny);
         A1_d = CuArray(A1)
         A2_d = CuArray(A2)

         evolve!(A1, A2, dx, dy, a, dt)

         evolve_gpu!(A1_d, A2_d, dx, dy, a, dt)

         all(A1 .≈ Array(A1_d))
   
   6. Perform some benchmarking of the ``evolve!`` and ``evolve_gpu!`` 
      functions for arrays of various sizes and with different choices 
      of ``nthreads``. You will need to prefix the 
      kernel execution with the ``CUDA.@sync`` macro 
      to let the CPU wait for the GPU kernel to finish (otherwise you 
      would be measuring the time it takes to only launch the kernel):

   
   7. Compare your Julia code with the 
      `corresponding CUDA version <https://github.com/cschpc/heat-equation/blob/main/cuda/core_cuda.cu>`__
      to enjoy the (relative) simplicity of Julia!

   .. solution:: 

      This is one possible GPU kernel version of ``evolve!``:

      .. code-block:: julia

         function evolve_gpu!(currdata, prevdata, dx2, dy2, a, dt)
             nx, ny = size(currdata) .- 2   
             # which index (i or j) you assign to x and y matters enormously!
             i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
             j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
             #@cuprintln("threads $i $j") #only for debugging!
             if i > 1 && j > 1 && i < nx+2 && j < ny+2
                 @inbounds xderiv = (prevdata[i-1, j] - 2.0 * prevdata[i, j] + prevdata[i+1, j]) / dx2
                 @inbounds yderiv = (prevdata[i, j-1] - 2.0 * prevdata[i, j] + prevdata[i, j+1]) / dy2
                 @inbounds currdata[i, j] = prevdata[i, j] + a * dt * (xderiv + yderiv)
             end
             return nothing
         end

      To test it:

      .. code-block:: julia

         dx = dy = 0.01
         a = 0.5
         nx = ny = 1000
         dt = dx^2 * dy^2 / (2.0 * a * (dx^2 + dy^2))
         M1 = rand(nx, ny);
         M2 = rand(nx, ny);

         # copy to GPU and convert to Float32
         M1_d = CuArray(cu(M1))
         M2_d = CuArray(cu(M2))

         # set number of threads and blocks
         nthreads = 16
         numblocks = cld(nx, nthreads)

         # call cpu and gpu versions
         evolve!(M1, M2, dx, dy, a, dt)
         @cuda threads=(nthreads, nthreads) blocks=(numblocks, numblocks) evolve_gpu!(M1_d, M2_d, dx^2, dy^2, a, dt)

         # element-wise comparison
         all(M1 .≈ Array(M1_d))

      To benchmark:

      .. code-block:: julia

         using BenchmarkTools
         @btime evolve!(M1, M2, dx, dy, a, dt)
         @btime CUDA.@sync @cuda threads=(nthreads, nthreads) blocks=(numblocks, numblocks) evolve_gpu!(M1_d, M2_d, dx^2, dy^2, a, dt)

