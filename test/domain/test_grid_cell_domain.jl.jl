function test_grid_cell_domain()
    @testset "Test grid cell domain" begin
        N = 20
        lons = [-180 + (i - 0.5) * 360 / N for i = 1:N]
        lats = [-90 + (j - 0.5) * 180 / N for j = 1:N]
        mask = rand(Bool, (N, N))

        domain = GridCellDomain(lons, lats, mask)

        @test count(domain) == count(mask)
        
        which_domain_1D, vars_1D = define_on_domain((:u, :v), domain)
        @test length(vars.u) == count(mask)
        
        which_domain_3D, vars_3D = define_on_domain((:w,), domain, (5, 5))
        @test size(vars_3D.w) == (count(mask), 5, 5)

        vars = ComponentArray((; vars_1D..., vars_3D...))
        which_domain = merge(which_domain_1D, which_domain_3D)
        @test which_domain[:u] == typeof(domain)

        which_domain, vars
    end
end
