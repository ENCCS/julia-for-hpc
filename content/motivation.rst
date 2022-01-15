Motivation
==========

.. questions::

   - Why use Julia?
   - How good is the performance?

.. objectives::

   - Get inspired to try Julia


Why Julia?
----------

Julia has been designed to be both fast and dynamic.
In the words of its developers::

   We want a language that's open source, with a liberal license. We
   want the speed of C with the dynamism of Ruby. We want a language
   that's homoiconic, with true macros like Lisp, but with obvious,
   familiar mathematical notation like Matlab. We want something as
   usable for general programming as Python, as easy for statistics as
   R, as natural for string processing as Perl, as powerful for linear
   algebra as Matlab, as good at gluing programs together as the
   shell. Something that is dirt simple to learn, yet keeps the most
   serious hackers happy. We want it interactive and we want it
   compiled. (Did we mention it should be as fast as C?)

From `Why We Created Julia
<https://julialang.org/blog/2012/02/why-we-created-julia/>`_ by
Jeff Bezanson Stefan Karpinski Viral B. Shah Alan Edelman

Many researchers and programmers are drawn to Julia because of its
speed. Indeed, Julia is among the few languages in the exclusive
`petaflop club
<https://www.hpcwire.com/off-the-wire/julia-joins-petaflop-club/>`_
(along with C, C++ and Fortran).


.. figure:: img/benchmarks.svg
   :align: center

   Micro-benchmarks comparing Julia with many other languages. Taken
   from the `Julia benchmarks section
   <https://julialang.org/benchmarks/>`_
	   
To run code in any programming language, some sort of translation into
machine instructions (assembly code) needs to take place, but how
this translation takes place differs between programming languages.
*Interpreted* languages like Python and R translate instructions line
by line, while *compiled* languages like C/C++ and Fortran are
translated by a compiler prior to running the program. The benefits of
interpreted languages are that they are easier to read and write
because less information on aspects like types and array sizes needs
to be provided.  Programmer productivity is thus higher in interpreted
languages, but compiled languages can perform faster by orders of
magnitude because the compiler can perform optimizations during the
translation to assembly.

In many ways Julia looks like an
interpreted language.  and mostly behaves like one. But before each
function is executed it will compile it just in time.

Thus you get the flexibility of an interpreted language and the
execution speed of the compiled language at the cost of waiting a bit
longer for the first execution of any function.




Some advantages of Julia:

- Julia was designed from the beginning for high performance.
  Although Julia is dynamically typed and feels like a scripting language,
  Julia programs compile to efficient native code for multiple platforms
  via [LLVM](https://llvm.org/).


The two-language problem
------------------------


Benchmarks
----------


Composability
-------------


When not to use Julia
---------------------

- time to first plot (TTFP)

  - no running multiple short jobs etc

- large memory consumption

  - huge runtime because of precompilation
