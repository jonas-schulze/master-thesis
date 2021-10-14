function [Kk,Xf] = g_dense_rb4o(E,A,B,C,tX,tspan)
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
%  X ........... initial (terminal) value of DRE
%  tspan ....... time line
% Outputs:
%  X ........... solution of the DRE for all t=tk
%  Kk .......... solution of DRE (in feedback form) for all t=tk
%
% Norman Lang, Mai 2012

compX = false;
if (nargout >= 2) 
    compX = true;
end

tspan_bw = fliplr(tspan);
len = length(tspan_bw);

Kk = cell(1,len);  % Output Trajectory in terms of K 
K = (B'*tX)*E;
Kk{1} = K;
if compX 
    Xf = cell(1,len);  % Output Trajectory
    Xf{1} = tX;
end 
Xo = tX;

for i = 2:len
    fprintf('Time step: %4d \t Time: %d \n', i-1, tspan(end-(i-1)));
    tau = tspan_bw(i-1)-tspan_bw(i);
    gF = (tau*(A-B*K)-E)/2;

    % First stage 
    R = C'*C+A'*Xo*E+E'*Xo*A-K'*K;
    R = (R+R')/2;
    R = real(R);
    K1 = lyap(gF',R,[],E');
	
    % Second stage 
    EK1E = E'*K1*E;
    EK1B = E'*(K1*B); 
    R2 = -tau^2*(EK1B*EK1B')-2*EK1E;
	R2 = (R2+R2')/2;
	R2 = real(R2);
    K21 = lyap(gF',R2,[],E'); 
    K2 = K21-K1;

    
    % Thrid stage 
    alpha = (24/25)*tau; 
    beta = (3/25)*tau;
    EK2E = E'*K2*E;
    EK2B = E'*(K2*B); 
    TMP = EK2B*EK1B'; 
    R3 = (245/25)*EK1E+(36/25)*EK2E-...
        (426/625)*tau^2*(EK1B*EK1B')-...
        beta^2*(EK2B*EK2B')-...
        alpha*beta*(TMP+TMP');
    R3 = (R3+R3')/2;
    R3 = real(R3);
    K31 = lyap(gF',R3,[],E');
    K3 = K31-(17/25)*K1;
    
    % Fourth stage 
    R4 = -(981/125)*EK1E-(177/125)*EK2E-(1/5)*E'*K3*E;
    R4 = (R4+R4')/2;
    R4 = real(R4);
    K41 = lyap(gF',R4,[],E');
    K4 = K41+K3;

	% Set up solution
    X = Xo + tau*((19/18)*K1+.25*K2+(25/216)*K3+(125/216)*K4);
    K = (B'*X)*E;
    
       Xo = X;
    % Store X
    if compX
        Xf{i} = X;
    end
    Kk{i} = K;
end


Kk = fliplr(Kk);
Xf = fliplr(Xf);
