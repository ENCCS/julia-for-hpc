GPU programming
===============

.. questions::

   - How can Julia be run on GPUs?

.. objectives::

   - Understand the difference between array and kernel GPU programming in Julia
   - Learn to use CuArrays in Julia
   - Get an idea on how to write GPU kernels in Julia



- Low-level (C kernel) based operations OpenCL.jl and CUDAdrv.jl which are respectively an OpenCL interface and a CUDA wrapper.
- Low-level (Julia Kernel) interfaces like CUDAnative.jl which is a Julia native CUDA implementation.
- High-level vendor-specific abstractions like CuArrays.jl and CLArrays.jl
- High-level libraries like ArrayFire.jl and GPUArrays.jl
- https://github.com/JuliaGPU/AMDGPU.jl
- https://github.com/JuliaGPU  
- https://github.com/JuliaGPU/ArrayFire.jl
- 

Julia has first-class support for GPU programming through the following 
packages that target GPUs from all three major vendors:

- `CUDA.jl <https://cuda.juliagpu.org/stable/>`_ for NVIDIA GPUs
- `AMDGPU.jl <https://amdgpu.juliagpu.org/stable/>`_ for AMD GPUs
- `oneAPI.jl <https://github.com/JuliaGPU/oneAPI.jl>`_ for Intel GPUs

``CUDA.jl`` is the most mature, ``AMDGPU.jl`` is somewhat behind but still 
ready for general use, while ``oneAPI.jl`` is still under heavy development.

NVIDIA GPUs still dominate the HPC accelerator market and we will focus here 
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
access to all of Julia and GPUs. Or one can use 
`Google Colab <https://colab.research.google.com/>`_ which requires a Google 
account and a manual Julia installation, but using simple NVIDIA GPUs is free.

A quick way to get started is to use this 
`Colab Julia notebook template 
<https://colab.research.google.com/github/ageron/julia_notebooks/blob/master/Julia_Colab_Notebook_Template.ipynb>`_.
If you have a Google account and agree to using it here, follow these steps:

- Open the notebook, save it to your Drive and optionally rename it
- Click on `Runtime` > `Change runtime type` and select GPU under `Hardware accelerator`
- Execute the first code cell (starting with ``%%shell``) to install Julia
- Reload the page
- Execute the second code cell (``versioninfo()``) with `SHIFT-ENTER` to see if it works
- Press "b" to create a new code cell below and start typing along.


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
  they are divided into "streaming multiprocessors". Some of these details are 
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

   a = CuArray([1,2,3,4])
   a += 1

However, the overhead of copying data to the GPU makes such simple calculations 
very slow.

Let's have a look at a more realistic example: matrix multiplication. We 
create two random arrays, one on the CPU and one on the GPU, and compare the 
performance:

.. code-block:: julia

   using BenchmarkTools

   A_cpu = rand(2^13, 2^13)
   A_gpu = CUDA.rand(2^13, 2^13)

   @btime A_cpu * A_cpu
   @btime A_gpu * A_gpu

There should be a dramatic speedup!

The NVIDIA libraries contain precompiled kernels for common 
operations like matrix multiplication (`cuBLAS`), fast Fourier transforms 
(`cuFFT`), linear solvers (`cuSOLVER`), etc. These kernels are wrapped
in ``CUDA.jl`` and can be used directly with ``CuArrays``:

.. code-block:: julia

   # create a 100x100 Float32 random array and an uninitialized array
   a = CUDA.rand(100, 100)
   b = CuArray{Float32, 2}(undef, 100, 100)

   # use cuBLAS for matrix multiplication
   using LinearAlgebra
   mul!(b, a, a)

   # use cuSOLVER for QR factorization
   qr(b)

   # use cuFFT for FFT
   using AbstractFFTs
   fft(b)

To move an array back from the GPU to the CPU, we can simply do ``Array(b)``.


Writing your own kernels
------------------------

Not all algorithms can be made to work with the higher-level abstractions 
in ``CUDA.jl``. In such cases it's necessary to write our own GPU kernel.
We will now do this for the ``evolve!`` function in ``HeatEquation.jl``.



.. exercise:: Write a kernel for HeatEquation.evolve! 

   step-by-step guide to write the kernel



Profiling
---------

We can not use the regular Julia profilers to profile GPU code. However, 
we can use NVIDIA's `nvprof` profiler simply by starting Julia like this:

.. code-block:: bash

   nvprof --profile-from-start off julia

To then profile a particular function, we prefix by the ``CUDA.@profile`` macro:

.. code-block:: julia

   # first run it once to force compilation
   my_function(y_d, x_d)  
   CUDA.@profile my_function(y_d, x_d)

When we quit the REPL again, the profiler process will print information about 
the executed kernels and API calls.


Neural networks on the GPU
--------------------------

- show how to leverage Flux's inbuilt GPU support for penguin training


See also
--------

- https://juliagpu.org/
