include("test_grid_cell_domain.jl")

function test_domain()
    @testset "Test generic domain" begin
        # Initialise variables and variable library
        vars = ComponentArray()
        var_lib = Dict()

        # Create the mask to use for future tests
        mask = rand(Bool, 10, 10)

        # Test the grid cell domain
        grid_which_domain, grid_vars = test_grid_cell_domain(mask)
        vars = ComponentArray((;vars..., grid_vars...))

        # Test surface type domains
        

