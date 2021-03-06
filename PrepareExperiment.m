if datasetId <= 6
    dataType = 1;
    prefix = '../20-newsgroup/';
elseif datasetId > 6 && datasetId <= 9
    dataType = 1;
    prefix = '../Reuter/';
elseif datasetId >= 10
    dataType = 2;
    prefix = '../Animal_img/';
end

domainNameList = {sprintf('source%d.csv', datasetId), sprintf('target%d.csv', datasetId)};

TrueYMatrix = cell(1, numDom);
YMatrix = cell(1, numDom);
Label = cell(1, numDom);
Su = cell(1, numDom);
Du = cell(1, numDom);
Lu = cell(1, numDom);

X = createSparseMatrix_multiple(prefix, domainNameList, numDom, dataType);

sourceDataIndex = csvread(sprintf('sampleIndex/%ssampleSourceDataIndex%d.csv', sampleSizeLevel, datasetId));
validationDataIndex = csvread(sprintf('sampleIndex/%ssampleValidationDataIndex%d.csv', sampleSizeLevel, datasetId));
numValidationInstance = length(validationDataIndex);
testDataIndex = csvread(sprintf('sampleIndex/%ssampleTestDataIndex%d.csv', sampleSizeLevel, datasetId));
numTestInstance = length(testDataIndex);

denseFeatures = findCoDenseFeature(X{1}, X{2}, numSampleFeature);
for i = 1: numDom
    domainName = domainNameList{i};
    Label{i} = load([prefix, domainName(1:length(domainName)-4), '_label.csv']);
    %Randomly sample instances & the corresponding labels
    %     fprintf('Sample domain %d data\n', i);
    if isSampleInstance == true
        if i == sourceDomain
            X{i} = X{i}(sourceDataIndex, :);
            Label{i} = Label{i}(sourceDataIndex, :);
        elseif i == targetDomain
            if isTestPhase == true
                X{i} = [X{i}(validationDataIndex, :); X{i}(testDataIndex, :)];
                Label{i} = [Label{i}(validationDataIndex, :); Label{i}(testDataIndex, :)];
            else
                X{i} = X{i}(validationDataIndex, :);
                Label{i} = Label{i}(validationDataIndex, :);
            end
        end
    end
    [numSampleInstance(i), ~] = size(X{i});
    if isSampleFeature == true
        %             denseFeatures = findDenseFeature(X{i}, numSampleFeature);
        X{i} = X{i}(:, denseFeatures);
    end
    TrueYMatrix{i} = zeros(numSampleInstance(i), numClass(i));
    for j = 1: numSampleInstance(i)
        TrueYMatrix{i}(j, Label{i}(j)) = 1;
    end
    X{i} = normr(X{i});
end

%
prepareTimer = tic;
for dom = 1: numDom
    Su{dom} = zeros(numSampleInstance(dom), numSampleInstance(dom));
    Du{dom} = zeros(numSampleInstance(dom), numSampleInstance(dom));
    Lu{dom} = zeros(numSampleInstance(dom), numSampleInstance(dom));
    
    %user
    %     fprintf('Domain%d: calculating Su, Du, Lu\n', dom);
    Su{dom} = gaussianSimilarityMatrix(X{dom}, sigma);
    Su{dom}(isnan(Su{dom})) = 0;
    for useri = 1:numSampleInstance(dom)
        Du{dom}(useri,useri) = sum(Su{dom}(useri,:));
    end
    Lu{dom} = Du{dom} - Su{dom};
end

prepareTime = toc(prepareTimer);
disp(prepareTime);
if isTestPhase
    numCVFold = 1;
    CVFoldSize = numTestInstance/ numCVFold;
else
    CVFoldSize = numSampleInstance(targetDomain)/ numCVFold;
end
