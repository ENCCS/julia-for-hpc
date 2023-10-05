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

Traditional languages for programming HPC computers are C, C++, and Fortran.
Their constructs map efficiently to machine instructions, which is necessary for creating programs that use hardware efficiently.
They are statically compiled languages with manual memory management.
Their main drawbacks are that they can be tedious and error-prone to write, and the programmer is responsible for memory management.
Furthermore, they lack uniform dependency management conventions.

On the other hand, dynamic, interpreted languages like Python and R offer easier syntax for writing programs that cannot produce efficient machines.
Thus, they interface with programs written in the traditional compiled languages.

Julia language offers ... [#c1]_

- Parallel computing capabilities
- Julia has packages for using MPI [#c2]_ and GPUs [#c3]_.
- Ability to generate efficient machine code for many architectures
- Memory managed runtime
- Open source, MIT license

----

.. [#c1] Bridging HPC Communities through the Julia Programming Language (https://arxiv.org/abs/2211.02740)
.. [#c2] MPI.jl: Julia bindings for the Message Passing Interface (https://proceedings.juliacon.org/papers/10.21105/jcon.00068)
.. [#c3] High-level GPU programming in Julia
.. [#c4] Comparing Julia to Performance Portable Parallel Programming Models for HPC
