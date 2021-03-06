function generateSeed(datasetName, userId, maxSeedCombination)
    
    seedCount = 2;
    if strcmp(datasetName, 'mturk')
        isSample = false;
    else
        isSample = true;
    end
    load(sprintf('../../%s/User%d.mat', datasetName, userId));
    load(sprintf('../../%s/data_feature.mat', datasetName));
    if isSample
        load(sprintf('../../%s/sampleData/User%d.mat', datasetName, userId));
        InstanceCluster = InstanceCluster(sampleIndex, bigEnoughClusterIndex);
    end
    SeedSet = cell(1, maxSeedCombination);
    SeedCluster = cell(1, maxSeedCombination);
    for seedCombinationId = 1: maxSeedCombination
        [numInstance, numCluster] = size(InstanceCluster);
        tmpSeedCluster = zeros(numInstance, numCluster);
        tmpSeedSet = zeros(numCluster*seedCount, 1);
        for clusterId = 1: numCluster
            % Find each cluster's random two instances to be the cluster's seeds
            seed = find(InstanceCluster(:, clusterId));
            seed = seed(randperm(length(seed)));
            seed = seed(1:seedCount);
            tmpSeedSet(clusterId*seedCount-(seedCount-1): clusterId*seedCount) = seed;
            for seedId = 1: seedCount
                tmpSeedCluster(seed(seedId), clusterId) = 1;
            end
        end
        SeedSet{seedCombinationId} = tmpSeedSet;
        SeedCluster{seedCombinationId} = tmpSeedCluster;
    end
    save(sprintf('ClusterSeed/default/SeedData_%s_%d.mat', datasetName, userId), 'SeedSet', 'SeedCluster');
end