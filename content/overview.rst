Special features of Julia
=========================

.. questions::

   - What sets Julia apart from other languages?
   - How can a dynamically-typed language still be based on an elaborate type system?
   - What is multiple dispatch?

.. objectives::

   - Get an overview of Julia's type system and how it underpins the language
   - Understand why Julia is fast
   - Learn about multiple dispatch and how it's used
   - Know how Julia code can be introspected to improve performance
   - Know how scoping in Julia works

Types
-----

Julia is a dynamically typed language and does not require the
declaration of types. Counterintuitively, it is notetheless due to its
sophisticated type system that Julia is a high-performance language!
This is because types are *inferred* and used when Julia is run.

Julia's type system is also what enables “multiple dispatch” on function
argument types - this is what sets the language apart from most other
languages and makes it fast when combined with JIT and LLVM.

Since types play a fundamental role in Julia’s design it’s important to
have a mental model of Julia’s type system. There are two basic kinds of
types in Julia: - **Abstract types**: Define the kind of a thing,
i.e. represent sets of related types. - **Concrete types**: Describe
data structures, i.e. concrete implementations that can be used for
variables.

.. code-block:: julia

    typeof(1)


.. code-block:: julia

    typeof(1.0)


.. code-block:: julia

    supertypes(Float64)



.. code-block:: julia

    subtypes(Real)



Types in Julia form a “type tree”, in which the leaves are concrete
types.

.. figure:: img/Type-hierarchy-for-julia-numbers.png

Derived types
~~~~~~~~~~~~~

New types, i.e. new kinds of data structures, can be defined with the
``struct`` keyword, or ``mutable struct`` if you want to be able to
change the values of fields in the new data structure. To take a
classical example:

.. code-block:: julia

    struct Point2D
        x
        y
    end

A new ``Point`` object can be defined by

.. code-block:: julia

    p = Point(1.1, 2.2)


and its elements accessed by

.. code-block:: julia

    p.x


Parametric types
~~~~~~~~~~~~~~~~

A useful feature of Julia’s type system are *type parameters*: the
ability to use parameters when defining types. For example:

.. code-block:: julia

    struct Point{T}
        x::T
        y::T
    end

We can now create ``Point`` variables with explicitly different types:

.. code-block:: julia

    x1 = Point(1,2)



.. code-block:: julia

    x2 = Point(1.0, 2.0)


Type stability
^^^^^^^^^^^^^^


Functions and methods
---------------------

Functions form the backbone of any Julia code. Their syntax is
straighforward:

.. code-block:: julia

    function sumsquare(x, y)
        return x^2 + y^2
    end


.. code-block:: julia

    sumsquare(2.72, 3.83)



.. code-block:: julia

    sumsquare(2, 3)



Note that our ``sumsquare`` function has no type annotations. The base
library of Julia has different implementations of ``+`` and ``^`` which
will be chosen (“dispatched”) at runtime according to the argument
types.

In most cases it’s fine to omit types. The main reasons for adding type
annotate are: 

- Improve readability 
- Catch errors 
- Take advantage of **multiple dispatch** by implementing different meethods to the same function.

Let’s see how we can add a new **method** to our ``sumsquare``
**function** and dispatch on our ``Point`` type.

.. code-block:: julia

    function sumsquare(p1::Point, p2::Point)
        return Point(p1.x^2 + p2.x^2, p1.y^2 + p2.y^2)
    end


Note the output, ``sumsquare`` is now a “generic function with 2
methods”.

.. code-block:: julia

    p1 = Point(1, 2)
    p2 = Point(3, 4)
    sumsquare(p1, p2)


.. code-block:: julia

    cp1 = Point(1+1im, 2+2im)
    cp2 = Point(3+3im, 4+4im)
    sumsquare(cp1, cp2)



We can list all methods defined for a function:

.. code-block:: julia

    methods(sumsquare)


.. callout:: Methods and functions

   -  A **function** describing the “what” can have multiple **methods**
      describing the “how”
   -  This differs from object-oriented languages in which objects (not
      functions) have methods
   -  **Multiple dispatch** is when Julia selects the most specialized
      method to run based on the types of all input arguments
   -  **Best practice**: constrain argument types to the widest possible
      level, and introduce constraints only if you know other argument
      types will fail. \``\`


WRITEME: mention speed for derived datatypes

Just in time compilation
~~~~~~~~~~~~~~~~~~~~~~~~

Julia relies on just-in-time (JIT) compilation and the
`LLVM <https://llvm.org/>`__ compiler infrastructure to compile its
source code. The Julia runtime code generator produces an LLVM
**Intermediate Representation** (IR) which the LLMV compiler then
converts to machine code using sophisticated optimization technology.

.. callout:: Just-in-time compilation vs interpreted and compiled languages

   -  Interpreted languages rely on a runtime which directly executes the
      source code.
   -  Compiled languages rely on ahead-of-time compilation where source
      code is converted to an executable before execution.
   -  Just-in-time compilation is when code is compiled to machine code at
      runtime. 

.. figure:: img/compiler_components.png
   :align: center
   :scale: 50%

   Adapted from `"High-level GPU programming in Julia" <https://arxiv.org/pdf/1604.03410.pdf>`_ 
   by Tim Besard, Pieter Verstraete and Bjorn De Sutter .



To see the code that’s generated by the JIT compiler, we can use a
*macro*:

.. code-block:: julia

    @code_llvm(sumsquare(p1, p2))

.. code-block:: julia

    @code_lowered(sumsquare(p1, p2))





.. code-block:: julia

    @code_typed(sumsquare(1.2, 2.3))


.. code-block:: julia

    @code_warntype(sumsquare(1.2, 2.3))




Code introspection
------------------

-  @code_lowered
-  @code_typed & @code_warntype
-  @code_llvm
-  @code_native

WRITEME: use pi-estimation example and run introspection on different function
definitions


Metaprogramming
---------------

Unicode support
---------------




See also
--------

- https://slides.com/valentinchuravy/julia-parallelism#/1/1
- Lin, Wei-Chen, and Simon McIntosh-Smith. 
  `Comparing Julia to Performance Portable Parallel Programming Models for HPC. <https://ieeexplore.ieee.org/abstract/document/9652798>`_, 
  2021 International Workshop on Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems (PMBS). IEEE, 2021.

