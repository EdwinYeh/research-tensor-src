time = round(clock);
fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
fprintf('Use (Sigma, Sigma2, Lambda, Delta):(%g,%g,%g,%g)\n', sigma, sigma2, lambda, delta);

bestObjectiveScore = Inf;
bestAccuracy = 0;
bestTime = 0;
SU=cell(1,2);
SV=cell(1,2);

for t = 1: randomTryTime
    
    U = cell(numCVFold, 2);
    V = cell(numCVFold, 2);
    tmpU = cell(numCVFold, 2);
    tmpV = cell(numCVFold, 2);
    realU = cell(numCVFold, 2);
    realV = cell(numCVFold, 2);
    CP1 = cell(numCVFold, 1);
    CP2 = cell(numCVFold, 1);
    CP3 = cell(numCVFold, 1);
    CP4 = cell(numCVFold, 1);
    tmpCP1 = cell(numCVFold, 1);
    tmpCP2 = cell(numCVFold, 1);
    tmpCP3 = cell(numCVFold, 1);
    tmpCP4 = cell(numCVFold, 1);
    
    for fold = 1: numCVFold
        CP1{fold} = rand(numInstanceCluster, cpRank);
        CP2{fold} = rand(numFeatureCluster, cpRank);
        CP3{fold} = rand(numInstanceCluster, cpRank);
        CP4{fold} = rand(numFeatureCluster, cpRank);
        tmpCP1 = CP1;
        tmpCP2 = CP2;
        tmpCP3 = CP3;
        tmpCP4 = CP4;
        
        for dom = 1: 2
            U{fold, dom} = rand(numSampleInstance(dom), numInstanceCluster);
            V{fold, dom} = rand(2, numFeatureCluster);
        end
        tmpU = U;
        tmpV = V;
    end
    % When fakeOptimization == 1, train UVAE  to be the initial points
    % during fakeOptimization == 2. Only the report the result of
    % fakeOptimization == 2 will be report
    
    for fakeOptimization = 1: 2
        numCorrectPredict = 0;
        validateIndex = 1: CVFoldSize;
        TotalTimer = tic;
        foldObjectiveScores = zeros(1,numCVFold);
        
        if fakeOptimization == 2
           U = realU;
           V = realV;
           maxIter = 500;
        end
        
        for fold = 1:numCVFold
            YMatrix = TrueYMatrix;
            W = ones(numSampleInstance(targetDomain), numClass(1));
            W(validateIndex, :) = 0;
            [rY,cY]=size(YMatrix{1});
%             SU{1} = eye(rY);
%             SU{2} = SU{1};
%             SV{1} = eye(cY);
%             SV{2} = SV{1};
            iter = 0;
            diff = Inf;
            newObjectiveScore = Inf;
            
            while ((fakeOptimization == 2 && diff >= 0.0001 && iter < maxIter)||(fakeOptimization ~= 2 && iter < maxIter))
                iter = iter + 1;
                fprintf('Fake:%d, Fold:%d, Iteration:%d, ObjectiveScore:%g\n', fakeOptimization, fold, iter, newObjectiveScore);
                oldObjectiveScore = newObjectiveScore;
                tmpOldObj=oldObjectiveScore;
                for dom = 1:numDom
                    [A,sumFi,E] = projectTensorToMatrix({CP1{fold},CP2{fold},CP3{fold},CP4{fold}}, dom);
                    projB = A*sumFi*E';
                    
                    if dom == targetDomain
                        tmpV{fold,dom} = V{fold,dom}.*sqrt(((YMatrix{dom}.*W)'*U{fold,dom}*projB)./(V{fold,dom}*V{fold,dom}'*(V{fold,dom}*projB'*U{fold,dom}'.*W')*U{fold,dom}*projB));
                    else
                        tmpV{fold,dom} = V{fold,dom}.*sqrt((YMatrix{dom}'*U{fold,dom}*projB)./(V{fold,dom}*V{fold,dom}'*(V{fold,dom}*projB'*U{fold,dom}')*U{fold,dom}*projB));
                    end
                    tmpV{fold,dom}(isnan(V{fold,dom})) = 0;
                    tmpV{fold,dom}(~isfinite(V{fold,dom})) = 0;
                    tmpObjectiveScore = ShowObjective(fold, U, tmpV, W, YMatrix, Lu, CP1, CP2, CP3, CP4, lambda);
                    
                    if fakeOptimization == 2
                        if tmpObjectiveScore < tmpOldObj
                            tmpOldObj = tmpObjectiveScore;
                            V = tmpV;
                            fprintf('Update V (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        else
                            tmpV = V;
                            fprintf('Did not update V (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        end
                    else
                        tmpOldObj = tmpObjectiveScore;
                        V = tmpV;
                    end
                    
                    %update U
                    if dom == targetDomain
                        tmpU{fold,dom} = U{fold,dom}.*sqrt(((YMatrix{dom}.*W)*V{fold,dom}*projB'+lambda*Su{dom}*U{fold,dom})./(U{fold,dom}*U{fold,dom}'*(U{fold,dom}*projB*V{fold,dom}'.*W)*V{fold,dom}*projB'+lambda*Du{dom}*U{fold,dom}));
                    else
                        YMatrix{dom}*V{fold,dom}*projB';
                        tmpU{fold,dom} = U{fold,dom}.*sqrt((YMatrix{dom}*V{fold,dom}*projB'+lambda*Su{dom}*U{fold,dom})./(U{fold,dom}*U{fold,dom}'*U{fold,dom}*projB*V{fold,dom}'*V{fold,dom}*projB'+lambda*Du{dom}*U{fold,dom}));
                    end
                    tmpU{fold,dom}(isnan(U{fold,dom})) = 0;
                    tmpU{fold,dom}(~isfinite(U{fold,dom})) = 0;
                    tmpObjectiveScore = ShowObjective(fold, tmpU, V, W, YMatrix, Lu, CP1, CP2, CP3, CP4, lambda);                    
                    if fakeOptimization == 2
                        if tmpObjectiveScore < tmpOldObj
                            U = tmpU;
                            tmpOldObj=tmpObjectiveScore;
                            fprintf('Update U (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        else
                            tmpU = U;
                            fprintf('Did not update U (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        end                
                    else
                        U = tmpU;
                        tmpOldObj=tmpObjectiveScore;
                    end
                    
                    %update AE
                    if dom == sourceDomain
                        A = CP1{fold};
                        E = CP2{fold};
                    else
                        A = CP3{fold};
                        E = CP4{fold};
                    end
                    
                    [rA, cA] = size(A);
                    [rE, cE] = size(E);
                    
                    if dom ==targetDomain                        
                        A = A.*sqrt((U{fold,dom}'*(YMatrix{dom}.*W)*V{fold,dom}*E*sumFi)./(U{fold,dom}'*(U{fold,dom}*A*sumFi*E'*V{fold,dom}'.*W)*V{fold,dom}*E*sumFi+delta*ones(rE,rA)'*(sumFi*E')'));
                    else
                        A = A.*sqrt((U{fold,dom}'*YMatrix{dom}*V{fold,dom}*E*sumFi)./(U{fold,dom}'*U{fold,dom}*A*sumFi*E'*V{fold,dom}'*V{fold,dom}*E*sumFi+delta*ones(rE,rA)'*(sumFi*E')'));
                    end
                    A(isnan(A)) = 0;
                    A(~isfinite(A)) = 0;
                    if dom == sourceDomain
                        tmpCP1{fold} = A;              
                        tmpObjectiveScore = ShowObjective(fold, U, V, W, YMatrix, Lu, tmpCP1, CP2, CP3, CP4, lambda);
                    else
                        tmpCP3{fold} = A;
                        tmpObjectiveScore = ShowObjective(fold, U, V, W, YMatrix, Lu, CP1, CP2, tmpCP3, CP4, lambda);
                    end
                    if fakeOptimization == 2
                        if tmpObjectiveScore < tmpOldObj
                            fprintf('Update A (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                            if dom == sourceDomain
                                CP1 = tmpCP1;
                            else
                                CP3 = tmpCP3;
                            end
                        else
                            tmpCP1 = CP1;
                            tmpCP3 = CP3;
                            fprintf('Did not update A (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        end
                    else
                        if dom == sourceDomain
                            CP1 = tmpCP1;
                        else
                            CP3 = tmpCP3;
                        end
                        tmpOldObj = tmpObjectiveScore;
                    end                   
                    
                    if dom == targetDomain
                        E = E.*sqrt((V{fold,dom}'*(YMatrix{dom}.*W)'*U{fold,dom}*A*sumFi)./(V{fold,dom}'*(V{fold,dom}*E*sumFi*A'*U{fold,dom}'.*W')*U{fold,dom}*A*sumFi+delta*ones(rE,rA)*A*sumFi));
                    else
                        E = E.*sqrt((V{fold,dom}'*YMatrix{dom}'*U{fold,dom}*A*sumFi)./(V{fold,dom}'*V{fold,dom}*E*sumFi*A'*U{fold,dom}'*U{fold,dom}*A*sumFi+delta*ones(rE,rA)*A*sumFi));
                    end
                    E(isnan(E)) = 0;
                    E(~isfinite(E)) = 0;
                    if dom == sourceDomain
                        tmpCP2{fold} = E;              
                        tmpObjectiveScore = ShowObjective(fold, U, V, W, YMatrix, Lu, CP1, tmpCP2, CP3, CP4, lambda);
                    else
                        tmpCP4{fold} = E;
                        tmpObjectiveScore = ShowObjective(fold, U, V, W, YMatrix, Lu, CP1, CP2, CP3, tmpCP4, lambda);
                    end
                    if fakeOptimization == 2
                        if tmpObjectiveScore < tmpOldObj
                            if dom == sourceDomain
                                CP2 = tmpCP2;
                            else
                                CP4 = tmpCP4;
                            end
                            tmpOldObj = tmpObjectiveScore;
                            fprintf('Update E (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        else
                            tmpCP2 = CP2;
                            tmpCP4 = CP4;
                            fprintf('Did not update E (%f=>%f)\n', tmpOldObj, tmpObjectiveScore);
                        end   
                    else
                        if dom == sourceDomain
                            CP2 = tmpCP2;
                        else
                            CP4 = tmpCP4;
                        end
                        tmpOldObj = tmpObjectiveScore;
                    end
                    
                end
                newObjectiveScore = ShowObjective(fold, U, V, W, YMatrix, Lu, CP1, CP2, CP3, CP4, lambda);
                diff = oldObjectiveScore - newObjectiveScore;
            end
            foldObjectiveScores(fold) = newObjectiveScore;
            %calculate validationScore
            [A,sumFi,E] = projectTensorToMatrix({CP1{fold},CP2{fold},CP3{fold},CP4{fold}}, targetDomain);
            projB = A*sumFi*E';
            result = U{fold, targetDomain}*projB*V{fold, targetDomain}';
            [~, maxIndex] = max(result, [], 2);
            predictResult = maxIndex;
            for dom = 1: CVFoldSize
                if(predictResult(validateIndex(dom)) == Label{targetDomain}(validateIndex(dom)))
                    numCorrectPredict = numCorrectPredict + 1;
                end
            end
            validateIndex = validateIndex + CVFoldSize;
            
            if fakeOptimization == 1
                realU = U;
                realV = V;
            end
        end
        
        if fakeOptimization == 2
            accuracy = numCorrectPredict/ numSampleInstance(targetDomain);
            avgObjectiveScore = sum(foldObjectiveScores)/ numCVFold;
            avgTime = toc(TotalTimer)/ numCVFold;
            
            if avgObjectiveScore < bestObjectiveScore
                bestObjectiveScore = avgObjectiveScore;
                bestAccuracy = accuracy*100;
                bestTime = avgTime;
            end
            time = round(clock);
            %             fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
            %             fprintf('Initial try: %d, ObjectiveScore:%f, Accuracy:%f%%\n', t, avgObjectiveScore, accuracy*100);
        end
    end
end

fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g\n', sigma, sigma2, lambda, delta, bestObjectiveScore, bestAccuracy, bestTime);
%     csvwrite(sprintf('../exp_result/predict_result/%s_predict_result.csv', exp_title), bestPredictResult);