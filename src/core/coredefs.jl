using DimensionalData

using DimensionalData: @dim, AbDimArray, hasdim, Dimension, IndependentDim
using Dates

Time = DimensionalData.Ti

export At, Between, Near # Selectors from DimensionalArrays.jl
export hasdim, AbDimArray, DimensionalArray
export get_var_as_dimarray, allkeys
export Time, Lon, Lat, dims, Coord, Hei
export EqArea, Grid, spacestructure, wrap_lon

@dim Lon IndependentDim "Longitude" "lon"
@dim Lat IndependentDim "Latitude" "lat"
@dim Coord IndependentDim "Coordinates"
@dim Hei IndependentDim "Height" "height"

ALLDIMS = (Lon, Lat, Time, Hei, Coord)

const COMMONNAMES = Dict(
    "lat" => Lat,
    "latitude" => Lat,
    "lon" => Lon,
    "long" => Lon,
    "longitude" => Lon,
    "time" => Time,
    "height" => Hei,
)

# the trait EqArea is for equal area grids. Functions can use the `spacestructure` and
# dispatch on `EqArea` or other types while still being type-stable
struct EqArea end
struct Grid end
spacestructure(a::AbDimArray) = spacestructure(dims(a))
function spacestructure(dims)
    if hasdim(dims, Coord)
        EqArea()
    elseif hasdim(dims, Lon) || hasdim(dims, Lat)
        Grid()
    else
        nothing
    end
end

# ClimArray type
export ClimArray
struct ClimArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na<:AbstractString,Me} <: AbstractDimensionalArray{T,N,D,A}
    data::A
    dims::D
    refdims::R
    name::Na
    attrib::Me
end

"""
    ClimArray(A, dims::Tuple; name = "", attrib = nothing)

`ClimArray` is a simple wrapper of a standard dimensional array from DimensionalData.jl
bundled with an extra `attrib` field (typically a dictionary) that holds general attributes.

`ClimArray` is created by passing in standard array data `A` and a tuple of dimensions `dims`.
"""
ClimArray(A::AbstractArray, dims::Tuple; refdims=(), name="", attrib=nothing) =
ClimArray(A, DimensionalData.formatdims(A, dims), refdims, name, attrib)

rebuild(A::ClimArray, data, dims::Tuple, refdims, name, attrib = A.attrib) =
ClimArray(data, dims, refdims, name, attrib)

Base.parent(A::ClimArray) = A.data
Base.@propagate_inbounds Base.setindex!(A::ClimArray, x, I) = setindex!(data(A), x, I...)

DimensionalData.metadata(A::ClimArray) = A.attrib
DimensionalData.rebuild(A::ClimArray, data, dims::Tuple=dims(A), refdims=DimensionalData.refdims(A),
name="", attrib=nothing) = ClimArray(data, dims, refdims, name, attrib)
DimensionalData.basetypeof(::ClimArray) = ClimArray

# Remove reference dims from printing, and show attributes if any
function Base.show(io::IO, A::ClimArray)
    l = nameof(typeof(A))
    printstyled(io, nameof(typeof(A)); color=:blue)
    if A.name != ""
        print(io, " (named ")
        printstyled(io, A.name; color=:blue)
        print(io, ")")
    end

    print(io, " with dimensions:\n")
    for d in dims(A)
        print(io, " ", d, "\n")
    end
    if !isnothing(A.attrib)
        print(io, "and")
        printstyled(io, " attributes: "; color=:magenta)
        show(io, MIME"text/plain"(), A.attrib)
        print(io, '\n')
    end
    print(io, "and")
    printstyled(io, " data: "; color=:green)
    dataA = data(A)
    print(io, summary(dataA), "\n")
    DimensionalData.custom_show(io, data(A))
end