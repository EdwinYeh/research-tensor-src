function [X, Y, XW, Su, Du, AllSeedPerception, AllClusterSeedFilter, AllSeedSet] = ...
    prepareExperiment2(datasetName, userIdList, sigmaInstsnce, maxSeedCombination)
% Input:
%   userIdArray: 1-d array saving userId involved in experiment
% Output:
%   X: low level feature matrix of instance (#instance * #feature)
%   Y: cluster matrix of instance (#cluster * #instance)
%   XW: perception feature matrix of instance (#instance * #perception)
%   Su, Du: for calculating Laplacian matrix of instance
%   Sv, Dv: for calculating Laplacian matrix of perception feature
%   PerceptionSeedFilter: filter matrix that has value 1 on seed positions and remains 0 otherwise
% Note:
%   (1) #feature is shared to all users
%   (2) #perception feature & #cluster are different from users

% Y: p*i=>c*i v
% XW: i*c=>i*p v
% SeedCluster: i*c=>i*p(SeedPerception) v
% PerceptionSeedFilter: p*i=>c*i(ClusterSeedFilter)

if strcmp(datasetName, 'mturk')
    isSample = false;
else
    isSample = true;
end
numDom = length(userIdList);
X = cell(1,numDom);
Y = cell(1, numDom);
XW = cell(1, numDom);
Su = cell(1, numDom);
Du = cell(1, numDom);
SeedSet = cell(maxSeedCombination,1);
AllSeedSet = cell(maxSeedCombination, numDom);
AllSeedPerception = cell(maxSeedCombination, numDom);
AllClusterSeedFilter = cell(maxSeedCombination, numDom);

%     Sv = cell(1, domNum);
%     Dv = cell(1, domNum);
for domId = 1:numDom;
    userId = userIdList(domId);
    load(sprintf('../../%s/User%d.mat', datasetName, userId));
    load(sprintf('../../%s/data_feature.mat', datasetName));
    SeedData = load(sprintf('SeedData_%s_%d.mat', datasetName, userId));
    if isSample
        load(sprintf('../../%s/sampleData/User%d.mat', datasetName, userId));
        InstanceCluster = InstanceCluster(sampleIndex, bigEnoughClusterIndex);
        PerceptionInstance = PerceptionInstance(:, sampleIndex);
        data_feature = data_feature(sampleIndex, :);
    end
    % Normalize data
    if strcmp(datasetName, 'song')
        data_feature = zNormalize(data_feature);
    else
        data_feature = normr(data_feature);
    end
    X{domId} = data_feature;
    Y{domId} = InstanceCluster';
    XW{domId} = PerceptionInstance';
    [numInstance, ~] = size(data_feature);
    [numPerception, ~] = size(PerceptionInstance);
    [~, numCluster] = size(InstanceCluster);
    
    Su{domId} = zeros(numInstance, numInstance);
    Du{domId} = zeros(numInstance, numInstance);
    Su{domId} = gaussianSimilarityMatrix(data_feature, sigmaInstsnce);
    Su{domId}(isnan(Su{domId})) = 0;
    for instanceId = 1:numInstance
        Du{domId}(instanceId,instanceId) = sum(Su{domId}(instanceId,:));
    end
    for seedCombination = 1:maxSeedCombination
        SeedPerception = zeros(numInstance, numPerception);
        ClusterSeedFilter = zeros(numCluster, numInstance);
        seedSet = SeedData.SeedSet{seedCombination};
        AllSeedSet{seedCombination, domId} = seedSet;
        SeedPerception(seedSet,:) = PerceptionInstance(:,seedSet)';
        ClusterSeedFilter(:, seedSet) = 1;
        AllSeedPerception{seedCombination, domId} = SeedPerception;
        AllClusterSeedFilter{seedCombination, domId} = ClusterSeedFilter;
    end
end
[XW, remainPerceptionIndex] = deleteZeroPerception(XW);
for domId = 1:numDom
    for seedCombination = 1:maxSeedCombination
        AllSeedPerception{seedCombination, domId} = AllSeedPerception{seedCombination, domId}(:, remainPerceptionIndex);
    end
end

end


function newX = zNormalize(X)
% X: #instance x #feature
[numInstance, numFeature] = size(X);
newX = zeros(numInstance, numFeature);
for featureId = 1: numFeature
    colX = X(:, featureId);
    colX = (colX - mean(colX))/ std(colX);
    newX(:, featureId) = colX;
end
end

function [newXW,remainPerceptionIndex] = deleteZeroPerception(XW)
    numDom = length(XW);
    newXW = cell(1,numDom);
    combXW = [];
    for domId = 1:numDom
        combXW = [combXW; XW{domId}];
    end
    remainPerceptionIndex = find(sum(combXW,1) > 0);
    for domId = 1:numDom
        newXW{domId} = XW{domId}(:, remainPerceptionIndex);
    end
end