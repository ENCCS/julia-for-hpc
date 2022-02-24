Instructor's guide
==================

Prerequisites
-------------

This lesson material assumes some familiarity with Julia's syntax. However, the necessary 
prerequisites are covered in the Quick Reference section which should be required  
reading for participants prior to attending a workshop.


Mode of teaching
----------------

In the first hands-on episode "Special features of Julia" only the Julia REPL is used.
This makes learners comfortable with the REPL before moving on to the more complicated 
environment in VSCode.

Following episodes use VSCode as it is the preferred IDE by Julia developers and 
has a powerful language extension for Julia. 

The final episode on GPU programming requires access to an NVIDIA GPU. It is possible 
to request sponsorship in the form of cloud credits from JuliaHub. Using Julia 
and CUDA.jl on Google Colab was found to not work as it should. 
An alternative is to use an HPC system with NVIDIA GPUs where workshop participants 
can each get interactive access to a GPU for testing.

Demonstrations, type-alongs and exercises
-----------------------------------------

The instructor walks through the material and demonstrates all the coding found 
outside the special type-along boxes. It's important to not rush and to clearly 
explain what is being written. It should be clear that learners are not expected 
to type-along during these sessions. The instructor can either type things out or 
copy-paste from the code blocks.

Most episodes have type-along sections demarkated with light-green boxes with a keyboard 
emoji. It should be clearly explained that learners are expected to type-along during 
these sessions. Here's it's better for the instructor to type things out rather than 
copy-pasting everything, although larger code blocks should be copy-pasted to avoid 
error-prone and boring typing.

Each episode ends with one or more exercises. Learners should be given plenty of 
time to work on these. Recommended timings are provided at the top of each episode.


Possibly confusing points
-------------------------

- To enable learners to copy-paste from code blocks to install and manage packages, 
  the lesson adheres to the convention of using the ``Pkg`` API (e.g. 
  ``using Pkg ; Pkg.add("some-package")``. This is explained in the "Developing in Julia" episode 
  but needs to be explained very carefully to avoid confusion.
- In exercises where the ``evolve!`` function from HeatEquation.jl should be modified, it 
  should be clearly explained that it's best to extract the function to a separate script 
  and incrementally work on it there, rather than modifying the HeatEquation module.
   




The following schedule was used for a workshop in February 2022. 
However, time was too short and most episodes require 10-20 minutes more
for a thorough treatment.

**Day 1**

+-------------+--------------------------------------------+
| Time        | Section                                    |
+=============+============================================+
| 9:00-9:10   | Welcome                                    |
+-------------+--------------------------------------------+
| 9:10-9:20   | Motivation                                 |
+-------------+--------------------------------------------+
| 9:20-9:50   | Special features of Julia                  |
+-------------+--------------------------------------------+
| 9:50-10:00  | Break                                      |
+-------------+--------------------------------------------+
| 10:00-10:40 | Developing in Julia                        |
+-------------+--------------------------------------------+
| 10:40-11:00 | Break                                      |
+-------------+--------------------------------------------+
| 11:00-12:00 | Scientific computing and data science      |
+-------------+--------------------------------------------+

**Day 2**

+-------------+--------------------------------------------+
|  Time       | Section                                    | 
+=============+============================================+
| 9:00-9:40   | Writing performant Julia code              |
+-------------+--------------------------------------------+
| 9:40-9:50   | Break                                      |
+-------------+--------------------------------------------+
| 9:50-10:40  | Parallelization                            |
+-------------+--------------------------------------------+
| 10:40-11:00 | Break                                      |
+-------------+--------------------------------------------+
| 11:00-11:50 | GPU computing                              |
+-------------+--------------------------------------------+
| 11:50-12:00 | Conclusions and outlook                    |
+-------------+--------------------------------------------+


Future improvements of the lesson
---------------------------------

- The workshop should be taught over three half days instead of two. 
- Instead of requiring participants to go through the Quick Reference 
  before attending the workshop, the first 1-2 hours of the workshop 
  should cover Julia's basic syntax. Material should be moved from the Quick 
  Reference to a new episode following Motivation.
- The machine learning section should probably be removed because only 
  a minority of participants will be familiar enough with the concepts 
  to be able to learn from it. The "Scientific computing and data science" 
  episode should instead cover more ground in visualization.
- Provide a Project.toml file in a repository for participants to download 
  and instantiate in project environment before workshop starts.
- Come up with exercises/discussions that more easily can be performed in groups.
- Deeper dive into running Julia on HPC systems. Demonstrate/exercise using ClusterManagers.jl.
- Consider adding section on interfacing to Python, R, C/C++, Fortran, MatLab.
- Add exercises, particularly in "Writing performant Julia code"
- A better schedule could be:  
 
  **Day 1:** 

  - Motivation
  - Syntax basics 
  - Special features in Julia
  - Developing in Julia 

  **Day 2:**

  - Scientific computing and data science 
  - Writing performant Julia code
  
  **Day 3:**

  - Parallelization
  - GPU programming

