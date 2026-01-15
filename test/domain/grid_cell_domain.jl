@testset "Test grid cell domain" begin
    N = 20
    lons = [-180 + (i - 0.5) * 360 / N for i = 1:N]
    lats = [-90 + (j - 0.5) * 180 / N for j = 1:N]
    mask = rand(Bool, (N, N))

    domain = GridCellDomain(lons, lats, mask)

    @test count(domain) == count(mask)
    
    vars = define_on_domain((:u, :v), domain)
    @test length(vars.u) ==
    


