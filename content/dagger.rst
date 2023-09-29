Dagger
======

.. questions::

   - What is a task graph and how it relates to parallel execution?
   - How to using Dagger.jl to define and execute tasks in a task graph?

.. instructor-note::

   - 30 min teaching
   - 30 min exercises

Task Graphs
-----------
We can use a `Directed Acyclic Graph` (DAG) to model dependencies between computational tasks.
In the graph, the vertices are `tasks` and the directed edges are `dependencies` between the tasks.
Dependecies arise when the output of one task is an input to other task.
Task graphs are commonly used to represent scientific workflows.

.. figure:: img/dag.png
   :align: center

   An example of a directed acyclic graph with vertices :math:`V=\{1,2,3,4\}` and directed edges :math:`E=\{(1,2), (1,3), (2,4), (3, 4)\}.`
   The graph has two paths :math:`(1,2,4)` and :math:`(1,3,4).`
   We can see that the vertices :math:`2` and :math:`3` are independent because there no path between them.

Formally, we a directed acyclic graph consist of set of vertices :math:`V=\{1,2,...,n\}` called tasks and set of directed edges :math:`E\subseteq \{(i,j) \mid i\in V, j\in V, i<j \}` called dependencies.
We say that a task :math:`j` `depends` on task :math:`i` if there is a path from :math:`i` to :math:`j.`
Otherwise, the tasks are `independent`.
**Independent tasks can be executed in parallel.**

We also focus on task graphs that are **dynamically generated** such that a task can create new tasks and dependencies based on the inputs it receives.
In these cases, the full task graph is not know before computing it.

There are frameworks, such as `Dask` for Python and `Dagger.jl` for Julia, that can express task graphs and automatically execute independent tasks in parallel.
Furthermore, they may support features such as out-of-core execution to process data that is larger than the memory and checkpointing for saving intermediate result to disk.
We focus on defining task graphs and parallel execution.


Dagger
------
`Dagger.jl` can dynamically execute tasks on a task graph such that it executes independent tasks in parallel with available threads and distributed workers.
We can install dagger with the package manager:

.. code-block:: julia

   using Pkg
   Pkg.add("Dagger")

Let's start Julia with two threads using ``julia --threads=2``.
Then, we can add distributed workers and import Dagger as follows:

.. code-block:: julia

   using Distributed

   # We add one worker with two threads before loading Dagger
   addprocs(1; exeflags="--threads=2")

   # Let's load Dagger on all workers
   @everywhere using Dagger

Dagger automatically creates Dagger processors which it uses to execute tasks.
We can query the available processors as follows:

.. code-block:: julia

   ctx = Context()

   # Dagger CPU (OS) processes (Dagger.OSProc)
   ctx.procs

   # Dagger Thread processes on each CPU process (Dagger.ThreadProc)
   Dagger.get_processors.(ctx.procs)


Next, we would like to define and execute a task graph using Dagger.

.. code-block:: julia

   # Add task function to all workers
   @everywhere task() = (Distributed.myid(), Threads.threadid())

   # Let's define a simple task graph consisting of 10 independent tasks
   tasks = [Dagger.@spawn task() for _ in 1:10]

   # Fetch the results
   results = fetch.(tasks)

   println("(Worker ID, Thread ID)")
   println("Main process")
   println(task())
   println("Dagger tasks")
   foreach(println, sort(results))

We can see that Dagger thread 1 on worker 1 for scheduling tasks and the other Dagger processors to execute the tasks.

We can also specify more complex, dynamic tasks graphs since Dagger uses a dynamic scheduler and allows nesting tasks.
Here is an example of dynamic task graph:

.. code-block:: julia

   @everywhere function task_nested(a, b)
       return [Dagger.@spawn b+i for i in 1:a]
   end

   # Define and execute a task graph
   a = Dagger.@spawn rand(4:8)
   b = Dagger.@spawn rand(10:20)
   # The value of `a` determines how many nested tasks are spawned
   c = Dagger.@spawn task_nested(a, b)
   d = Dagger.@spawn rand(10:20)
   # We use fetch inside @spawn so it does not block
   f = Dagger.@spawn +(fetch(c)..., d)

   # Fetch the final result
   fetch(f)


Exercises
---------

