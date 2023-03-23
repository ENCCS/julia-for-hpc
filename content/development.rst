Developing in Julia
===================

.. questions::

   - What development tools exist for Julia?
   - How can I write modules and packages in Julia?
   - How can reproducible environments be created?
   - How are tests written in Julia?
          
.. instructor-note::

   - 30 min teaching
   - 30 min exercises


Tooling
-------

We will now switch from the Julia REPL to 
`Visual Studio Code (VSCode) <https://code.visualstudio.com/>`_.
While VSCode with the `Julia extension <https://code.visualstudio.com/docs/languages/julia>`_ 
is the preferred development environment for many Julia programmers, there 
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

.. type-along:: Getting acquainted with VSCode

   - Open up VSCode either through a file browser or via the terminal command ``code``.
   - We should see a *Get started* page where we can create a new file, open a 
     folder or clone a git repository. The same options can be found in the Explorer 
     menu in the left sidebar.
   - Let's create a new text file. VSCode will ask for a language, which you can select 
     from a menu, but we can also save it as a ``.jl`` file and VSCode will understand
     it's a Julia file. 
   - Type ``println("hello world!")`` in the file and save it to a new folder (e.g. 
     a new folder ``workshop/`` under a ``julia/`` folder in your home directory).
   - To execute the file, we can press the *play* button in the top right corner, 
     or open up the command palette search with ``Ctrl+Shift+p`` (``CMD`` on Mac) 
     and type ``Julia: Execute active File in REPL``, or by hitting ``Shift+Enter``
     on the code line like in Jupyter.
   - A REPL should open up below our code file and show the result of the execution.
   - The `Julia in VSCode <https://www.julia-vscode.org/docs/stable/userguide/runningcode/>`__ 
     documentation is a useful reference.


Modules
-------

Code written in Julia is normally encapsulated in modules. Modules 
have their own global scope (namespace) separate from the global scope of 
other modules (including ``Main``, the top-level module). 
Modules are imported by either the ``using`` or ``import`` keywords.
The difference is how variables defined in the module are brought into scope:

- With ``using ModuleName``, all `exported` names (variables and functions) in the 
  module are brought into scope. Non-exported names are still available via 
  ``ModuleName.func()`` or ``ModuleName.var1``.
- With ``import ModuleName``, all the module's names need to be qualified, e.g. 
  ``ModuleName.func()`` or ``ModuleName.var1``.

.. type-along:: Creating a module

   Let's create a toy module based on the code in the previous section.
   Save it in a new file ``Points.jl`` under e.g. ``$HOME/julia/workshop``.

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

   We can now import and use the module. First we include it either by 
   ``include("Points.jl")`` or by hitting ``Shift+Enter`` to evaluate the whole file.
   Since our new module is defined within 
   the current ``Main`` module, we need to import it with a dot in front, ``using .Points`` 
   (an alternative is to add our current path with the Points module to Julia's 
   LOAD_PATH, ``push!(LOAD_PATH, pwd())``, after which no dot is needed):

   .. code-block:: julia

      using .Points
      p1 = Point(0.0, 1.0)
      p2 = Point(1.0, 2.0)
      p3 = sumsquare(p1, p2)

      # list all names exported from our module 
      names(Points)

   It should return a list of the three symbols ``:Points``, ``:Point`` 
   and ``:sumsquare``.

Revise
^^^^^^

Before `Revise.jl <https://timholy.github.io/Revise.jl/stable/>`__  
was created, it was necessary to restart the Julia 
REPL when developing a package for new changes to take effect in the REPL. 
This is because calling ``using Example`` JIT-compiles the package.
With ``Revise`` loaded this is no longer needed - it cleverly finds what code 
has been modified and reloads only that.

Revise is automatically loaded in VSCode, but if you are developing in 
another editor you will need to install ``Revise`` and when developing a 
package always do ``using Revise`` before ``using MyPackage``.

A caveat when using VSCode is that when developing a script (i.e. not a full package), 
files need to be included in Revise-tracked mode with ``includet("MyScript")``.
When developing packages everything works automatically.

Structure of a Julia package
----------------------------

Julia packages contain one top-level module (submodules are allowed), 
defined in a source file under ``src/`` with the same name as the 
package itself.

All functions, variables and custom types of a package can be put in one 
module file or (more commonly) into multiple files named 
according to their functionality.

.. type-along:: Inspecting a Julia package
   
   Have a look at an example Julia package to get an 
   overview of its structure: https://github.com/JuliaLang/Example.jl

   Pay particular attention to the following aspects:

   - The ``Project.toml`` and ``Manifest.toml`` files
   - The ``test/`` subfolder if it exists
   - Files in the ``src/`` subfolder
   - The structure of the main module file and the other files under ``src/``


The package manager
-------------------

Julia comes with a powerful inbuilt package manager to install 
and remove packages, manage dependencies and create isolated 
software environments.
   
- To enter the package manager from a Julia session we 
  can hit the ``]`` character, after which the prompt 
  changes to ``pkg>``. 
- To see all available options, type `help`. For example, we see that to 
  install a new package we should type ``pkg> add some-package``.
- To go back to the REPL, hit backspace or ``^C``.

.. callout:: A syntax convention

   Instead of using ``]`` to enter the package manager, this lesson 
   will use the following syntax to manage packages through the ``Pkg`` API. 
   This way, code blocks can be copied directly into the REPL and executed:

   .. code-block:: julia

      using Pkg
      Pkg.add("some-package")
      Pkg.status()

Let us get familiar with the package manager by working with the 
Example package that ships with Julia.

.. type-along:: Installing and using a package

   Install ``Example.jl`` using the package manager:

   .. code-block:: julia

      using Pkg
      Pkg.add("Example")
      Pkg.status()

   Import and inspect it:

   .. code-block:: julia

      using Example
      names(Example)

   Look at the help page of the functions:

   .. code-block:: julia

      # type ?domath and ?hello to see the documentation
      domath(12)
      hello("Julia")




Environments
^^^^^^^^^^^^

It is good practice to develop software in isolated environments.
This enables us to use different versions of packages for different 
projects and avoids dependency clashes. It is also the best way to 
ensure `reproducibility` because the exact same software environment 
can be easily created on different computers.

.. type-along:: Creating an environment

   After navigating to a suitable directory, 
   we create a new environment by:
   
   .. code-block:: julia
   
      pwd()
      mkdir("example-project")
      cd("example-project")
      Pkg.activate(".")
   
   The output tells us that a new environment has been created in our 
   current directory - specifically using the ``Project.toml`` file 
   (don't look for it yet as it's only created after we add the first package).
      
   We now add the `Example` package:
   
   .. code-block:: julia
   
      Pkg.add("Example")
      Pkg.status()
   
   The status command shows the version of the `Example` package installed in 
   our new ``Project.toml`` file.  
   What does this file contain? 
   Try printing it through the Julia shell by 
   typing ``;`` followed by ``cat Project.toml`` 
   (or ``println(String(read("Project.toml")))`` in Julia mode).
   
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


.. callout:: Project environments inherit from default environment

   A possibly confusing aspect when working with environments is that 
   you have access to packages in the default environment (e.g. ``@v1.7``)
   even if you have activated a project environment. One thus has to be careful 
   to add all needed packages to a project environment so that the same environment 
   can be generated on other machines.   

   But this also has benefits since packages like Revise, Test, BenchmarkTools etc. 
   can be installed in the default environment rather than cluttering a project 
   environment.


Creating environments for other projects
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To create a new environment based on another project you only need a 
`Project.toml` or `Manifest.toml` file. 

- Using `Project.toml` will install the required dependencies but not 
  necessarily with the same package versions.
- Using `Manifest.toml` will install the packages in the **same state** that 
  is given by the manifest file.

For example:

.. code-block:: julia

   # first git clone the project (or similar) and enter the package directory

   # activate the environment
   Pkg.activate(".")

   # install packages from Manifest.toml or Project.toml
   Pkg.instantiate()


Creating a new project
----------------------

We also use the package manager to start a new project, i.e. when we 
want to develop a new package.

.. type-along:: Create a project

   First we navigate to where we want to create the package, and then:

   .. code-block:: julia

      Pkg.generate("MyPackage")
      cd("MyPackage")

   ``Pkg.generate`` creates both a Project.toml file which has package metadata and 
   is where our dependencies will go, and a basic src/MyPackage.jl template.
   Inspect both!

   Now we activate the environment and add dependencies:

   .. code-block:: julia

      Pkg.activate(".")
      Pkg.add("Example")

   We can now use anything from the Example package in our new project:

   Let's import the Example package and add a function to the MyPackage module:

   .. code-block:: julia

      module MyPackage

      using Example
      export greet, x

      greet() = print("Hello World!")

      x = domath(10)

      end # module



Testing
-------

The ``Test`` package provides unit testing functionality.
We can have a look at the Example package again:
https://github.com/JuliaLang/Example.jl

In the ``test/`` subdirectory we find a script called (following convention)
``runtests.jl``:

.. code-block:: Julia

   using Test, Example

   @test hello("Julia") == "Hello, Julia"
   @test domath(2.0) ≈ 7.0

Running these tests can either be done from inside the package manager:

.. code-block:: julia

   cd("MyPackage")
   Pkg.test("Example")

or from the command line:

.. code-block:: bash

   julia --project=. test/runtests.jl

Usually, one needs to perform more than one test per function or module, 
and usually this is done by collecting related tests in a ``@testset``
block:

.. code-block:: julia

   @testset "Testing domath" begin
      @test domath(2.0) ≈ 7.0
      @test domath(2) ≈ 7
      @test domath(2+2im) ≈ 7 + 2im
   end

The ``@test_throws`` macro can be used to make sure that an expected error 
is raised:

.. code-block:: julia

   @test_throws MethodError domath("abc")

The ``@test``, ``@test_throws`` and ``@testset`` macros are highly useful and can be 
sufficient for many projects, but large projects sometimes need more advanced 
functionality. This is provided in `ReTest <https://github.com/JuliaTesting/ReTest.jl>`__
and other packages in the `JuliaTesting organization <https://github.com/JuliaTesting>`__.



Exercises
---------

.. exercise:: Create a package out of the Points module

   Make the Points module we created above into a Julia package!

   .. solution::

      Navigate to a suitable directory, and then:

      .. code-block:: julia

         Pkg.generate("Points")
         cd("Points")

      Then edit the ``Points.jl`` file under ``src/``:

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

      To start using it:

      .. code-block:: julia

         Pkg.activate(".")
         using Points
         

.. exercise:: Write a test

   Write a few tests for the ``sumsquare`` function in the `Points` package you 
   created in the previous exercise. Run the tests and see if they pass!

   .. solution::

      Create a file ``runtests.jl`` under ``test/``:

      .. code-block:: julia

         using Test
         using Points
         
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
             @test_throws MethodError sumsquare(s1, s2)
         end

      Run the tests with:

      .. code-block:: julia

         Pkg.test("Points")



See also
--------

- Tutorial on a `Julia coding workflow in VSCode <https://techytok.com/lesson-workflow/>`__
- Documentation for `Julia in VSCode <https://www.julia-vscode.org/docs/stable/>`__
- `JuliaTesting organization <https://github.com/JuliaTesting>`__.
- `Pkg documentation <https://pkgdocs.julialang.org/v1/>`__
     
