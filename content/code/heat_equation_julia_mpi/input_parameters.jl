import YAML

function input_parameters(ARGS)

    path = ARGS[1]
    data = YAML.load(open(path))

    key = "grids"
    Nx = data[key]["nx"]
    Ny = data[key]["ny"]

    key = "processes"
    NPROCX = data[key]["nprocx"]
    NPROCY = data[key]["nprocy"]

    key = "steps"
    MAX_STEPS = data[key]["max_step"]

    key = "output"
    filename = data[key]["filename"]
    workdir = dirname(path)
    output_path = joinpath(workdir, basename(filename))

    println()
    println("Loading: ", path)
    println("Output: ", output_path)

    return Int64[Nx, Ny, NPROCX, NPROCY, MAX_STEPS], output_path

end
