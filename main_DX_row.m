time = round(clock);
fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
fprintf('Use (cpRank, instanceCluster, featureCluster, sigma, sigma2, lambda, gama, delta):(%g,%g,%g,%g,%g,%g,%g,%g)\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, sigma2, lambda, gama, delta);

bestRandomInitialObjectiveScore = Inf;
U = cell(2,1);
V = cell(2,1);

validationAccuracyList = zeros(randomTryTime, 1);
validationObjectiveScoreList = zeros(randomTryTime, 1);
validationTimeList = zeros(randomTryTime, 1);

bestTestObjectiveScore = Inf;
bestTestAccuracy = 0;
bestTestTime = Inf;

objTrack = cell(randomTryTime, 1);
for t = 1: randomTryTime
    
    CP1 = rand(numInstanceCluster, cpRank);
    CP2 = rand(numFeatureCluster, cpRank);
    CP3 = rand(numInstanceCluster, cpRank);
    CP4 = rand(numFeatureCluster, cpRank);
    
    for dom = 1:2
        U{dom} = rand(numSampleInstance(dom), numInstanceCluster);
        V{dom} = rand(numSampleFeature, numFeatureCluster);
    end
    
    objectiveScore = 0;
    newObjectiveScore = Inf;
    iter = 0;
    diff = Inf;
    stopTag = 0;
    convergeTimer = tic;
    
    while (stopTag < 50  && iter < maxIter)
        iter = iter + 1;
        oldObjectiveScore = newObjectiveScore;
        newObjectiveScore = 0;
        for dom = 1:numDom
            [A,sumFi,E] = projectTensorToMatrix({CP1,CP2,CP3,CP4}, dom);
            projB = A*sumFi*E';
            % Update V
            V{dom} = V{dom}.*sqrt((X{dom}'*U{dom}*projB + gama*Sv{dom}*V{dom})./((U{dom}*projB*V{dom}')'*U{dom}*projB + gama*Dv{dom}*V{dom}));
            %row normalize
            [r, ~] = size(V{dom});
            for tmpI = 1:r
                bot = sum(abs(V{dom}(tmpI,:)));
                if bot == 0
                    bot = 1;
                end
                V{dom}(tmpI,:) = V{dom}(tmpI,:)/bot;
            end
            % Update U
            U{dom} = U{dom}.*sqrt((X{dom}*V{dom}*projB' + lambda*Su{dom}*U{dom})./((U{dom}*projB*V{dom}')*V{dom}*projB' + lambda*Du{dom}*U{dom}));
            [r, ~] = size(U{dom});
            for tmpI = 1:r
                bot = sum(abs(U{dom}(tmpI,:)));
                if bot == 0
                    bot = 1;
                end
                U{dom}(tmpI,:) = U{dom}(tmpI,:)/bot;
            end
            % Update A E
            if dom == sourceDomain
                A = CP1;
                E = CP2;
            else
                A = CP3;
                E = CP4;
            end
            [rA, cA] = size(A);
            [rE, cE] = size(E);
            
            A = A.*sqrt((U{dom}'*X{dom}*V{dom}*E*sumFi)./(U{dom}'*U{dom}*A*sumFi*E'*V{dom}'*V{dom}*E*sumFi+delta*ones(rE,rA)'*(sumFi*E')'));
            
            if dom == sourceDomain
                CP1 = A;
            else
                CP3 = A;
            end
            %disp(sprintf('\t\tupdate E...'));
            E = E.*sqrt((V{dom}'*X{dom}'*U{dom}*A*sumFi)./(V{dom}'*V{dom}*E*sumFi*A'*U{dom}'*U{dom}*A*sumFi+delta*ones(rE,rA)*A*sumFi));
            
            if dom == sourceDomain
                CP2 = E;
            else
                CP4 = E;
            end
        end
        %disp(sprintf('\tCalculate this iterator error'));
        for dom = 1:numDom
            [A,sumFi,E] = projectTensorToMatrix({CP1,CP2,CP3,CP4}, dom);
            projB = A*sumFi*E';
            result = U{dom}*projB*V{dom}';
            normEmp = norm((X{dom} - result), 'fro')*norm((X{dom} - result), 'fro');
            smoothU = lambda*trace(U{dom}'*Lu{dom}*U{dom});
            smoothV = gama*trace(V{dom}'*Lv{dom}*V{dom});
            oneNormH = delta*norm(projB,1);
            objectiveScore = normEmp + smoothU + smoothV + oneNormH;
            newObjectiveScore = newObjectiveScore + objectiveScore;
        end
        objTrack{t} = [objTrack{t}, newObjectiveScore];
        %disp(sprintf('\tEmperical Error:%f', newObjectiveScore));
        %         fprintf('iter:%d, objective = %f\n', iter, newObjectiveScore);
        diff = oldObjectiveScore - newObjectiveScore;
        if diff < 0.1
            stopTag = stopTag + 1;
        else
            stopTag = 0;
        end
    end
    
    convergeTime = toc(convergeTimer);
    save(sprintf('%sU(%d)_%g_%g_%g_%g_%g_%g_%g_%g.mat', resultDirectory, t, cpRank, numInstanceCluster, numFeatureCluster, sigma, sigma2, lambda, gama, delta), 'U', 'newObjectiveScore');
%     holdoutIndex = 1:CVFoldSize;
%     if isTestPhase
%         holdoutIndex = holdoutIndex + numValidationInstance;
%     end
%     
%     numCorrectPredict = 0;
%     for cvFold = 1: numCVFold
%         targetTrainingDataIndex = setdiff(1:numSampleInstance(targetDomain),holdoutIndex);
%         trainingData = [U{sourceDomain}; U{targetDomain}(targetTrainingDataIndex,:)];
%         trainingLabel = [sampledLabel{sourceDomain}; sampledLabel{targetDomain}(targetTrainingDataIndex, :)];
%         svmModel = fitcsvm(trainingData, trainingLabel, 'KernelFunction', 'rbf', 'KernelScale', 'auto', 'Standardize', true);
%         predictLabel = predict(svmModel, U{targetDomain}(holdoutIndex,:));
%         for dataIndex = 1: CVFoldSize
%             if sampledLabel{targetDomain}(holdoutIndex(dataIndex)) == predictLabel(dataIndex)
%                 numCorrectPredict = numCorrectPredict + 1;
%             end
%         end
%         holdoutIndex = holdoutIndex + CVFoldSize;
%     end
%     if isTestPhase
%         testAccuracy = numCorrect/ numTestInstance;
%         if newObjectiveScore < bestTestObjectiveScore
%             bestTestObjectiveScore = newObjectiveScore;
%             bestTestAccuracy = testAccuracy;
%             bestTestTime = convergeTime;
%         end
%     else
%         validationAccuracy = numCorrectPredict/ numValidationInstance;
%         validationTimeList(t) = convergeTime;
%         validationObjectiveScoreList(t) = newObjectiveScore;
%     end
end

% if isTestPhase
%     fprtinf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, sigma2, lambda, gama, delta, bestTestObjectiveScore, bestTestAccuracy, bestTestTime);
%     fprintf('bestTestAccuracy: %g, objectiveScore: %g\n', bestTestAccuracy, bestTestObjectiveScore);
% else
%     avgValidationAccuracy = sum(validationAccuracyList)/ randomTryTime;
%     avgObjectiveScore = sum(validationObjectiveScoreList)/ randomTryTime;
%     avgValidationTime = sum(validationTimeList)/ randomTryTime;
%     fprintf('avgValidationAccuracy: %g, objectiveScore:%g\n', avgValidationAccuracy, avgObjectiveScore);
%     compareWithTheBestDX(avgValidationAccuracy, avgObjectiveScore, avgValidationTime, sigma, sigma2, lambda, gama, delta, cpRank, numInstanceCluster, numFeatureCluster, resultDirectory, expTitle);
%     fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g,%g,%g\n', cpRank, numInstanceCluster, numFeatureCluster, sigma, sigma2, lambda, gama, delta, validationObjectiveScore, ValidationAccuracy, bestConvergeTime);
% end