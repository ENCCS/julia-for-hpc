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

   # regular matrix multiplication uses cuBLAS under the hood
   A * A

   # use LinearAlgebra for matrix multiplication
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

   function vadd!(C, A, B)
       for i in 1:length(A)
           @inbounds C[i] = A[i] + B[i]
       end
   end

   A = zeros(10) .+ 5.0
   B = ones(10)
   C = similar(B)
   vadd!(C, A, B)

We can already run this on the GPU with the ``@cuda`` macro, which 
will compile :meth:`vadd!` into a GPU kernel and launch it:

.. tabs:: 

   .. group-tab:: NVIDIA

      .. code-block:: julia

         A_d = CuArray(A)
         B_d = CuArray(B)
         C_d = similar(B_d)

         @cuda vadd!(C_d, A_d, B_d)

   .. group-tab:: AMD

      .. code-block:: julia

         A_d = ROCArray(A)
         B_d = ROCArray(B)
         C_d = similar(B_d)

         @roc vadd!(C_d, A_d, B_d)         

   .. group-tab:: Intel

      .. code-block:: julia

         A_d = oneArray(A)
         B_d = oneArray(B)
         C_d = similar(B_d)

         @oneapi vadd!(C_d, A_d, B_d)   

   .. group-tab:: Apple

      .. code-block:: julia

         A_d = MtlArray(Float32.(A))
         B_d = MtlArray(Float32.(B))
         C_d = similar(B_d)

         @metal vadd!(C_d, A_d, B_d)   


**But the performance would be terrible** because each thread on the GPU 
would be performing the same loop! So we have to remove the loop over all 
elements and instead use the special ``threadIdx`` and ``blockDim`` functions,  
analogous respectively to ``threadid`` and ``nthreads`` for multithreading.

.. figure:: img/MappingBlocksToSMs.png
   :align: center

We can split work between the GPU threads by using a special function which 
returns the index of the GPU thread which executes it (e.g. ``threadIdx().x`` for NVIDIA 
and ``workitemIdx().x`` for AMD):  

.. tabs:: 

   .. group-tab:: NVIDIA

      .. code-block:: julia
      
         function vadd!(C, A, B)
             index = threadIdx().x   # linear indexing, so only use `x`
             @inbounds C[index] = A[index] + B[index]
             return
         end

         A, B = CUDA.ones(2^9)*2, CUDA.ones(2^9)*3
         C = similar(A)

         nthreads = length(A)
         @cuda threads=nthreads vadd!(C, A, B)

         @assert all(Array(C) .== 5.0)

   .. group-tab:: AMD

      .. code-block:: julia

         # WARNING: this is still untested on AMD GPUs
         function vadd!(C, A, B)
             index = workitemIdx().x   # linear indexing, so only use `x`
             @inbounds C[index] = A[index] + B[index]
             return
         end

         A, B = ROCArray(ones(2^9)*2), ROCArray(ones(2^9)*3)
         C = similar(A)  

         groupsize = length(A)
         @roc groupsize=groupsize vadd!(C, A, B)   
         
         @assert all(Array(C) .== 5.0)

   .. group-tab:: Intel

      .. code-block:: julia

         # WARNING: this is still untested on Intel GPUs
         function vadd!(C, A, B)
             index = get_local_id()
             @inbounds C[index] = A[index] + B[index]
             return
         end

         A, B = oneArray(ones(2^9)*2), oneArray(ones(2^9)*3)
         C = similar(A)      

         items = length(A)
         @oneapi items=items vadd!(C, A, B) 

         @assert all(Array(C) .== 5.0)  

   .. group-tab:: Apple

      .. code-block:: julia
      
         function vadd!(C, A, B)
             index = thread_position_in_grid_1d()
             @inbounds C[index] = A[index] + B[index]
             return
         end
      
         A, B = MtlArray(ones(Float32, 2^9)*2), MtlArray(Float32, ones(2^9)*3)
         C = similar(A)

         nthreads = length(A)
         @metal threads=nthreads vadd!(C, A, B)

         @assert all(Array(C) .== 5.0)

However, this implementation will **not scale up** to arrays that are larger than the 
maximum number of threads in a block! We can find out how many threads are supported on the 
GPU we are using:

.. tabs::

   .. group-tab:: NVIDIA

      .. code-block:: julia

         CUDA.attribute(device(), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK)

   .. group-tab:: AMD

      .. code-block:: julia
   
         Int(AMDGPU.max_group_size(first(AMDGPU.isas(get_default_agent()))))

   .. group-tab:: Intel

      .. code-block:: julia

         oneL0.compute_properties(device()).maxTotalGroupSize

   .. group-tab:: Apple

      .. code-block:: julia

         WRITEME


Clearly, GPUs have a limited number of threads they can run on a single SM. 
To parallelise over multiple SMs we need to run a kernel with multiple blocks 
where we also take advantage of the :meth:`blockDim` and :meth:`blockIdx` functions 
(in the case of NVIDIA):

.. tabs::

   .. group-tab:: NVIDIA

      .. code-block:: julia
      
         function vadd!(C, A, B)
             i = threadIdx().x + (blockIdx().x - 1) * blockDim().x        
             if i <= length(A)
                 @inbounds C[i] = A[i] + B[i]
             end
             return
         end

         nthreads = 256
         # smallest integer larger than or equal to length(A)/threads
         numblocks = cld(length(A), nthreads)

         # run using 256 threads
         @cuda threads=nthreads blocks=numblocks vadd!(C, A, B)

         @assert all(Array(C) .== 5.0)

   .. group-tab:: AMD

      .. code-block:: julia
      
         # WARNING: this is still untested on AMD GPUs
         function vadd!(C, A, B)
             i = workitemIdx().x + (workgroupIdx().x - 1) * workgroupDim().x 
             if i <= length(a)
                 @inbounds C[i] = A[i] + B[i]
             end
             return
         end
      
         nthreads = 256
         # smallest integer larger than or equal to length(A)/threads
         numblocks = cld(length(A_d), nthreads)
      
         # run using 256 threads
         @roc groupsize=nthreads blocks=numblocks vadd!(C, A, B)

         @assert all(Array(C) .== 5.0)

   .. group-tab:: Intel

      .. code-block:: julia

         # WARNING: this is still untested on Intel GPUs
         function vadd!(C, A, B)
             i = get_global_id()
             if i <= length(a)
                 c[i] = a[i] + b[i]
             end
             return
         end
   
         nthreads = 256
         # smallest integer larger than or equal to length(A)/threads
         numgroups = cld(length(a),256)
   
         @oneapi items=nthreads groups=numgroups vadd!(c, a, b)

         @assert all(Array(C) .== 5.0)

   .. group-tab:: Apple

      .. code-block:: julia
      
         function vadd!(C, A, B)
             i = thread_position_in_grid_1d()
             if i <= length(A)
                 @inbounds C[i] = A[i] + B[i]
             end
             return
         end
      
         nthreads = 256
         # smallest integer larger than or equal to length(A)/threads
         numblocks = cld(length(A), nthreads)
      
         # run using 256 threads
         @metal threads=nthreads grid=numblocks vadd!(C, A, B)    

         @assert all(Array(C) .== 5.0)              

We have been using 256 GPU threads, but this might not be optimal. The more 
threads we use the better is the performance, but the maximum number depends 
both on the GPU and the nature of the kernel. 

To optimize the number of threads, we can 
first create the kernel without launching it, query it for the number of threads 
supported, and then launch the compiled kernel:

.. tabs:: 

   .. group-tab:: NVIDIA 

      .. code-block:: julia
      
         # compile kernel
         kernel = @cuda launch=false vadd!(C, A, B)
         # extract configuration via occupancy API
         config = launch_configuration(kernel.fun)
         # number of threads should not exceed size of array
         threads = min(length(A), config.threads)
         # smallest integer larger than or equal to length(A)/threads
         blocks = cld(length(A), threads)

         # launch kernel with specific configuration
         kernel(C, A, B; threads, blocks)

   .. group-tab:: AMD 

      WRITEME

   .. group-tab:: Intel

      WRITEME

   .. group-tab:: Apple

      WRITEME


.. callout:: Restrictions in kernel programming

   Within kernels, most of the Julia language is supported with the exception of functionality 
   that requires the Julia runtime library. This means one cannot allocate memory or perform 
   dynamic function calls, both of which are easy to do accidentally!


Debugging
---------

Many things can go wrong with GPU kernel programming and unfortunately error messages are not very 
useful because of how the GPU compiler works.

- @cuprintln
- @cushow
- @device_code_warntype

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

Conditional use
---------------

Using functionality from CUDA.jl (or another GPU package) will result in a run-time error 
on systems without CUDA and a GPU.
If GPU is required for a code to run, one can use an assertion:

.. code-block:: julia

   using CUDA
   @assert CUDA.functional(true)   

However, it can be desirable to be able to write code that works systems both with and without 
GPUs. If GPU is optional, you can write a function to copy arrays to the GPU if one is present:

.. code-block:: julia

   if CUDA.functional()
       to_gpu_or_not_to_gpu(x::AbstractArray) = CuArray(x)
   else
       to_gpu_or_not_to_gpu(x::AbstractArray) = x
   end

Some caveats apply and other solutions exist to address them as outlined in 
`the documentation <https://cuda.juliagpu.org/stable/installation/conditional/>`__.

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

   - Use higher-order array abstractions to compute the sqrt-sum operation on a GPU!
   - If you're interested in how the performance changes, benchmark the CPU and GPU versions with ``@btime``

   Hint: You can do it on a single line...

   .. solution::

      First the square root should be taken of each element of the array, 
      which we can do with ``map(sqrt,A)``. Next we perform a reduction with the ``+``
      operator. Combining these steps:
      
      .. code-block:: julia
      
         A = CuArray([1 2 3; 4 5 6; 7 8 9])
      
         reduce(+, map(sqrt,A))
      
      GPU porting complete!

      To benchmark:

      .. code-block:: julia

         A=ones(1024,1024);
         A_d = CuArray(A);

         # benchmark CPU function
         @btime sqrt_sum(A)
         #  2.664 ms (1 allocation: 16 bytes)

         # benchmark also broadcast operations on the CPU:
         @btime reduce(+, map(sqrt,A))
         #  2.930 ms (4 allocations: 8.00 MiB)
         #  Slightly slower than the sqrt_sum function call but much larger memory allocations!

         # benchmark GPU broadcast (result is from NVIDIA A100):
         @btime reduce(+, map(sqrt,A_d))
         #  59.719 μs (119 allocations: 6.36 KiB)

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

   .. solution:: 

      First define the kernel (for NVIDIA):

      .. code-block:: julia

         function vadd!(C, A, B)
             i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
             if i <= length(A)
                 @inbounds C[i] = A[i] + B[i]
             end
             return nothing
         end

      Define largish vectors:

      .. code-block:: julia

         A = CuArray(ones(2^20))
         B = CuArray(ones(2^20).*2)
         C = CuArray(similar(A))

      Set nthreads and numblocks and benchmark kernel:

      .. code-block:: julia

         @btime C .= A .+ B
         nthreads = 1024
         numblocks = cld(length(A), nthreads)

         @btime CUDA.@sync @cuda threads=nthreads blocks=numblocks vadd!(C, A, B)
         #  18.410 μs (33 allocations: 1.67 KiB)

      Finally compare to the higher-level array interface:

      .. code-block:: julia

         @btime C .= A .+ B
         #  5.014 μs (27 allocations: 1.66 KiB)

      The high-level abstraction is significantly faster!

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

   3. You also need to specify tuples 
      for the number of threads and blocks in the ``x`` and ``y`` dimensions, 
      e.g. ``threads = (32, 32)`` and similarly for ``blocks`` (using ``cld``).

      - **Note the hardware limitations**: the product of ``x`` and ``y`` threads cannot 
        exceed it!

   4. For debugging, you can print from inside a kernel using ``@cuprintln`` 
      (e.g. to print thread numbers). **But printing is slow so use small matrix sizes**! 
      It will only print during the first 
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

         function lap2d_gpu!(u, unew)
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
         nthreads = (16, 16)
         numblocks = (cld(size(u, 1), nthreads[1]), cld(size(u, 2), nthreads[2]))

         for i in 1:1000
            # call cpu and gpu versions
            lap2d!(u, unew)
            u = copy(unew)

            @cuda threads=nthreads blocks=numblocks lap2d_gpu!(u_d, unew_d)
            u_d = copy(unew_d)
         end

         # element-wise comparison
         all(u .≈ Array(u_d))

      To benchmark:

      .. code-block:: julia

         using BenchmarkTools
         @btime lap2d!(u, unew)
         @btime CUDA.@sync @cuda threads=(nthreads, nthreads) blocks=(numblocks, numblocks) lap2d_gpu!(u_d, unew_d)



See also
--------

- `JuliaGPU organisation <https://juliagpu.org/>`__
- `CUDA.jl documentation <https://cuda.juliagpu.org/stable/>`__
- `AMDGPU.jl documentation <https://amdgpu.juliagpu.org/stable/>`__
- `JuliaCon2021 GPU workshop <https://github.com/maleadt/juliacon21-gpu_workshop>`__
- `Advanced GPU programming tutorials <https://github.com/JuliaComputing/Training/tree/master/AdvancedGPU>`__