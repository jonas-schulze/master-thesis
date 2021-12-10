%% Setup
P = load(datadir('Rail371.mat'));

if ~exist('dt')
  dt = str2num(getenv('MY_DT'));
  if isempty(dt)
    dt = 1500;
  end
end
tspan = 0:dt:4500;

if ~exist('order')
  order = str2num(getenv('MY_ORDER'));
  if isempty(order)
    order = 1;
  end
end

switch order
case 1
  alg = @g_dense_rb1o
case 2
  alg = @g_dense_rb2o
case 3
  alg = @g_dense_rb3o
case 4
  alg = @g_dense_rb4o
otherwise
  error("unknown order: " + order)
  quit(1);
end

%% Prepare output
[~] = mkdir(datadir('dense-seq', 'matlab'));
container = datadir('dense-seq', 'matlab', sprintf('rail371_dt=%d_order=%d.h5', dt, order));
if isfile(container)
  error("output already exists: " + container)
  quit(1);
end
h5create(container, '/gitcommit', [1], 'Datatype', 'string');
h5create(container, '/script', [1], 'Datatype', 'string');
h5create(container, '/SLURM_JOB_ID', [1], 'Datatype', 'string');
h5write(container, '/gitcommit', string(gitdescribe));
h5write(container, '/script', string(mfilename('fullpath')));
h5write(container, '/SLURM_JOB_ID', string(getenv('SLURM_JOB_ID')));

%% Solve
[Kc,Xc] = alg(P.E, P.A, P.B, P.C, P.X0, tspan);

%% Store
for i = 1:length(tspan)
  t = tspan(i);
  K = Kc{i};
  X = Xc{i};
  K_path = "/K/t=" + t;
  X_path = "/X/t=" + t;
  h5create(container, K_path, size(K));
  h5create(container, X_path, size(X));
  h5write(container, K_path, K);
  h5write(container, X_path, X);
end
