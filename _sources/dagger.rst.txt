Parallel execution with Dagger
==============================

.. questions::

   - What is a task graph, and how it relates to parallel execution?
   - How to use Dagger.jl to define and execute tasks in a task graph?

.. instructor-note::

   - 30 min teaching
   - 30 min exercises

Task Graphs
-----------
We can use a `Directed Acyclic Graph` (DAG) to model dependencies between computational tasks.
In the graph, the vertices are tasks, and the directed edges are dependencies between tasks.
Dependencies arise when the output of one task is an input to another task.
Task graphs are commonly used to represent scientific workflows.

.. figure:: img/dag.png
   :align: center

   An example of a directed acyclic graph with two paths.
   We can see that the vertices 2 and 3 are independent because there is no path between them.

Formally, a **task graph** is a directed acyclic graph consisting of a set of vertices called **tasks** and a set of directed edges that represent **dependencies** between tasks.
We say that one task **depends** on another task if there is a path from the first task to the second task.
Otherwise, the tasks are **independent**.
We can compute independent tasks in **parallel**.

We also focus on task graphs that are **dynamically generated** such that a task can create new tasks and dependencies based on the inputs it receives.
In these cases, the complete task graph is not known prior to computing it.

Some frameworks, such as `Dask` for Python and `Dagger.jl` for Julia, can express task graphs and automatically execute independent tasks in parallel.
Furthermore, they may support features such as out-of-core execution to process data larger than the memory and checkpointing for saving intermediate results to disk.
We focus on defining task graphs and parallel execution.


Dagger
------
Let's start Julia with two threads using the command:

.. code-block:: console

   $ julia --threads=2

`Dagger.jl` can dynamically execute tasks on a task graph to execute independent tasks in parallel with available threads and distributed workers.
We can install Dagger with the package manager:

.. code-block:: julia

   using Pkg
   Pkg.add("Dagger")

Then, we can add distributed workers and import Dagger as follows:

.. code-block:: julia

   using Distributed

   # We add one worker with two threads before loading Dagger
   addprocs(1; exeflags="--threads=2")

   # Let's load Dagger on all workers
   @everywhere using Dagger

Dagger automatically creates Dagger processors, which it uses to execute tasks.
We can query the available processors as follows:

.. code-block:: julia

   ctx = Context()

   # Dagger CPU (OS) processes (Dagger.OSProc)
   ctx.procs

   # Dagger Thread processes on each CPU process (Dagger.ThreadProc)
   Dagger.get_processors.(ctx.procs)


Next, we want to define and execute a task graph using Dagger.

.. code-block:: julia

   # Add task function to all workers
   @everywhere function task()
       return (Distributed.myid(), Threads.threadid())
   end

   # Let's define a simple task graph consisting of 10 independent tasks
   tasks = [Dagger.@spawn task() for _ in 1:10]

   # Fetch the results
   results = fetch.(tasks)

   println("(Worker ID, Thread ID)")
   println("Main process")
   println(task())
   println("Dagger tasks")
   foreach(println, sort(results))

We can see that Dagger used thread one on worker one for scheduling tasks and the other Dagger processors to execute the tasks.

We can also specify more complex, dynamic task graphs since Dagger uses a dynamic scheduler and allows nesting tasks.
Here is an example of a dynamic task graph:

.. code-block:: julia

   @everywhere using Random

   @everywhere function task_nested(a::Integer, b::Integer)
       return [Dagger.@spawn b+i for i in one(a):a]
   end

   # Use determistic random number generators
   rngs = [MersenneTwister(seed) for seed in 1:3]

   # Define and execute a task graph
   # We use fetch inside @spawn so it does not block
   a = Dagger.@spawn rand(rngs[1], 4:8)
   b = Dagger.@spawn rand(rngs[2], 10:20)
   c = Dagger.@spawn task_nested(fetch(a), fetch(b))
   d = Dagger.@spawn rand(rngs[3], 10:20)
   f = Dagger.@spawn mapreduce(fetch, +, fetch(c)) + fetch(d)

   # Fetch the final result
   fetch(f)



Exercises
---------
.. exercise:: Parallelize serial code using Dagger

   Parallelize the following serial code using Dagger.
   The, execute the script with Julia process using two threads, and add one Distributed worker with two threads.
   Compare the results and execution time between the serial and parallel versions.

   .. literalinclude:: code/dagger_serial.jl
      :language: julia

   .. solution:: Hints

      .. literalinclude:: code/dagger_hints.jl
         :language: julia

   .. solution:: Solution

      .. code-block:: bash

         julia --threads=2 dagger.jl

      ``dagger.jl``

      .. literalinclude:: code/dagger_parallel.jl
         :language: julia
