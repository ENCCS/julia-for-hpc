Interfacing to C and Fortran
============================

.. questions::

   - 1
   - 2

.. instructor-note::

   - 20 min teaching
   - 20 min exercises


Why Julia interfacing with other languages?
-------------------------------------------

One of the most significant advantages of Julia is its speed. As we have shown in the Episode
`Motivation <https://enccs.github.io/julia-for-hpc/motivation/#speed>`_, Julia is fast out-of-box
without the necessity to do any additional steps. As such, Julia solves the so-called **two-Language problem**.

Since Julia is fast enough, most of the libraries are written in pure Julia, and there is no need to use C or Fortran for performance.
However, there are many high-quality, mature libraries for numerical computing already written in C and Fortran.
It would be resource-wasting if it is not possible to use them in Julia.

In fact, to allow easy use of existing C and Fortran code, Julia has native support for calling C and Fortran functions.
Julia has a **no boilerplate** philosophy: *functions can be called directly from Julia without any glue code generation
or compilation – even from the interactive prompt*.

This is accomplished by making an appropriate call with the ``ccall`` syntax, which looks like an ordinary function call.
Moreover, it is possible to pass Julia functions to native C functions that accept function pointer arguments.
In this episode, we will show one example of the interaction between Julia and C.
Extensive description of all provided functionality can be found in the `official manual <https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/>`_.


Interfacing Julia with C
------------------------


Interfacing Julia with Fortran
------------------------------


Interfacing Julia with other languages
--------------------------------------


See also
--------


.. keypoints::

   - One
