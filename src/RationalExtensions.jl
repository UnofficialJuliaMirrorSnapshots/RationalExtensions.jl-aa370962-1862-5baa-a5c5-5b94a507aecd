__precompile__(true)

module RationalExtensions

import Base.convert,
       Base.promote_rule,
       Base.show,
       Base.norm,
       Base.conj,
       Base.*,
       Base.//,
       Base./,
       Base.+,
       Base.-,
       Base.==

import Primes

export Rad,
       Sqrt,
       AbstractRational

AbstractRational = Union{Rational,Integer}

immutable Rad{S<:AbstractRational,T<:Integer} <: Real
    a::S
    b::S
    n::T
    
    function Rad{S,T}(a::S,b::S,n::T) where {S,T}
        if b == 0 || n == 0
            return new(a,convert(S,0),convert(T,1))
        end
        sgn = sign(n)
        d = Primes.factor(abs(n)) 
        for p in keys(d)
            b *= p^div(d[p],2)
            d[p] = mod(d[p],2)
        end
        n = isempty(d) ? 1 : prod(p^(d[p]) for p in keys(d))
        if sgn * n != 1
            return new(a,b,sgn * n)
        else
            return new(a+b,0,1) 
        end
    end
end

Rad{S<:AbstractRational,T<:Integer}(a::S,b::S,n::T) = Rad{S,T}(a,b,n)
Rad{S<:AbstractRational,U<:AbstractRational,T<:Integer}(a::S,b::U,n::T) = Rad(promote(a,b)...,n)
Rad{S<:AbstractRational,T<:Integer}(a::S,b::S,r::Rational{T}) =
    Rad(a,b//denominator(r),numerator(r)*denominator(r))

Sqrt{T<:Integer}(n::T) = Rad{T,T}(zero(n),one(n),n)
Sqrt(r::Rational) = Rad(0,1,r)
Sqrt(x::Rad) = (x.n == 1 ? Sqrt(b(x)) : throw(InexactError()))
Sqrt(x::AbstractFloat) = sqrt(x)

==(x::Rad{S,T},y::Rad{S,T}) where {S,T} = (x.a,x.b,x.n) == (y.a,y.b,y.n) 

function *(x::Rad,y::Rad) 
    if x.n == y.n 
        return Rad(x.a * y.a + x.b * y.b * x.n, y.a * x.b + y.b * x.a, x.n) 
    elseif x.a == y.a == 0
        return Rad(zero(x.a), x.b * y.b, x.n * y.n)
    else
        error("Error multiplying radicals: radicands must mutiply to give a perfect square")
    end
end

*(x::Bool,y::Rad) = Rad( x * y.a, x * y.b, y.n)
*{T<:AbstractRational}(x::T,y::Rad) = Rad(x * y.a, x * y.b, y.n)
*(x::Rad,y::Bool) = y * x
*{T<:AbstractRational}(x::Rad,y::T) = y * x

function //(x::Rad,y::Rad)
    if x.n == y.n || x.b == 0 || y.b == 0
        return (x.a * y.a + y.a * x.b * Sqrt(x.n) - x.a * y.b * Sqrt(y.n)
                - x.b * y.b * Sqrt(x.n * y.n))//(y.a^2 - y.n * y.b^2)
    else
        error("Division with different radicands not supported")
    end
end

//{T<:AbstractRational}(x::T,y::Rad) = Rad(x,zero(x),one(x)) // y
//{T<:AbstractRational}(x::Rad,y::T) = Rad(x.a//y, x.b//y,x.n)

/(x::Rad,y::Rad) = float(x)/float(y)
/(x::Rad,y::AbstractRational) = convert(typeof(float(y)),x)/float(y)
/{T<:Real}(x::Rad,y::T) = /(promote(x,y)...)
/{T<:Real}(x::T,y::Rad) = /(promote(x,y)...)

function +(x::Rad,y::Rad) 
    if x.n == y.n || x.b == 0
        return Rad(x.a + y.a, x.b+y.b, y.n)    
    elseif y.b == 0
        return Rad(x.a + y.a, x.b, x.n)
    else
        error("Addition with different radicands not supported") 
    end
end

-(x::Rad) = Rad(-x.a,-x.b,x.n)
-(x::Rad,y::Rad) = x + (-y)
+{T<:AbstractRational}(x::Rad,y::T) = Rad(x.a + y, x.b, x.n) 
+{T<:AbstractRational}(x::T,y::Rad) = y + x
-{T<:AbstractRational}(x::Rad,y::T) = x + (-y) 
-{T<:AbstractRational}(x::T,y::Rad) = x + (-y) 

convert{S<:AbstractRational,T<:Integer}(::Type{Rad{S,T}},n::Integer) = Rad(n,zero(n),one(n))
convert{S<:AbstractRational,T<:Integer}(::Type{Rad{S,T}},r::Rational) = Rad(r,zero(r),one(r))
convert(::Type{AbstractFloat}, x::Rad) = float(x.a) + float(x.b) * (sqrt∘float)(x.n)

convert{S,T}(::Type{BigFloat},x::Rad{S,T}) = big(x.a) + big(x.b) * (sqrt∘float)(big(x.n))

convert{S<:AbstractFloat,T,U}(::Type{S},x::Rad{T,U}) = 
    ((a,b,n) -> a + b*(sqrt∘float)(n))(promote(x.a,x.b,x.n)...)

convert(::Type{Bool},x::Rad) = (x.b != 0)
convert{T<:Integer}(::Type{T}, x::Rad) = (x.n == 1 ? convert(T,x.a + x.b) : throw(InexactError()))
convert{S<:AbstractRational,T<:Integer}(::Type{Rad{S,T}},x::Rad) = 
     Rad(convert(S,x.a),convert(S,x.b),convert(T,x.n))

promote_rule{S<:AbstractRational,T<:Integer,U<:Integer}(::Type{Rad{S,T}}, ::Type{U}) = 
     Rad{S,promote_type(T,U)}
promote_rule{S<:AbstractRational,T<:Integer,U<:Integer}(::Type{Rad{S,T}}, ::Type{Rational{U}}) =
     Rad{promote_type(S,U),T}
promote_rule{S<:AbstractRational,T<:Integer,U<:AbstractRational,V<:Integer}(::Type{Rad{S,T}},
     ::Type{Rad{U,V}}) = Rad{promote_type(S,U),promote_type(T,V)}
promote_rule{T<:Rad}(::Type{BigFloat},::Type{T}) = BigFloat
promote_rule{S<:AbstractFloat,T<:Rad}(::Type{S},::Type{T}) = S

convert(::Type{Rad}, x::Rad) = x
convert(::Type{Rad}, r::AbstractRational) = Rad(r,zero(r),one(r))

conj(x::Rad) = Rad(x.a,-x.b,x.n)
norm(x::Rad) = x * conj(x)

function show(io::IO,x::Rad)
    if x == 0
        show(io,0)
    elseif isa(x.b,Rational) 
        if x.a != 0
            if x.a != 1
                show(io,x.a) 
            else
                show(io,numerator(x.a))
            end
            if sign(x.b) == 1
                print(io," + ")
            elseif sign(x.b) == -1
                print(io," - ")
            end
        end
        if ~in(numerator(x.b),[-1,0,1])
            show(io,abs(numerator(x.b))) 
        end
        if x.n != 1
            print(io,"√(") 
            show(io,x.n) 
            print(io,")") 
        end
        if denominator(x.b) != 1
            print(io,"//")
            show(io,denominator(x.b))
        end
    else 
        if x.a != 0
            show(io,x.a)
            if sign(x.b) == 1
                print(io," + ")
            elseif sign(x.b) == -1
                print(io," - ")
            end
        elseif sign(x.b) == -1
            print(io,"-")
        end
        if x.b != 0
            if abs(x.b) != 1
                show(io,abs(x.b))
            end
            if x.n != 1
                print(io,"√(")
                show(io,x.n)
                print(io,")")
            end
            if x.n == 1 && x.b == 1
                show(io,1)
            end
        end
    end
end

end # module
