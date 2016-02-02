disp('Start training');

for tuneLambda = 0:lambdaTryTime
    lambda = 0.000001 * 10 ^ tuneLambda;
    time = round(clock);
    fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
    fprintf('Use Lambda:%f\n', lambda);
    %each pair is (objective score, accuracy);
    resultCellArray = cell(randomTryTime, 4);
    for t = 1: randomTryTime
        numCorrectPredict = 0;
        avgIterationUsed = 0;
        validateIndex = 1: CVFoldSize;
        foldObjectiveScores = zeros(1,numCVFold);
        TotalTimer = tic;
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
            
            while (diff >= 0.0001  && iter < maxIter)
                iter = iter + 1;
                oldObjectiveScore = newObjectiveScore;
                newObjectiveScore = 0;
                for i = 1:numDom
                    updateTimer  = tic;
%                     fprintf('iter:%d\n', iter);
%                     fprintf('domain:%d\n', i);
                    [projB, threeMatrixB] = SumOfMatricize(B, 2*(i - 1)+1);      
                    
                    tmpLu = Lu{i} + diag(0.0000001*ones(numSampleInstance(i), 1));
                    L = chol(tmpLu);
                    
                    % Solve cvx U
                    disp('Solve cvx U')
                    if i == sourceDomain
                        cvx_begin quiet
                            variable tmpU(size(U{i}));
                            minimize(norm(YMatrix{i}-tmpU*projB*V{i}', 'fro')+lambda*norm(tmpU'*L, 'fro'));
                        cvx_end
                    elseif i == targetDomain
                        cvx_begin quiet
                            variable tmpU(size(U{i}));
                            minimize(norm((YMatrix{i}-tmpU*projB*V{i}').*W, 'fro')+lambda*norm(tmpU'*L, 'fro'));  
                        cvx_end
                    end
                    %Assign cvx result
                    U{i} = tmpU;
                    
                    %Solve cvx V
                    %disp('Solve cvx V');
                    if i == sourceDomain
                        cvx_begin quiet
                            variable tmpV(size(V{i}));
                            minimize(norm(YMatrix{i}-U{i}*projB*tmpV', 'fro'));
                        cvx_end
                    elseif i == targetDomain
                        cvx_begin quiet
                            variable tmpV(size(V{i}));
                            minimize(norm((YMatrix{i}-U{i}*projB*tmpV').*W, 'fro'));
                        cvx_end
                    end
                    % Assign cvx result
                    V{i} = tmpV;

                    %Update fi
                    bestCPR = 20;
                    CP = cp_als(tensor(threeMatrixB), bestCPR, 'printitn', 0);                 
                    A = CP.U{1};
                    E = CP.U{2};
                    U3 = CP.U{3};
                    
                    fi = cell(1, length(CP.U{3}));
                    [r, c] = size(U3);
                    nextThreeB = zeros(numInstanceCluster, numFeatureCluster, r);
                    sumFi = zeros(c, c);
                    CPLamda = CP.lambda(:);
                    for idx = 1:r
                        fi{idx} = diag(CPLamda.*U3(idx,:)');
                        sumFi = sumFi + fi{idx};
                    end
                    %Update A, E
                    if isUpdateAE
                        %Solve cvx A
                        %disp('Solve cvx A');
                        if i == sourceDomain
                            cvx_begin quiet
                                variable tmpA(size(A));
                                minimize(norm(YMatrix{i}-U{i}*tmpA*sumFi*E'*V{i}',  'fro'));
                            cvx_end
                        elseif i == targetDomain
                            cvx_begin quiet
                                variable tmpA(size(A));
                                minimize(norm((YMatrix{i}-U{i}*tmpA*sumFi*E'*V{i}').*W, 'fro'));
                            cvx_end
                        end
                        % Assign cvx result
                        A = tmpA;
                        
                        %Solve cvx E
                        %disp('Solve cvx E');
                        if i == sourceDomain
                            cvx_begin quiet
                                variable tmpE(size(E));
                                minimize(norm(YMatrix{i}-U{i}*A*sumFi*tmpE'*V{i}', 'fro'));
                            cvx_end
                        elseif i == targetDomain
                            cvx_begin quiet
                                variable tmpE(size(E));
                                minimize(norm((YMatrix{i}-U{i}*A*sumFi*tmpE'*V{i}').*W, 'fro'));
                            cvx_end
                        end
                        % Assign cvx result
                        E = tmpE;
                        
                        for idx = 1:r
                            nextThreeB(:,:,idx) = A*fi{idx}*E';
                        end
                    end
                    B = InverseThreeToOriginalB(tensor(nextThreeB), 2*(i-1)+1, originalSize);
                end
                %disp(sprintf('\tCalculate this iterator error'));
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
%                 fprintf('iteration:%d, objectivescore:%f\n', iter, newObjectiveScore);
                diff = oldObjectiveScore - newObjectiveScore;
            end
            avgIterationUsed  = avgIterationUsed + iter/ numCVFold;
            fprintf('iteration used: %d\n', iter);
            foldObjectiveScores(fold) = newObjectiveScore;
            
            %calculate validationScore
            [projB, ~] = SumOfMatricize(B, 2*(targetDomain - 1)+1);
            result = U{targetDomain}*projB*V{targetDomain}';
            
            [~, maxIndex] = max(result, [], 2);
            predictResult = maxIndex;
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
        resultCellArray{t}{1} = avgObjectiveScore;
        resultCellArray{t}{2} = accuracy*100;
        resultCellArray{t}{3} = avgTime;
        resultCellArray{t}{4} = avgIterationUsed;
        time = round(clock);
        fprintf('Time: %d/%d/%d,%d:%d:%d\n', time(1), time(2), time(3), time(4), time(5), time(6));
        fprintf('Initial try: %d, ObjectiveScore:%f, Accuracy:%f%%\n', t, avgObjectiveScore, accuracy*100);
    end
    for numResult = 1:randomTryTime
        fprintf(resultFile, '%f,%f,%f,%f,%f\n', lambda, resultCellArray{numResult}{1}, resultCellArray{numResult}{2}, resultCellArray{numResult}{3}, resultCellArray{numResult}{4});
    end
end
showExperimentInfo(exp_title, datasetId, prefix, numSampleInstance, numSampleFeature, numInstanceCluster, numFeatureCluster, sigma);
fprintf('done\n');
fclose(resultFile);
% matlabpool close;