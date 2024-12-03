# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
sys.path.insert(0, os.path.abspath('.'))


# -- Project information -----------------------------------------------------

project = 'Julia for High-Performance Scientific Computing'
copyright = '2022, EuroCC National Competence Center Sweden'
author = 'Kjartan Thor Wikfeldt'
github_user = 'enccs'
github_repo_name = 'Julia-for-HPC'  # auto-detected from dirname if blank
github_version = 'master'
conf_py_path = '/content/' # with leading and trailing slash

# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    # githubpages just adds a .nojekyll file
    "sphinx.ext.githubpages",
    "sphinx_lesson",
    #'sphinx.ext.intersphinx',
    #"sphinxcontrib.bibtex",
    "sphinx.ext.todo",
]

# configure sphinxcontrib.bibtex
#bibtex_bibfiles = ["bibliography.bib"]

# Settings for myst_nb:
# https://myst-nb.readthedocs.io/en/latest/use/execute.html#triggering-notebook-execution
# jupyter_execute_notebooks = "off"
# jupyter_execute_notebooks = "auto"   # *only* execute if at least one output is missing.
# jupyter_execute_notebooks = "force"
jupyter_execute_notebooks = "cache"

# Add any paths that contain templates here, relative to this directory.
# templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = [
    "code*",
    "README*",
    "_build",
    "Thumbs.db",
    ".DS_Store",
    "jupyter_execute",
    "*venv*",
]


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"
html_logo = "img/ENCCS.jpg"
html_favicon = "img/favicon.ico"
html_title = project

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["css"]

# HTML context:
from os.path import dirname, realpath, basename

html_context = {
    "display_github": True,
    "github_user": github_user,
    # Auto-detect directory name.  This can break, but
    # useful as a default.
    "github_repo": github_repo_name or basename(dirname(realpath(__file__))),
    "github_version": github_version,
    "conf_py_path": conf_py_path,
}

todo_include_todos = True

# Intersphinx mapping.  For example, with this you can use
# :py:mod:`multiprocessing` to link straight to the Python docs of that module.
# List all available references:
#   python -msphinx.ext.intersphinx https://docs.python.org/3/objects.inv
# intersphinx_mapping = {
#    #'python': ('https://docs.python.org/3', None),
#    #'sphinx': ('https://www.sphinx-doc.org/', None),
#    }

# Our own customisation
#from custom import DIRECTIVES, cmake_glossary


# the epilog
#rst_epilog = f"""
#.. role:: red
#.. role:: blue
#.. _CMake: https://cmake.org/cmake/help/v3.19/
#
#{cmake_glossary()}
#"""




# add few new directives
from sphinx_lesson.directives import _BaseCRDirective

class TypealongDirective(_BaseCRDirective):
    extra_classes = ["toggle-shown", "dropdown"]

class ParametersDirective(_BaseCRDirective):
    extra_classes = ["dropdown"]

class DemoDirective(_BaseCRDirective):
    extra_classes = ["toggle-shown", "dropdown"]

DIRECTIVES = [TypealongDirective, ParametersDirective, DemoDirective]




def setup(app):
#    for obj in DIRECTIVES:
#        app.add_directive(obj.get_cssname(), obj)
    app.add_css_file("overrides.css")

import os
if os.environ.get('GITHUB_REF', '') == 'refs/heads/main':
    html_js_files = [
        ('https://plausible.io/js/script.js', {"data-domain": "enccs.github.io/julia-for-hpc", "defer": "\
defer"}),
    ]
    
