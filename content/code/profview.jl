function lap2d!(u, unew)
    M, N = size(u)
    for j in 2:N-1
        for i in 2:M-1
            unew[i,j] = 0.25 * (u[i+1,j] + u[i-1,j] + u[i,j+1] + u[i,j-1])
        end 
    end
end

function setup(N=4096, M=4096)
    u = zeros(M, N)
    u[1,:] = u[end,:] = u[:,1] = u[:,end] .= 10.0
    unew = copy(u);
    return u, unew
end

u, unew = setup()

for i in 1:1000
    lap2d!(u, unew)
    # copy new computed field to old array
    global u = copy(unew)
end

using Pkg

using Plots
heatmap(u)


Pkg.activate()
Pkg.add("BenchmarkTools")

using BenchmarkTools
@benchmark lap2d!(u, unew)

Pkg.add("Profile")
using Profile

Profile.clear() # clear backtraces from earlier runs
@profile lap2d!(u, unew)
Profile.print()

Pkg.add("ProfileView")
using ProfileView

#ProfileView.@profview lap2d!(u, unew)
VSCodeServer.@profview lap2d!(u, unew)


