%% Setup
P = load('Rail371.mat');

tspan = 0:25:900;

%% Solve
%[Kc,Xc] = g_dense_rb1o(P.E, P.A, P.B, P.C, P.X0, tspan);
%[Kc,Xc] = g_dense_rb2o(P.E, P.A, P.B, P.C, P.X0, tspan);
%[Kc,Xc] = g_dense_rb3o(P.E, P.A, P.B, P.C, P.X0, tspan);
[Kc,Xc] = g_dense_rb4o(P.E, P.A, P.B, P.C, P.X0, tspan);

%% Plot 
Ka = cell2mat(Kc');
plot(tspan, Ka(1:7:end, 71));
xlabel('t');
ylabel('K_{1,71}');
