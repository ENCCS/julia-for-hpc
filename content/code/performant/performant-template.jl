u = zeros(256, 256)
unew = copy(u)

function lap2d!(u, unew)
    M, N = size(u)
    for j in 2:N-1
        for i in 2:M-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end
    end
end

function setup(N=256, M=256)
    local u = zeros(M, N)
    # set boundary conditions
    u[1,:] = u[end,:] = u[:,1] = u[:,end] .= 2.0
    local unew = copy(u);
    return u, unew
end

u, unew = setup()
for i in 1:1000
    lap2d!(u, unew)
    # copy new computed field to old array
    global u= copy(unew)
end


# visualization of computional results
using Pkg
Pkg.add("Plots")
using Plots

heatmap(u)
savefig("./performant-heatmap.png")


## benchmarking
Pkg.add("BenchmarkTools")
using BenchmarkTools

bench_results = @benchmark lap2d!(u, unew)
typeof(bench_results)
println(minimum(bench_results.times))


