using Stuff

jobids = [
    #351158, # lr11
    #351167, # lr12
    #351160, # lr22
    #351236, # d11
    #351235, # d12
    #351270, # d44
    351290, # d22
]

taskid = readenv("SLURM_ARRAY_TASK_ID")

@show taskid

jobid = jobids[taskid]

@show jobid

path = datadir("dense-par")
dirs = readdir(path)
filter!(endswith(".dir"), dirs)

i = findfirst(contains("$jobid"), dirs)
input = joinpath(path, dirs[i])
output = replace(input, ".dir" => ".h5")

@show input
@show output

mergedata(input, output)
