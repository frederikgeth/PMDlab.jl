using Pkg
Pkg.activate("./")
using PMDlab
using PowerModelsDistribution
using Ipopt
using JuMP
using LinearAlgebra

import JuMP._CONSTRAINT_LIMIT_FOR_PRINTING
JuMP._CONSTRAINT_LIMIT_FOR_PRINTING[] = 10000

# optimizer = Ipopt.Optimizer

optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "print_level"=>0, "sb"=>"yes","warm_start_init_point"=>"yes", "max_iter"=>100)
optimizer = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "max_iter"=>100)

const PMD = PowerModelsDistribution

PMD.silence!()

## read and parse network data
# file = "data/three-wire-with-transformer/network_1/Feeder_2/Master.dss"     # three-wire with transformer
# file = "data/three-wire-with-transformer/network_23/Feeder_3/Master.dss"     # three-wire with transformer

# file = "data/three-wire/network_1/Feeder_2/Master.dss"                      # three-wire without transformer
file = "data/three-wire/network_23/Feeder_3/Master.dss"                      # three-wire without transformer  SMALLEST network

# eng3w = parse_file(file, transformations=[transform_loops!])
# PMDlab.augment_eng_3wire!(eng3w; line_current_rating=true, reduce_lines=true, sbase=1)

# math3w = transform_data_model(eng3w, kron_reduce=true, phase_project=true)
# PMDlab.augment_math_3wire!(math3w; relax_vsource_vm=true, Vsequence_bounds=true, cost_multiplier=1000)  # changing some of the input data

# ## run optimal power flow AC polar
# result3w_acp = PMD.solve_mc_model(math3w, ACPUPowerModel, optimizer, PMDlab.build_mc_opf)
# # result3w_acp = solve_mc_opf(math3w, ACPUPowerModel, optimizer)  # alternative, if the opf problem hadn't changed
# [bus["vm"] for (i, bus) in result3w_acp["solution"]["bus"]]

# using Plots
# plot([bus["vm"] for (i, bus) in result3w_acp["solution"]["bus"]], seriestype=:scatter)

# ## run optimal power flow AC rectangular
# # add_start_vrvi!(math3w; explicit_neutral=false)  # This function does not work for explicit_neutral=false
# add_start_voltage!(math3w, coordinates=:rectangular, explicit_neutral=false)
# result3w_acr = PMD.solve_mc_model(math3w, ACRUPowerModel, optimizer, PMDlab.build_mc_opf)
# # result3w_acr = solve_mc _opf(math3w, ACRUPowerModel, optimizer)    # alternative, if the opf problem hadn't changed


## run optimal power flow IV rectangular
# add_start_vrvi!(math3w; explicit_neutral=false)  # This function does not work for explicit_neutral=false

file = "data/three-wire/network_23/Feeder_3/Master.dss"                      # three-wire without transformer  SMALLEST network

eng3w = parse_file(file, transformations=[transform_loops!])
PMDlab.augment_eng_3wire!(eng3w; line_current_rating=false, reduce_lines=true, sbase=1)

math3w = transform_data_model(eng3w, kron_reduce=true, phase_project=true)

# relax_vsource_vm = options : "3vm 3va fix", "3va fix", "va fix va diff",  "va fix seq"
PMDlab.augment_math_3wire!(math3w; relax_vsource="va fix va diff", reverse_va_rotation=false, Vsequence_bounds=false, cost_multiplier=1000)  # changing some of the input data

## how to initialise
add_start_voltage!(math3w, coordinates=:rectangular, explicit_neutral=false)

pm = PMD.instantiate_mc_model(math3w, IVRUPowerModel, PMDlab.build_mc_opf)
result3w_ivr = PMD.solve_mc_model(math3w, IVRUPowerModel, optimizer, PMDlab.build_mc_opf)
# check_active_bounds(result3w_ivr, math3w)


# vm_bounds = [sqrt.(bus["vr"].^2 .+ bus["vi"].^2) for (i, bus) in result3w_ivr["solution"]["bus"]]

# output_file = "model.json"
# open(output_file, "w") do f
#     # for i in eachindex(PMD.(pm, 0, ))
#     #     println(f, )
#     # end
#     print(f, pm.model)
# end