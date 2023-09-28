Dagger
======

.. questions::

   - What is a task graph and how it relates to parallel execution?
   - How to using Dagger.jl to define and execute tasks in a task graph?

.. instructor-note::

   - 30 min teaching
   - 30 min exercises

Overview
--------
We can use a `Directed Acyclic Graph` (DAG) to model dependencies between computation tasks.
In the graph, the nodes are tasks and the directed edges are dependencies between the tasks.
Dependecies arise when the output of one task is an input to other task.

Formally, we a directed acyclic graph consist of set of nodes :math:`V=\{1,2,...,n\}` and set of directed edges :math:`E\subseteq \{(i,j) \mid i\in V, j\in V, i<j \}.`
We say that a task :math:`j` depends on task :math:`i` if there is a path from :math:`i` to :math:`j.`
Otherwise, the tasks are independent.
Independent tasks can be executed in parallel.

Similar to Dask in Python, `Dagger.jl` can dynamically execute tasks on a task graph such that it executes independent tasks in parallel with available threads and distributed workers.

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

We can also specify more complex tasks graph.
Furthermore task graphs can be dynamic, that is, the graph can depend on the output of tasks because Dagger executes task dynamically.
Also, Dagger allows nesting, that is, we can spawn new task from another task.

.. code-block:: julia

   @everywhere function task_nested(a, b)
       return [Dagger.@spawn b+i for i in 1:a]
   end

   a = Dagger.@spawn rand(4:8)
   b = Dagger.@spawn rand(10:20)
   c = Dagger.@spawn task_nested(a, b)
   d = Dagger.@spawn rand(10:20)
   f = Dagger.@spawn +(fetch(c)..., d)
   fetch(f)
