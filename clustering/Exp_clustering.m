function Exp_clustering(datasetName, userIdList)
resultDirectory = '../../exp_result/Mturk/';
parameterNameOrder = 'sigma, lambda, gama, cpRank';
mkdir(resultDirectory);
numDom = length(userIdList);
expTitle = datasetName;
for domId = 1:numDom
    expTitle = [expTitle '_' num2str(userIdList(domId))];
end
% resultFile = fopen(sprintf('%s%s.csv', resultDirectory, expTitle), 'a');
% fprintf(resultFile, 'sigma,cpRank,lambda,gama,avgPrecision,objective,trainingTime\n');

gamaStart = 10^-4;
gamaScale = 10^2;
gamaMaxOrder = 2;

lambdaStart = 10^-4;
lambdaScale = 10^2;
lambdaMaxOrder = 2;

sigmaList = [0.01, 0.2, 0.4, 0.6];
cpRankList = [40, 80];

maxRandomTryTime = 2;
maxSeedCombination = 100;

bestSeedCombinationPrecision = cell(1, maxSeedCombination);
bestSeedCombinationRecall = cell(1, maxSeedCombination);
bestSeedCombinationFScore = cell(1, maxSeedCombination);
bestSeedCombinationTrainingTime = zeros(1, maxSeedCombination);
bestSeedCombinationObjective = ones(1, maxSeedCombination)*Inf;
bestParamCombination = cell(1, maxSeedCombination);

for tuneSigma = 1:length(sigmaList)
    sigma = sigmaList(tuneSigma);
    [X, Y, XW, Su, Du, SeedCluster, PerceptionSeedFilter, SeedSet] = ...
        prepareExperimentMturk(datasetName, userIdList, sigma, maxSeedCombination);
    for tuneCPRank = 1: length(cpRankList)
        cpRank = cpRankList(tuneCPRank);
        for lambdaOrder = 0: lambdaMaxOrder
            lambda = lambdaStart * lambdaScale ^ lambdaOrder;
            for gamaOrder = 0: gamaMaxOrder
                gama = gamaStart * gamaScale ^ gamaOrder;
                fprintf('(sigma, lambda, gama, cpRank)=(%g,%g,%g,%g)\n', sigma, lambda, gama, cpRank);
                for seedCombinationId = 1: maxSeedCombination
                    RandomPrecision = zeros(maxRandomTryTime, numDom);
                    RandomRecall = zeros(maxRandomTryTime, numDom);
                    RandomFScore = zeros(maxRandomTryTime, numDom);
                    RandomTrainingTime = zeros(1, maxRandomTryTime);
                    RandomObjective = zeros(1, maxRandomTryTime);
                    for randomTryTime = 1:maxRandomTryTime
                        for domId = 1: numDom
                            input.S{domId}=PerceptionSeedFilter{seedCombinationId, domId};
                            input.SeedSet{domId} = SeedSet{seedCombinationId, domId};
                            input.SeedCluster{domId}=SeedCluster{seedCombinationId, domId};
                            input.X{domId} = X{domId};
                            % If Y has all 0 row or col update rule will fail
                            Y{domId}(Y{domId}==0) = 10^-18;
                            input.Y{domId} = Y{domId};
                            input.XW{domId} = XW{domId};
                            input.Sxw{domId} = Su{domId};
                            input.Dxw{domId} = Du{domId};
                        end;
                        
                        hyperparam.beta = 0;
                        hyperparam.gamma = gama;
                        hyperparam.lambda = lambda;
                        hyperparam.cpRank = cpRank;                        
                        
                        trainingTimer = tic;
                        output=solver_orthognal(input, hyperparam);
                        trainingTime = toc(trainingTimer);
                        RandomTrainingTime(randomTryTime) = trainingTime;
                                 
                        % Precision of each domain
                        for domId = 1: numDom
                            [RandomRecall(randomTryTime, domId), RandomPrecision(randomTryTime, domId)] = getRecallPrecision(XW{domId}, output.XW{domId}, SeedSet{domId});
                            RandomFScore(randomTryTime, domId) = 2*((RandomRecall(randomTryTime, domId)*RandomPrecision(randomTryTime, domId))/(RandomRecall(randomTryTime, domId)+RandomPrecision(randomTryTime, domId)));
                        end                        
                        RandomObjective(randomTryTime) = output.objective;
                    end
                    avgRandomPrecision = mean(RandomPrecision, 1);
                    avgRandomRecall = mean(RandomRecall, 1);
                    avgRandomFScore = mean(RandomFScore, 1);
                    avgRandomTrainingTime = mean(RandomTrainingTime);
                    avgRandomObjective = mean(RandomObjective);
                    
                    if avgRandomObjective < bestSeedCombinationObjective(seedCombinationId)
                        bestSeedCombinationPrecision{seedCombinationId} = avgRandomPrecision;
                        bestSeedCombinationRecall{seedCombinationId} = avgRandomRecall;
                        bestSeedCombinationFScore{seedCombinationId} = avgRandomFScore;
                        bestSeedCombinationTrainingTime(seedCombinationId) = avgRandomTrainingTime;
                        bestSeedCombinationObjective(seedCombinationId) = avgRandomObjective;
                        bestParamCombination{seedCombinationId} = [sigma, lambda, gama, cpRank];
                        save(sprintf('%s%s.mat', resultDirectory, expTitle), ...
                            'bestSeedCombinationPrecision', 'bestSeedCombinationRecall', 'bestSeedCombinationFScore', ...
                            'bestSeedCombinationTrainingTime', 'bestSeedCombinationObjective', ...
                            'bestParamCombination', 'parameterNameOrder');
                    end
                end
            end
        end
    end
end
% fclose(resultFile);
end