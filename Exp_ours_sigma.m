sigmaList = [1, 5, 10, 20, 50];

for sigmaTryTime = 1:5
%     datasetId = 1;
    SetParameter;
    lambdaTryTime = 0;
    sigma = sigmaList(sigmaTryTime);
    exp_title = sprintf('ours_%d_sigma_%f', datasetId, sigma);
    showExperimentInfo(exp_title, datasetId, prefix, numSampleInstance, numSampleFeature, numInstanceCluster, numFeatureCluster, sigma);
    PrepareExperiment;
    main_ours;
end