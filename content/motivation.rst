Motivation
==========

.. questions::

   - Why use Julia?
   - How performant is Julia?

.. objectives::

   - Get inspired to try Julia!


Why Julia?
----------

Julia has been designed to be both fast and dynamic.
In the words of its developers:

.. callout:: The vision

   *We want a language that's open source, with a liberal license. We
   want the speed of C with the dynamism of Ruby. We want a language
   that's homoiconic, with true macros like Lisp, but with obvious,
   familiar mathematical notation like Matlab. We want something as
   usable for general programming as Python, as easy for statistics as
   R, as natural for string processing as Perl, as powerful for linear
   algebra as Matlab, as good at gluing programs together as the
   shell. Something that is dirt simple to learn, yet keeps the most
   serious hackers happy. We want it interactive and we want it
   compiled. (Did we mention it should be as fast as C?)*

From `Why We Created Julia
<https://julialang.org/blog/2012/02/why-we-created-julia/>`_ by
Jeff Bezanson Stefan Karpinski Viral B. Shah Alan Edelman

Speed
^^^^^

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


The two-language problem
------------------------

.. exercise:: Combining languages

   Have you ever written and prototyped code in a high-level language and then 
   found it necessary to rewrite it or port to a different language for performance?

To run code in any programming language, some sort of translation into
machine instructions (assembly code) needs to take place, but how
this translation takes place differs between programming languages:

- *Interpreted* languages like Python and R translate instructions line
  by line.
- *Compiled* languages like C/C++ and Fortran are translated by a compiler 
  prior to running the program. 

The benefits of
interpreted languages are that they are easier to read and write
because less information on aspects like types and array sizes needs
to be provided.  **Programmer productivity** is thus higher in interpreted
languages, but compiled languages can perform **faster by orders of
magnitude** because the compiler can perform optimizations during the
translation to assembly.

In many ways **Julia looks like an
interpreted language**, and mostly behaves like one. But before each
function is executed it will compile it "just in time". More on that later.
Thus you get the flexibility of an interpreted language and the
execution speed of the compiled language at the cost of waiting a bit
longer for the first execution of any function.



Composability
-------------

Julia is highly `commposable <https://en.wikipedia.org/wiki/Composability>`__,
but what does that mean in practice?


When not to use Julia
---------------------

- time to first plot (TTFP)

  - no running multiple short jobs etc

- large memory consumption

  - huge runtime because of precompilation




What you will learn
-------------------

We will be focusing on higher-level performance considerations and parallelization 
approaces and not dig deep into lower-level aspects. There is always a tradeoff; 
to squeeze as much performance out of a code as possible one often needs to drop 
down to lower levels of memory management, interprocess communication etc.
But using higher-level approaches can lead to significant performance gain 
for many scientific problems which makes it a good (initial) time investment.



What you will not learn
-----------------------

- We will only be scratching the surface of the topics we do cover. Make 
  sure to go through the recommended additional reading at the end of each 
  episode if you want to learn more.
- How to interoperate with other languages. Calling code from Python, R, 
  C/C++ and Fortran is relatively straightforward but is outside the current scope.
- Julia has mature packages for scientific computing in many different scientific disciplines.
  An overview of the package ecosystem will be provided in :doc:`scientific_computing` but we 
  will not go into any details except for an appetizer on data science and machine learning.

After the workshop
------------------

- https://julialang.org/learning/
