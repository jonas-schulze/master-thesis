function [Kk,Xf] = g_dense_rb2o(E,A,B,C,X,tspan)
%
% Explicit computation of the feedback
% matrix of the LQR problem with the corresponding DRE
% (Solve dense Lyapunov equation for reduced order model
%  / projected system matrices)
%  E'*dX/dt*E = C'*C + A'*X*E + E'*X*A - E'*X*B*B'*X*E
%
% calling sequence:
%  Kk = dense_rb2o(A,B,C,E,X,tspan_bw,gam)
%
% Inputs:
%  E ........... mass matrix in DRE
%  A ........... system matrix in DRE
%  B ........... input matrix in DRE
%  C ........... output matrix in DRE
%  X .......... initial (terminal) value of DRE
%  tspan ....... time line
% Outputs:
%  Xf ........... solution of the DRE for all t=tk
%  Kk .......... feedback for all t=tk
%
% Norman Lang, Mai 2012

% Global parameter for the method
gam = 1+(1/sqrt(2));

tspan_bw = fliplr(tspan);
len = length(tspan_bw);

compX = false;
if (nargout >= 2) 
    compX = true;
end

Kf = cell(1,len);  % Output Trajectory in terms of K 
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
    gF = gam*tau*(A-B*K)-E/2;
    
    % Solve Lyap.-equ. of 1st stage
    R = C'*C+A'*X*E+E'*X*A-K'*K;
    R = (R+R')/2;
    R = real(R);

    K1 = lyap(gF',R,[],E');
    
	R2 = -tau^2*(E'*(K1*B))*((B'*K1)*E)-(2-1/gam)*E'*K1*E;
	R2 = (R2+R2')/2;
	R2 = real(R2);

 	K21 = lyap(gF',R2,[],E');

	% Build update K2
	K2 = K21 + (4-1/gam)*K1;
    % Update X and K 
    X = X + (tau/2)*K2;
    K = (B'*X)*E;
    
    % Store X
    if compX
        Xf{i} = X;
    end
    Kk{i} = K;
end
Kk = fliplr(Kk);
Xf = fliplr(Xf);