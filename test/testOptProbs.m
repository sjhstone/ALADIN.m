% reset envoronment variables for running the tests
clear all;
import casadi.*

% numerical tolerance for tests
testNumTol = 1e-6;
emptyfun      = @(x) [];


%% mini non-convex example test
import casadi.*

N   =   2;
n   =   2;
m   =   1;
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');

f1  =   2*(y1(1)-1)^2;
f2  =   (y2(2)-2)^2;


h1  =   1-y1(1)*y1(2);
h2  =   -1.5+y2(1)*y2(2);

A1  =   [0, 1];
A2  =   [-1,0];
b   =   0;

lb1 =   [0;0];
lb2 =   [0;0];

ub1 =   [10;10];
ub2 =   [10;10];

% convert symbolic variables to MATLAB fuctions
f1f     =  matlabFunction(f1,'Vars',{y1});
f2f     =  matlabFunction(f2,'Vars',{y2});

h1f     =   matlabFunction(h1,'Vars',{y1});
h2f     =   matlabFunction(h2,'Vars',{y2});

% initalize
maxit   =   30;
y0      =   3*rand(N*n,1);
lam0    =   10*(rand(1)-0.5);
rho     =   100;
mu      =   1000000;
eps     =   1e-4;
Sig     =   {eye(n),eye(n)};

% compute reference solution via IPOPT
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');
f1fun   =   matlabFunction(f1,'Vars',{y1});
f2fun   =   matlabFunction(f2,'Vars',{y2});
h1fun   =   matlabFunction(h1,'Vars',{y1});
h2fun   =   matlabFunction(h2,'Vars',{y2});


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

% solve with ALADIN
emptyfun      = @(x) [];
AQP           = [A1,A2];
ffifun        = {f1f,f2f};
hhifun        = {h1f,h2f};
[ggifun{1:N}] = deal(emptyfun);

yy0         = {y0(1:2),y0(3:4)};
%xx0        = {[1 1]',[1 1]'};

llbx        = {lb1,lb2};
uubx        = {ub1,ub2};
AA          = {A1,A2};

opts = struct('rho0',rho,'rhoUpdate',1,'rhoMax',5e3,'mu0',mu,'muUpdate',1,...
    'muMax',1e5,'eps',eps,'maxiter',maxit);

% convert to new interface
[sProb, opts] = old2new(ffifun,ggifun,hhifun,AA,yy0,lam0,llbx,uubx,Sig,opts);

res_ALADIN    = run_ALADIN(sProb,opts);

% check result                                  
assert(full(norm(sol.x -vertcat(res_ALADIN.xxOpt{:}),inf)) < 1e-6, 'Out of tolerance for local minizer!')

%clean up
clear all;
import casadi.*
emptyfun      = @(x) [];
%% Rosenbrock function example test
import casadi.*

y1  =   sym('y1',[1,1],'real');
y2  =   sym('y2',[2,1],'real');

f1  =   (1-y1(1))^2;
f2  =   100*(y2(1)-y2(2)^2)^2;

h2  =   -1.5-y2(1);

A1  =   [1];
A2  =   [0, -1];
b   =   0;

lb1 =   [-inf];
lb2 =   [-inf; -inf];

ub1 =   [inf];
ub2 =   [inf; inf];

% convert symbolic variables to MATLAB fuctions
f1f     =   matlabFunction(f1,'Vars',{y1});
f2f     =   matlabFunction(f2,'Vars',{y2});

h1f     =   emptyfun;
h2f     =   matlabFunction(h2,'Vars',{y2});

% initalize
maxit   =   15;
%y0      =   3*rand(N*n,1);
lam0    =   10*(rand(1)-0.5);
rho     =   10;
mu      =   10;
eps     =   1e-4;
Sig     =   {eye(1),eye(2)};

% solve with ALADIN
AQP           = [A1,A2];
ffifun        = {f1f,f2f};
hhifun        = {h1f,h2f};
[ggifun{1:2}] = deal(emptyfun);

yy0         = {[-2],[-2;1]};
%xx0        = {[1 1]',[1 1]'};

llbx        = {lb1,lb2};
uubx        = {ub1,ub2};
AA          = {A1,A2};

opts = struct('rho0',rho,'rhoUpdate',1,'rhoMax',5e3,'mu0',mu,'muUpdate',1.2,...
    'muMax',1e5,'eps',eps,'maxiter',maxit);

% convert to new interface
[sProb, opts] = old2new(ffifun,ggifun,hhifun,AA,yy0,lam0,llbx,uubx,Sig,opts);

res_ALADIN    = run_ALADIN(sProb,opts);
                                  
% solve centralized problem with CasADi & IPOPT
y1  =   sym('y1',[1,1],'real');
y2  =   sym('y2',[2,1],'real');
f1fun   =   matlabFunction(f1,'Vars',{y1});
f2fun   =   matlabFunction(f2,'Vars',{y2});
h1fun   =   emptyfun;
h2fun   =   matlabFunction(h2,'Vars',{y2});

% y0  =   ones(N*n,1);
y   =   SX.sym('y',[3,1]);
F   =   f1fun(y(1))+f2fun(y(2:3));
g   =   [h1fun(y(1));
         h2fun(y(2:3));
         [A1, A2]*y];
nlp =   struct('x',y,'f',F,'g',g);
cas =   nlpsol('solver','ipopt',nlp);
sol =   cas('lbx', [lb1; lb2],...
            'ubx', [ub1; ub2],...
            'lbg', [-inf;b], ...
            'ubg', [0;b]);

% check result                                  
assert(full(norm(sol.x -vertcat(res_ALADIN.xxOpt{:}),inf)) < 1e-6, 'Out of tolerance for local minizer!')

%clean up
clear all;
import casadi.*
emptyfun      = @(x) [];

%% Beale's problem example test
import casadi.*

N   =   3;
n   =   3;
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');
y3  =   sym('y3',[n,1],'real');

f1  =   9-8*y1(1)-6*y1(2)-4*y1(3);
f2  =   2*y2(1)^2+2*y2(2)^2+y2(3)^2;
f3  =   2*y3(1)*y3(2)+2*y3(1)*y3(3);

h1  =   -3+y1(1)+y1(2)+y1(3);
h2  =   [-y2(1); -y2(2)];
h3  =   -y3(3);

A1  =   [ 1,  0,  0;...
          1,  0,  0;...
          0,  1,  0;...
          0,  1,  0;...
          0,  0,  1;...
          0,  0,  1];
A2  =   [-1,  0,  0;...
          0,  0,  0;...
          0, -1,  0;...
          0,  0,  0;...
          0,  0, -1;...
          0,  0,  0];
A3  =   [ 0,  0,  0;...
         -1,  0,  0;...
          0,  0,  0;...
          0, -1,  0;...
          0,  0,  0;...
          0,  0, -1];
b   =   0;

lb1 =   [-inf; -inf; -inf];
lb2 =   [-inf; -inf; -inf];
lb3 =   [-inf; -inf; -inf];

ub1 =   [inf; inf; inf];
ub2 =   [inf; inf; inf];
ub3 =   [inf; inf; inf];

% convert symbolic variables to MATLAB fuctions
f1f     =  matlabFunction(f1,'Vars',{y1});
f2f     =  matlabFunction(f2,'Vars',{y2});
f3f     =  matlabFunction(f3,'Vars',{y3});

h1f     =   matlabFunction(h1,'Vars',{y1});
h2f     =   matlabFunction(h2,'Vars',{y2});
h3f     =   matlabFunction(h3,'Vars',{y3});

% initalize
maxit   =   100;
%y0      =   3*rand(N*n,1);
lam0    =   10*(rand(1)-0.5)*ones(size(A1,1),1);
rho     =   10;
mu      =   1000;
eps     =   1e-4;
Sig     =   {eye(n),eye(n),eye(n)};

% solve with ALADIN
AQP           = [A1,A2,A3];
ffifun        = {f1f,f2f,f3f};
hhifun        = {h1f,h2f,h3f};
[ggifun{1:N}] = deal(emptyfun);

yy0         = {[0.5; 0.5; 0.5],[0.5; 0.5; 0.5],[0.5; 0.5; 0.5]};
%xx0        = {[1 1]',[1 1]'};

llbx        = {lb1,lb2,lb3};
uubx        = {ub1,ub2,ub3};
AA          = {A1,A2,A3};

opts = struct('rho0',rho,'rhoUpdate',1,'rhoMax',5e3,'mu0',mu,'muUpdate',1,...
    'muMax',1e5,'eps',eps,'maxiter',maxit);

% convert to new interface
[sProb, opts] = old2new(ffifun,ggifun,hhifun,AA,yy0,lam0,llbx,uubx,Sig,opts);

res_ALADIN    = run_ALADIN(sProb,opts);
                                  
% solve centralized problem with CasADi & IPOPT
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');
y3  =   sym('y3',[n,1],'real');
f1fun   =   matlabFunction(f1,'Vars',{y1});
f2fun   =   matlabFunction(f2,'Vars',{y2});
f3fun   =   matlabFunction(f3,'Vars',{y3});
h1fun   =   matlabFunction(h1,'Vars',{y1});
h2fun   =   matlabFunction(h2,'Vars',{y2});
h3fun   =   matlabFunction(h3,'Vars',{y3});


% y0  =   ones(N*n,1);
y   =   SX.sym('y',[N*n,1]);
F   =   f1fun(y(1:3))+f2fun(y(4:6))+f3fun(y(7:9));
g   =   [h1fun(y(1:3));
         h2fun(y(4:6));
         h3fun(y(7:9));
         [A1, A2, A3]*y];
nlp =   struct('x',y,'f',F,'g',g);
cas =   nlpsol('solver','ipopt',nlp);
sol =   cas('lbx', [lb1; lb2; lb3],...
            'ubx', [ub1; ub2; ub3],...
            'lbg', [-inf;-inf;-inf;-inf;-inf;-inf;-inf;-inf;-inf;b], ...
            'ubg', [0;0;0;0;0;0;0;0;0;b]);
        
% check result                                  
assert(full(norm(sol.x -vertcat(res_ALADIN.xxOpt{:}),inf)) < 1e-4, 'Out of tolerance for local minizer!')

%clean up
clear all;
import casadi.*
emptyfun      = @(x) [];

%% Mishra's Bird problem example test
% N   =   3;
% n   =   2;
% y1  =   sym('y1',[n,1],'real');
% y2  =   sym('y2',[n,1],'real');
% y3  =   sym('y3',[n,1],'real');
% 
% f1  =   sin(y1(1)).*exp((1-cos(y1(2))).^2);
% f2  =   cos(y2(2)).*exp((1-sin(y2(1))).^2);
% f3  =   (y3(1)-y3(2)).^2;
% 
% h3  =   (y3(1)+5)^2+(y3(2)+5)^2-25;
% 
% A1  =   [ 1,  0;...
%           1,  0;...
%           0,  1;...
%           0,  1];
% A2  =   [-1,  0;...
%           0,  0;...
%           0, -1;...
%           0,  0];
% A3  =   [ 0,  0;...
%          -1,  0;...
%           0,  0;...
%           0, -1];
% b   =   0;
% 
% lb1 =   [-10;-6.5];
% lb2 =   [-10;-6.5];
% lb3 =   [-10;-6.5];
% 
% ub1 =   [0;0];
% ub2 =   [0;0];
% ub3 =   [0;0];
% 
% % convert symbolic variables to MATLAB fuctions
% f1f     =   matlabFunction(f1,'Vars',{y1});
% f2f     =   matlabFunction(f2,'Vars',{y2});
% f3f     =   matlabFunction(f3,'Vars',{y3});
% 
% h1f     =   emptyfun;
% h2f     =   emptyfun;
% h3f     =   matlabFunction(h3,'Vars',{y3});
% 
% % initalize
% maxit   =   20;
% y0      =   3*rand(N*n,1);
% lam0    =   10*(rand(1)-0.5)*ones(size(A1,1),1);
% rho     =   100;
% mu      =   1000;
% eps     =   1e-4;
% Sig     =   {eye(n),eye(n),eye(n)};
% 
% % solve with ALADIN
% AQP           = [A1,A2,A3];
% ffifun        = {f1f,f2f,f3f};
% hhifun        = {h1f,h2f,h3f};
% [ggifun{1:N}] = deal(emptyfun);
% 
% yy0         = {[-1;-1],[-1;-1],[-1;-1]};
% %xx0        = {[1 1]',[1 1]'};
% 
% llbx        = {lb1,lb2,lb3};
% uubx        = {ub1,ub2,ub3};
% AA          = {A1,A2,A3};
% 
% opts = struct('rho0',rho,'rhoUpdate',1,'rhoMax',5e3,'mu0',mu,'muUpdate',1,...
%     'muMax',1e5,'eps',eps,'maxiter',maxit);
% 
% [xoptAL, loggAL]   = run_ALADIN(ffifun,ggifun,hhifun,AA,yy0,...
%                                       lam0,llbx,uubx,Sig,opts);
%                                   
% % solve centralized problem with CasADi & IPOPT
% y1  =   sym('y1',[n,1],'real');
% y2  =   sym('y2',[n,1],'real');
% y3  =   sym('y3',[n,1],'real');
% f1fun   =   matlabFunction(f1,'Vars',{y1});
% f2fun   =   matlabFunction(f2,'Vars',{y2});
% f3fun   =   matlabFunction(f3,'Vars',{y3});
% h1fun   =   emptyfun;
% h2fun   =   emptyfun;
% h3fun   =   matlabFunction(h3,'Vars',{y3});
% 
% 
% % y0  =   ones(N*n,1);
% y   =   SX.sym('y',[N*n,1]);
% F   =   f1fun(y(1:2))+f2fun(y(3:4))+f3fun(y(5:6));
% g   =   [h1fun(y(1:2));
%          h2fun(y(3:4));
%          h2fun(y(5:6));
%          [A1, A2, A3]*y];
% nlp =   struct('x',y,'f',F,'g',g);
% cas =   nlpsol('solver','ipopt',nlp);
% sol =   cas('lbx', [lb1; lb2; lb3],...
%             'ubx', [ub1; ub2; ub3],...
%             'lbg', [-inf;-inf;-inf;b], ...
%             'ubg', [0;0;0;b]);
% 
% % check result                                  
% assert(full(norm(sol.x -xoptAL,inf)) < 1e-6, 'Out of tolerance for local minizer!')
% 
% %clean up
% clear all;
% clc;
% import casadi.*
% emptyfun      = @(x) [];

%% Rastrigin problem example test
import casadi.*

N   =   2;
n   =   4;
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');

f1  =   10*N-10*cos(2*pi*y1(1))-10*cos(2*pi*y1(2))-10*cos(2*pi*y1(3))-10*cos(2*pi*y1(4));
f2  =   y2(1)^2+y2(2)^2+y2(3)^2+y2(4)^2;

A1  =   [ 1,  0,  0,  0;...
          0,  1,  0,  0;...
          0,  0,  1,  0;...
          0,  0,  0,  1];
A2  =   [-1,  0,  0,  0;...
          0, -1,  0,  0;...
          0,  0, -1,  0;...
          0,  0,  0, -1];
b   =   0;

lb1 =   [-5.12; -5.12; -5.12; -5.12];
lb2 =   [-5.12; -5.12; -5.12; -5.12];

ub1 =   [5.12; 5.12; 5.12; 5.12];
ub2 =   [5.12; 5.12; 5.12; 5.12];

% convert symbolic variables to MATLAB fuctions
f1f     =   matlabFunction(f1,'Vars',{y1});
f2f     =   matlabFunction(f2,'Vars',{y2});

h1f     =   emptyfun;
h2f     =   emptyfun;


% initalize
maxit   =   15;
y0      =   3*rand(N*n,1);
lam0    =   10*(rand(1)-0.5)*ones(size(A1,1),1);;
rho     =   10;
mu      =   100;
eps     =   1e-4;
Sig     =   {eye(4),eye(4)};

% solve with ALADIN
AQP           = [A1,A2];
ffifun        = {f1f,f2f};
hhifun        = {h1f,h2f};
[ggifun{1:N}] = deal(emptyfun);

yy0         = {y0(1:4),y0(5:8)};
%xx0        = {[1 1]',[1 1]'};

llbx        = {lb1,lb2};
uubx        = {ub1,ub2};
AA          = {A1,A2};

opts = struct('rho0',rho,'rhoUpdate',1,'rhoMax',5e3,'mu0',mu,'muUpdate',1,...
    'muMax',1e5,'eps',eps,'maxiter',maxit);

% convert to new interface
[sProb, opts] = old2new(ffifun,ggifun,hhifun,AA,yy0,lam0,llbx,uubx,Sig,opts);

res_ALADIN    = run_ALADIN(sProb,opts);
                                  
% solve centralized problem with CasADi & IPOPT
y1  =   sym('y1',[n,1],'real');
y2  =   sym('y2',[n,1],'real');
f1fun   =   matlabFunction(f1,'Vars',{y1});
f2fun   =   matlabFunction(f2,'Vars',{y2});
h1fun   =   emptyfun;
h2fun   =   emptyfun;


% y0  =   ones(N*n,1);
y   =   SX.sym('y',[N*n,1]);
F   =   f1fun(y(1:4))+f2fun(y(5:8));
g   =   [h1fun(y(1:4));
         h2fun(y(5:8));
         [A1, A2]*y];
nlp =   struct('x',y,'f',F,'g',g);
cas =   nlpsol('solver','ipopt',nlp);
sol =   cas('lbx', [lb1; lb2],...
            'ubx', [ub1; ub2],...
            'lbg', [-inf;-inf;-inf;b], ...
            'ubg', [0;0;0;b]);  