%restoredefaultpath;
clear all;
clc;

% addpath(genpath('../src'));
% addpath(genpath('../tools/'))
% import casadi.*

%% define Alex's non-convex problem
% give general settings
N   =   2;
n   =   2;
m   =   1;
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');

f1  =   2*(y1(1)-1)^2;
f2  =   (y2(2)-2)^2;

h1  =   1-y1(1)*y1(2);
h2  =   -1.5+y2(1)*y2(2);

A1  =   [1, 0;
         0, 1];
A2  =   [-1,0;
         0, -1];
b   =   [0; 0];

lb1 =   [0;0];
lb2 =   [0;0];

ub1 =   [10;10];
ub2 =   [10;10];

%% convert symbolic variables to MATLAB fuctions
f1f     =  matlabFunction(f1,'Vars',{y1});
f2f     =  matlabFunction(f2,'Vars',{y2});

h1f     =   matlabFunction(h1,'Vars',{y1});
h2f     =   matlabFunction(h2,'Vars',{y2});

%% set solver options
maxit   =   30;
y0      =   3*rand(N*n,1);
lam0    =   10*(rand(1)-0.5)*ones(size(A1,1),1);
rho     =   100;
mu      =   100;
eps     =   1e-4;
Sig     =   {eye(n),eye(n)};

% no termination criterion, stop after maxit
term_eps = 0;

%% solve with ALADIN
emptyfun      = @(x) [];
[ggifun{1:N}] = deal(emptyfun);

% define the optimization set up
% define objective and constraint functions
sProb.locFuns.ffi  = {f1f, f2f};
sProb.locFuns.hhi  = {h1f, h2f};
sProb.locFuns.ggi  = ggifun;

% define boundaries
sProb.llbx = {lb1,lb2};
sProb.uubx = {ub1,ub2};

% define counpling matrix
sProb.AA   = {A1,A2};

% define initial values for solutions and lagrange multipliers
sProb.zz0  = {y0(1:2),y0(3:4)};
sProb.lam0 = lam0;

% define the options for ALADIN algorthm in parallel form
 opts = initializeOpts(rho, mu, maxit, Sig, term_eps, 'true');
 sol_ALADIN_parallel = run_ALADINnew( sProb, opts ); 

% define the options for ALADIN algorthm in centralized form
opts = initializeOpts(rho, mu, maxit, Sig, term_eps, 'false');
sol_ALADIN_centralized = run_ALADINnew( sProb, opts ); 


%% solve centralized problem with CasADi & IPOPT
import casadi.*
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');
f1fun   =   matlabFunction(f1,'Vars',{y1});
f2fun   =   matlabFunction(f2,'Vars',{y2});
h1fun   =   matlabFunction(h1,'Vars',{y1});
h2fun   =   matlabFunction(h2,'Vars',{y2});


% y0  =   ones(N*n,1);
y   =   SX.sym('y',[N*n,1]);
F   =   f1fun(y(1:2))+f2fun(y(3:4));
g   =   [h1fun(y(1:2));
         h2fun(y(3:4));
         [A1, A2]*y];
nlp =   struct('x',y,'f',F,'g',g);
cas =   nlpsol('solver','ipopt',nlp);
sol =   cas('lbx', [lb1; lb2],...
            'ubx', [ub1; ub2],...
            'lbg', [-inf;-inf;b], ...
            'ubg', [0;0;b]);  



%% solve with ADMM
% rhoADMM = 1000;
% for i=1:length(ffifun) 
%     lam0ADM{i}  = zeros(size(AA{i},1),1);
% end   
% 
% ADMMopts = struct('scaling',false,'rhoUpdate',false,'maxIter',100);
% [xoptADM, loggADM]         = run_ADMM(ffifun,ggifun,hhifun,AA,xx0,...
%                              lam0ADM,llbx,uubx,rhoADMM,Sig,ADMMopts);             
                                  
% [xoptSQP, loggSQP] = run_SQP(ffifun,ggifun,hhifun,AA,xxgi0,...
%                                       lam0,llbx,uubx,Sig,opts);

%% define this problem using casadi functions
y_1 = SX.sym('y_1', n);
y_2 = SX.sym('y_2', n);

f1f = 2 * (y_1(1) - 1)^2;
f2f = (y_2(2) - 2)^2;

f1 = Function('f_1', {y_1}, {f1f});
f2 = Function('f_2', {y_2}, {f2f});

h1f = 1 - y_1(1)*y_1(2);
h2f = -1.5 + y_2(1)*y_2(2);

h1 = Function('h_1', {y_1}, {h1f});
h2 = Function('h_2', {y_2}, {h2f});

sProb.locFuns.ffi  = {f1, f2};
sProb.locFuns.hhi  = {h1, h2};

sol_ALADIN = run_ALADINnew( sProb, opts ); 

%% define the problem using function handle
f1 = @(x) 2 * ( x(1) - 1)^2;
f2 = @(y) (y(2) - 2)^2;

h1 = @(x) (1 - x(1) * x(2));
h2 = @(y) (-1.5 + y(1) * y(2));

sProb.locFuns.ffi  = {f1, f2};
sProb.locFuns.hhi  = {h1, h2};

sol_ALADIN = run_ALADINnew( sProb, opts ); 

%% plotting
set(0,'defaulttextInterpreter','latex')
figure(2)
hold on
plot(sol_ALADIN.iter.logg.X')
hold on
plot(maxit,full(sol.x),'ob')
xlabel('$k$');
ylabel('$x^k$');