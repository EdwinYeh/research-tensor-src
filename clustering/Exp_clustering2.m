function Exp_clustering(datasetName, userIdList)
resultDirectory = sprintf('../../exp_result/%s/tmp', datasetName);
parameterNameOrder = 'sigma, lambda, gama, cpRank';
mkdir(resultDirectory);
numDom = length(userIdList);
expTitle = datasetName;
for domId = 1:numDom
    expTitle = [expTitle '_' num2str(userIdList(domId))];
end
% resultFile = fopen(sprintf('%s%s.csv', resultDirectory, expTitle), 'a');
% fprintf(resultFile, 'sigma,cpRank,lambda,gama,avgPrecision,objective,trainingTime\n');

gamaStart = 10^-10;
gamaScale = 10^2;
gamaMaxOrder = 2;

lambdaStart = 10^-4;
lambdaScale = 10^2;
lambdaMaxOrder = 2;

if strcmp(datasetName, 'song')
    sigmaList = [300, 500, 700, 900];
else
    sigmaList = [0.001, 0.005, 0.01, 0.05];
end
cpRankList = [40, 60, 80];

maxRandomTryTime = 2;
maxSeedCombination = 1;

bestParamPrecision = cell(1, maxSeedCombination);
bestParamRecall = cell(1, maxSeedCombination);
bestParamFScore = cell(1, maxSeedCombination);
bestParamTrainingTime = zeros(1, maxSeedCombination);
bestParamObjective = ones(1, maxSeedCombination)*Inf;
bestParamCombination = cell(1, maxSeedCombination);

for sigma = sigmaList
    [X, Y, XW, Su, Du, SeedPerception, ClusterSeedFilter, SeedSet] = ...
        prepareExperiment2(datasetName, userIdList, sigma, maxSeedCombination);
    for cpRank = cpRankList
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
                            input.S{domId} = ClusterSeedFilter{seedCombinationId, domId};
                            input.SeedSet{domId} = SeedSet{seedCombinationId, domId};
                            input.SeedCluster{domId} = SeedPerception{seedCombinationId, domId};
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
%                         save('debug.mat');
                        output=solver(input, hyperparam);
                        trainingTime = toc(trainingTimer);
                        RandomTrainingTime(randomTryTime) = trainingTime;
                                 
                        % Precision of each domain
                        for domId = 1: numDom
                            clusterResult = output.reconstructY{domId};
                            [RandomRecall(randomTryTime, domId), RandomPrecision(randomTryTime, domId)] = ...
                                getRecallPrecision(Y{domId}', clusterResult', SeedSet{domId});
                            RandomFScore(randomTryTime, domId) = ...
                                2*((RandomRecall(randomTryTime, domId)*RandomPrecision(randomTryTime, domId))/(RandomRecall(randomTryTime, domId)+RandomPrecision(randomTryTime, domId)));
                        end
                        fprintf('objective: %g, FScore: %g\n', output.objective, RandomFScore(randomTryTime,1));
                        RandomObjective(randomTryTime) = output.objective;
                    end
                    
                    [minRandomObjective, minObjRandomTime] = min(RandomObjective);
                    minRandomPrecision = RandomPrecision(minObjRandomTime, :);
                    minRandomRecall = RandomRecall(minObjRandomTime, :);
                    minRandomFScore = RandomFScore(minObjRandomTime, :);
                    minRandomTrainingTime = RandomTrainingTime(minObjRandomTime);
                    
                    if minRandomObjective < bestParamObjective(seedCombinationId)
                        bestParamPrecision{seedCombinationId} = minRandomPrecision;
                        bestParamRecall{seedCombinationId} = minRandomRecall;
                        bestParamFScore{seedCombinationId} = minRandomFScore;
                        bestParamTrainingTime(seedCombinationId) = minRandomTrainingTime;
                        bestParamObjective(seedCombinationId) = minRandomObjective;
                        bestParamCombination{seedCombinationId} = [sigma, lambda, gama, cpRank];
                        save(sprintf('%s%s.mat', resultDirectory, expTitle), ...
                            'bestParamPrecision', 'bestParamRecall', 'bestParamFScore', ...
                            'bestParamTrainingTime', 'bestParamObjective', ...
                            'bestParamCombination', 'parameterNameOrder');
                    end
                end
            end
        end
    end
end
% fclose(resultFile);
end