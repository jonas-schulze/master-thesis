function [Kk,Xf] = g_dense_rb3o(E,A,B,C,tX,tspan)
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
%  tX .......... initial (terminal) value of DRE
%  tspan ....... time line
% Outputs:
%  X ........... solution of the DRE for all t=tk
%  Kk .......... feedback for all t=tk
%
% Norman Lang, January 2015
%
% [1] ROS3P - An accurate third-order Rosenbrock solver designed for
%             parabolic problems
%


% set up Ros3 coefficients according to [1]
gam = 7.886751345948129e-1;
a21 = 1.267949192431123;
c21 = -1.607695154586736; 
c31 = -3.464101615137755; 
c32 = -1.732050807568877;
m1 = 2; 
m2 = 5.773502691896258e-1; 
m3 = 4.226497308103742e-1;

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
    gF = (A-B*K)-E/(2*gam*tau);
    
    % Solve Lyap.-equ. of 1st stage
    AXE=A'*Xo*E; 
    R = C'*C+AXE+AXE'-K'*K;
    R = (R+R')/2;
    R = real(R);
    K1 = lyap(gF',R,[],E');
    
    % Second Stage 
    RX = (A'*K1-K'*(B'*K1))*E; 
    R23 = a21 *(RX+RX'); 
    R2 = R23+(c21/tau)*E'*K1*E;
    R2 = (R2+R2')/2;
	R2 = real(R2);
    K21 = lyap(gF',R2,[],E');

    % Third stage 
    R3 = R23+E'*(((c31/tau)+(c32/tau))*K1+(c32/tau)*K21)*E;
	R3 = (R3+R3')/2;
	R3 = real(R3);
    K31 = lyap(gF',R3,[],E');

    % Update X and K
    Xup = (m1+m2+m3)*K1+m2*K21+m3*K31;
    X = Xo + Xup;
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
