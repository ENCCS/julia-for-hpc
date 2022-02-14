GPU programming
===============

.. questions::

   - What are the high-level and low-level methods for GPU programming in Julia?
   - How do CuArrays work?
   - How are GPU kernels written?


Julia has first-class support for GPU programming through the following 
packages that target GPUs from all three major vendors:

- `CUDA.jl <https://cuda.juliagpu.org/stable/>`_ for NVIDIA GPUs
- `AMDGPU.jl <https://amdgpu.juliagpu.org/stable/>`_ for AMD GPUs
- `oneAPI.jl <https://github.com/JuliaGPU/oneAPI.jl>`_ for Intel GPUs

``CUDA.jl`` is the most mature, ``AMDGPU.jl`` is somewhat behind but still 
ready for general use, while ``oneAPI.jl`` is still under heavy development.

NVIDIA still dominates the HPC accelerator market and we will focus here 
on using ``CUDA.jl`` - the API of ``AMDGPU.jl`` is however completely analogous
and translation between the two is straightforward.

``CUDA.jl`` offers both user-friendly high-level abstractions that require 
very little programming effort and a lower level approach for writing kernels 
for fine-grained control.

Setup
-----

Installing ``CUDA.jl``:

.. code-block:: julia

   using Pkg
   Pkg.add("CUDA")

To use the Julia GPU stack, one needs to have NVIDIA drivers installed and
the CUDA toolkit to go with the drivers. Supercomputers with NVIDIA GPUs 
will already have both. For installation on other workstations one can follow the 
`instructions from NVIDIA <https://www.nvidia.com/Download/index.aspx>`_ to 
install the drivers, and let Julia automatically install the correct version 
of the toolkit upon the first import: ``using CUDA``.

Access to GPUs in the cloud
---------------------------

To fully experience the walkthrough in this episode we need to have access 
to an NVIDIA GPU and the necessary software stack. Access to a HPC system with 
GPUs and a Julia installation will work. Another option is to use 
`JuliaHub <https://juliahub.com/lp/>`_, a commercial cloud platform from 
`Julia Computing <https://juliacomputing.com/>`_ with 
access to Julia's ecosystem of packages and GPU hardware. Or one can use 
`Google Colab <https://colab.research.google.com/>`_ which requires a Google 
account and a manual Julia installation, but using simple NVIDIA GPUs is free.

Google Colab does not support Julia, but a
`helpful person on the internet <https://github.com/Dsantra92/Julia-on-Colab>`__ 
has created a Colab notebook that can be reused for Julia computing on Colab.
If you have a Google account and agree to using it here, follow the link above 
and go through the instructions found in the colab notebook.


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

GPU programming with Julia can be as simple as using ``CuArray``
(``ROCArray`` for AMD) instead of regular ``Base.Array`` arrays. 
The ``CuArray`` type closely resembles ``Base.Array`` which enables 
us to write generic code which works on both types.

The following code copies an array to the GPU and executes a simple operation on 
the GPU:

.. code-block:: julia

   using CUDA

   A_d = CuArray([1,2,3,4])
   A_d .+= 1

Moving an array back from the GPU to the CPU is simple:

.. code-block:: julia
   
   A = Array(A_d)


However, the overhead of copying data to the GPU makes such simple calculations 
very slow.

Let's have a look at a more realistic example: matrix multiplication. We 
create two random arrays, one on the CPU and one on the GPU, and compare the 
performance:

.. code-block:: julia

   using BenchmarkTools

   A = rand(2^13, 2^13)
   A_d = CUDA.rand(2^13, 2^13)

   @btime A * A
   @btime A_d * A_d

There should be a dramatic speedup!

Vendor libraries
^^^^^^^^^^^^^^^^

The NVIDIA libraries contain precompiled kernels for common 
operations like matrix multiplication (`cuBLAS`), fast Fourier transforms 
(`cuFFT`), linear solvers (`cuSOLVER`), etc. These kernels are wrapped
in ``CUDA.jl`` and can be used directly with ``CuArrays``:

.. code-block:: julia

   # create a 100x100 Float32 random array and an uninitialized array
   A = CUDA.rand(100, 100)
   B = CuArray{Float32, 2}(undef, 100, 100)

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

Let's see if we can GPU-port the ``sqrt_sum`` function we saw in an earlier 
episode using these methods.

.. code-block:: julia

   function sqrt_sum(A)
       s = zero(eltype(A))
       for i in eachindex(A)
           @inbounds s += sqrt(A[i])
       end
       return s
   end

First the square root should be taken of each element of the array, 
which we can do with ``map(sqrt,A)``. Next we perform a reduction with the ``+``
operator. Combining these steps:

.. code-block:: julia

   A = CuArray([1 2 3; 4 5 6; 7 8 9])

   reduce(+, map(sqrt,A))

GPU porting complete!


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

.. code-block:: julia

   function vadd!(c, a, b)
       index = threadIdx().x   # linear indexing, so only use `x`
       stride = blockDim().x   
       for i = index:stride:length(a)
           c[i] = a[i] + b[i]
       end
       return
   end

   # run using 256 threads
   @cuda threads=256 vadd!(C_d, A_d, B_d)

But we can parallelize even further. GPUs have a limited number of threads they 
can run on a single SM, but they also have multiple SMs. 
To take advantage of them all, we need to run a kernel with multiple blocks: 

.. code-block:: julia

   function vadd!(c, a, b)
       i = threadIdx().x + (blockIdx().x - 1) * blockDim().x        
       if i <= length(a)
           c[i] = a[i] + b[i]
       end
       return
   end

   # smallest integer larger than or equal to length(A_d)/threads
   numblocks = cld(length(A_d), 256)

   # run using 256 threads
   @cuda threads=256 blocks=numblocks vadd!(C_d, A_d, B_d)


We have been using 256 GPU threads, but this might not be optimal. The more 
threads we use the better is the performance, but the maximum number depends 
both on the GPU and the nature of the kernel. To optimize this choice, we can 
first create the kernel without launching it, query it for the number of threads 
supported, and then launch the compiled kernel:

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


See also
--------

- https://juliagpu.org/
- https://cuda.juliagpu.org/stable/
- https://github.com/maleadt/juliacon21-gpu_workshop
