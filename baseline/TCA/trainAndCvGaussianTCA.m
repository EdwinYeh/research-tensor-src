function [predictLabel, avgEmpError, accuracy ] = trainAndCvGaussianTCA( mu, sigma, numFold, numSourceData, numTargetData, numTestData, featureDimAfterReduce, sourceDomainData, targetDomainData, Y, isTestPhase)
    fprintf('mu = %f\nsigma = %f\n', mu, sigma);
    numCorrectPredict = 0;
    empErrorSum = 0;
    if isTestPhase
        sizeOfOneFold = numTestData/ numFold;
        numAllData = numSourceData + numTargetData + numTestData;
    else
        sizeOfOneFold = numTargetData/ numFold;
        numAllData = numSourceData + numTargetData;
    end
    
    % Pre-allocate matrix K, L, and compute H
    K = zeros(numAllData, numAllData);
    L = zeros(numAllData, numAllData);
    H = eye(numAllData) - ((1/(numAllData) * ones(numAllData, numAllData)));
    
    for fold = 0: (numFold-1)
        % Compute K, L matrix
        if isTestPhase
            validateDataIndex = (fold*sizeOfOneFold+1+numTestData: fold*sizeOfOneFold+sizeOfOneFold+numTestData) + numSourceData;
        else
            validateDataIndex = (fold*sizeOfOneFold+1: fold*sizeOfOneFold+sizeOfOneFold) + numSourceData;
        end
        fprintf('fold: %d, (%d~%d)\n', fold, min(validateDataIndex), max(validateDataIndex));
        trainDataIndex = setdiff(1:numAllData, validateDataIndex);
        trainY = Y(trainDataIndex);
        validateY = Y(validateDataIndex);
        %             fprintf('testIndex: %d~%d\n', min(testDataIndex), max(testDataIndex));
        
        for i = 1:numAllData
            for j = 1:numAllData
                if i > numSourceData
                    instance1 = targetDomainData(i-numSourceData, :);
                else
                    instance1 = sourceDomainData(i, :);
                end
                
                if j > numSourceData
                    instance2 = targetDomainData(j-numSourceData, :);
                else
                    instance2 = sourceDomainData(j, :);
                end
                
                %linear kernal
                %K(i, j) = instance1 * instance2';
                K(i, j) = gaussianSimilarity(instance1, instance2, sigma);
                
                if i < numSourceData && j < numSourceData
                    L(i, j) = 1/ numSourceData^2;
                elseif i > numSourceData && j > numSourceData
                    L(i, j) = 1/ (numTargetData-sizeOfOneFold)^2;
                else
                    L(i, j) = 1/ (numSourceData*(numTargetData-sizeOfOneFold));
                end
            end
        end
        tcaMatrix = (K*L*K + mu*eye(numAllData))\(K*H*K);
        [eigVectorMatrix, ~] = eig(tcaMatrix);
        transformMatrix = eigVectorMatrix(:, 1:featureDimAfterReduce);
        % Project data in kernel space to the learned components
        dimReducedMatrix = tcaMatrix * transformMatrix;
        trainX = dimReducedMatrix(trainDataIndex, :);
        svmModel = fitcsvm(trainX, trainY, 'KernelFunction', 'gaussian');
        empErrorSum = empErrorSum + loss(svmModel, trainX, trainY);
        predictLabel = predict(svmModel, dimReducedMatrix(validateDataIndex, :));
        
        for i = 1: sizeOfOneFold
            if(predictLabel(i) == validateY(i))
                numCorrectPredict = numCorrectPredict + 1;
            end
        end
    end
    avgEmpError = empErrorSum/ numFold;
    accuracy = numCorrectPredict/ numTargetData;
    disp(avgEmpError);
    disp(accuracy);
end