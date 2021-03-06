function sampleDataAndSave(datasetId, saveDirectory, numTrainInstance, numTestInstance)

mkdir(sprintf('sampleIndex/%s/', saveDirectory));

numDom = 2;
sourceDomain = 1;
targetDomain = 2;

if datasetId <= 6
    dataType = 1;
    prefix = '../20-newsgroup/';
elseif datasetId > 6 && datasetId <= 9
    dataType = 1;
    prefix = '../Reuter/';
elseif datasetId >= 10 &&datasetId <=13
    dataType = 2;
    prefix = '../Animal_img/';
elseif datasetId >=14 && datasetId <=23
    prefix = '../DBLP/';
end

if datasetId <= 13
    domainNameList = {sprintf('source%d.csv', datasetId), sprintf('target%d.csv', datasetId)};
    X = createSparseMatrix_multiple(prefix, domainNameList, numDom, dataType);
    [numSourceInstance, ~] = size(X{sourceDomain});
    [numTargetInstance, ~] = size(X{targetDomain});
    fprintf('dataset:%d=>[%d,%d]\n', datasetId, numSourceInstance, numTargetInstance);
    
elseif datasetId >=14 && datasetId <=23
    fileName = sprintf('%sDBLP%d.mat', prefix, datasetId - 13);
    load(fileName);
    [numSourceInstance, ~] = size(edges1);
    [numTargetInstance, ~] = size(edges2);
    
end

sampleSourceIndex = randperm(numSourceInstance, (numTrainInstance+numTestInstance));
sampleTargetIndex = randperm(numTargetInstance, (numTrainInstance+numTestInstance));

sampleSourceTrainIndex = sampleSourceIndex(1:numTrainInstance);
sampleSourceTestIndex = sampleSourceIndex(numTrainInstance+1:(numTrainInstance+numTestInstance));
sampleTargetTrainIndex = sampleTargetIndex(1:numTrainInstance);
sampleTargetTestIndex = sampleTargetIndex(numTrainInstance+1:(numTrainInstance+numTestInstance));

csvwrite(sprintf('sampleIndex/%s/sampleSourceTrainIndex%d.csv', saveDirectory, datasetId), sampleSourceTrainIndex);
csvwrite(sprintf('sampleIndex/%s/sampleSourceTestIndex%d.csv', saveDirectory, datasetId), sampleSourceTestIndex);
csvwrite(sprintf('sampleIndex/%s/sampleTargetTrainIndex%d.csv', saveDirectory, datasetId), sampleTargetTrainIndex);
csvwrite(sprintf('sampleIndex/%s/sampleTargetTestIndex%d.csv', saveDirectory, datasetId), sampleTargetTestIndex);

end