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

%% Solve
[Kc,Xc] = alg(P.E, P.A, P.B, P.C, P.X0, tspan);

%% Store
container = datadir("matlab_dt=" + dt + "_order=" + order + ".h5");
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
