datasetId = 7;
sampleSizeLevel = 'bigSample2/';
disp('DY/bigSample2');
SetParameter;
resultDirectory = sprintf('../exp_result/%sDY/%d/', sampleSizeLevel, datasetId);
mkdir(resultDirectory);
expTitle = sprintf('DY_%d', datasetId);
sigma = 0.035;
lambda = 0.0001;
delta = 10^-7;
cpRank = 15;
numInstanceCluster = 15;
numFeatureCluster = 15;
isTestPhase = true;
randomTryTime = 5;
nuCVFold = 1;
resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
PrepareExperiment;
main_DY;
fclose(resultFile);

% sampleSizeLevel = '1000(200)/';
% disp('DY/1000(200)');
% SetParameter;
% resultDirectory = sprintf('../exp_result/1000(200)/DY/%d/', datasetId);
% mkdir(resultDirectory);
% expTitle = sprintf('DY_%d', datasetId);
% sigma = 0.015;
% lambda = 0.0001;
% delta = 10^-13;
% cpRank = 15;
% numInstanceCluster = 15;
% numFeatureCluster = 15;
% isTestPhase = true;
% randomTryTime = 5;
% nuCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
% PrepareExperiment;
% main_DY;
% fclose(resultFile);
% 
% sampleSizeLevel = '1000(400)/';
% disp('DY/1000(400)');
% SetParameter;
% resultDirectory = sprintf('../exp_result/1000(400)/DY/%d/', datasetId);
% mkdir(resultDirectory);
% expTitle = sprintf('DY_%d', datasetId);
% sigma = 0.015;
% lambda = 0.0001;
% delta = 10^-13;
% cpRank = 15;
% numInstanceCluster = 15;
% numFeatureCluster = 15;
% isTestPhase = true;
% randomTryTime = 5;
% nuCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
% PrepareExperiment;
% main_DY;
% fclose(resultFile);
% 
% sampleSizeLevel = '1000(600)/';
% disp('DY/1000(600)');
% SetParameter;
% resultDirectory = sprintf('../exp_result/1000(600)/DY/%d/', datasetId);
% mkdir(resultDirectory);
% expTitle = sprintf('DY_%d', datasetId);
% sigma = 0.015;
% lambda = 0.0001;
% delta = 10^-13;
% cpRank = 15;
% numInstanceCluster = 15;
% numFeatureCluster = 15;
% isTestPhase = true;
% randomTryTime = 5;
% nuCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
% PrepareExperiment;
% main_DY;
% fclose(resultFile);
% 
% sampleSizeLevel = '1000(800)/';
% disp('DY/1000(800)');
% SetParameter;
% resultDirectory = sprintf('../exp_result/1000(800)/DY/%d/', datasetId);
% mkdir(resultDirectory);
% expTitle = sprintf('DY_%d', datasetId);
% sigma = 0.015;
% lambda = 0.0001;
% delta = 10^-13;
% cpRank = 15;
% numInstanceCluster = 15;
% numFeatureCluster = 15;
% isTestPhase = true;
% randomTryTime = 5;
% nuCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
% PrepareExperiment;
% main_DY;
% fclose(resultFile);