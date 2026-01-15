@testset "Forcing methods"
    @testset "Functional forcing"
        function demo_forcing(x, y, t)
            ref_time = DateTime(2000, 0, 0)
            0.5 * sin(x) * 2 * cos(y) * sin((t - ref_time).value)
        end

        forcing = FunctionalForcing(demo_forcing, AggInstantaneous(), RealTime())



