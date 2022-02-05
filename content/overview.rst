Special features of Julia
=========================

.. questions::

   - What are the main characteristics of Julia?
   - How can a language be both dynamically and statically typed?
   - What is multiple dispatch?

.. objectives::

   - Get an overview of Julia's type system and how it underpins the language
   - Understand why Julia is fast
   - Learn about multiple dispatch and how it's used
   - Know how Julia code can be introspected to improve performance

Types
-----

Julia is a dynamically typed language and does not require the
declaration of types. Counterintuitively, it is notetheless due to its
sophisticated type system that Julia is a high-performance language!
This is because types are *inferred* and used at runtime.

Julia's type system is also what enables 
`multiple dispatch <https://en.wikipedia.org/wiki/Multiple_dispatch>`__ 
on function argument types - this is what sets the language apart from most other
languages and makes it fast when combined with just-in-time (JIT) compilation 
using the LLVM compiler toolchain.

Since types play a fundamental role in Julia's design it's important to
have a mental model of Julia's type system. There are two basic kinds of
types in Julia: 

- **Abstract types**: Define the kind of a thing, i.e. represent sets of related types. 
- **Concrete types**: Describe data structures, i.e. concrete implementations that 
  can be used for variables.

.. code-block:: julia

    typeof(1)  # returns Int64
  
    typeof(1.0) # returns Float64

    typeof(1.0+2.0im) # returns ComplexF64
  
    supertypes(Float64) # returns (Float64, AbstractFloat, Real, Number, Any)

    subtypes(Real) # returns (AbstractFloat, AbstractIrrational, Integer, Rational)


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

    struct Point
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

    p1 = Point(1,2)
    # Point{Int64}(1, 2)

    p2 = Point(1.0, 2.0)
    # Point{Float64}(1.0, 2.0)



Functions and methods
---------------------

Functions form the backbone of any Julia code. Their syntax is
similar to other languages:

.. code-block:: julia

    function sumsquare(x, y)
        return x^2 + y^2
    end

For short functions such as this one, it's also possible to use this 
short-hand form:

.. code-block:: julia

   sumsquare(x,y) = x^2 + y^2

We can pass in arguments with all kinds of types:

.. code-block:: julia

   # Int64
   sumsquare(2, 3)
   # Float64
   sumsquare(2.72, 3.83)
   # Complex{Int64}
   sumsquare(1+2im, 2-1im)
   # Complex{Float64}
   sumsquare(1.2+2.3im, 2.1-1.5im)

Note that our ``sumsquare`` function has no type annotations. The base
library of Julia has different implementations of ``+`` and ``^`` which
will be chosen ("dispatched") at runtime according to the argument
types.

In most cases it's fine to omit types. The main reasons for adding type
annotate are: 

- Improve readability 
- Catch errors 
- Take advantage of **multiple dispatch** by implementing different 
  methods to the same function.

.. exercise:: Extending sumsquare

   What happens if you try to call the ``sumsquare`` function with two 
   input arguments of type ``Point``? Try it and try to make sense of the output.

   Now add a new **method** to our ``sumsquare`` **function** for the 
   ``Point`` type. 

   - We decide that the summed square of two points 
     is ``p1.x^2 + p2.x^2, p1.y^2 + p2.y^2``
   - You will need to modify both the function signature and body.   

   .. solution::

      Calling the original (un-extended) ``sumsquare`` function with two 
      ``Point`` variables returns the error 
      ``MethodError: no method matching ^(::Point{Int64}, ::Int64)``. 
      This means that Julia doesn't know how to take powers of this type!

      One way to implement the new ``sumsquare`` method for ``Point`` types is:

      .. code-block:: julia

         function sumsquare(p1::Point, p2::Point)
            return Point(p1.x^2 + p2.x^2, p1.y^2 + p2.y^2)
         end


      Note the output, ``sumsquare`` is now a "generic function with 2
      methods".

If we solved the exercise, we should now be able to call ``sumsquare``
with ``Point`` types. The element types can still be anything!

.. code-block:: julia

    p1 = Point(1, 2)
    p2 = Point(3, 4)
    sumsquare(p1, p2)
    # returns Point{Int64}(10, 20)

.. code-block:: julia

    cp1 = Point(1+1im, 2+2im)
    cp2 = Point(3+3im, 4+4im)
    sumsquare(cp1, cp2)
    # returns Point{Complex{Int64}}(0 + 20im, 0 + 40im)


We can list all methods defined for a function:

.. code-block:: julia

    methods(sumsquare)

    # 2 methods for generic function "sumsquare":
    # [1] sumsquare(p1::Point, p2::Point) in Main at REPL[35]:1
    # [2] sumsquare(x, y) in Main at REPL[14]:1

.. callout:: Methods and functions

   -  A **function** describing the "what" can have multiple **methods**
      describing the "how"
   -  This differs from object-oriented languages in which objects (not
      functions) have methods
   -  **Multiple dispatch** is when Julia selects the most specialized
      method to run based on the types of all input arguments
   -  **Best practice**: constrain argument types to the widest possible
      level, and introduce constraints only if you know other argument
      types will fail. 


Type stability
~~~~~~~~~~~~~~

To compile specialized versions of a function for each 
argument type the compiler needs to be able to infer all the argument 
and return types of that function. This is called type stability, but 
unfortunately it's possible to write type-unstable functions:

.. code-block:: julia

   # type-unstable function
   function relu_unstable(x)
       if x < 0
           return 0
       else 
           return x
       end
   end           

We can pass both integer and floating point arguments to this function, 
but if we pass in a negative float it will return an integer 0, while 
positive floats return a float. This can have a dramatically negative effect 
on performance because the compiler will not be able to specialize!

The solution is to use an inbuilt ``zero`` function to return a zero of the same 
type as the input argument, so that inputting integers always gives 
integer output and likewise for floats:

.. code-block:: julia

   # type-stable function
   function relu_stable(x)
       if x < 0
           return zero(0)
       else 
           return x
       end
   end           

Other convenience functions exist for working with arrays, including: 

- ``eltype`` to determine the type of the array elements
- ``similar`` to create an uninitialized mutable array with 
  the given element type and size.


Just in time compilation
------------------------

Julia was designed from the beginning for high performance and this is accomplished by 
compiling Julia programs to efficient native code for multiple platforms
via the `LLVM <https://llvm.org/>`__ compiler toolchain and just-in-time (JIT) compilation.
The Julia runtime code generator produces an LLVM
**Intermediate Representation** (IR) which the LLMV compiler then
converts to machine code using sophisticated optimization technology.

-  Interpreted languages rely on a runtime which directly executes the source code.
-  Compiled languages rely on ahead-of-time compilation where source
   code is converted to an executable before execution.
-  Just-in-time compilation is when code is compiled to machine code at runtime. 

.. figure:: img/compiler_components.png
   :align: center
   :scale: 50%

   Adapted from `"High-level GPU programming in Julia" <https://arxiv.org/pdf/1604.03410.pdf>`_ 
   by Tim Besard, Pieter Verstraete and Bjorn De Sutter .


To see the code that is generated by the JIT compiler, we can use *macros*.

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

We saw in the compilation diagram above that after parsing the source code, 
the Julia compiler generates an *abstract syntax tree* (AST) - a tree-like data 
structure representing the source code. This is a legacy from the Lisp language.
Since code is represented by objects that can be created and manipulated from 
within the language, it is possible for a program to transform and generate its 
own code.

Let's have a look at the AST of a simple expression:

.. code-block:: julia

   Meta.parse("x + y") |> dump

It returns:

.. code-block:: text

   Expr
     head: Symbol call
     args: Array{Any}((3,))
       1: Symbol +
       2: Symbol x
       3: Symbol y

These three symbols +, x and y are leaves of the AST.
A shorter form to create expressions is ``:(x + y)``.
We can create an expression and then evaluate it:

.. code-block:: julia

   ex = :(x + y)
   x = y = 2
   eval(ex)   # returns 4

A *macro* is like a function, except it accepts expressions as arguments, 
manipulates the expressions, and returns a new expression - thus modifying 
the AST.

We can for example define a macro to 
`repeat an expression N times <https://gist.github.com/MikeInnes/8299575>`_:

.. code-block:: Julia

   macro dotimes(n, body)
       quote
           for i = 1:$(esc(n))
               $(esc(body))
           end
       end
   end

   # print hello! 5 times
   @dotimes 5 println("hello!")
   
   # square 2 4 times
   x = 2
   @dotimes 4 x = x^2

To see what a macro expands to, we can use another macro:

.. code-block:: julia

   @macroexpand @dotimes x -= 13

The output shows that a for loop has been generated:

.. code-block:: text

   quote
       #= REPL[31]:3 =#
       for var"#11#i" = 1:5
           #= REPL[31]:4 =#
           x -= 13
       end
   end

To learn more about metaprogramming and macros in Julia head 
over to:

- `The docs <https://docs.julialang.org/en/v1/manual/metaprogramming/>`__
- `This tutorial from JuliaCon21 <https://github.com/dpsanders/Metaprogramming_JuliaCon_2021>`__


Unicode support
---------------

Julia has full support for Unicode characters. Some are reserved for 
constants or operators, like π, ∈ and √, while the 
majority can be used for names of variables, functions etc.
Unicode characters are entered via tab completion of LaTeX-like abbreviations 
in the Julia REPL or IDEs with Julia extensions, including VSCode. If you are 
unsure how to enter a particular character, you can copy-paste it into 
Julia's help mode to see the LaTeX-like syntax.
For a full list of supported symbols see 
`this page in the Julia docs <https://docs.julialang.org/en/v1/manual/unicode-input/>`__.

.. code-block:: julia

   function Σsqrt(Ω)
       σ = 0  
       for ω ∈ Ω
           σ += √ω
       end
       σ
   end

   ω₁, ω₂, ω₃ = 1, 2, 3
   Ω = [ω₁, ω₂, ω₃]
   σ = Σsqrt(Ω) 

See also
--------

- Lin, Wei-Chen, and Simon McIntosh-Smith. 
  `Comparing Julia to Performance Portable Parallel Programming Models for HPC. <https://ieeexplore.ieee.org/abstract/document/9652798>`_, 
  2021 International Workshop on Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems (PMBS). IEEE, 2021.

