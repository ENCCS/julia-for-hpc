Developing in Julia
===================

.. questions::

   - How do modules work in Julia?
   - How do I create a new project?
   - How can I create reprodubible environments?
   - How are tests written in Julia?
   - How does scoping work?
     
.. objectives::

   - Get familiar with the package manager
   - Learn to use, extend and write packages in Julia
   - Learn how to create reproducible environments and add tests to your code
   - Understand scoping in Julia
     

Tooling
-------

We will now switch from the Julia REPL to 
`Visual Studio Code (VSCode) <https://code.visualstudio.com/>`_.
While VSCode with the `Julia extension <https://code.visualstudio.com/docs/languages/julia>`_ 
is the prefered development environment for many Julia programmers, there 
are some alternatives:

- `Jupyter <https://jupyter.org/>`_:
  Jupyter notebooks are familiar to many Python and R users. 
- `Pluto.jl <https://github.com/fonsp/Pluto.jl>`_:
  Offers a similar notebook experience to Jupyter, but
  understands global references between cells, and
  reactively re-evaluates cells affected by a code change.
- A text editor like nano, emacs, vim, etc., followed by running your
  code with ``julia filename.jl``. There are also plugins for Julia for 
  major text editors - do an internet search on e.g. "emacs julia" or "vim julia"
  to find out more.

Using VSCode with the Julia extension
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

After following the :doc:`setup` instructions to install VSCode and the Julia extension, 
we can fire up a VSCode session and explore the functionality.

.. type-along:: Exploring VSCode

   - Open up VSCode
   - WRITEME



Structure of a Julia package
----------------------------

Modules
^^^^^^^

Code written in Julia is normally encapsulated in modules. Modules 
have their own global scope (namespace) separate from the global scope of 
other modules (including ``Main``, the top-level module). 
Modules are imported by either the ``using`` or ``import`` keywords.
The difference is how variables defined in the module are brought into scope:

- With ``using ModuleName``, all `exported` names (variables and functions) in the 
  module are brought into scope.
- With ``import ModuleName``, the module's names need to be qualified, e.g. 
  ``ModuleName.func()`` or ``ModuleName.var1``.

.. type-along:: Creating a module

   Let's create a toy module based on the code in the previous section:

   .. code-block:: julia

      module Points
 
      export Point, sumsquare

      struct Point{T}
          x::T
          y::T
      end

      function sumsquare(p1::Point, p2::Point)
          return Point(p1.x^2 + p2.x^2, p1.y^2 + p2.y^2)
      end

      end

   We can now import and use the module. Since our new module is defined within 
   the current ``Main`` module, we need to import it with a dot in front.

   .. code-block:: julia

      using .Points
      p1 = Point(0.0, 1.0)
      p2 = Point(1.0, 2.0)
      p3 = sumsquare(p1, p2)

      # list all names exported from our module 
      names(Points)

Packages
^^^^^^^^

Julia packages contain one top-level module (submodules are allowed), 
defined in a source file under ``src/`` with the same name as the 
package itself.

All functions, variables and custom types of a package can be put in one 
(possibly large) module file, 
or (more commonly) into multiple files
according to the functionality (``core.jl``, ``io.jl``, ``utils.jl``, ...).

.. type-along:: Inspecting a Julia package
   
   Let us have a look at representative Julia packages. Here are a few examples 
   of Julia packages of a managable size:

   - https://github.com/JuliaLang/Example.jl
   - https://github.com/carstenbauer/MonteCarlo.jl
   - https://github.com/aurelio-amerio/Mandelbrot.jl
   - https://github.com/lucaferranti/MatrixPolynomials.jl
   - https://github.com/FluxML/Trebuchet.jl
   - https://github.com/wikfeldt/miniWeather.jl

   Pay particular attention to the following aspects:

   - The ``Project.toml`` and ``Manifest.toml`` files
   - The ``test/`` subfolder if it exists
   - Files in the ``src/`` subfolder
   - The structure of the main module file and the other files under ``src/``




Let us play around in the REPL to get used to the workflow.

.. type-along:: Installing and using a package

   WRITEME

Revise
------

WRITEME

Julia's package manager
-----------------------

Julia comes with an powerful inbuilt package manager to install 
and remove packages, manage dependencies and create isolated 
software environments.

.. type-along:: Entering the package manager
   
   - To enter the package manager from a Julia session we 
     can hit the ``]`` character, after which the prompt 
     changes to ```pkg>```. 
   - To see all available options, type `help`. For example, we see that to 
     install a new package we should type ``pkg> add some-package``.
   - To go back to the REPL, hit backspace or ``^C``.

.. callout:: Using the ``Pkg`` module

   Instead of using ``]`` to enter the package manager, this lesson 
   will use the following syntax to manage packages. This way, code blocks
   can be copied directly into the REPL and executed:

   .. code-block:: julia

      using Pkg
      Pkg.add("some-package")
      Pkg.status()

Let us get familiar with the package manager by working with an 
example package that ships with Julia.

Environments
^^^^^^^^^^^^

It is good practice to develop software in isolated environments.
This enables us to use different versions of packages for different 
projects and avoids dependency clashes. It is also the best way to 
ensure `reproducibility` because the exact same software environment 
can be easily created on different computers.

We begin by creating a new environment:

.. code-block:: julia

   Pkg.activate("example-project")

The output tells us that a new environment has been created in our 
current directory - specifically using the ``Project.toml`` file 
(don't look for it yet, it's only created after we start adding packages).

Alternatively, one can first create the directory, then navigate to 
that directory and type ``Pkg.activate(".")``.

We now add the `Example` package by

.. code-block:: julia

   Pkg.add("Example")
   Pkg.status()

The status command shows the version of the `Example` package installed in 
our new ``Project.toml`` file.  
What does this file contain? Try printing it through the Julia shell by 
typing ``;`` followed by ``cat example-project/Project.toml``.

We can also see that there's another file in the ``example-project`` directory
called ``Manifest.toml``.

.. callout:: ``Project.toml`` and ``Manifest.toml``
   
   - ``Project.toml`` describes a project on a high level, including 
     package dependencies and compatibilities, metadata such as `authors`,
     `name`, `version` etc. It can be modified by hand. 
   - ``Manifest.toml`` 
     is an absolute record of the state of packages in an environment and 
     can be used to create identical Julia environments on different computers.
     It should not be modified by hand.

Creating environments for other projects
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To create a new environment based on another project you only need a 
`Project.toml` or `Manifest.toml` file. Using `Project.toml` will install 
the required dependencies but not necessarily with the same package versions, 
while using `Manifest.toml` will install the packages in the **same state** that 
is given by the manifest file.

For example:

.. code-block:: julia

   # first git clone the project (or similar) and enter the package directory
   using Pkg
   # activate the environment
   Pkg.activate(".")
   # install packages from Manifest.toml or Project.toml
   Pkg.instantiate()




Creating a new project
----------------------



Modules
^^^^^^^



Where can I find existing packages?
-----------------------------------



Adding tests
------------

- Test
- ReTest
- InlineTest

**Should be installed in default environment, not in project**.
VSCode imports it with the julia extension.



Exercises
---------

.. exercise:: Creating a new environment

   In preparation for the next section on data science techniques in Julia, 
   create a new environment named `datascience`, activate it and install 
   the following packages:

   - `DataFrames <https://github.com/JuliaData/DataFrames.jl>`_
   - `PalmerPenguins <https://github.com/devmotion/PalmerPenguins.jl>`_
   - `Plots <https://github.com/JuliaPlots/Plots.jl>`_
   - `Flux <https://github.com/FluxML/Flux.jl>`_

.. exercise:: Writing a test

   Write a test for the ``sumsquare`` function in the `Points` module we wrote above!

   - Create a new file `testPoints.jl` in the same directory as your `Points.jl` file.
   - Include the module by ``include("Points.jl")`` and load it with ``using .Points`` 
     (because the module is included in ``Main``).
   - Write your tests using the ``@testset`` and ``@test`` macros. 
   - Run the tests and see if they pass.

   .. solution::

      .. code-block:: julia

         using Test
         using .Points
         
         @testset begin
             # test floats
             p1 = Point(1.0, 2.0)
             p2 = Point(0.0, 3.0)
             @test sumsquare(p1, p2) == Point(1.0, 13.0)
             # test integers
             q1 = Point(1, 2)
             q2 = Point(0, 3)
             @test sumsquare(q1, q2) == Point(1, 13)
             # test that strings fail
             s1 = Point("a", "b")
             s2 = Point("c", "d")
             @test_throws MethodError sumsquare(s1, s2) == Point(1, 13)    
         end

See also
--------

- https://docs.julialang.org/en/v1/manual/faq/#Packages-and-Modules
- https://docs.julialang.org/en/v1/manual/code-loading/#Federation-of-packages
- https://julialang.github.io/Pkg.jl/v1/creating-packages/  
- https://juliahub.com/ui/Home
- https://discourse.julialang.org/t/experimental-reproducibility-julia-vs-the-rest/46769/6
- https://julialang.github.io/Pkg.jl/v1/environments/
- https://docs.julialang.org/en/v1.0/stdlib/Pkg/
     
