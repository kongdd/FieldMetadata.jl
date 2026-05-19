using Parameters
import FieldMetadata: @metadata

@metadata bounds nothing
@metadata units "-" String

@bounds @units @with_kw mutable struct Muskingum{FT}
  x::FT = 0.35 | (0.01, 0.5) | "-"

  dt::FT = 1.0
  C0::FT = FT(NaN)
  C1::FT = FT(NaN)
  C2::FT = FT(NaN)
end

@testset "work with Parameter" begin
  x = Muskingum{Float64}()
  @show x  # display struct in CI logs
  @test bounds(x) == ((0.01, 0.5), nothing, nothing, nothing, nothing)
  @test units(x) == ("-", "-", "-", "-", "-")
end
