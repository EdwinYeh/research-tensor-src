time = round(clock);
fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
fprintf('Use Sigma:%g, Lambda:%g, Gama:%g, Delta:%g\n', sigma, lambda, gama, delta);

bestRandomInitialObjectiveScore = Inf;
U = cell(2,1);
V = cell(2,1);
realU = cell(2,1);
realV = cell(2,1);

for t = 1: randomTryTime
    
    CP1 = rand(numInstanceCluster, cpRank);
    CP2 = rand(numFeatureCluster, cpRank);
    CP3 = rand(numInstanceCluster, cpRank);
    CP4 = rand(numFeatureCluster, cpRank);
    
    for dom = 1:2
        U{dom} = rand(numSampleInstance(dom), numInstanceCluster);
        V{dom} = rand(numSampleFeature, numFeatureCluster);
    end
    
    realCP1 = rand(numInstanceCluster, cpRank);
    realCP2 = rand(numFeatureCluster, cpRank);
    realCP3 = rand(numInstanceCluster, cpRank);
    realCP4 = rand(numFeatureCluster, cpRank);
    
    for dom = 1:2
        realU{dom} = rand(numSampleInstance(dom), numInstanceCluster);
        realV{dom} = rand(numSampleFeature, numFeatureCluster);
    end
    
    for fakeOptimization = 1:2
        objectiveScore = 0;
        newObjectiveScore = Inf;
        iter = 0;
        diff = Inf;
        convergeTimer = tic;
        
        if fakeOptimization == 2
            CP1 = realCP1;
            CP2 = realCP2;
            CP3 = realCP3;
            CP4 = realCP4;
            U = realU;
            V = realV;
        end
        
        while (diff >= 0.0001  && iter < maxIter)
            iter = iter + 1;
            oldObjectiveScore = newObjectiveScore;
            newObjectiveScore = 0;
            for dom = 1:numDom
                [A,sumFi,E] = projectTensorToMatrix({CP1,CP2,CP3,CP4}, dom);
                projB = A*sumFi*E';
                % Update V
                V{dom} = V{dom}.*sqrt((X{dom}'*U{dom}*projB + gama*Sv{dom}*V{dom})./(V{dom}*V{dom}'*V{dom}*projB'*U{dom}'*U{dom}*projB + gama*Dv{dom}*V{dom}));
                V{dom}(isnan(V{dom})) = 0;
                V{dom}(~isfinite(V{dom})) = 0;
                % Update U
                U{dom} = U{dom}.*sqrt((X{dom}*V{dom}*projB' + lambda*Su{dom}*U{dom})./U{dom}*U{dom}'*(U{dom}*projB*V{dom}'*V{dom}*projB' + lambda*Du{dom}*U{dom}));
                U{dom}(isnan(U{dom})) = 0;
                U{dom}(~isfinite(U{dom})) = 0;
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
                A(isnan(A)) = 0;
                A(~isfinite(A)) = 0;
                if dom == sourceDomain
                    CP1 = A;
                else
                    CP3 = A;
                end
                %disp(sprintf('\t\tupdate E...'));
                E = E.*sqrt((V{dom}'*X{dom}'*U{dom}*A*sumFi)./(V{dom}'*V{dom}*E*sumFi*A'*U{dom}'*U{dom}*A*sumFi+delta*ones(rE,rA)*A*sumFi));
                E(isnan(E)) = 0;
                E(~isfinite(E)) = 0;
                if dom == sourceDomain
                    CP2 = E;
                else
                    CP4 = E;
                end
            end
            %disp(sprintf('\tCalculate this iterator error'));
            for dom = 1:numDom
                [A,sumFi,E] = projectTensorToMatrix({CP1,CP2,CP3,CP4}, targetDomain);
                projB = A*sumFi*E';
                result = U{targetDomain}*projB*V{targetDomain}';
                normEmp = norm((X{dom} - result), 'fro')*norm((X{dom} - result), 'fro');
                smoothU = lambda*trace(U{dom}'*Lu{dom}*U{dom});
                smoothV = gama*trace(V{dom}'*Lv{dom}*V{dom});
                oneNormH = delta*norm(projB,1);
                objectiveScore = normEmp + smoothU + smoothV + oneNormH;
                newObjectiveScore = newObjectiveScore + objectiveScore;
            end
            %disp(sprintf('\tEmperical Error:%f', newObjectiveScore));
            fprintf('fake:%d, iter:%d, error = %f\n', fakeOptimization, iter, newObjectiveScore);
            diff = oldObjectiveScore - newObjectiveScore;
        end
        
        if fakeOptimization == 1
            realCP1 = CP1;
            realCP2 = CP2;
            realCP3 = CP3;
            realCP4 = CP4;
            realU = U;
            realV = V;
        end
        
        if fakeOptimization == 2
            convergeTime = toc(convergeTimer);
            if newObjectiveScore < bestRandomInitialObjectiveScore
                bestRandomInitialObjectiveScore = newObjectiveScore;
                bestU = U;
                bestConvergeTime = convergeTime;
            end
        end
    end
end

targetTestingDataIndex = 1:CVFoldSize;
numCorrectPredict = 0;
for cvFold = 1: numCVFold
    targetTrainingDataIndex = setdiff(1:numInstance(targetDomain),targetTestingDataIndex);
    trainingData = [bestU{sourceDomain}; bestU{targetDomain}(targetTrainingDataIndex,:)];
    trainingLabel = [sampledLabel{sourceDomain}; sampledLabel{targetDomain}(targetTrainingDataIndex, :)];
    svmModel = fitcsvm(trainingData, trainingLabel, 'KernelFunction', 'rbf');
    predictLabel = predict(svmModel, bestU{targetDomain}(targetTestingDataIndex,:));
    for dataIndex = 1: CVFoldSize
        if sampledLabel{targetDomain}(targetTestingDataIndex(dataIndex)) == predictLabel(dataIndex)
            numCorrectPredict = numCorrectPredict + 1;
        end
    end
    targetTestingDataIndex = targetTestingDataIndex + CVFoldSize;
end
accuracy = numCorrectPredict/ (CVFoldSize*numCVFold);
fprintf('Sigma:%g, Lambda:%g, Gama:%g, Delta:%g, ObjectiveScore:%g, Accuracy:%g%%\n', sigma, lambda, gama, delta, bestRandomInitialObjectiveScore, accuracy);
fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g\n', sigma, lambda, gama, delta, bestRandomInitialObjectiveScore, accuracy, bestConvergeTime);