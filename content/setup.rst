Setup
=====

Please follow the instructions on this page to install both **Julia** and **VS Code** with the Julia 
plugin on your machine.

Installing Julia
----------------

There are two ways to install Julia:

1. Downloading an `installer <https://julialang.org/downloads/#current_stable_release>`__ 
   for your operating system for the latest stable Julia version.
2. Using `Juliaup <https://github.com/JuliaLang/juliaup>`__, the Julia version manager.

Option 2 is (as of October 2022) the recommended installation method on Windows, and while 
`juliaup` is marked as a pre-release on MacOS and Linux it already works smoothly there too.

The benefit of `juliaup` is that it allows users to install specific Julia versions, it alerts 
users when new Julia versions are released and it provides a convenient Julia release channel 
abstraction.

Both installation methods are documented here. If you are on Windows we recommend using 
`juliaup`. If you are on MacOS or Linux, choose the installation method you feel most 
comfortable with.

1. Using the Julia installer
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First download the latest stable release of Julia for your operating system 
`from the julialang.org website <https://julialang.org/downloads/#current_stable_release>`_.

.. figure:: img/installers.png
   :align: center

Follow the instructions to complete the installation.

Platform-specific instructions can be found at 
https://julialang.org/downloads/platform/. It is convenient to be able 
to run Julia from the command line, so follow the instructions for 
"adding Julia to PATH".  
For Windows users who do not already have a terminal installed,
we recommend to install the 
`Windows Terminal from the Microsoft Store <https://www.microsoft.com/sv-se/p/windows-terminal/9n0dx20hk701?rtc=1&activetab=pivot:overviewtab>`_.


2. Using Juliaup      
^^^^^^^^^^^^^^^^

Full instructions can be found at https://github.com/JuliaLang/juliaup.

In short:
- On Windows you can install Julia and Juliaup either through the 
  `Windows store <https://www.microsoft.com/store/apps/9NJNWW8PVKMN>`__ or on a command line 
  by executing `winget install julia -s msstore`.
- On MacOS or Linux, type `curl -fsSL https://install.julialang.org | sh` on a command line 
  and follow the instructions.  

Checking your installation
^^^^^^^^^^^^^^^^^^^^^^^^^^

Regardless of how you installed Julia, please ensure that you can open the Julia REPL by
typing ``julia`` on the command line in a terminal, or by clicking the Julia 
icon on your Desktop or Applications folder. You should
see something like in the image below (nevermind the version number).

.. figure:: img/repl.png
   :align: center

To exit the REPL again, hit ``CTRL-d`` or type ``exit()``.

Installing Visual Studio Code
-----------------------------

https://code.visualstudio.com/Download

Installing the VSCode Julia extension
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Click the Extensions button on the left-side menu, type `Julia` and 
click `Install` to install the Julia extension.

.. figure:: img/vscode_extensionbutton.png
   :align: center
   :scale: 50 %

.. figure:: img/vscode_juliaextension.png
   :align: center
   :scale: 50 %

You now need to configure the Julia extension and set the path 
to the Julia executable. Click the cogwheel button next to the Julia 
extension:

.. figure:: img/vscode_extensionconfig.png
   :align: center
   :scale: 50 %

Then find the "Julia: Executable Path" field:

.. figure:: img/vscode_execpath.png
   :align: center
   :scale: 50 %

In this field enter the path to the Julia executable that you have installed.

If you are curious, scroll through the other possible configuration settings!

(Optional) Installing JupyterLab and a Julia kernel
---------------------------------------------------

JupyterLab can most easily be installed through the full
Anaconda distribution of Python packages or the minimal
Miniconda distribution.

To install Anaconda, visit
https://www.anaconda.com/products/individual , download an installer
for your operating system and follow the instructions. JupyterLab and
an IPython kernel are included in the distribution.

To install Miniconda, visit
https://docs.conda.io/en/latest/miniconda.html , download an installer
for your operating system and follow the instructions.  After
activating a ``conda`` environment in your terminal, you can install
JupyterLab with the command ``conda install jupyterlab``.

Add Julia to JupyterLab
^^^^^^^^^^^^^^^^^^^^^^^

To be able to use a Julia kernel in a Jupyter notebook you need to
install the ``IJulia`` Julia package. Open the Julia REPL and type::

  using Pkg
  Pkg.add("IJulia")

Create a Julia notebook
^^^^^^^^^^^^^^^^^^^^^^^

Now you should be able to open up a JupyterLab session by typing
``jupyter-lab`` in a terminal, and create a Julia notebook by clicking
on Julia in the JupyterLab Launcher or by selecting File > New > Notebook
and selecting a Julia kernel in the drop-down menu that appears.

