function [ sol, timers ] = iterateAL( sProb, opts, timers )
%ITERATEAL Summary of this function goes here
NsubSys = length(sProb.AA);
Ncons   = size(sProb.AA{1},1);
initializeVariables;

if isfield(sProb, 'p')
    parSubstitution;
end

iterTimer = tic;
i         = 1;
iter.i    = 1;

while ((i <= opts.maxiter) && ( (strcmp(opts.term_eps,'false')) || ...
                                      (iter.logg.consViol(i) >= opts.term_eps)))
                             
    % solve local NLPs and evaluate sensitivities
    [ timers, opts, iter ] = parallelStep( sProb, iter, timers, opts );

    % set up and solve the coordination QP
    tic
    iter.lamOld      = iter.lam;
    if strcmp(opts.innerAlg, 'none')
        % update scaling matrix for consensus violation slack
        if strcmp(opts.DelUp,'true') 
            if i > 2                            
                [opts.Del, iter.consViol] = updateParam(opts.Del,...
                         [sProb.AA{:}]*vertcat(iter.yy{:}),iter.consViol, 'Del');
            else
                iter.consViol = [sProb.AA{:}]*vertcat(iter.yy{:});
            end
        end
        
        % set up and solve coordination QP
        [ HQP, gQP, AQP, bQP]   = createCoordQP( sProb, iter, opts );
        [ xs, lamTot]           = solveQP(HQP,gQP,AQP,bQP,opts.solveQP);    
        [ iter.ddelx iter.lam ] = decomposeX(xs, lamTot, iter, opts);
    else 
        % solve coordination QP decentrally
        iter.loc.cond           = condenseLocally(sProb, iter);
        % solve condensed QP by decentralized CG/ADMM
        [ iter.llam, iter.lam, iter.comm ] = ...
                              solveQPdec(iter.loc.cond, iter.lam, opts);
       % [ iter.llam, iter.lam ] = solveQPdecOld(iter.loc.cond, iter.lam, ...
      %                                                 opts, iter, sProb );
        % expand again locally based on computed \lamda
        iter.ddelx              = expandLocally(iter.llam, iter.loc.cond);
        
        % update mu in classical since Del not yet included --> has tto be adapted
        % to new structure
        if iter.stepSizes.mu < opts.muMax
            iter.stepSizes.mu = iter.stepSizes.mu * opts.muUpdate;
        end
    end        
    timers.QPtotTime      = timers.QPtotTime + toc;   
   
    % do a line search on the QP step?
    linS = false;
    if linS == true
        stepSizes.alpha   = lineSearch(Mfun, x ,delx);
    end
  
    % compute the ALADIN step
    iter.yyOld            = iter.yy; 
    [ iter.yy, iter.lam ] = computeALstep( iter );
    
    % rho update
    if iter.stepSizes.rho < opts.rhoMax
        iter.stepSizes.rho = iter.stepSizes.rho * opts.rhoUpdate;
    end
    % mu update
    if iter.stepSizes.mu < opts.muMax && strcmp(opts.DelUp, 'false')
        opts.Del  = opts.Del * 1/opts.muUpdate;
    end
    
    % logging of variables?
    loggFl = true;
    if loggFl == true
        logValues;
    end
   
    % plot iterates?
    if strcmp(opts.plot,'true') 
       tic
       plotIterates;
       timers.plotTimer = timers.plotTimer + toc;
    end
    
    i      = i+1;
    iter.i = i;
end
timers.iterTime = toc(iterTimer);

sol.xxOpt  = iter.yy;
sol.lamOpt = iter.lam;
sol.iter   = iter;

end

