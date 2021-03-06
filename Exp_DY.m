% dataset 1 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.015	0.0001	1.00E-13
% 10	10	10	0.015	0.0001	1.00E-10
% 10	10	10	0.005	0.004	1.00E-07
% 10	10	10	0.015	0.0001	1.00E-16
%  dataset 2 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.005	0.0001	1.00E-13
% 10	10	10	0.005	0.004	1.00E-13
% 10	10	10	0.005	0.16	1.00E-07
% 10	10	10	0.005	0.0001	1.00E-07
% dataset 3 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.005	0.0001	1.00E-13
% 10	10	10	0.005	0.004	1.00E-16
% 10	10	10	0.015	0.004	1.00E-10
% 10	10	10	0.015	0.16	1.00E-13
% dataset 4 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.025	0.004	1.00E-07
% 10	10	10	0.015	0.0001	1.00E-10
% 10	10	10	0.015	0.004	1.00E-16
% 10	10	10	0.015	0.16	1.00E-07
% dataset 5 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.005	0.16	1.00E-13
% 10	10	10	0.015	0.004	1.00E-10
% 10	10	10	0.015	0.004	1.00E-07
% 10	10	10	0.005	6.4	    1.00E-13
% dataset 6 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.005	0.0001	1.00E-07
% 10	10	10	0.015	6.4	    1.00E-07
% 10	10	10	0.005	0.16	1.00E-16
% 10	10	10	0.005	0.004	1.00E-07
% dataset 7 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.035	0.0001	1.00E-07
% 10	10	10	0.035	0.004	1.00E-16
% 10	10	10	0.035	0.004	1.00E-10
% 10	10	10	0.035	0.0001	1.00E-10
% dataset 8 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.035	0.0001	1.00E-16
% 10	10	10	0.035	0.004	1.00E-13
% 10	10	10	0.025	0.0001	1.00E-16
% 10	10	10	0.025	0.004	1.00E-10
% dataset 9 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.035	6.4	1.00E-13
% 10	10	10	0.015	0.16	1.00E-16
% 10	10	10	0.035	0.0001	1.00E-10
% 10	10	10	0.005	0.0001	1.00E-13
% dataset 10 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.015	0.16	1.00E-16
% 10	10	10	0.015	0.004	1.00E-10
% 10	10	10	0.025	0.16	1.00E-16
% 10	10	10	0.015	0.16	1.00E-10
% dataset 11 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.015	0.004	1.00E-16
% 10	10	10	0.025	0.0001	1.00E-10
% 10	10	10	0.015	0.0001	1.00E-07
% 10	10	10	0.005	0.16	1.00E-13
% dataset 12 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.025	0.004	1.00E-07
% 10	10	10	0.025	6.4	    1.00E-07
% 10	10	10	0.025	0.004	1.00E-13
% 10	10	10	0.035	6.4	    1.00E-13
% dataset 13 (cpRank,instanceCluster,featureCluster,sigma,lambda,delta)
% 10	10	10	0.035	0.004	1.00E-13
% 10	10	10	0.035	0.16	1.00E-16
% 10	10	10	0.025	6.4	    1.00E-13
% 10	10	10	0.025	0.0001	1.00E-07

SetParameter;
sampleSizeLevel = 'bigSample2/';
resultDirectory = sprintf('../exp_result/%sDY/%d/', sampleSizeLevel, datasetId);
mkdir(resultDirectory);
expTitle = sprintf('DY_%d', datasetId);
resultFile = fopen(sprintf('%s%s_validate.csv', resultDirectory, expTitle), 'w');
fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');

lambdaStart = 10^-6;
lambdaScale = 100;
lambdaMaxOrder = 4;

deltaStart = 10^-18;
deltaScale = 10000;
deltaMaxOrder = 2;

if datasetId < 7
    sigmaList = 0.003:0.005:0.028;
else
    sigmaList = 0.01:0.01:0.06;
end

cpRankList = [15];
instanceClusterList = [15];
featureClusterList = [15];

randomTryTime = 1;
isTestPhase = false;
for tuneSigma = 1:length(sigmaList)
    sigma = sigmaList(tuneSigma);
    PrepareExperiment;
    for tuneCPRank = 1: length(cpRankList)
        cpRank = cpRankList(tuneCPRank);
        for tuneInstanceCluster = 1: length(instanceClusterList)
            numInstanceCluster = instanceClusterList(tuneInstanceCluster);
            for tuneFeatureCluster = 1: length(featureClusterList)
                numFeatureCluster = featureClusterList(tuneFeatureCluster);
                if numInstanceCluster <= cpRank && numFeatureCluster <= cpRank
                    for lambdaOrder = 0: lambdaMaxOrder
                        lambda = lambdaStart * lambdaScale ^ lambdaOrder;
                        for deltaOrder = 0: deltaMaxOrder
                            delta = deltaStart * deltaScale ^ deltaOrder;
                            main_DY;
                        end
                    end
                end
            end
        end
    end
end
fclose(resultFile);
disp('Start testing');
isTestPhase = true;
numCVFold = 1;
randomTryTime = 10;
resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
load(sprintf('%sBestParameter_%s.mat', resultDirectory, expTitle));
PrepareExperiment;
main_DY;
fclose(resultFile);