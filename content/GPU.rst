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

  


CuArrays
--------


Writing your own kernels
------------------------



Neural networks on the GPU
--------------------------

- show how to leverage Flux's inbuilt GPU support for penguin training


See also
--------

- https://juliagpu.org/
