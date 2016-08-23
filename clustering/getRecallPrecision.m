function [ recall, precision] = getRecallPrecision(GroundTruth, Prediction, SeedSet)
% Calculate recall and precision for a domain

% Input
%   GroundTruth: instance x cluster matrix, has value 1 on (i, j) if instance
%       i belongs to j cluster
%   Prediction: instance x cluster matrix, prediction value from solver
%   supervisedIndex: vector that store the indeices that have groudtruth
% Output
%   Recall: matrix that stores recell of each cluster
%   Precision: vector that stores precision
    numCluster = size(GroundTruth, 2);
    supervisedIndex = find(sum(GroundTruth, 2));
    supervisedIndex = setdiff(supervisedIndex, SeedSet); 
    GroundTruth = GroundTruth(supervisedIndex, :);
    Prediction = Prediction(supervisedIndex, :);
    [~, PredictionResult] = max(Prediction, [], 2);
    Prediction = zeros(size(Prediction,1), size(Prediction,2));
    for instanceId = 1: length(PredictionResult)
        Prediction(instanceId, PredictionResult(instanceId)) = 1;
    end
   
    precision = 0;
    for clusterId = 1: numCluster;
        precisionDenominator = sum(Prediction(:, clusterId));
        if precisionDenominator ==0
            continue;
        end
        PrecisionIntersect = Prediction(:, clusterId) & GroundTruth(:, clusterId);
        PrecisionNumerator = sum(PrecisionIntersect);
        precision = precision + (PrecisionNumerator/ precisionDenominator);
    end
    precision = precision/ numCluster;
    
    recallDenominator = sum(sum(GroundTruth));
    recallIntersect = GroundTruth & Prediction;
    recallNumerator = sum(sum(recallIntersect));
    recall = recallNumerator/ recallDenominator;
end

