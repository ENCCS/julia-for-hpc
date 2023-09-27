Dagger
======

.. questions::

   - ?
   - ?

.. instructor-note::

   - 20 min teaching
   - 20 min exercises

Overview
--------
`Dagger.jl` can seamlessly execute tasks on available threads and distributed workers.
Furthermore, it can model dependencies between tasks as a Directed Acyclic Graph (DAG), hence the name, dagger.

Install dagger

.. code-block:: julia

   using Pkg
   Pkg.add("Dagger")

Let's start Julia with multiple threads using ``julia -t 2``

.. code-block:: julia

   using Distributed
   # Add workers before loading dagger
   addprocs(2; exeflags="--threads=2")
   using Dagger

   # Add task function to all workers
   @everywhere function task()
       return (
           myid(),             # worker id
           Threads.threadid()  # thread id
       )
   end

   tasks = [Dagger.@spawn task() for _ in 1:10]
   results = fetch.(tasks)

   println("(Worker ID, Thread ID)")
   println("Main process")
   println(task())
   println("Worker processes")
   println.(unique(results))

Dagger reserved the thread 1 on worker 1 for spawning tasks and uses other threads and workers to execute tasks.
