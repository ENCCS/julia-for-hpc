.. _data_science:

Data science and machine learning
=================================

.. questions::

   - How can I manipulate and wrangle data in Julia?
   - Can I use Julia for machine learning?
     
.. instructor-note::

   - 20 min teaching
   - 30 min exercises


Working with data
-----------------

We will now explore a Julian approach to a use case common to 
many scientific disciplines: manipulating data, visualization 
and machine learning.
Julia is a good language to use for data science problems as
it will perform well and alleviate the need to translate
computationally demanding parts to another language.

Here we will learn how to work with data using 
the DataFrames package, visualize it with the Plots and StatsPlots
packages and get a flavor for how to set up a 
deep learning workflow using the Flux package.

Download a dataset
^^^^^^^^^^^^^^^^^^

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
^^^^^^^^^^

The `DataFrames.jl <https://dataframes.juliadata.org/stable/>`_ 
package is Julia's version of the ``pandas`` library in Python and 
the ``data.frame()`` function in R. We will use it here to 
analyze the penguins dataset, but first we need to install it:

.. code-block:: julia

   Pkg.add("DataFrames")
   using DataFrames


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


.. type-along:: Dataframes

   We now create a dataframe containing the PalmerPenguins dataset.
   Note that the ``table`` variable is of type ``CSV.File``; the 
   PalmerPenguins package uses the `CSV.jl <https://csv.juliadata.org/stable/>`_ 
   package for fast loading of data. Note further that ``DataFrame`` can 
   accept a ``CSV.File`` object and read it into a dataframe!

   We will do this in a new script ``datascience.jl`` in the same directory as 
   the ``datascience`` environment created in 
   :ref:`this earlier exercise <datascience_env>`. We can execute the expressions 
   in the script line-by-line by hitting `Shift-Enter`.
   
   .. code-block:: julia
   
      using PalmerPenguins
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

   We can see in the output of ``describe`` that the element type of 
   all the columns is a union of ``missing`` and a numeric type. This
   implies that our dataset contains missing values.
   
   We can remove these by the ``dropmissing`` or ``dropmissing!`` functions
   (what is the difference between them?):
   
   .. code-block:: julia
   
      dropmissing!(df)
   


The main features we are interested in for each penguin observation are 
`bill_length_mm`, `bill_depth_mm`, `flipper_length_mm` and `body_mass_g`.
What the first three features mean is illustrated in the picture below.

.. figure:: img/culmen_depth.png
   :align: center

   Artwork by @allison_horst



Plotting
^^^^^^^^

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

   p1 = plot(x, y); # Make a line plot
   p2 = scatter(x, y); # Make a scatter plot
   p3 = plot(x, y, xlabel = "This one is labelled", lw = 3, title = "Subtitle");
   p4 = histogram(x, y); # Four histograms each with 10 points? Why not!
   plot(p1, p2, p3, p4, layout = (2, 2), legend = false)


.. type-along:: Visualizing the Penguin dataset

   First load ``Plots`` and set the backend to GR (precompilation of Plots 
   might take some time):

   .. code-block:: julia

      using Plots
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
              color = [:magenta :springgreen :blue],
              markersize = 5,
              alpha = 0.8
              )

   .. figure:: img/penguin_scatter.png
      :align: center
      :scale: 50%

   The ``scatter`` function comes from the base `Plots` package. `StatsPlots` provides
   many other types of plot types, for example ``density``. To use dataframes with `StatsPlots`
   we need to use the ``@df`` macro which allows passing columns as symbols (this can also be used 
   for ``scatter`` and other plot functions):

   .. code-block:: julia

      using StatsPlots        

      @df df density(:flipper_length_mm,
                     xlabel = "flipper length (mm)",
                     group = :species,
                     color = [:magenta :springgreen :blue],
                     )

   .. figure:: img/penguin_density.png
      :align: center
      :scale: 50%


Machine learning in Julia
-------------------------

Despite being a relatively new language, Julia already has a strong and rapidly expanding 
ecosystem of libraries for machine learning and deep learning. A fundamental advantage of Julia for ML 
is that it solves the two-language problem - there is no need for different languages for the 
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

We will use a few utility functions from ``MLJ.jl`` in our deep learning 
exercise below, so we will need to add it to our environment:

.. code-block:: julia

   using Pkg
   Pkg.add("MLJ")

Deep learning
^^^^^^^^^^^^^

`Flux.jl <https://fluxml.ai/>`_ comes "batteries-included" with many useful tools 
built in, but also enables the user to write own Julia code for DL components.

- Flux has relatively few explicit APIs for features like regularisation or embeddings. 
- All of Flux is straightforward Julia code and it can be worth to inspect and extend it if needed.
- Flux works well with other Julia libraries, like dataframes, images and differential equation solvers.
  One can build complex data processing pipelines that integrate Flux models.

To install Flux:

.. code-block:: julia

   using Pkg
   Pkg.add("Flux")


.. type-along:: Training a deep neural network to classify penguins

   To train a model we need four things:

   - A collection of data points that will be provided to the objective
     function.
   - A objective (cost or loss) function, that evaluates how well a model 
     is doing given some input data.
   - The definition of a model and access to its trainable parameters.
   - An optimiser that will update the model parameters appropriately.

   First we import the required modules and load the data:

   .. code-block:: julia

      using Flux
      using MLJ: partition, ConfusionMatrix
      using DataFrames
      using PalmerPenguins

      table = PalmerPenguins.load()
      df = DataFrame(table)
      dropmissing!(df)

   We can now preprocess our dataset to make it suitable for training a network:

   .. code-block:: julia

      # select feature and label columns
      X = select(df, Not([:species, :sex, :island]))
      Y = df[:, :species]
      
      # split into training and testing parts
      (xtrain, xtest), (ytrain, ytest) = partition((X, Y), 0.8, shuffle=true, rng=123, multi=true)
      
      # use single precision and transpose arrays
      xtrain, xtest = Float32.(Array(xtrain)'), Float32.(Array(xtest)')
      
      # one-hot encoding
      ytrain = Flux.onehotbatch(ytrain, ["Adelie", "Gentoo", "Chinstrap"])
      ytest = Flux.onehotbatch(ytest, ["Adelie", "Gentoo", "Chinstrap"])
      
      # count penguin classes to see if it's balanced
      sum(ytrain, dims=2)
      sum(ytest, dims=2)

   Next up is the loss function which will be minimized during the training.
   We also define another function which will give us the accuracy of the model:

   .. code-block:: julia

      # we use the cross-entropy loss function typically used for classification
      loss(x, y) = Flux.crossentropy(model(x), y)

      # onecold (opposite to onehot) gives back the original representation
      function accuracy(x, y)
          return sum(Flux.onecold(model(x)) .== Flux.onecold(y)) / size(y, 2)
      end

   ``model`` will be our neural network, so we go ahead and define it:

   .. code-block:: julia

      n_features, n_classes, n_neurons = 4, 3, 10
      model = Chain(
              Dense(n_features, n_neurons, sigmoid),
              Dense(n_neurons, n_classes),
              softmax)  

   We now define an anonymous callback function to pass into the training function 
   to monitor the progress, select the standard ADAM optimizer, and extract the parameters 
   of the model:

   .. code-block:: julia

      callback = () -> @show(loss(xtrain, ytrain))
      opt = ADAM()
      θ = Flux.params(model)

   Before training the model, let's have a look at some initial predictions 
   and the accuracy:

   .. code-block:: julia

      # predictions before training
      model(xtrain[:,1:5])
      ytrain[:,1:5]
      # accuracy before training
      accuracy(xtrain, ytrain)
      accuracy(xtest, ytest)

   Finally we are ready to train the model. Let's run 100 epochs:

   .. code-block:: julia

      # the training data and the labels can be passed as tuples to train!
      for i in 1:10
          Flux.train!(loss, θ, [(xtrain, ytrain)], opt, cb = Flux.throttle(callback, 1))
      end

      # check final accuracy
      accuracy(xtrain, ytrain)
      accuracy(xtest, ytest)

   The performance of the model is probably somewhat underwhelming, but you will 
   fix that in an exercise below!

   We finally create a confusion matrix to quantify the performance of the model:

   .. code-block:: julia

      predicted_species = Flux.onecold(model(xtest), ["Adelie", "Gentoo", "Chinstrap"])
      true_species = Flux.onecold(ytest, ["Adelie", "Gentoo", "Chinstrap"])
      ConfusionMatrix()(predicted_species, true_species)


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

      .. code-block:: julia

         function create_scatterplot(df, col1, col2, groupby)
             xmin, xmax = minimum(df[:, col1]), maximum(df[:, col1])
             # markers and colors to use for the groups
             markers = [:circle :ltriangle :star5 :rect :diamond :hexagon]
             colors = [:magenta :springgreen :blue :coral2 :gold3 :purple]
             # number of unique groups can't be larger than the number of colors/markers
             ngroups = length(unique(df[:, groupby]))
             @assert ngroups <= length(colors)
         
             scatter(df[!, col1],
                     df[!, col2],
                     xlabel = col1,
                     ylabel = col2,
                     xlim = (xmin, xmax),
                     group = df[!, groupby],
                     marker = markers[:, 1:ngroups],
                     color = colors[:, 1:ngroups],
                     markersize = 5,
                     alpha = 0.8
                     )
         end    

         create_scatterplot(df, :bill_length_mm, :body_mass_g, :sex)
         create_scatterplot(df, :flipper_length_mm, :body_mass_g, :island)  


.. _DLexercise:

.. exercise:: Improve the deep learning model

   Improve the performance of the neural network we trained above! 
   The network is not improving much because of the large numerical 
   range of the input features (from around 15 to around 6000) combined 
   with the fact that we use a ``sigmoid`` activation function. A standard 
   method in machine learning is to normalize features by "batch 
   normalization". Replace the network definition with the following and 
   see if the performance improves:
   
   .. code-block:: julia

      n_features, n_classes, n_neurons = 4, 3, 10
      model = Chain(
                 Dense(n_features, n_neurons),
                 BatchNorm(n_neurons, relu),
                 Dense(n_neurons, n_classes),
                 softmax)  

   Performance is usually better also if we, instead of training on the entire 
   dataset at once, divide the training data into "minibatches" and update 
   the network weights on each minibatch separately.
   First define the following function:

   .. code-block:: julia

      using StatsBase: sample

      function create_minibatches(xtrain, ytrain, batch_size=32, n_batch=10)
          minibatches = Tuple[]
          for i in 1:n_batch
              randinds = sample(1:size(xtrain, 2), batch_size)
              push!(minibatches, (xtrain[:, randinds], ytrain[:,randinds]))
          end
          return minibatches
      end

   and then create the minibatches by calling the function.  

   You will not need to manually loop over the minibatches, simply pass 
   the ``minibatches`` vector of tuples to the ``Flux.train!`` function. 
   Does this make a difference?

   .. solution:: 

      .. code-block:: julia

         function create_minibatches(xtrain, ytrain, batch_size=32, n_batch=10)
             minibatches = Tuple[]
             for i in 1:n_batch
                 randinds = sample(1:size(xtrain, 2), batch_size)
                 push!(minibatches, (xtrain[:, randinds], ytrain[:,randinds]))
             end
             return minibatches
         end
   
         n_features, n_classes, n_neurons = 4, 3, 10
         model = Chain(
                 Dense(n_features, n_neurons),
                 BatchNorm(n_neurons, relu),
                 Dense(n_neurons, n_classes),
                 softmax)
   
         callback = () -> @show(loss(xtrain, ytrain))
         opt = ADAM()
         θ = Flux.params(model)
   
         minibatches = create_minibatches(xtrain, ytrain)
         for i in 1:100
             # train on minibatches
             Flux.train!(loss, θ, minibatches, opt, cb = Flux.throttle(callback, 1));
         end
   
         accuracy(xtrain, ytrain)
         # 0.9849624060150376
         accuracy(xtest, ytest)
         # 0.9850746268656716
   
         predicted_species = Flux.onecold(model(xtest), ["Adelie", "Gentoo", "Chinstrap"])
         true_species = Flux.onecold(ytest, ["Adelie", "Gentoo", "Chinstrap"])
         ConfusionMatrix()(predicted_species, true_species)
   
      .. figure:: img/confusion_matrix.png
         :scale: 40 %

      Much better!

See also
--------

-  Many interesting datasets are available in Julia through the 
   `RDatasets <https://github.com/JuliaStats/RDatasets.jl>`_ package.
   For instance:

   .. code-block:: julia

      Pkg.add("RDatasets")
      using RDatasets
      # load a couple of datasets
      iris = dataset("datasets", "iris")
      neuro = dataset("boot", "neuro")

- `"The Future of Machine Learning and why it looks a lot like Julia" by Logan Kilpatrick <https://towardsdatascience.com/the-future-of-machine-learning-and-why-it-looks-a-lot-like-julia-a0e26b51f6a6>`_
- `Deep Learning with Flux - A 60 Minute Blitz <https://fluxml.ai/tutorials/2020/09/15/deep-learning-flux.html>`__