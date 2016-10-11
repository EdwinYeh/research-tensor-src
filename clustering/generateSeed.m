function generateSeed(datasetName, userId, seedRatio, maxSeedCombination)

mkdir(sprintf('ClusterSeed/%s/', num2str(seedRatio)));
UserData = load(sprintf('../../%s/User%d.mat', datasetName, userId));
InstanceCluster = UserData.InstanceCluster;
SeedSet = cell(1, maxSeedCombination);
SeedCluster = cell(1, maxSeedCombination);

for seedCombinationId = 1: maxSeedCombination
    [numInstance, numCluster] = size(InstanceCluster);
    tmpSeedCluster = zeros(numInstance, numCluster);
    supervisedEntry = find(InstanceCluster);
    numSupervision = length(supervisedEntry);
    numSeed = round(numSupervision * seedRatio);
    tmpSeedCluster(supervisedEntry(randperm(numSupervision, numSeed))) = 1;
    tmpSeedSet = find(sum(tmpSeedCluster, 2));
    SeedSet{seedCombinationId} = tmpSeedSet;
    SeedCluster{seedCombinationId} = tmpSeedCluster;
    save(sprintf('ClusterSeed/%s/SeedData_%s_%d.mat', num2str(seedRatio), datasetName, userId), 'SeedSet', 'SeedCluster');
end
end