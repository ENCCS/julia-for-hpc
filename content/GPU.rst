GPU programming
===============

.. questions::

   - What are the high-level and low-level methods for GPU programming in Julia?
   - How do GPU Arrays work?
   - How are GPU kernels written?

.. instructor-note::

   - 30 min teaching
   - 40 min exercises


Julia has first-class support for GPU programming through the following 
packages that target GPUs from all three major vendors:

- `CUDA.jl <https://cuda.juliagpu.org/stable/>`_ for NVIDIA GPUs
- `AMDGPU.jl <https://amdgpu.juliagpu.org/stable/>`_ for AMD GPUs
- `oneAPI.jl <https://github.com/JuliaGPU/oneAPI.jl>`_ for Intel GPUs
- `Metal.jl <https://github.com/JuliaGPU/Metal.jl>`_ for Apple M-series GPUs

``CUDA.jl`` is the most mature, ``AMDGPU.jl`` is somewhat behind but still 
ready for general use, while ``oneAPI.jl`` and ``Metal.jl`` are functional but might 
contain bugs, miss some features and provide suboptimal performance.

NVIDIA still dominates the HPC accelerator market and we will focus here 
on using ``CUDA.jl`` - the API of ``AMDGPU.jl`` is however completely analogous
and translation between the two is straightforward.

``CUDA.jl`` offers both user-friendly high-level abstractions that require 
very little programming effort and a lower level approach for writing kernels 
for fine-grained control.

Setup
-----

.. tabs::

   .. group-tab:: NVIDIA

      Installing ``CUDA.jl``:

      .. code-block:: julia
      
         using Pkg
         Pkg.add("CUDA")

   .. group-tab:: AMD

      Installing ``AMDGPU.jl``:

      .. code-block:: julia
      
         using Pkg
         Pkg.add("AMDGPU")

   .. group-tab:: Intel

      Installing ``oneAPI.jl``:

      .. code-block:: julia
      
         using Pkg
         Pkg.add("oneAPI")

   .. group-tab:: Apple

      Installing ``Metal.jl``:

      .. code-block:: julia
      
         using Pkg
         Pkg.add("Metal")


To use the Julia GPU stack, one needs to have the relevant GPU drivers and 
programming toolkits installed. GPU drivers are already installed on HPC systems 
while on your own machine you will need to install them yourself (see e.g.  these 
`instructions from NVIDIA <https://www.nvidia.com/Download/index.aspx>`_). 
Programming toolkits (e.g. CUDA, ROCm etc.) can be installed automatically through 
Julia's artifact system upon the first import (e.g. ``using CUDA``).

Access to GPUs
--------------

To fully experience the walkthrough in this episode we need to have access 
to a GPU device and the necessary software stack. 

- Access to a HPC system with GPUs and a Julia installation is optimal. 
- If you have a powerful GPU on your own machine you can also install the drivers and toolkits yourself. Another option is to use 
- `JuliaHub <https://juliahub.com/lp/>`_, a commercial cloud platform from `Julia Computing <https://juliacomputing.com/>`_ 
  with access to Julia's ecosystem of packages and GPU hardware. 
- Or one can use `Google Colab <https://colab.research.google.com/>`_ which requires a Google 
  account and a manual Julia installation, but using simple NVIDIA GPUs is free.
  Google Colab does not support Julia, but a
  `helpful person on the internet <https://github.com/Dsantra92/Julia-on-Colab>`__ 
  has created a Colab notebook that can be reused for Julia computing on Colab.


GPUs vs CPUs
------------

We first briefly discuss the hardware differences between GPUs and CPUs. 
This will help us understand the rationale behind the GPU programming methods 
described later.

.. figure:: img/CPUAndGPU.png

   A comparison of CPU and GPU architectures. A CPU has a complex core 
   structure and packs several cores on a single chip. GPU cores are very simple 
   in comparison and they share data, allowing to pack more cores on a single chip. 
   
Some key aspects of GPUs that need to be kept in mind:

- The large number of compute elements on a GPU (in the thousands) can enable 
  extreme scaling for `data parallel` tasks (single-program multiple-data, SPMD)
- GPUs have their own memory. This means that data needs to be transfered to 
  and from the GPU during the execution of a program.
- Cores in a GPU are arranged into a particular structure. At the highest level 
  they are divided into "streaming multiprocessors" (SMs). Some of these details are 
  important when writing own GPU kernels.


The array interface
-------------------

GPU programming with Julia can be as simple as using a different array type 
instead of regular ``Base.Array`` arrays:

- ``CuArray`` from CUDA.jl for NVIDIA GPUs
- ``ROCArray`` from AMDGPU.jl for AMD GPUs
- ``oneArray`` from oneAPI.jl for Intel GPUs
- ``MtlArray`` from Metal.jl for Apple GPUs

These array types closely resemble ``Base.Array`` which enables 
us to write generic code which works on both types.

The following code copies an array to the GPU and executes a simple operation on 
the GPU:

.. tabs::

   .. group-tab:: NVIDIA

      .. code-block:: julia
      
         using CUDA

         A_d = CuArray([1,2,3,4])
         A_d .+= 1

   .. group-tab:: AMD

      .. code-block:: julia
      
         using AMDGPU
      
         A_d = ROCArray([1,2,3,4])
         A_d .+= 1

   .. group-tab:: Intel

      .. code-block:: julia
      
         using oneAPI
      
         A_d = oneArray([1,2,3,4])
         A_d .+= 1

   .. group-tab:: Apple

      .. code-block:: julia
      
         using Metal
      
         A_d = MtlArray([1,2,3,4])
         A_d .+= 1

Moving an array back from the GPU to the CPU is simple:

.. code-block:: julia
   
   A = Array(A_d)


However, the overhead of copying data to the GPU makes such simple calculations 
very slow.

Let's have a look at a more realistic example: matrix multiplication. We 
create two random arrays, one on the CPU and one on the GPU, and compare the 
performance:

.. tabs::

   .. group-tab:: NVIDIA

      .. code-block:: julia
      
         using BenchmarkTools
         using CUDA

         A = rand(2^9, 2^9)
         A_d = CuArray(A)

         @btime A * A
         @btime A_d * A_d

   .. group-tab:: AMD

      .. code-block:: julia
      
         using BenchmarkTools
         using AMDGPU
      
         A = rand(2^9, 2^9)
         A_d = ROCArray(A)
      
         @btime A * A
         @btime A_d * A_d

   .. group-tab:: Intel

      .. code-block:: julia
      
         using BenchmarkTools
         using oneAPI
      
         A = rand(2^9, 2^9)
         A_d = oneArray(A)
      
         @btime A * A
         @btime A_d * A_d

   .. group-tab:: Apple

      .. code-block:: julia
      
         using BenchmarkTools
         using Metal         
      
         A = rand(2^9, 2^9)
         A_d = MtlArray(A)
      
         @btime A * A
         @btime A_d * A_d


There should be a considerable speedup!

.. challenge:: Effect of array size
   
   Does the size of the array affect how much the performance improves?

   .. solution::

      For example, on an A100 NVIDIA GPU:

      .. code-block:: julia

         using CUDA
         using BenchmarkTools

         A = rand(2^9, 2^9)
         A_d = CuArray(A)
         @btime A * A
         #  1.702 ms (2 allocations: 2.00 MiB)  
         @btime A_d * A_d
         #  13.000 μs (29 allocations: 592 bytes)  
         #  130 times faster
      
         A = rand(2^10, 2^10)
         A_d = CuArray(A)
         @btime A * A
         #  10.179 ms (2 allocations: 8.00 MiB)
         @btime A_d * A_d
         #  9.620 μs (29 allocations: 592 bytes)  
         #  1,114 times faster

         A = rand(2^11, 2^11)
         A_d = CuArray(A)
         @btime A * A
         #    72.950 ms (2 allocations: 32.00 MiB)
         @btime A_d * A_d
         #    10.861 μs (29 allocations: 592 bytes)
         # 6,717 times faster

         A = rand(2^12, 2^12)
         A_d = CuArray(A)
         @btime A * A
         #  454.483 ms (2 allocations: 128.00 MiB)
         @btime A * A
         #  12.480 μs (29 allocations: 592 bytes)
         # 36,416 times faster

         A = rand(2^13, 2^13)
         A_d = CuArray(A)
         @btime A * A
         #  3.237 s (2 allocations: 512.00 MiB)
         @btime A * A
         #  15.000 μs (32 allocations: 640 bytes)
         # 216,000 times faster!


Vendor libraries
^^^^^^^^^^^^^^^^

Support for using GPU vendor libraries from Julia is currently only supported on 
NVIDIA GPUs.
NVIDIA libraries contain precompiled kernels for common 
operations like matrix multiplication (`cuBLAS`), fast Fourier transforms 
(`cuFFT`), linear solvers (`cuSOLVER`), etc. These kernels are wrapped
in ``CUDA.jl`` and can be used directly with ``CuArrays``:

.. code-block:: julia

   # create a 100x100 Float32 random array and an uninitialized array
   A = CUDA.rand(2^9, 2^9)
   B = CuArray{Float32, 2}(undef, 2^9, 2^9)

   # use cuBLAS for matrix multiplication
   using LinearAlgebra
   mul!(B, A, A)

   # use cuSOLVER for QR factorization
   qr(A)

   # solve equation A*X == B
   A \ B

   # use cuFFT for FFT
   using CUDA.CUFFT
   fft(A)

.. challenge:: Convert from Base.Array or use GPU methods?

   What is the difference between creating a random array in the following two ways? 

   .. tabs:: 

      .. tab:: Converting from ``Base.Array``

         .. code-block:: julia
         
            A = rand(2^9, 2^9)
            A_d = CuArray(A)

      .. tab:: :meth:`rand` method from CUDA.jl

         .. code-block:: julia

            A_d = CUDA.rand(2^9, 2^9)

   .. solution:: 

      .. code-block:: julia

         A = rand(2^9, 2^9)
         A_d = CuArray(A)
         typeof(A_d)
         # CuArray{Float64, 2, CUDA.Mem.DeviceBuffer}

         B_d = CUDA.rand(2^9, 2^9)
         typeof(B_d)
         # CuArray{Float32, 2, CUDA.Mem.DeviceBuffer}

      The :meth:`rand` method defined in CUDA.jl creates 32-bit floating point numbers while 
      converting from a 64-bit float Base.Array to a CuArray retains it as Float64!

      GPUs normally perform significantly better for 32-bit floats.


Higher-order abstractions
^^^^^^^^^^^^^^^^^^^^^^^^^

A powerful way to program GPUs with arrays is through Julia's higher-order array 
abstractions. The simple element-wise addition we saw above, ``a .+= 1``, is 
an example of this, but more general constructs can be created with 
``broadcast``, ``map``, ``reduce``, ``accumulate`` etc:

.. tabs:: 

   .. tab:: broadcast

      .. code-block:: julia

         broadcast(A) do x
             x += 1
         end

   .. tab:: map

      .. code-block:: julia

         map(A) do x
             x + 1
         end

   .. tab:: reduce

      .. code-block:: julia

         reduce(+, A)

   .. tab:: accumulate

      .. code-block:: julia

         accumulate(+, A)



Writing your own kernels
------------------------

Not all algorithms can be made to work with the higher-level abstractions 
in ``CUDA.jl``. In such cases it's necessary to explicitly write our own GPU kernel.

Let's take a simple example, adding two vectors:

.. code-block:: julia

   function vadd!(c, a, b)
       for i in 1:length(a)
           @inbounds c[i] = a[i] + b[i]
       end
   end

   A = zeros(10) .+ 5.0
   B = ones(10)
   C = similar(B)
   vadd!(C, A, B)

We can already run this on the GPU with the ``@cuda`` macro, which 
will compile ``vadd!`` into a GPU kernel and launch it:

.. code-block:: julia

   A_d = CuArray(A)
   B_d = CuArray(B)
   C_d = similar(B_d)

   @cuda vadd!(C_d, A_d, B_d)

But the performance would be terrible because each thread on the GPU 
would be performing the same loop. So we have to remove the loop over all 
elements and instead use the special ``threadIdx`` and ``blockDim`` functions,  
analogous respectively to ``threadid`` and ``nthreads`` for multithreading.

.. figure:: img/MappingBlocksToSMs.png
   :align: center

We can split work between the GPU threads like this:   

.. tabs:: 

   .. group-tab:: NVIDIA

      .. code-block:: julia
      
         function vadd!(c, a, b)
             index = threadIdx().x   # linear indexing, so only use `x`
             @inbounds c[i] = a[i] + b[i]
             return
         end

         @cuda threads=length(A_d) vadd!(C_d, A_d, B_d)

   .. group-tab:: AMD

      .. code-block:: julia
      
         function vadd!(c, a, b)
             i = workitemIdx().x
             @inbounds c[i] = a[i] + b[i]
             return
         end
      
         @roc groupsize=length(A_d) vadd!(C_d, A_d, B_d)   

   .. group-tab:: Intel

      .. code-block:: julia
      
         function vadd!(c, a, b)
             i = get_global_id()
             @inbounds c[i] = a[i] + b[i]
             return
         end
      
         @oneapi items=length(A_d) vadd!(C_d, A_d, B_d)         

   .. group-tab:: Apple

      .. code-block:: julia
      
         function vadd!(c, a, b)
             i = thread_position_in_grid_1d()
             @inbounds c[i] = a[i] + b[i]
             return
         end
      
         @metal threads=length(A_d) vadd(C_d, A_d, B_d)

But we can parallelize even further. GPUs have a limited number of threads they 
can run on a single SM, but they also have multiple SMs. 
To take advantage of them all, we need to run a kernel with multiple blocks: 

.. tabs::

   .. group-tab:: NVIDIA

      .. code-block:: julia
      
         function vadd!(c, a, b)
             i = threadIdx().x + (blockIdx().x - 1) * blockDim().x        
             if i <= length(a)
                 @inbounds c[i] = a[i] + b[i]
             end
             return
         end

         # smallest integer larger than or equal to length(A_d)/threads
         numblocks = cld(length(A_d), 256)

         # run using 256 threads
         @cuda threads=size(A_d) blocks=numblocks vadd!(C_d, A_d, B_d)

   .. group-tab:: AMD

      .. code-block:: julia
      
         # WARNING: this is still untested on AMD GPUs
         function vadd!(c, a, b)
             i = workitemIdx().x + (workgroupIdx().x - 1) * workgroupDim().x * 
             if i <= length(a)
                 @inbounds c[i] = a[i] + b[i]
             end
             return
         end
      
         # smallest integer larger than or equal to length(A_d)/threads
         numblocks = cld(length(A_d), 256)
      
         # run using 256 threads
         @roc groupsize=256 blocks=numblocks vadd!(C_d, A_d, B_d)

   .. group-tab:: Intel

      WRITEME

   .. group-tab:: Apple

      .. code-block:: julia
      
         # WARNING: this is still untested on Apple GPUs
         function vadd!(c, a, b)
             i = thread_position_in_grid_1d()
             if i <= length(a)
                 @inbounds c[i] = a[i] + b[i]
             end
             return
         end
      
         # smallest integer larger than or equal to length(A_d)/threads
         numblocks = cld(length(A_d), 256)
      
         # run using 256 threads
         @metal threads=256 grid=numblocks vadd!(C_d, A_d, B_d)                  

We have been using 256 GPU threads, but this might not be optimal. The more 
threads we use the better is the performance, but the maximum number depends 
both on the GPU and the nature of the kernel. To optimize this choice, we can 
first create the kernel without launching it, query it for the number of threads 
supported, and then launch the compiled kernel:

.. tabs:: 

   .. group-tab:: NVIDIA 

      .. code-block:: julia
      
         # compile kernel
         kernel = @cuda launch=false vadd!(C_d, A_d, B_d)
         # extract configuration via occupancy API
         config = launch_configuration(kernel.fun)
         # number of threads should not exceed size of array
         threads = min(length(A), config.threads)
         # smallest integer larger than or equal to length(A)/threads
         blocks = cld(length(A), threads)

         # launch kernel with specific configuration
         kernel(C_d, A_d, B_d; threads, blocks)

   .. group-tab:: AMD 

      WRITEME

   .. group-tab:: Intel

      WRITEME

   .. group-tab:: Apple

      WRITEME




Profiling
---------

We can not use the regular Julia profilers to profile GPU code. However, 
we can use NVIDIA's `nvprof` profiler simply by starting Julia like this:

.. code-block:: bash

   nvprof --profile-from-start off julia

To then profile a particular function, we prefix by the ``CUDA.@profile`` macro:

.. code-block:: julia

   using CUDA
   A_d = CuArray(zeros(10) .+ 5.0)
   B_d = CuArray(ones(10))
   C_d = CuArray(similar(B_d))
   # first run it once to force compilation
   vadd!(C_d, A_d, B_d)  
   CUDA.@profile vadd!(C_d, A_d, B_d)

When we quit the REPL again, the profiler process will print information about 
the executed kernels and API calls.


Neural networks on the GPU
--------------------------

Flux has `inbuilt support for running on GPUs 
<https://fluxml.ai/Flux.jl/stable/gpu/>`__ and 
provides simple macros and convenience functions 
to transfer data and models to the GPU.
For example:

.. code-block:: julia

   (xtrain, xtest), (ytrain, ytest) = partition((X, Y), 0.8, shuffle=true, rng=123, multi=true)
   xtrain, xtest = Float32.(Array(xtrain)'), Float32.(Array(xtest)')    |> gpu
   ytrain = Flux.onehotbatch(ytrain, ["Adelie", "Gentoo", "Chinstrap"]) |> gpu
   ytest = Flux.onehotbatch(ytest, ["Adelie", "Gentoo", "Chinstrap"])   |> gpu
      
   n_features, n_classes, n_neurons = 4, 3, 10
   model = Chain(
           Dense(n_features, n_neurons),
           BatchNorm(n_neurons, relu),
           Dense(n_neurons, n_classes),
           softmax)  |> gpu






Exercises
---------

.. challenge:: Port :meth:`sqrt_sum` to GPU

   Try to GPU-port the ``sqrt_sum`` function we saw in an earlier 
   episode:

   .. code-block:: julia

      function sqrt_sum(A)
          s = zero(eltype(A))
          for i in eachindex(A)
              @inbounds s += sqrt(A[i])
          end
          return s
      end

   Use higher-order array abstractions to compute the sqrt-sum operation on a GPU!

   Hint: You can do it on a single line...

   .. solution::

      First the square root should be taken of each element of the array, 
      which we can do with ``map(sqrt,A)``. Next we perform a reduction with the ``+``
      operator. Combining these steps:
      
      .. code-block:: julia
      
         A = CuArray([1 2 3; 4 5 6; 7 8 9])
      
         reduce(+, map(sqrt,A))
      
      GPU porting complete!


.. challenge:: Does LinearAlgebra provide acceleration?

   Compare how long it takes to run a normal matrix multiplication and using the :meth:`mul!`
   method from LinearAlgebra. Is there a speedup from using :meth:`mul!`? 

   .. solution:: 

      .. code-block:: julia

         using CUDA, BenchmarkTools, LinearAlgebra

         A = CUDA.rand(2^5, 2^5)
         B = similar(A)
         @btime A*A;
         #  8.803 μs (16 allocations: 384 bytes)  
         @btime mul!(B, A, A);
         #  7.282 μs (12 allocations: 224 bytes)

         A = CUDA.rand(2^12, 2^12)
         B = similar(A)
         @btime A*A;
         #  12.760 μs (28 allocations: 576 bytes)
         @btime mul!(B, A, A)
         #  11.020 μs (24 allocations: 416 bytes)

      :meth:`LinearAlgebra.mul!` is around 15-20% faster!

.. challenge:: Compare broadcasting to kernel

   Consider the vector addition function from above:

   .. code-block:: julia

      function vadd!(c, a, b)
          for i in 1:length(a)
              @inbounds c[i] = a[i] + b[i]
          end
      end

   - Write a kernel (or use the one shown above) and benchmark it with a moderately large vector.
   - Then benchmark a broadcasted version of the vector addition. How does it compare to the kernel?


.. exercise:: Port Laplace function to GPU

   Write a kernel for the ``lap2d!`` function!

   Start with the regular version with ``@inbounds`` added:

   .. code-block:: julia

      function lap2d!(u, unew)
          M, N = size(u)
          for j in 2:N-1
              for i in 2:M-1
                  @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
              end 
          end
      end

   Now start implementing a GPU kernel version.

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

   5. Check correctness of your results! To test that the CPU and GPU versions 
      give (approximately) the same results, for example:

      .. code-block:: julia

         M = 4096
         N = 4096
         u = zeros(M, N);
         # set boundary conditions
         u[1,:] = u[end,:] = u[:,1] = u[:,end] .= 10.0;
         unew = copy(u);

         # copy to GPU and convert to Float32
         u_d, unew_d = CuArray(cu(u)), CuArray(cu(unew))

         for i in 1:1000
             lap2d!(u, unew)
             u = copy(unew)
         end

         for i in 1:1000
             @cuda threads=(nthreads, nthreads) blocks=(numblocks, numblocks) lap2d!(u_d, unew_d)
             u_d = copy(unew_d)
         end

         all(u .≈ Array(u_d))
   
   6. Perform some benchmarking of the CPU and GPU methods of the 
      function for arrays of various sizes and with different choices 
      of ``nthreads``. You will need to prefix the 
      kernel execution with the ``CUDA.@sync`` macro 
      to let the CPU wait for the GPU kernel to finish (otherwise you 
      would be measuring the time it takes to only launch the kernel):

   .. solution:: 

      This is one possible GPU kernel version of ``lap2d!``:

      .. code-block:: julia

         function lap2d!(u::CuArray, unew::CuArray)
             M, N = size(u)
             i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
             j = (blockIdx().y - 1) * blockDim().y + threadIdx().y
             #@cuprintln("threads $i $j") #only for debugging!
             if i > 1 && j > 1 && i < M && j < N
                 @inbounds unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
             end
             return nothing
         end

      To test it:

      .. code-block:: julia

         # set number of threads and blocks
         nthreads = 16
         numblocks = cld(nx, nthreads)

         for i in 1:1000
            # call cpu and gpu versions
            lap2d!(u, unew)
            u = copy(unew)

            @cuda threads=(nthreads, nthreads) blocks=(numblocks, numblocks) lap2d!(u_d, unew_d)
            u_d = copy(unew_d)
         end

         # element-wise comparison
         all(u .≈ Array(u_d))

      To benchmark:

      .. code-block:: julia

         using BenchmarkTools
         @btime lap2d!(u, unew)
         @btime CUDA.@sync @cuda threads=(nthreads, nthreads) blocks=(numblocks, numblocks) lap2d!(u_d, unew_d)


.. exercise:: Port a neural network to the GPU

   Take the neural network model that you trained in the  
   :ref:`Deep learning exercise <DLexercise>` and GPU-port it!

   Additional reading material that might help:

   - https://fluxml.ai/Flux.jl/stable/gpu/
   - https://fluxml.ai/tutorials/2020/09/15/deep-learning-flux.html

See also
--------

- https://juliagpu.org/
- https://cuda.juliagpu.org/stable/
- https://github.com/maleadt/juliacon21-gpu_workshop
- https://fluxml.ai/tutorials/2020/09/15/deep-learning-flux.html
