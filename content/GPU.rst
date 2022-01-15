GPU programming
===============

.. questions::

   - How can Julia be run on GPUs?

.. objectives::

   - Understand the difference between array and kernel GPU programming in Julia
   - Learn to use CuArrays in Julia
   - Get an idea on how to write GPU kernels in Julia


Section
-------

- Low-level (C kernel) based operations OpenCL.jl and CUDAdrv.jl which are respectively an OpenCL interface and a CUDA wrapper.
- Low-level (Julia Kernel) interfaces like CUDAnative.jl which is a Julia native CUDA implementation.
- High-level vendor-specific abstractions like CuArrays.jl and CLArrays.jl
- High-level libraries like ArrayFire.jl and GPUArrays.jl
- https://github.com/JuliaGPU/AMDGPU.jl
- https://github.com/JuliaGPU  
- https://github.com/JuliaGPU/ArrayFire.jl
- 
See also
--------

- https://juliagpu.org/
