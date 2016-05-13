datasetId = 1;
sampleSizeLevel = '';
% DY
disp('DY');
SetParameter;
resultDirectory = sprintf('../exp_result/DY/%d/', datasetId);
mkdir(resultDirectory);
expTitle = sprintf('DY_%d', datasetId);
sigma = 0.015;
lambda = 0.0001;
delta = 10^-13;
cpRank = 10;
numInstanceCluster = 10;
numFeatureCluster = 10;
isTestPhase = true;
randomTryTime = 5;
nuCVFold = 1;
resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
PrepareExperiment;
main_DY;
fclose(resultFile);

%DY_cross
% disp('DY_cross');
% SetParameter;
% resultDirectory = sprintf('../exp_result/DY_cross/%d/', datasetId);
% mkdir(resultDirectory);
% expTitle = sprintf('DY_cross%d', datasetId);
% sigma = 0.015;
% lambda = 0.0001;
% delta = 10^-13;
% cpRank = 10;
% numInstanceCluster = 10;
% numFeatureCluster = 10;
% isTestPhase = true;
% randomTryTime = 5;
% nuCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
% PrepareExperiment;
% main_DY_cross_domain;
% delta = 0;
% main_DY_cross_domain;
% fclose(resultFile);
% 
% %DY_cross_3ways
% disp('cross_3ways');
% SetParameter;
% resultDirectory = sprintf('../exp_result/DY_cross_3ways/%d/', datasetId);
% mkdir(resultDirectory);
% expTitle = sprintf('DY_cross_3ways%d', datasetId);
% sigma = 0.015;
% lambda = 0.0001;
% delta = 10^-13;
% cpRank = 10;
% numInstanceCluster = 10;
% numFeatureCluster = 10;
% isTestPhase = true;
% randomTryTime = 5;
% nuCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'cpRank,instanceCluster,featureCluster,sigma,lambda,delta,objectiveScore,accuracy,trainingTime\n');
% PrepareExperiment;
% main_DY_cross_domain_3way;
% delta = 0;
% main_DY_cross_domain_3way;
% fclose(resultFile);
% 
% cd baseline/GCMF;
% % Please assign datasetId in the commend line
% disp('GCMF');
% SetParameter;
% expTitle = sprintf('GCMF%d', datasetId);
% resultDirectory = sprintf('../../../exp_result/GCMF/%d/', datasetId);
% sigma = 0.001;
% sigma2 = 0.001;
% lambda = 0.001;
% gama = 0.001;
% numFeatureCluster = 10;
% numInstanceCluster = 2;
% mkdir(resultDirectory);
% isTestPhase = true;
% randomTryTime = 5;
% numCVFold = 1;
% resultFile = fopen(sprintf('%s%s_test.csv', resultDirectory, expTitle), 'w');
% fprintf(resultFile, 'numInstanceCluster, numFeatureCluster, sigma, sigma2, lambda, gama, objectiveScore, accuracy, convergeTime\n');
% PrepareGCMFExperiment;
% main_GCMF_beta;
% fclose(resultFile);
% 
% cd ../TCA;
% disp('TCA');
% main_TCA_gaussian_SVM;