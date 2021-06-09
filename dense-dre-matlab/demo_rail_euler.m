%% Setup
P = load('Rail371.mat');

dt = 300
tspan = 0:dt:900;

%% Solve
[Kc,Xc] = g_dense_rb1o(P.E, P.A, P.B, P.C, P.X0, tspan);
%[Kc,Xc] = g_dense_rb2o(P.E, P.A, P.B, P.C, P.X0, tspan);
%[Kc,Xc] = g_dense_rb3o(P.E, P.A, P.B, P.C, P.X0, tspan);
%[Kc,Xc] = g_dense_rb4o(P.E, P.A, P.B, P.C, P.X0, tspan);

%% Store
container = "baseline" + dt + ".h5"
for i = 1:length(tspan)
  t = tspan(i)
  K = cell2mat(Kc(i))
  X = cell2mat(Xc(i))
  K_path = "/K/t=" + t
  X_path = "/X/t=" + t
  h5create(container, K_path, size(K))
  h5create(container, X_path, size(X))
  h5write(container, K_path, K)
  h5write(container, X_path, X)
end
