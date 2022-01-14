Working with data
=================

.. questions::

   - How can I manipulate and wrangle data in Julia?
   - What packages exist?
     
.. objectives::

   - Learn to efficiently use data frames 
   - Learn some good practices around tidy data


Julia is a good language to use for data science problems.
It will perform well, alleviating the need to translate
computationally demanding parts to another language, and its 
ecosystem of libraries for data science and machine learning 
problems is mature and user friendly.

In this episode we will learn how to work with data using 
the DataFrames package and get a flavor for how to set up a 
deep learning workflow using the Flux package.

Download a dataset
------------------

We start by downloading a dataset containing measurements 
of characteristic features of different penguin species.


.. figure:: img/lter_penguins.png
   :align: center

   Artwork by @allison_horst

To obtain the data we simply add the PalmerPenguins package.

.. code-block:: julia

   Pkg.add("PalmerPenguins")
   using PalmerPenguins



Dataframes
----------

The `DataFrames.jl <https://dataframes.juliadata.org/stable/>`_ 
package is Julia's version of the ``pandas`` library in Python and 
the ``data.frame()`` function in R. We will use it here to 
analyze the penguins dataset, but first we need to install it:

.. code-block:: 

   Pkg.add("DataFrames")
   using DataFrames


.. type-along:: Dataframes

   A dataframe is a 2-dimensional table of rows and columns, much 
   like a Excel spreadsheet. The rows usually represent independent 
   observations, while the columns represent the 
   features (variables) for each observation. Just like in Python and R, 
   the DataFrames.jl package provides functionality for data 
   manipulation and analysis.  
   Here's how you can create a new dataframe:

   .. code-block:: julia

      using DataFrames
      names = ["Ali", "Clara", "Jingfei", "Stefan"]
      age = ["25", "39", "64", "45"]
      df = DataFrame(; name=names, age=age)

   .. code-block:: text

      4×2 DataFrame
       Row │ first_name  age    
           │ String      String 
       ────┼────────────────────
         1 │ Ali         25
         2 │ Clara       39
         3 │ Jingfei     64
         4 │ Stefan      45


We now create a dataframe containing the PalmerPenguins dataset:

.. code-block:: julia

   table = PalmerPenguins.load()
   df = DataFrame(table)

   # the raw data can be loaded by
   #tableraw = PalmerPenguins.load(; raw = true)

   first(df, 5)

.. code-block:: text

   344×7 DataFrame
    Row │ species    island     bill_length_mm  bill_depth_mm  flipper_length_mm  body_mass_g  sex     
        │ String     String     Float64?        Float64?       Int64?             Int64?       String? 
   ─────┼──────────────────────────────────────────────────────────────────────────────────────────────
      1 │ Adelie   Torgersen            39.1           18.7                181         3750  male
      2 │ Adelie   Torgersen            39.5           17.4                186         3800  female
      3 │ Adelie   Torgersen            40.3           18.0                195         3250  female
      4 │ Adelie   Torgersen       missing        missing              missing      missing  missing 
      5 │ Adelie   Torgersen            36.7           19.3                193         3450  female


We can inspect the data using a few basic operations:

.. code-block:: julia

   # slicing
   df[1, 1:3]

   # slicing and column name (can also use "island")
   df[1:20:100, :island]

   # dot syntax (editing will change the dataframe)
   df.species

   # get a copy of a column 
   df[:, [:sex, :body_mass_g]]

   # access column directly without copying (editing will change the dataframe)
   df[!, :bill_length_mm]

   # get size
   size(df), ncol(df), nrow(df)

   # find unique species
   unique(df.species)

   # names of columns
   names(df)


Summary statistics can be displayed with the ``describe`` function:

.. code-block:: julia

   describe(df)

.. code-block:: text

   7×7 DataFrame
    Row │ variable           mean     min     median  max        nmissing  eltype                  
        │ Symbol             Union…   Any     Union…  Any        Int64     Type                    
   ─────┼──────────────────────────────────────────────────────────────────────────────────────────
      1 │ species                     Adelie          Gentoo            0  String
      2 │ island                      Biscoe          Torgersen         0  String
      3 │ bill_length_mm     43.9219  32.1    44.45   59.6              2  Union{Missing, Float64}
      4 │ bill_depth_mm      17.1512  13.1    17.3    21.5              2  Union{Missing, Float64}
      5 │ flipper_length_mm  200.915  172     197.0   231               2  Union{Missing, Int64}
      6 │ body_mass_g        4201.75  2700    4050.0  6300              2  Union{Missing, Int64}
      7 │ sex                         female          male             11  Union{Missing, String}

The main features we are interested in for each penguin observation are 
`bill_length_mm`, `bill_depth_mm`, `flipper_length_mm` and `body_mass_g`.
What the first three features mean is illustrated in the picture below.

.. figure:: img/culmen_depth.png
   :align: center

   Artwork by @allison_horst


We can see in the output of ``describe`` that the element type of 
all the columns is a union of ``missing`` and a numeric type. This
implies that our dataset contains missing values.

We can remove these by the ``dropmissing`` or ``dropmissing!`` functions
(what is the difference between them?):

.. code-block:: julia

   dropmissing!(df)



Plotting
--------

Let us now look at different ways to visualize this data.
Many different plotting libraries exist for Julia and which 
one to use will depend on the specific use case as well as 
personal preference. 

.. callout:: Some plotting packages in Julia
      
   - `Plots.jl <http://docs.juliaplots.org/latest/>`_: high-level 
     API for working with several different plotting back-ends, including `GR`, 
     `Matplotlib.Pyplot`, `Plotly` and `PlotlyJS`.
   - `StatsPlots.jl <https://github.com/JuliaPlots/StatsPlots.jl>`_: was moved 
     out from core `Plots.jl`. Focuses on statistical use-cases and supports 
     specialized statistical plotting functionalities.
   - `GadFly.jl <http://gadflyjl.org/stable/>`_: based largely on 
     `ggplot2 for R <https://ggplot2.tidyverse.org/>`_ and the book 
     `The Grammar of Graphics <https://www.cs.uic.edu/~wilkinson/TheGrammarOfGraphics/GOG.html>`_.
     Well suited for statistics and machine learning.
   - `VegaLite.jl <https://www.queryverse.org/VegaLite.jl/stable/>`_: based on 
     `Vega-Lite <https://vega.github.io/vega-lite/>`_, a grammar of interactive graphics. 
     Great for interactive graphics.
   - `Makie.jl <https://makie.juliaplots.org/stable/>`_ data visualization ecosystem with backends 
     `GLMakie.jl` (OpenCL), `CairoMakie.jl` (Cairo) and `WGLMakie.jl` (WebGL). 
     Good for publication-quality plotting but can be a bit slow to load and use.

We will be using `Plots.jl` and `StatsPlots.jl` but we encourage to explore these 
other packages to find the one that best fits your use case.

First we install `Plots.jl` and `StatsPlots` backend:

.. code-block:: julia

   Pkg.add("Plots")
   Pkg.add("StatsPlots")   


Here's how a simple line plot works:

.. code-block:: julia

   using Plots 
   gr()  # set the backend to GR

   x = 1:10; y = rand(10, 2) 
   plot(x, y, title = "Two Lines", label = ["Line 1" "Line 2"], lw = 3) 

In VSCode, the plot should appear in a new plot pane.  
We can add labels:

.. code-block:: julia

   xlabel!("x label")
   ylabel!("y label")

To add a line to an existing plot, we mutate it with ``plot!``:

.. code-block:: julia

   z = rand(10)
   plot!(x, z)

Finally we can save to the plot to a file:

.. code-block:: julia

   savefig("myplot.png")

Multiple subplots can be created by:

.. code-block:: julia

   y = rand(10, 4)

   p1 = plot(x, y) # Make a line plot
   p2 = scatter(x, y) # Make a scatter plot
   p3 = plot(x, y, xlabel = "This one is labelled", lw = 3, title = "Subtitle")
   p4 = histogram(x, y) # Four histograms each with 10 points? Why not!
   plot(p1, p2, p3, p4, layout = (2, 2), legend = false)


.. type-along:: Visualizing the Penguin dataset

   First we make sure to have the packages installed and set the backend to GR:

   .. code-block::

      using Pkg
      Pkg.add("Plots")
      Pkg.add("StatsPlots")
      gr()

   For the Penguin dataset it is more appropriate to use scatter plots, for example:

   .. code-block:: julia

      scatter(df[!, :bill_length_mm], df[!, :bill_depth_mm])

   We can adjust the markers by `this list of named colors <https://juliagraphics.github.io/Colors.jl/stable/namedcolors/>`_
   and `this list of marker types <https://docs.juliaplots.org/latest/generated/unicodeplots/#unicodeplots-ref13>`_:

   .. code-block:: julia

      scatter(df[!, :bill_length_mm], df[!, :bill_depth_mm], marker = :hexagon, color = :magenta)

   We can also change the plot theme according to `this list of themes <https://docs.juliaplots.org/latest/generated/plotthemes/>`_, 
   for example:

   .. code-block::

      theme(:dark)
      # then re-execute the scatter function

   We can add a dimension to the plot by grouping by another column. Let's see if 
   the different penguin species can be distiguished based on their bill length 
   and bill depth. We also set different marker shapes and colors based on the 
   grouping, and adjust the markersize and transparency (``alpha``):

   .. code-block:: julia

      scatter(df[!, :bill_length_mm],
              df[!, :bill_depth_mm], 
              xlabel = "bill length (mm)",
              ylabel = "bill depth (g)",
              group = df[!, :species],
              marker = [:circle :ltriangle :star5],
              color = [:magenta :springgreen :yellow],
              markersize = 5,
              alpha = 0.8
              )

   The ``scatter`` function comes from the base `Plots` package. `StatsPlots` provides
   many other types of plot types, for example ``density``. To use dataframes with `StatsPlots`
   we need to use the ``@df`` macro which allows passing columns as symbols (this can also be used 
   for ``scatter`` and other plot functions):

   .. code-block:: julia

      @df df density(:flipper_length_mm,
                     xlabel = "flipper length (mm)",
                     group = :species,
                     color = [:magenta :springgreen :yellow],
                     )


Machine learning in Julia
-------------------------

Despite being a relatively new language, Julia already has a strong and rapidly expanding 
ecosystem of libraries for machine learning and deep learning. A fundamental advantage of Julia for ML 
that it solves the two-language problem - there is no need for different languages for the 
user-facing framework and the backend heavy-lifting (like for most other DL frameworks).

A particular focus in the Julia approach to ML is `"scientific machine learning" (SciML) <https://sciml.ai/>`_ 
(a.k.a. physics-informed learning), i.e. machine learning which incorporates scientific models into 
the learning process instead of relying only on data. The core principle of SciML is `differentiable 
programming` - the ability to automatically differentiate any code and thus incorporate it into 
Flux models.

However, Julia is still behind frameworks like PyTorch and Tensorflow/Keras in terms of documentation and API design.

Traditional machine learning
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Julia has packages for traditional (non-deep) machine learning:

- `ScikitLearn.jl <https://scikitlearnjl.readthedocs.io/en/latest/>`_ is a port of the popular Python package.
- `MLJ.jl <https://alan-turing-institute.github.io/MLJ.jl/dev/>`_ provides a common interface 
  and meta-algorithms for selecting, tuning, evaluating, composing and comparing over 150 machine learning models.


Flux.jl
^^^^^^^

Flux comes "batteries-included" with many useful tools built in, but also enables the user to 
write own Julia code for DL components.

- Flux has relatively few explicit APIs for features like regularisation or embeddings. 
- All of Flux is straightforward Julia code and. It can be worth to inspect it build own parts if needed.
- Flux works well with other Julia libraries, like dataframes, images and differential equation solvers.
  One can build complex data processing pipelines that integrate Flux models.


Training a model
~~~~~~~~~~~~~~~~

To train a model we need four things:

- A objective function, that evaluates how well a model is doing given
  some input data.
- The trainable parameters of the model.
- A collection of data points that will be provided to the objective
  function.
- An optimiser that will update the model parameters appropriately.




Exercises
---------


.. exercise:: Create a custom plotting function

   Convert the final ``scatter`` plot in the type-along section "Visualizing the Penguin dataset"
   and convert it into a ``create_scatterplot`` function: 
   
   - The function should take as arguments a dataframe and two column symbols. 
   - Use the ``minimum()`` and ``maximum()`` functions to automatically set the x-range of the plot 
     using the ``xlim = (xmin, xmax)`` argument to ``scatter()``.
   - If you have time, try grouping the data by ``:island`` or ``:sex`` instead of ``:species`` 
     (keep in mind that you may need to adjust the number of marker symbols and colors).
   - If you have more time, play around with the plot appearance using ``theme()`` and the marker symbols and colors.

   .. solution::

      WRITEME

.. exercise::

   Start from the neural network we trained to identify penguins, and try adding 
   the following layers one by one and see if the predictive ability improves:

   - dense layer
   - ...
  

See also
--------

- `Best Julia Data Manipulation packages combo 2020-09 <https://www.youtube.com/watch?v=q_P2H_ZXVxI>`__
-  Many interesting datasets are available in Julia through the 
   `RDatasets <https://github.com/JuliaStats/RDatasets.jl>`_ package.
   For instance:

   .. code-block:: julia

      Pkg.add("RDatasets")
      using RDatasets
      # load a couple of datasets
      iris = dataset("datasets", "iris")
      neuro = dataset("boot", "neuro")

- `"The Future of Machine Learning and why it looks a lot like Julia" by Logan Kilpatrick <https://towardsdatascience.com/the-future-of-machine-learning-and-why-it-looks-a-lot-like-julia-a0e26b51f6a6>_
