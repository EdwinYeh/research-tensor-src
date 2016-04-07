disp('Start training');

if isTestPhase
    resultFile = fopen(sprintf('../exp_result/result_%s.csv', exp_title), 'w');
    fprintf(resultFile, 'sigma,sigma2,lambda,objectiveScore,accuracy,trainingTime\n');
end

time = round(clock);
fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
fprintf('Use Lambda:%f\n', lambda);
%each pair is (objective score, accuracy);
resultCellArray = cell(randomTryTime);
bestObjectiveScore = Inf;

for t = 1: randomTryTime
    numCorrectPredict = 0;
    avgIterationUsed = 0;
    validateIndex = 1: CVFoldSize;
    foldObjectiveScores = zeros(1,numCVFold);
    TotalTimer = tic;
    totalPredictResult = zeros(numSampleInstance(targetDomain), 1);
    for fold = 1:numCVFold
        YMatrix = TrueYMatrix;
        YMatrix{targetDomain}(validateIndex, :) = zeros(CVFoldSize, numClass(1));
        W = ones(numSampleInstance(targetDomain), numClass(1));
        W(validateIndex, :) = 0;
        U = initU(t, :);
        V = initV(t, :);
        B = initB{t};
        iter = 0;
        diff = Inf;
        newObjectiveScore = Inf;
        
        while (abs(diff) >= 0.001  && iter < maxIter)
            iter = iter + 1;
            oldObjectiveScore = newObjectiveScore;
            newObjectiveScore = 0;
            for i = 1:numDom
                [projB, threeMatrixB] = SumOfMatricize(B, 2*(i - 1)+1);
                bestCPR = 20;
                CP = cp_apr(tensor(threeMatrixB), bestCPR, 'printitn', 0, 'alg', 'mu');%parafac_als(tensor(threeMatrixB), bestCPR);
                
                A = CP.U{1};
                E = CP.U{2};
                U3 = CP.U{3};
                
                fi = cell(1, length(CP.U{3}));
                
                if i == targetDomain
                    V{i} = V{i}.*sqrt((YMatrix{i}'*U{i}*projB)./((V{i}*projB'*U{i}'.*W')*U{i}*projB));
                else
                    V{i} = V{i}.*sqrt((YMatrix{i}'*U{i}*projB)./((V{i}*projB'*U{i}')*U{i}*projB));
                end
                V{i}(isnan(V{i})) = 0;
                V{i}(~isfinite(V{i})) = 0;
                
                %col normalize
                [r, ~] = size(V{i});
                for tmpI = 1:r
                    bot = sum(abs(V{i}(tmpI,:)));
                    if bot == 0
                        bot = 1;
                    end
                    V{i}(tmpI,:) = V{i}(tmpI,:)/bot;
                end
                V{i}(isnan(V{i})) = 0;
                V{i}(~isfinite(V{i})) = 0;
                
                %update U
                if i == targetDomain
                    U{i} = U{i}.*sqrt((YMatrix{i}*V{i}*projB' + lambda*Su{i}*U{i})./((U{i}*projB*V{i}'.*W)*V{i}*projB' + lambda*Du{i}*U{i}));
                else
                    U{i} = U{i}.*sqrt((YMatrix{i}*V{i}*projB' + lambda*Su{i}*U{i})./(U{i}*projB*V{i}'*V{i}*projB' + lambda*Du{i}*U{i}));
                end
                U{i}(isnan(U{i})) = 0;
                U{i}(~isfinite(U{i})) = 0;
                
                %col normalize
                [r, ~] = size(U{i});
                for tmpI = 1:r
                    bot = sum(abs(U{i}(tmpI,:)));
                    if bot == 0
                        bot = 1;
                    end
                    U{i}(tmpI,:) = U{i}(tmpI,:)/bot;
                end
                U{i}(isnan(U{i})) = 0;
                U{i}(~isfinite(U{i})) = 0;
                
                %update fi
                [r, c] = size(U3);
                nextThreeB = zeros(numInstanceCluster, numFeatureCluster, r);
                sumFi = zeros(c, c);
                CPLamda = CP.lambda(:);
                for idx = 1:r
                    fi{idx} = diag(CPLamda.*U3(idx,:)');
                    sumFi = sumFi + fi{idx};
                end
                if isUpdateAE
                    [rA, cA] = size(A);
                    onesA = ones(rA, cA);
                    A = A.*sqrt((U{i}'*YMatrix{i}*V{i}*E*sumFi+alpha*(onesA))./((A*sumFi*(E'*E)*sumFi'/norm(A*sumFi*E','fro'))+U{i}'*U{i}*A*sumFi*E'*V{i}'*V{i}*E*sumFi));
                    A(isnan(A)) = 0;
                    A(~isfinite(A)) = 0;
                    A(isnan(A)) = 0;
                    A(~isfinite(A)) = 0;
                    
                    [rE ,cE] = size(E);
                    onesE = ones(rE, cE);
                    E = E.*sqrt((V{i}'*YMatrix{i}'*U{i}*A*sumFi + beta*(onesE))./((E*sumFi'*(A'*A)*sumFi/norm(A*sumFi*E','fro'))+V{i}'*V{i}*E*sumFi*A'*U{i}'*U{i}*A*sumFi));
                    E(isnan(E)) = 0;
                    E(~isfinite(E)) = 0;
                    E(isnan(E)) = 0;
                    E(~isfinite(E)) = 0;
                    for idx = 1:r
                        nextThreeB(:,:,idx) = A*fi{idx}*E';
                    end
                end
                B = InverseThreeToOriginalB(tensor(nextThreeB), 2*(i-1)+1, originalSize);
            end
            for i = 1:numDom
                [projB, ~] = SumOfMatricize(B, 2*(i - 1)+1);
                result = U{i}*projB*V{i}';
                if i == targetDomain
                    normEmp = norm((YMatrix{i} - result).*W, 'fro')*norm((YMatrix{i} - result).*W, 'fro');
                else
                    normEmp = norm((YMatrix{i} - result), 'fro')*norm((YMatrix{i} - result), 'fro');
                end
                smoothU = lambda*trace(U{i}'*Lu{i}*U{i});
                objectiveScore = normEmp + smoothU;
                newObjectiveScore = newObjectiveScore + objectiveScore;
            end
            diff = oldObjectiveScore - newObjectiveScore;
        end
        foldObjectiveScores(fold) = newObjectiveScore;
        
        %calculate validationScore
        [projB, ~] = SumOfMatricize(B, 2*(targetDomain - 1)+1);
        result = U{targetDomain}*projB*V{targetDomain}';
        
        [~, maxIndex] = max(result, [], 2);
        predictResult = maxIndex;
        totalPredictResult(validateIndex) = predictResult(validateIndex);
        for i = 1: CVFoldSize
            if(predictResult(validateIndex(i)) == Label{targetDomain}(validateIndex(i)))
                numCorrectPredict = numCorrectPredict + 1;
            end
        end
        validateIndex = validateIndex + CVFoldSize;
    end
    
    accuracy = numCorrectPredict/ numSampleInstance(targetDomain);
    avgObjectiveScore = sum(foldObjectiveScores)/ numCVFold;
    avgTime = toc(TotalTimer)/ numCVFold;
    
    if avgObjectiveScore < bestObjectiveScore
        bestObjectiveScore = avgObjectiveScore;
        bestPredictResult = totalPredictResult;
    end
    
    time = round(clock);
    fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
    fprintf('Initial try: %d, ObjectiveScore:%f, Accuracy:%f%%\n', t, avgObjectiveScore, accuracy*100);
    resultCellArray{t}{1} = avgObjectiveScore;
    resultCellArray{t}{2} = accuracy*100;
    resultCellArray{t}{3} = avgTime;
end

if isTestPhase
    for numResult = 1:randomTryTime
        fprintf(resultFile, '%f,%f,%f,%f,%f,%f\n', sigma, lambda, resultCellArray{numResult}{1}, resultCellArray{numResult}{2}, resultCellArray{numResult}{3});
    end
%     csvwrite(sprintf('../exp_result/predict_result/%s_predict_result.csv', exp_title), bestPredictResult);
    fclose(resultFile);
end
fprintf('done\n\n');
% matlabpool close;