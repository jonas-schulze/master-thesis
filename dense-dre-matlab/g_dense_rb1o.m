function [Kk,Xf] = g_dense_rb1o(E,A,B,C,X,tspan)
%
% Explicit computation of the feedback
% matrix of the LQR problem with the corresponding DRE
% (Solve dense Lyapunov equation for reduced order model
%  / projected system matrices)
%  E'*dX/dt*E = C'*C + A'*X*E + E'*X*A - E'*X*B*B'*X*E
%
% calling sequence:
% Kk = g_dense_rb1o(E,A,B,C,X,tspan)
%
% Inputs:
%
% E,A,B,C,X     the matrices E, A, B, C, in the DRE above and the
%               final value of the solution of DRE to solve ODE
%               backward in time
% tspan         vector of time samples, where the DRE should be solved
%
% Output:
% 
% Kk            Cell Array containing K for each point in tspan 
% Xf            Cell Array containing X for each point in tspan
%
% Norman Lang, July 2012

tspan_bw = fliplr(tspan); % we work backward in time.
len = length(tspan_bw);

compX = false;
if (nargout >= 2) 
    compX = true;
end

Kk = cell(1,len);  % Output Trajectory in terms of K 
K = (B'*X)*E;
Kk{1} = K;

if compX 
    Xf = cell(1,len);  % Output Trajectory
    Xf{1} = X;
end 

for i = 2:len
    tau = tspan_bw(i-1)-tspan_bw(i);
    fprintf('Time step: %4d \t Time: %g  \t Timestep %g\n', i-1, ...
            tspan(len-(i-1)),tau);
    
    % Coefficient Matrix of the Lyapunov Equation 
    F = (A-B*K)-E/(2*tau);
    R = C'*C+K'*K+(1/tau)*E'*X*E;
    
    % Only for safety since Matlab/Octave do not guarantee symmetry of R.
    R = real(R+R')/2;

    % Solve the Equation. 
    X = lyap(F',R,[],E');

    % Compute K for the next set. 
    
    K = (B'*X)*E;
    
    % Store X
    if compX
        Xf{i} = X;
    end
    Kk{i} = K;
end
Kk = fliplr(Kk);
Xf = fliplr(Xf);

