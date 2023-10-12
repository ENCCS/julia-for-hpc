using Printf

function write_to_disk(x::Array{Float64,1}, x_domains::Int, y_domains::Int,
                        xcell::Int, ycell::Int, temp1::Float64, filename:: String)
    f = open(filename, "w")

    # 1. add first x-boundary
    for k = 1:ycell*y_domains + 2
        print(f, @sprintf("%15.11f", temp1))
        print(f, "\t")
    end

    # 2. add internal cells + y-boundaries
    c = 0
    for k = 1:x_domains
        for m = 1:xcell
            for i = 1:y_domains
                for j = 1:ycell
                    c += 1
                    if (i==1 && j==1)
                        print(f, @sprintf("%15.11f", temp1))
                        print(f, "\t")
                    end
                    print(f, @sprintf("%15.11f", x[(i-1) * x_domains * xcell * ycell +
                                         (k-1) * xcell * ycell + (j-1) * xcell + m]))
                    print(f, "\t")
                    if (i==y_domains && j==ycell)
                        print(f, @sprintf("%15.11f", temp1))
                        print(f, "\t")
                    end
                end
            end
        end
    end

    # 3. add second x-boundary
    for k = 1:ycell*y_domains + 2
        print(f, @sprintf("%15.11f", temp1))
        if (k < ycell*y_domains + 2)
            print(f, "\t")
        end
    end
    close(f)
end

