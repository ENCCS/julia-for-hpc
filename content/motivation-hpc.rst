Motivation
==========

.. questions::

   - What is high-performance computing?
   - Why is Julia suitable for high-performance computing?

.. instructor-note::

   - 15 min teaching


High-performance computing (HPC) uses large computing resources to solve computationally demanding or data-intensive problems.
Such problems often arise in scientific simulation and modeling, data analysis, and machine learning.
Most HPC systems are computer clusters, a computer network with many colocated computers connected via a high-speed network.
Contemporary HPC clusters derive the computational capacity from parallel processing on Central Processing Units (CPUs) for general tasks and accelerators, such as Graphics Processing Units (GPUs), for specialized tasks.
We consider a programming language a high-performance language if it can efficiently use the features of HPC clusters.

Traditional languages for programming HPC computers are C, C++, and Fortran.
Their constructs map efficiently to machine instructions, which is necessary for creating programs that use hardware efficiently.
They are statically compiled and require manual memory management.
Their main drawbacks are that they can be slow, tedious, and error-prone to write, limiting productivity and making fast experimentation difficult.
Furthermore, depending on the software engineering practices, the software written in traditional languages can be challenging to build and understand, and porting software from one cluster to another can be complicated.
On the other hand, dynamic, interpreted languages such as Python and R cannot produce efficient machine code.
Therefore, they act as an interface to programs written in the traditional compiled languages in HPC systems.

Julia is an open-source software with a permissive MIT license that offers a modern alternative to scientific and high-performance computing. [#c1]_
Julia is `fast, composable and practical <https://enccs.github.io/julia-intro/motivation/>`_ with natural syntax for scientific computing and a memory-managed runtime.
NERSC has demonstrated that Julia can run at large scale at petaflop speeds, a feat previously possible only by C, C++, and Fortran. [#c5]_
Running Julia at scale is possible because Julia can generate efficient machine code for multiple architectures via the LLVM compiler and has parallel computing capabilities, including SIMD, multithreading, multiprocessing, and packages for using MPI and various GPUs. [#c2]_ [#c3]_
The performance of Julia is comparable to other parallel programming frameworks [#c4]_.
Furthermore, Julia can directly interface with shared C and Fortran libraries with the same overhead as calling them natively.
There are also packages for interfacing with other languages, such as Python, R, and C++.
We can use Julia to call external programs directly, which means we can use it as an efficient, robust, parallelizable glue language instead of shell scripting.

Julia supports four main types of parallel programming:

- **Asynchronous tasks or coroutines**:
  Tasks allow suspending and resuming  computations for I/O, event handling and similar patterns.
  Not really HPC and outside the scope of the this lesson.

- **Multi-threading**:
  Provides the ability to schedule Tasks simultaneously on more than one thread or CPU core, sharing memory.
  The easiest way to parallelize on shared-memory systems.
  Contained in the ``Threads`` standard library.

- **Distributed computing**:
  Runs multiple Julia processes with separate memory spaces on the same or multiple computers.
  Useful high-level constructs are implemented in the standard library ``Distributed`` module.
  For those that like MPI there is `MPI.jl <https://github.com/JuliaParallel/MPI.jl>`_.

- **GPU computing**:
  Ports computation to a graphical processing unit (GPU) via either high-level or low-level programming. 

----

.. [#c1] `Bridging HPC Communities through the Julia Programming Language <https://arxiv.org/abs/2211.02740>`_
.. [#c5] `Julia Joins Petaflop Club <https://www.hpcwire.com/off-the-wire/julia-joins-petaflop-club/>`_
.. [#c2] `MPI.jl: Julia bindings for the Message Passing Interface <https://proceedings.juliacon.org/papers/10.21105/jcon.00068>`_
.. [#c3] `High-level GPU programming in Julia <https://arxiv.org/abs/1604.03410>`_
.. [#c4] `Comparing Julia to Performance Portable Parallel Programming Models for HPC <https://ieeexplore.ieee.org/abstract/document/9652798>`_
