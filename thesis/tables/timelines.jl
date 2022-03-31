### A Pluto.jl notebook ###
# v0.17.1

using Markdown
using InteractiveUtils

# ╔═╡ e39081c6-b0e5-11ec-00fc-33f084e7060a
using DrWatson

# ╔═╡ 55a50d60-45c1-46ef-9d7d-d9d432097b7f
using CSV

# ╔═╡ 16b88838-3484-45a3-90cf-d6636e5c9f15
using Stuff

# ╔═╡ e9ab6945-04fc-4edf-aaf3-6dfad652457c
@quickactivate

# ╔═╡ bb6e7a0e-8b89-4c13-9c47-ad92565c183a
using DataFrames

# ╔═╡ 1e2c26ee-8408-4d42-8337-36b0a7066ca1
using StatsBase: median, mean

# ╔═╡ af2e72c4-6f68-4a3b-b6ce-cd6835f7b29d
using LoggingFormats: LogFmt

# ╔═╡ 3da7e24c-d32b-4a53-8cba-a2eb9a97a513
using PlutoUI

# ╔═╡ f3c1a4e4-59d7-405f-9ebe-6380ba252157
using DataStructures

# ╔═╡ e3aade16-51e9-439a-8d69-6d1a04405f0d
md"""
# All Timelines

Collect ramp-up metrics etc. for all other timelines occuring in the thesis.
"""

# ╔═╡ 61055ac4-93d3-40fb-96c9-e7b34c634955
# cf. notebook p. 102
datasets = SortedDict(
	:lr11 => 351_158, # lr11
	:lr12 => 351_167, # lr12
	:lr22 => 351_160, # lr22
	:de11 => 351_236, # de11
	:de12 => 351_235, # de12
	:de22 => 351_290, # de22
	:de44 => 351_270, # de44
)

# ╔═╡ 4cb03455-315f-484c-9ad6-2dd89de10806
jobids = collect(values(datasets))

# ╔═╡ b5a11395-6a4d-46b1-8400-ec6a25607d27
key = collect(keys(datasets))

# ╔═╡ f95df1e0-3d80-4dc8-a154-4e9632c0388e
function desc(key::Symbol)
	s = string(key)
	data = s[1:2]
	data_desc = data == "de" ? "Dense" : "LRSIF"
	order_G = s[3]
	order_F = s[4]
	"$data_desc $order_G/$order_F"
end

# ╔═╡ d15eea91-dc77-4070-84a3-782080000d8c
md"## Group in Dense/Low-Rank/Reference"

# ╔═╡ a3b8b663-771c-41a7-b72a-0fb04eaff3d7
is_lr = [startswith(string(k), "lr") for k in key]

# ╔═╡ 5e8380c9-70c1-4d5f-bbcc-3d3384e0aad2
is_de = [startswith(string(k), "de") && k != :de44 for k in key]

# ╔═╡ 23f2495a-980e-4074-a0ec-8a779b5b0fa2
is_ref = key .== :de44

# ╔═╡ 618fbe6e-cf3a-4227-abb6-4e0acc8f7edf
@assert is_lr + is_de + is_ref == fill(1, 7)

# ╔═╡ bc9ada13-57c3-462e-843c-07db8f0427d5
md"## Load Event Logs"

# ╔═╡ 00786f67-88ef-4b2b-8c7e-a1ca5700ba24
logdirs = let
	dirs = readdir(logdir())
	filter!(!endswith(".gz"), dirs)
	filter!(startswith("rail"), dirs)
	map(jobids) do j
		i = findfirst(contains(string(j)), dirs)
		dirs[i]
	end
end

# ╔═╡ 762c20b6-5f93-4e98-8055-2aff84ff1a66
long = @. load_eventlog(LogFmt(), logdir(logdirs))

# ╔═╡ 9d822074-3759-46c5-9db5-27153bc33619
wide = map(long) do l
	wide = unstack(l, :type, :time; allowduplicates=true)
	dropmissing!(wide, [:start, :stop])
	wide[!, :duration] = wide.stop - wide.start
	wide
end

# ╔═╡ 0ba0ec40-55ab-47bc-b24b-044e9710adfc
md"## Define Metrics"

# ╔═╡ c29824d4-08e9-4823-85c9-6724af1ba58d
N(wide) = maximum(wide.n)

# ╔═╡ d0a2b08e-03e2-452c-ac87-89e0f04f9531
K(wide) = maximum(skipmissing(wide[wide.tag .== :ComputingF, :k]))

# ╔═╡ a4fc3f92-1cb6-4dce-8bdb-90f2bc129692
function t_warmup(wide)
	tags = (:WarmingUpC, :WarmingUpF)
	events = filter(:tag => in(tags), wide)
	ts = combine(
		groupby(events, :n),
		:start => (ts -> minimum(ts, init=0.0)) => :start,
		:stop  => (ts -> maximum(ts, init=0.0)) => :stop,
	)
	maximum(ts.stop - ts.start, init=0.0)
end

# ╔═╡ 27599f6a-2267-497f-911a-263d5d10a0e7
t_F(wide) = median(wide[wide.tag .== :ComputingF, :duration])

# ╔═╡ 7081600c-0022-49a4-8a26-300676abc3b1
t_G(wide) = median(wide[wide.tag .== :ComputingC, :duration])

# ╔═╡ 4cb55ec3-06f9-4677-9652-ef33ae5309ca
function t_rampup(wide)
	pred(tag, k) = tag == :ComputingC && k === 0
	start = filter([:tag, :k] => pred, wide).start
	delay = diff(start)
	mean(delay) - t_G(wide)
end

# ╔═╡ 587dbbdb-3095-4150-8d99-747033322081
t_par(long) = maximum(long.time)

# ╔═╡ 5c39d0ba-cdc3-41e3-bffb-7559b720f04a
function t̂_seq(wide)
	# collect last fine solutions
	Fs = filter(:tag => ==(:ComputingF), wide)
	k_n = combine(
		groupby(Fs, :n),
		:k => maximum => :k,
	)
	F_n = innerjoin(Fs, k_n, on=names(k_n))
	sum(F_n.duration)
end

# ╔═╡ 5ac3b672-f057-4bc6-851d-552cc11f52ca
function k_N(wide)
	_N = N(wide)
	pred(tag, n) = tag == :ComputingF && n == _N
	F_N = filter([:tag, :n] => pred, wide)
	maximum(F_N.k)
end

# ╔═╡ a90bd21b-1f28-486a-81a3-34191db02071
begin
	df = DataFrame(
		key = key,
		desc = desc.(key),
		N = N.(wide),
		K = K.(wide),
		k_N = k_N.(wide),
		t_warmup = t_warmup.(wide),
		t_rampup = t_rampup.(wide),
		t_G = t_G.(wide),
		t_F = t_F.(wide),
		t_par = t_par.(long),
	)
	df[!, :t̂_par] = @. df.t_warmup +
		df.N*(df.t_rampup + df.t_G) +
		df.K*(df.t_F + df.t_G) +
		df.t_F
	df[!, :err_par] = @. abs(df.t̂_par - df.t_par) / df.t_par
	df
end

# ╔═╡ 36ff357f-cc58-453d-8d9e-5d9414813d80
begin
	df_seq = DataFrame(
		key = key,
		desc = desc.(key),
		N = df.N,
		t_par = df.t_par,
		t̂_seq = t̂_seq.(wide),
	)
	df_seq[!, :speedup] = @. df_seq.t̂_seq / df_seq.t_par
	df_seq[!, :efficiency] = @. df_seq.t̂_seq / (df_seq.N * df_seq.t_par)
	df_seq
end

# ╔═╡ d4efa64f-bae3-4cba-bd24-6adaf82a2c99
md"## Save Tables"

# ╔═╡ 5ae47ec1-b937-4087-a51e-07f0a4800480
N_ = only(unique(df.N))

# ╔═╡ 450a097f-e322-4672-828b-48909120ee29
for (suffix, mask) in [
	("lr", is_lr),
	("de", is_de),
	("ref", is_ref),
]
	CSV.write(
		projectdir("thesis", "tables", "warmup$(N_)_$(suffix).csv"),
		df[mask, Not([:key,:N,:K])],
		header = false,
	)
end

# ╔═╡ 1bcf5dcd-9261-4340-a8ed-961baab63e97
for (suffix, mask) in [
	("lr", is_lr),
	("de", is_de),
	("ref", is_ref),
]
	CSV.write(
		projectdir("thesis", "tables", "speedup$(N_)_$(suffix).csv"),
		df_seq[mask, Not([:key,:N])],
		header = false,
	)
end

# ╔═╡ 075c72e0-0cae-463a-ada0-adb9a4568fcc
md"# Internal"

# ╔═╡ 15c0a7b7-cfc1-4b0f-9cc3-deb2ec132013
TableOfContents()

# ╔═╡ Cell order:
# ╟─e3aade16-51e9-439a-8d69-6d1a04405f0d
# ╠═61055ac4-93d3-40fb-96c9-e7b34c634955
# ╠═4cb03455-315f-484c-9ad6-2dd89de10806
# ╠═b5a11395-6a4d-46b1-8400-ec6a25607d27
# ╠═f95df1e0-3d80-4dc8-a154-4e9632c0388e
# ╠═a90bd21b-1f28-486a-81a3-34191db02071
# ╠═36ff357f-cc58-453d-8d9e-5d9414813d80
# ╟─d15eea91-dc77-4070-84a3-782080000d8c
# ╠═a3b8b663-771c-41a7-b72a-0fb04eaff3d7
# ╠═5e8380c9-70c1-4d5f-bbcc-3d3384e0aad2
# ╠═23f2495a-980e-4074-a0ec-8a779b5b0fa2
# ╠═618fbe6e-cf3a-4227-abb6-4e0acc8f7edf
# ╟─bc9ada13-57c3-462e-843c-07db8f0427d5
# ╠═00786f67-88ef-4b2b-8c7e-a1ca5700ba24
# ╠═762c20b6-5f93-4e98-8055-2aff84ff1a66
# ╠═9d822074-3759-46c5-9db5-27153bc33619
# ╟─0ba0ec40-55ab-47bc-b24b-044e9710adfc
# ╠═c29824d4-08e9-4823-85c9-6724af1ba58d
# ╠═d0a2b08e-03e2-452c-ac87-89e0f04f9531
# ╠═a4fc3f92-1cb6-4dce-8bdb-90f2bc129692
# ╠═4cb55ec3-06f9-4677-9652-ef33ae5309ca
# ╠═27599f6a-2267-497f-911a-263d5d10a0e7
# ╠═7081600c-0022-49a4-8a26-300676abc3b1
# ╠═587dbbdb-3095-4150-8d99-747033322081
# ╠═5c39d0ba-cdc3-41e3-bffb-7559b720f04a
# ╠═5ac3b672-f057-4bc6-851d-552cc11f52ca
# ╟─d4efa64f-bae3-4cba-bd24-6adaf82a2c99
# ╠═5ae47ec1-b937-4087-a51e-07f0a4800480
# ╠═55a50d60-45c1-46ef-9d7d-d9d432097b7f
# ╠═450a097f-e322-4672-828b-48909120ee29
# ╠═1bcf5dcd-9261-4340-a8ed-961baab63e97
# ╟─075c72e0-0cae-463a-ada0-adb9a4568fcc
# ╠═e39081c6-b0e5-11ec-00fc-33f084e7060a
# ╠═e9ab6945-04fc-4edf-aaf3-6dfad652457c
# ╠═16b88838-3484-45a3-90cf-d6636e5c9f15
# ╠═bb6e7a0e-8b89-4c13-9c47-ad92565c183a
# ╠═1e2c26ee-8408-4d42-8337-36b0a7066ca1
# ╠═af2e72c4-6f68-4a3b-b6ce-cd6835f7b29d
# ╠═3da7e24c-d32b-4a53-8cba-a2eb9a97a513
# ╠═f3c1a4e4-59d7-405f-9ebe-6380ba252157
# ╠═15c0a7b7-cfc1-4b0f-9cc3-deb2ec132013
