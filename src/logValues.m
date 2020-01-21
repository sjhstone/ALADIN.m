% logg consensus violation, objective value and gradient 
%consViol        = full(sol.g);
%consViolEq      = [consViolEq; consViol(1:nngi{j})];
%iinact{j}       = inact;

% maximal multiplier for inequalities
kappaMax        = max(abs(vertcat(iter.loc.KKapp{:})));


for j=1:NsubSys
        KioptEq{j}      = iter.loc.KKapp{j}(1:nngi{j});
        KioptIneq{j}    = iter.loc.KKapp{j}(nngi{j}+1:end); 
end

% logging
x               = vertcat(iter.loc.xx{:});
y               = vertcat(iter.yy{:});
yOld            = vertcat(iter.yyOld{:});

logg.X          = [iter.logg.X x];
logg.Y          = [iter.logg.Y y];
%         logg.delY       = [logg.delY delx];
%         logg.Kappa      = [logg.Kappa vertcat(Kiopt{:})];
%         logg.KappaEq    = [logg.KappaEq vertcat(KioptEq{:})];
%         logg.KappaIneq  = [logg.KappaIneq vertcat(KioptIneq{:})];
iter.logg.lam        = [iter.logg.lam iter.lam];
iter.logg.localStepS = [iter.logg.localStepS norm(x - yOld,inf)];
iter.logg.QPstepS    = [iter.logg.QPstepS norm(y-x,inf)];
iter.logg.Mfun       = [iter.logg.Mfun full(sProb.Mfun(y,iter.ls.muMeritMin*1.1))];
iter.logg.consViol   = [iter.logg.consViol norm([sProb.AA{:}]*x,inf)];
iter.logg.wrkSet     = [iter.logg.wrkSet ~vertcat(iter.loc.inact{:})];
if i>2 % number of changing active constraints
    iter.logg.wrkSetChang = [iter.logg.wrkSetChang sum(abs(iter.logg.wrkSet(:,end-1) - ~vertcat(iter.loc.inact{:})))];
end
%         logg.obj        = [logg.obj obj];
%    logg.desc       = [logg.desc full(grad'*delx)<0];
%         logg.alpha      = [logg.alpha alphaSQP];