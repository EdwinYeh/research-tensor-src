function Exp_mturk_perceptioncluster(expTitle, userIdList)
resultDirectory = '../exp_result/newmodel/Mturk/';
mkdir(resultDirectory);
resultFile = fopen(sprintf('%s%s.csv', resultDirectory, expTitle), 'a');
fprintf(resultFile, 'sigma,cpRank,perceptionCluster,lambda,gama,precisionAvg,recallVarAvg,objective,trainingTime\n');
domainNum = length(userIdList);

gamaStart = 10^-9;
gamaScale = 10^3;
gamaMaxOrder = 3;

lambdaStart = 10^-12;
lambdaScale = 10^3;
lambdaMaxOrder = 5;

sigmaList = [0.01, 0.05, 0.1, 0.5, 1];
perceptionClusterNumList = [5, 15];
cpRankList = [10, 30];

maxRandomTryTime = 5;

for tuneSigma = 1:length(sigmaList)
    sigma = sigmaList(tuneSigma);
    [X, Y, XW, Su, Du, SeedCluster, PerceptionSeedFilter, SeedSet] = prepareExperimentMturk(expTitle, userIdList, sigma);
    for tuneCPRank = 1: length(cpRankList)
        cpRank = cpRankList(tuneCPRank);
        for tunePerceptionClusterNum = 1: length(perceptionClusterNumList)
            perceptionClusterNum = perceptionClusterNumList(tunePerceptionClusterNum);
            if perceptionClusterNum <=cpRank
                for lambdaOrder = 0: lambdaMaxOrder
                    lambda = lambdaStart * lambdaScale ^ lambdaOrder;
                    for gamaOrder = 0: gamaMaxOrder
                        gama = gamaStart * gamaScale ^ gamaOrder;
                        randomPrecision = zeros(1, maxRandomTryTime);
                        randomVarRecall = zeros(1, maxRandomTryTime);
                        randomTrainingTime = zeros(1, maxRandomTryTime);
                        randomObjective = zeros(1, maxRandomTryTime);
                        for randomTryTime = 1:maxRandomTryTime
                            for domId = 1: domainNum
                                % fprintf('validation index domain%d: %d~%d\n', domID, min(validationIndex{domID}), max(validationIndex{domID}));
                                input.S{domId}=PerceptionSeedFilter{domId};
                                input.SeedSet{domId} = SeedSet{domId};
                                input.SeedCluster{domId}=SeedCluster{domId};
                                input.X{domId} = X{domId};
                                % If Y has all 0 row or col update rule will fail
                                Y{domId}(Y{domId}==0) = 10^-6;
                                input.Y{domId} = Y{domId};
                                input.XW{domId} = XW{domId};
                                input.Sxw{domId} = Su{domId};
                                input.Dxw{domId} = Du{domId};
                            end;
                            
                            hyperparam.beta = 0;
                            hyperparam.gamma = gama;
                            hyperparam.lambda = lambda;
                            hyperparam.cpRank = cpRank;
                            hyperparam.perceptionClusterNum = perceptionClusterNum;
                            
                            trainingTimer = tic;
                            output=solver_orthognal_perceptioncluster(input, hyperparam);
                            trainingTime = toc(trainingTimer);
                            randomTrainingTime(randomTryTime) = trainingTime;
                            
                            % Recall matrix for each domain
                            Recall = cell(1, domainNum);
                            % Recall varience of each domain
                            VarRecall = zeros(1, domainNum);
                            % Precision of each domain
                            Precision = zeros(1, domainNum);
                            for domId = 1: domainNum
                                [Recall{domId}, Precision(domId)] = getRecallPrecision(XW{domId}, output.XW{domId}, SeedSet{domId});
                                VarRecall(domId) = var(Recall{domId});
                            end
                            avgPrecision = mean(Precision);
                            avgVarRecall = mean(VarRecall);
                            randomPrecision(randomTryTime) = avgPrecision;
                            randomVarRecall(randomTryTime) = avgVarRecall;
                            randomObjective(randomTryTime) = output.objective;
                        end
                        avgRandomPrecision = mean(randomPrecision);
                        avgRandomVarRecall = mean(randomVarRecall);
                        avgRandomTrainingTime = mean(randomTrainingTime);
                        avgRandomObjective = mean(randomObjective);
                        fprintf(resultFile, '%g,%g,%g,%g,%g,%g,%g,%g,%g\n', sigma, cpRank, perceptionClusterNum, lambda, gama, avgRandomPrecision, avgRandomVarRecall, avgRandomObjective, avgRandomTrainingTime);
                        fprintf('%g,%g,%g,%g,%g,%g,%g,%g,%g\n', sigma, cpRank, perceptionClusterNum, lambda, gama, avgRandomPrecision, avgRandomVarRecall, avgRandomObjective, avgRandomTrainingTime);
                    end
                end
            end
        end
    end
end
fclose(resultFile);
end