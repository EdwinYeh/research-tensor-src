time = round(clock);
fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
fprintf('Use (cpRank, instanceCluster, featureCluster, Sigma, Lambda, Delta):(%g,%g,%g,%g,%g,%g)\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, lambda, delta);

bestObjectiveScore = Inf;
bestTestAccuracy = 0;
bestTime = Inf;
SU=cell(1,2);
SV=cell(1,2);
U = cell(numCVFold,2);
V = cell(numCVFold,2);
CP1 = cell(numCVFold,1);
CP2 = cell(numCVFold,1);
CP3 = cell(numCVFold,1);
CP4 = cell(numCVFold,1);

validationAccuracyList = zeros(randomTryTime, 1);
objectiveScoreList = zeros(randomTryTime, 1);
timeList = zeros(randomTryTime, 1);

for t = 1: randomTryTime
    
    for fold = 1: numCVFold
        CP1{fold} = rand(numInstanceCluster, cpRank);
        CP2{fold} = rand(numFeatureCluster, cpRank);
        CP3{fold} = rand(numInstanceCluster, cpRank);
        CP4{fold} = rand(numFeatureCluster, cpRank);
        
        for dom = 1: 2
            U{fold, dom} = rand(numSampleInstance(dom), numInstanceCluster);
            V{fold, dom} = rand(2, numFeatureCluster);
        end
    end
    
    numCorrectPredict = 0;
    hiddenIndex = 1: CVFoldSize;
    if isTestPhase
        hiddenIndex = hiddenIndex + numValidationInstance;
    end
    
    TotalTimer = tic;
    foldObjectiveScores = zeros(1,numCVFold);
    objTrack = cell(numCVFold, 1);
    
    for fold = 1:numCVFold
        YMatrix = TrueYMatrix;
        W = ones(numSampleInstance(targetDomain), numClass(1));
        W(hiddenIndex, :) = 0;
        [rY,cY]=size(YMatrix{1});
        iter = 0;
        diff = Inf;
        newObjectiveScore = Inf;
        stopTag = 0;
        
        while (stopTag < 75 && iter < maxIter)
            iter = iter + 1;
            %                 disp(diff);
%             fprintf('Fold:%d,Iteration:%d, ObjectiveScore:%g\n',fold, iter, newObjectiveScore);
            oldObjectiveScore = newObjectiveScore;
            tmpOldObj=oldObjectiveScore;
            for dom = 1:numDom
                [A,sumFi,E] = projectTensorToMatrix({CP1{fold},CP2{fold},CP3{fold},CP4{fold}}, dom);
                projB = A*sumFi*E';
                
                if dom == targetDomain
                    V{fold,dom} = V{fold,dom}.*sqrt(((YMatrix{dom}.*W)'*U{fold,dom}*projB)./(V{fold,dom}*V{fold,dom}'*(YMatrix{dom}'.*W')*U{fold,dom}*projB));
                else
                    V{fold,dom} = V{fold,dom}.*sqrt((YMatrix{dom}'*U{fold,dom}*projB)./(V{fold,dom}*V{fold,dom}'*(YMatrix{dom}')*U{fold,dom}*projB));
                end
                
                %update U
                if dom == targetDomain
                    U{fold,dom} = U{fold,dom}.*sqrt(((YMatrix{dom}.*W)*V{fold,dom}*projB'+lambda*Su{dom}*U{fold,dom})./(U{fold,dom}*U{fold,dom}'*(YMatrix{dom}.*W)*V{fold,dom}*projB'+lambda*Du{dom}*U{fold,dom}));
                else
                    U{fold,dom} = U{fold,dom}.*sqrt((YMatrix{dom}*V{fold,dom}*projB'+lambda*Su{dom}*U{fold,dom})./(U{fold,dom}*U{fold,dom}'*YMatrix{dom}*V{fold,dom}*projB'+lambda*Du{dom}*U{fold,dom}));
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
                [Num,Den]=cross_domain_term(YMatrix,W,U,V,CP1,CP2,CP3,CP4,dom,fold,'A',delta);
                if dom ==targetDomain
                    A = A.*sqrt((U{fold,dom}'*(YMatrix{dom}.*W)*V{fold,dom}*E*sumFi+Num)./(U{fold,dom}'*(U{fold,dom}*A*sumFi*E'*V{fold,dom}'.*W)*V{fold,dom}*E*sumFi+delta*ones(rE,rA)'*(sumFi*E')'+Den));
                else
                    A = A.*sqrt((U{fold,dom}'*YMatrix{dom}*V{fold,dom}*E*sumFi+Num)./(U{fold,dom}'*U{fold,dom}*A*sumFi*E'*V{fold,dom}'*V{fold,dom}*E*sumFi+delta*ones(rE,rA)'*(sumFi*E')'+Den));
                end
                %                     A(isnan(A)) = 0;
                %                     A(~isfinite(A)) = 0;
                if dom == sourceDomain
                    CP1{fold} = A;
                else
                    CP3{fold} = A;
                end
                [Num,Den]=cross_domain_term(YMatrix,W,U,V,CP1,CP2,CP3,CP4,dom,fold,'E',delta);
                if dom == targetDomain
                    E = E.*sqrt((V{fold,dom}'*(YMatrix{dom}.*W)'*U{fold,dom}*A*sumFi+Num)./(V{fold,dom}'*(V{fold,dom}*E*sumFi*A'*U{fold,dom}'.*W')*U{fold,dom}*A*sumFi+delta*ones(rE,rA)*A*sumFi+Den));
                else
                    E = E.*sqrt((V{fold,dom}'*YMatrix{dom}'*U{fold,dom}*A*sumFi+Num)./(V{fold,dom}'*V{fold,dom}*E*sumFi*A'*U{fold,dom}'*U{fold,dom}*A*sumFi+delta*ones(rE,rA)*A*sumFi+Den));
                end
                %                     E(isnan(E)) = 0;
                %                     E(~isfinite(E)) = 0;
                if dom == sourceDomain
                    CP2{fold} = E;
                else
                    CP4{fold} = E;
                end
                
            end
            newObjectiveScore = ShowObjective(fold, U, V, W, YMatrix, Lu, CP1, CP2, CP3, CP4, lambda, delta);
            objTrack{fold} = [objTrack{fold}, newObjectiveScore];
            diff = oldObjectiveScore - newObjectiveScore;
            if diff < 0.01
                stopTag = stopTag + 1;
            else
                stopTag = 0;
            end
        end
        foldObjectiveScores(fold) = newObjectiveScore;
        %Calculate objectiveScore
        [A,sumFi,E] = projectTensorToMatrix({CP1{fold},CP2{fold},CP3{fold},CP4{fold}}, targetDomain);
        projB = A*sumFi*E';
        result = U{fold,targetDomain}*projB*V{fold,targetDomain}';
        [~, maxIndex] = max(result, [], 2);
        predictResult = maxIndex;
        for dom = 1: CVFoldSize
            if(predictResult(hiddenIndex(dom)) == Label{targetDomain}(hiddenIndex(dom)))
                numCorrectPredict = numCorrectPredict + 1;
            end
        end
        hiddenIndex = hiddenIndex + CVFoldSize;
	if fold == numCVFold && t == randomTryTime
		if delta==0
			save('full_4way_result_delta0.mat', 'U', 'V', 'CP1', 'CP2', 'CP3', 'CP4','objTrack');
		else
			save('full_4way_result_deltaNot0.mat', 'U', 'V', 'CP1', 'CP2', 'CP3', 'CP4','objTrack');
		end
	end
    end
    
    if isTestPhase
        accuracy = numCorrectPredict/ numTestInstance;
    else
        accuracy = numCorrectPredict/ numValidationInstance;
    end
    
    avgObjectiveScore = sum(foldObjectiveScores)/ numCVFold;
    avgTime = toc(TotalTimer)/ numCVFold;
    fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, lambda, delta, avgObjectiveScore, accuracy, avgTime);

    if isTestPhase
%        fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, lambda, delta, avgObjectiveScore, accuracy, avgTime);
        if accuracy > bestTestAccuracy
            bestObjectiveScore = avgObjectiveScore;
            bestTestAccuracy = accuracy;
            bestTime = avgTime;
        end
    end
    time = round(clock);
    validationAccuracyList(t) = accuracy;
    objectiveScoreList(t) = avgObjectiveScore;
    timeList(t) = avgTime;
%     fprintf('randomTime:%d, accuracy: %g, objectiveScore:%g\n', t, accuracy, avgObjectiveScore);
end

if isTestPhase
%     fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, lambda, delta, bestObjectiveScore, bestTestAccuracy, bestTime);
else
    avgValidationAccuracy = sum(validationAccuracyList)/ randomTryTime;
    avgObjectiveScore = sum(objectiveScoreList)/ randomTryTime;
    avgTime = sum(timeList)/ randomTryTime;
    fprintf('avgValidationAccuracy: %g, objectiveScore:%g\n', avgValidationAccuracy, avgObjectiveScore);
    compareWithTheBest(avgValidationAccuracy, avgObjectiveScore, avgTime, sigma, lambda, delta, cpRank, numInstanceCluster, numFeatureCluster, resultDirectory, expTitle)
    fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, lambda, delta, avgObjectiveScore, avgValidationAccuracy, avgTime);
end
