function [output]=solver(input,hyperparam)
% Input variable:
%   input.X{d} = feature matrix in domain d
%   input.Y{d} = label matrix in domain d
%   input.S{d} = selector maxtrix in domain d
%   input.Sxw{d} = Laplacian on numerator in domain d
%   input.Dxw{d} = Laplacian on denomerator in domain d
%   hyperparam.beta = coef for 2-norm regularizer for W
%   hyperparam.gamma = 1-norm sparsity for Tensor projection
%   hyperparam.lambda = coef for Laplacian reg for instance
%   hyperparam.cpRank
%   hyperparam.clusterNum
% Output:
%   output.Tensor = Tensor
%   output.W = W
%   output.Objective = Objective


%  System parameter
%  Todo
%       add to hyperparam
tol = 10 ^-3;
debugMode = 1;

%%
% Initialize :
%     W{d} : featureNum x clusterNum,
%     A : clusterNum x cpRank,
%     E{d} : LabelNum x cpRank
%     XW{d} : instanceNum x
%
% Todo:
%       Add default setting
%       Add debug mode
%       Add Laplacian regularize ?
%
A = randi(10,hyperparam.clusterNum,hyperparam.cpRank);
E=cell(length(input.Y),1);
W=cell(length(input.Y),1);
XW=cell(length(input.Y),1);
reconstructY=cell(length(input.Y),1);
X = input.X;
Y = input.Y;
for domainIdx = 1:length(input.Y)
    E{domainIdx} = randi(10,size(input.Y{domainIdx},2),hyperparam.cpRank);
    W{domainIdx} = randi(10,size(input.X{domainIdx},2),hyperparam.clusterNum);
    XW{domainIdx} = input.X{domainIdx}*W{domainIdx};
end

% Package A,E matrices into structure named "Tensor"
Tensor.A = A; Tensor.E = E;


%%
%  Optimization main body
%  Todo objective tracking
objectiveTrack = [];
objectiveScore = Inf;
relativeError = Inf;
terminateFlag = 0;
while terminateFlag<5
    for domID = 1:length(input.Y)
%         getObjectiveScore(input,XW,Tensor,hyperparam)
        Tensor = updateA(input,XW,Tensor,hyperparam);
%         disp('A:')
%         getObjectiveScore(input,XW,Tensor,hyperparam)
        
        Tensor = updateE(input,XW,Tensor,hyperparam,domID);
%         disp('E:')
%         getObjectiveScore(input,XW,Tensor,hyperparam)
        
        XW = updateXW(XW,W,input,Tensor,domID,hyperparam);
%         getObjectiveScore(input,XW,Tensor,hyperparam)
%         W = updateW(W,XW,input,domainIdx);
    end
    NewObjectiveScore = getObjectiveScore(input,XW,Tensor,hyperparam);
    %disp(NewObjectiveScore);
    %     Terminate Check
    relativeError = objectiveScore - NewObjectiveScore;
    objectiveScore = NewObjectiveScore;
    objectiveTrack(end+1) = NewObjectiveScore;
    terminateFlag = terminateFlag + terminateCheck(relativeError,tol);
end
% W = updateW(W,XW,input,domainIdx);
% disp('solve W1');
W = updateW(input,W,XW,Tensor,1);
% disp('solve W2');
W = updateW(input,W,XW,Tensor,2);
if debugMode
%     plot(objectiveTrack)
%     saveas(gcf,['ObjectiveTrack.png']);
end
% save('obj.mat','objectiveTrack');
output.objective = objectiveScore;
output.Tensor = Tensor;
output.W = W;
output.XW = XW;
for domId = 1:length(input.Y)
    reconstructY{domId} = getReconstructY(XW,Tensor,domId);
end
output.reconstrucY = reconstructY;


function flag = terminateCheck(relativeError,tol)
flag = relativeError < tol;

function psi = getPsi(Tensor,domainIdx)
[M,n]=Khatrirao(Tensor,domainIdx);
cpRank=size(Tensor.E{1},2);
psi=zeros(cpRank);
for i = 1:n
    psi = psi + diag(M(i,:));
end

function [M,ProductionOfLabelNum]=Khatrirao(Tensor,domainIdx)
% Khatirao product on all the E matrices in Tensor, except E{domainIdx}
%  Todo : optimize
%           1.the preparation for large Label set (Total #Label cross domain) overflow
%           2.or sparse matrix calculation
%
%%
% Prepare the matrices
cpRank=size(Tensor.E{1},2);
domainNum=length(Tensor.E);
ProductionOfLabelNum = 1;
for DomIdx = 1:domainNum
    %     ignore E{domainIdx}
    if DomIdx == domainIdx
        continue;
    end
    ProductionOfLabelNum = ProductionOfLabelNum * size(Tensor.E{DomIdx},1);
end
M=sparse( ProductionOfLabelNum ,cpRank);


%%
for r = 1:cpRank
    M(:,r);
    E_col=1;
    % Note that E_col is a column
    for  DomIdx = 1:domainNum
        %     ignore E{domainIdx}
        if DomIdx == domainIdx
            continue;
        end
        tmpMatrix = Tensor.E{DomIdx};
        E_col=kron(E_col,tmpMatrix(:,r));
    end
    M(:,r)=M(:,r)+E_col;
end

function Y=getReconstructY(XW,Tensor,domainIdx)
% Note that
%       Y hasn't been filtered/selected here
%       Y = X * W * proj, where proj = A*psi*E'
proj = projection(Tensor,domainIdx);
Y=XW{domainIdx}*proj;

function proj = projection(Tensor,domainIdx)
psi = getPsi(Tensor,domainIdx);
proj = Tensor.A * psi * Tensor.E{domainIdx}';

function LatinAlphabat = getlatin(M)
% Output:
%       LatinAlphabat : #col of M  x  #col of M
LatinAlphabat = diag(sum(M,1));

function sparsityTerm = get1normSparsityTerm(Tensor,domainIdx)
% If doamainIdx = 0, then times all the E{d}.
%  Output:
%   sparsityTerm: cpRank x cpRank



cpRank = size(Tensor.A,2);
sparsityTerm=ones(cpRank);
domainNum = length(Tensor.E);


sparsityTerm = sparsityTerm.*getlatin(Tensor.A);
for DomIdx = 1:domainNum
    if DomIdx == domainIdx
        continue;
    end
    sparsityTerm = sparsityTerm.*getlatin(Tensor.E{DomIdx});
end

function Tensor = updateA(input,XW,Tensor,hyperparam)
A=Tensor.A;
[r,c]=size(A);

% Calculate Numerator and Denominator
Numerator = zeros(r,c);
Denominator = zeros(r,c);
domainNum = length(Tensor.E);
big1 = ones(size(A,1),size(A,2));
for DomIdx = 1:domainNum
    %     Numerator
%     Numerator = Numerator + ...
%         (input.X{DomIdx}*W{DomIdx})' ...
%         * (input.Y{DomIdx}.*input.S{DomIdx})...
%         * Tensor.E{DomIdx}*getPsi(Tensor,DomIdx);
    Numerator = Numerator + ...
        (XW{DomIdx})' ...
        * (input.Y{DomIdx}.*input.S{DomIdx})...
        * Tensor.E{DomIdx}*getPsi(Tensor,DomIdx);
    %     Denominator    
%     Denominator = Denominator + ...
%         (input.X{DomIdx}*W{DomIdx})' ...
%         * (getReconstructY(input,W,Tensor,DomIdx).*input.S{DomIdx})...
%         * Tensor.E{DomIdx}*getPsi(Tensor,DomIdx)...
%         + ...
%         hyperparam.gamma * big1 * get1normSparsityTerm(Tensor,0);
        Denominator = Denominator + ...
        (XW{DomIdx})' ...
        * (getReconstructY(XW,Tensor,DomIdx).*input.S{DomIdx})...
        * Tensor.E{DomIdx}*getPsi(Tensor,DomIdx)...
        + ...
        hyperparam.gamma * big1 * get1normSparsityTerm(Tensor,0);
        % regularize bug
        
end
A=A.*sqrt(Numerator./Denominator);
Tensor.A = A;

function Tensor = updateE(input,XW,Tensor,hyperparam,domainIdx)
E=Tensor.E{domainIdx};
[r,c]=size(E);

% Calculate Numerator and Denominator
Numerator = zeros(r,c);
Denominator = zeros(r,c);
domainNum = length(Tensor.E);
big1 = ones(size(E,1),size(E,2));
for DomIdx = 1:domainNum
    %     Numerator
    Numerator = Numerator + ...
        (input.Y{DomIdx}.*input.S{DomIdx})' ...
        * (XW{DomIdx})...
        * Tensor.A*getPsi(Tensor,DomIdx);
    %     Denominator
    Denominator = Denominator + ...
        (getReconstructY(XW,Tensor,DomIdx).*input.S{DomIdx})' ...
        * (XW{DomIdx})...
        * Tensor.A*getPsi(Tensor,DomIdx)...
        + ...
        hyperparam.gamma * big1 * get1normSparsityTerm(Tensor,DomIdx);
end
E=E.*sqrt(Numerator./Denominator);
Tensor.E{domainIdx} = E;

function W = updateW(input,W,XW,Tensor,domID)
%  Note that W is a cell sturcture
% W{domainIdx}=input.X{domainIdx}\(XW{domainIdx});
projH = projection(Tensor,domID);
[WRowSize, WColSize] = size(W{domID});
X = input.X{domID};
cvx_begin quiet
    variable tmpW(WRowSize, WColSize)
    minimize(norm(XW{domID}-X*tmpW,'fro'))
cvx_end
W{domID} = tmpW;


function XW = updateXW(XW,W,input,Tensor,domainIdx,hyperparam)
xw=XW{domainIdx};
% Calculate Numerator and Denominator

Numerator = input.Y{domainIdx} .* input.S{domainIdx}...
    * projection(Tensor,domainIdx)'...
    + hyperparam.lambda * input.Sxw{domainIdx} * xw;
Denominator = (xw*xw')...
    * (getReconstructY(XW,Tensor,domainIdx).*input.S{domainIdx})...
    * projection(Tensor,domainIdx)'...
    + hyperparam.lambda * input.Dxw{domainIdx} * xw;
xw=xw.*sqrt(Numerator./Denominator);
XW{domainIdx}=xw;

function objectiveScore = getObjectiveScore(input,XW,Tensor,hyperparam)
objectiveScore = 0;

for domID = 1:length(input.Y)
%     objectiveScore = objectiveScore ...
%         + norm(input.Y{DomIdx}-input.X{DomIdx}*W{DomIdx}*projection(Tensor,DomIdx),'fro')...
%         + hyperparam.gamma * norm(projection(Tensor,DomIdx),1);
    objectiveScore = objectiveScore ...
        + norm((input.Y{domID}-XW{domID}*projection(Tensor,domID).*input.S{domID}),'fro')...
        + hyperparam.gamma * norm(projection(Tensor,domID),1);
end

