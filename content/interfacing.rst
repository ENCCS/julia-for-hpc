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
Interfacing to C from Julia is relatively easy and overhead is same as calling a library function from C.
The interface uses Julia's `ccall` function.

The following example is adapted from `Calling C from Julia <https://craftofcoding.wordpress.com/2017/02/08/calling-c-from-julia-i-simple-arrays/>`_ by `The Craft of Coding`.
Let's conside the following C function which computes the mean from an array of integer values.
We will name the file as :code:`mean.c`.

.. code-block:: c

   double vectorMean(int *arr, int n)
   {
       int i, sum=0;
       double mean;
       for (i=0; i<n; i=i+1)
           sum = sum + arr[i];
       mean = sum / (double)n;
       return mean;
   }

Next, we need to compile the code in :code:`mean.c` into a shared object named as :code:`mean.so`.
We use the GNU C compiler (GCC) with the flags :code:`-Wall` to enable warnings, :code:`-fpic` to make the shared object relocatable and :code:`-shared` to produce a shared object.
A collection of shared objects is usually referred to as a library.

.. code-block:: bash

   gcc -Wall -fpic -shared -o mean.so mean.c

Now, we can call the shared object from Julia using the :code:`ccall` function as
follows:

.. code-block:: julia

   # Define the array in Julia
   arr = [1,2,3,4,5]

   # Length of the array
   n = length(arr_c)

   # Convert the inputs to native C integer types
   arr_c = collect(Cint, arr)
   n_c = convert(Cint, n)

   # Call the shared library
   ccall((:vectorMean, "./mean.so"), Cdouble, (Ptr{Cint}, Cint), arr_c, n_c)


Interfacing Julia with Fortran
------------------------------


Interfacing Julia with other languages
--------------------------------------


See also
--------


.. keypoints::

   - One
