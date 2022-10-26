Julia for high-performance scientific computing
===============================================

Julia is a scientific programming language that is free and open
source - see https://julialang.org/ for downloads, documentation,
learning resources etc. Bridging high-level interpreted and low-level
compiled languages, it offers high performance (comparable to C and
Fortran) without sacrificing simplicity and programming productivity
(like in Python or R).

Julia has a rich ecosystem of libraries aimed
towards scientific computing and a powerful in-built package manager
to install and manage their dependencies. Julia is also gaining ground
in HPC as it supports both threading and distributed-memory
parallelisation as well as GPU computing.

This lesson starts with the basics of Julia, its syntax,
multiple-dispatch paradigm, package development and best practices. It
then moves on to topics relevant to high-performance scientific
computing, including an overview of powerful libraries for modeling
and machine learning, visualization, parallelization and GPU
computing.

.. prereq::

   - Experience in one or more programming languages.
   - Familiarity with basic concepts in high-performance computing (HPC) 
     (including parallelization by threading or multiprocessing) 
     and programming graphical processing units (GPUs). No direct experience 
     is required.

.. toctree::
   :hidden:
   :maxdepth: 1
   :caption: Prerequisites

   setup

.. toctree::
   :hidden:
   :maxdepth: 1
   :caption: The lesson

   motivation
   syntax-intro
   overview
   development
   performant-code
   multithreading
   distributed
   MPI
   GPU
   outlook

.. toctree:: 
   :hidden:
   :maxdepth: 1
   :caption: Optional episodes  

   scientific-computing
   data-science
   exercises


.. toctree::
   :maxdepth: 1
   :caption: Reference

   guide



.. _learner-personas:

Who is the course for?
----------------------

This lesson material is targeted towards students, researchers and developers
who:

 - are already familiar with one or more programming languages (Python, R, C/C++, Fortran, Matlab, ...)
 - want to add a new exciting high-level yet performant language to their repertoire
 - might be mixing a high-level and a low-level language for performance reasons but want to make their life easier
 - need to analyze big data or perform computationally demanding modeling, analysis or simulations
 - want to develop high-performance parallelized and/or GPU code but prefer to stay within a
   productive high-level language.


About the course
----------------

This lesson material is developed by the `EuroCC National Competence Center
Sweden (ENCCS) <https://enccs.se/>`_ and taught in ENCCS workshops. It is aimed
at researchers and developers who want to learn a modern, high-level, high-performace 
programming language suitable for scientific computing, data science, machine learning
and high-performance computing on CPUs or GPUs.
Each lesson episode has clearly defined questions that will be addressed and includes
multiple exercises along with solutions, and is therefore also useful for
self-learning.
The lesson material is licensed under `CC-BY-4.0
<https://creativecommons.org/licenses/by/4.0/>`_ and can be reused in any form
(with appropriate credit) in other courses and workshops.
Instructors who wish to teach this lesson can refer to the :doc:`guide` for
practical advice.

Graphical and text conventions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Different graphical elements are used to organize the material.

Type-along sections
~~~~~~~~~~~~~~~~~~~

Type-along sections are intended for live coding where all participants 
type-along and appear in a separate text box, marked with a keyboard emoji:

.. type-along:: Defining a variables

  This is how you set a variable in Julia:

  .. code-block:: julia

    x = 1

Exercises
~~~~~~~~~

All lesson episodes (sections) end with one or more exercises for participants 
to practice what they've learned, marked with a hand-writing emoji. Sometimes 
there's also a solution:

.. exercise:: Printing to screen

  Which of these commands prints the value of the variable ``x``?

  1. ``print(x)``
  2. ``println(x)``
  3. ``write(x)``

  .. solution::

    Correct answer is both 1 and 2! ``println()`` uses ``print()`` and adds a new line.

Important information
~~~~~~~~~~~~~~~~~~~~~

Sometimes important information is displayed inside boxes with an exclamation mark emoji:

.. callout:: Important info

  Please don't hesitate to ask questions during the workshop!



See also
--------

Many resources for learning Julia can be found
at https://julialang.org/learning/. The list includes 
`Julia Academy <https://juliaacademy.com/>`__ courses, 
the `Julia manual <https://docs.julialang.org/en/v1/manual/getting-started/>`__,
the `Julia Youtube channel <https://www.youtube.com/user/JuliaLanguage/playlists>`__, 
and an assortment of tutorials and books.

A recent talk given by Kristoffer Carlsson, developer at Julia Computing in Sweden, gives an 
`excellent overview on using Julia for HPC <https://www.youtube.com/watch?v=bXHe7Kj3Xxg>`__.

Credits
-------

The lesson file structure and browsing layout is inspired by and derived from
`work <https://github.com/coderefinery/sphinx-lesson>`_ by `CodeRefinery
<https://coderefinery.org/>`_ licensed under the `MIT license
<http://opensource.org/licenses/mit-license.html>`_. We have copied and adapted
most of their license text.

Several examples and formulations are inspired by other Julia
lessons, particularly:

- `Educational prallelization/GPU-porting repository with C/C++/Fortran examples <https://github.com/cschpc/heat-equation>`__ developed by CSC
- `Introduction to Julia <https://github.com/csc-training/julia-introduction/>`__ provided by CSC and Aalto
- `Tim Besard's JuliaCon 2021 GPU tutorial <https://github.com/maleadt/juliacon21-gpu_workshop>`__
- `Carsten Bauer's 3-day Julia workshop <https://github.com/carstenbauer/JuliaCologne21>`__
- `The Carpentry lesson Introduction to Julia <https://carpentries-incubator.github.io/julia-novice/>`__
- `Storopoli, Huijzer and Alonso (2021). Julia Data Science. ISBN: 9798489859165. <https://juliadatascience.io>`__


Instructional Material
^^^^^^^^^^^^^^^^^^^^^^

All ENCCS instructional material is made available under the `Creative Commons
Attribution license (CC-BY-4.0)
<https://creativecommons.org/licenses/by/4.0/>`_. The following is a
human-readable summary of (and not a substitute for) the `full legal text of the
CC-BY-4.0 license <https://creativecommons.org/licenses/by/4.0/legalcode>`_.
You are free:

- to **share** - copy and redistribute the material in any medium or format
- to **adapt** - remix, transform, and build upon the material for any purpose,
  even commercially.

The licensor cannot revoke these freedoms as long as you follow these license terms:

- **Attribution** - You must give appropriate credit (mentioning that your work
  is derived from work that is Copyright (c) ENCCS and, where practical, linking
  to `<https://enccs.se>`_), provide a `link to the license
  <https://creativecommons.org/licenses/by/4.0/>`_, and indicate if changes were
  made. You may do so in any reasonable manner, but not in any way that suggests
  the licensor endorses you or your use.
- **No additional restrictions** - You may not apply legal terms or
  technological measures that legally restrict others from doing anything the
  license permits. With the understanding that:

  - You do not have to comply with the license for elements of the material in
    the public domain or where your use is permitted by an applicable exception
    or limitation.
  - No warranties are given. The license may not give you all of the permissions
    necessary for your intended use. For example, other rights such as
    publicity, privacy, or moral rights may limit how you use the material.
  
Software
^^^^^^^^

Except where otherwise noted, the example programs and other software provided
by ENCCS are made available under the `OSI <http://opensource.org/>`_-approved
`MIT license <http://opensource.org/licenses/mit-license.html>`_.
