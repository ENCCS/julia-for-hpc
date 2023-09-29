Interfacing to C and Fortran
============================

.. questions::

   - How can we call a compiled C library from Julia?
   - 2

.. instructor-note::

   - 30 min teaching
   - 30 min exercises

Calling C library functions
---------------------------
Interfacing to C from Julia is relatively easy and overhead is same as calling a library function from C.
The interface uses Julia's `ccall` function.
`Calling C and Fortran <https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/>`_ on Julia documentation.

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
