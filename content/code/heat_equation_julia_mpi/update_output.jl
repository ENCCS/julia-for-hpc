using Printf

function updateBound!(u::Array{Float64,2}, size_total_x, size_total_y, neighbors, comm,
                       me, xs, ys, xe, ye, xcell, ycell, nproc)

    mep1 = me + 1

    #assume, to start with, that this process is not going to receive anything
    rreq = Dict{String, MPI.Request}(
                                "N" => MPI.REQUEST_NULL,
                                "S" => MPI.REQUEST_NULL,
                                "E" => MPI.REQUEST_NULL,
                                "W" => MPI.REQUEST_NULL
                                )
    recv = Dict{String, Array{Float64,1}}()
    ghost_boundaries = Dict{String, Any}(
                                "N" => (xe[mep1]+1, ys[mep1]:ye[mep1]),
                                "S" => (xs[mep1]-1, ys[mep1]:ye[mep1]),
                                "E" => (xs[mep1]:xe[mep1], ye[mep1]+1),
                                "W" => (xs[mep1]:xe[mep1], ys[mep1]-1)
                                )
    is_receiving = Dict{String, Bool}("N" => false, "S" => false, "E" => false, "W" => false)

    #send
    neighbors["N"] >=0 && MPI.Isend(u[xe[mep1], ys[mep1]:ye[mep1]], neighbors["N"], me + 40, comm)
    neighbors["S"] >=0 && MPI.Isend(u[xs[mep1], ys[mep1]:ye[mep1]], neighbors["S"], me + 50, comm)
    neighbors["E"] >=0 && MPI.Isend(u[xs[mep1]:xe[mep1], ye[mep1]], neighbors["E"], me + 60, comm)
    neighbors["W"] >=0 && MPI.Isend(u[xs[mep1]:xe[mep1], ys[mep1]], neighbors["W"], me + 70, comm)

    #receive
    if (neighbors["N"] >= 0)
        recv["N"] = Array{Float64,1}(undef, ycell)
        is_receiving["N"] = true
        rreq["N"] = MPI.Irecv!(recv["N"], neighbors["N"], neighbors["N"] + 50, comm)
    end
    if (neighbors["S"] >= 0)
        recv["S"] = Array{Float64,1}(undef, ycell)
        is_receiving["S"] = true
        rreq["S"] = MPI.Irecv!(recv["S"], neighbors["S"], neighbors["S"] + 40, comm)
    end
    if (neighbors["E"] >= 0)
        recv["E"] = Array{Float64,1}(undef, xcell)
        is_receiving["E"] = true
        rreq["E"] = MPI.Irecv!(recv["E"], neighbors["E"], neighbors["E"] + 70, comm)
    end
    if (neighbors["W"] >= 0)
        recv["W"] = Array{Float64,1}(undef, xcell)
        is_receiving["W"] = true
        rreq["W"] = MPI.Irecv!(recv["W"], neighbors["W"], neighbors["W"] + 60, comm)
    end

    MPI.Waitall!([rreq[k] for k in keys(rreq)])
    for (k, v) in is_receiving
        if v
            u[ghost_boundaries[k][1], ghost_boundaries[k][2]] = recv[k]
        end
    end
end


function updateCellValue!(u0::Array{Float64,2}, u::Array{Float64,2},
    size_total_x::Int, size_total_y::Int, dt::Float64, hx::Float64, hy::Float64,
    me::Int, xs::Array{Int,1}, ys::Array{Int,1}, xe::Array{Int,1}, ye::Array{Int,1},
    nproc::Int, k0::Float64)

    mep1 = me + 1

    # column major
    for j = ys[mep1]:ye[mep1]
        for i = xs[mep1]:xe[mep1]
            u[i,j] =0.25 * (u0[i-1,j] + u0[i+1,j] + u0[i,j-1] + u0[i,j+1])
	    u0[i,j] = u[i,j]
    	end
    end
end


function write_to_disk(x::Array{Float64,1}, x_domains::Int, y_domains::Int,
                        xcell::Int, ycell::Int, temp_high::Float64, filename:: String)
    f = open(filename, "w")

    #add first x-boundary
    for k = 1:ycell*y_domains + 2
        print(f, @sprintf("%15.11f", temp_high))
        print(f, "\t")
    end

    #then, add internal cells + y-boundaries
    c = 0
    for k = 1:x_domains
        for m = 1:xcell
            for i = 1:y_domains
                for j = 1:ycell
                    c += 1
                    if (i==1 && j==1)
                        print(f, @sprintf("%15.11f", temp_high))
                        print(f, "\t")
                    end
                    print(f, @sprintf("%15.11f", x[(i-1) * x_domains * xcell * ycell +
                                         (k-1) * xcell * ycell + (j-1) * xcell + m]))
                    print(f, "\t")
                    if (i==y_domains && j==ycell)
                        print(f, @sprintf("%15.11f", temp_high))
                        print(f, "\t")
                    end
                end
            end
        end
    end

    #add second x-boundary
    for k = 1:ycell*y_domains + 2
        print(f, @sprintf("%15.11f", temp_high))
        if (k < ycell*y_domains + 2)
            print(f, "\t")
        end
    end
    close(f)
end

