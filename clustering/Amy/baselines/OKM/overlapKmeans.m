function [sampleCluster] = overlapKmeans(X,K,maxerr)
%
%  X = n*d
%  K = # of cluster 
%  (this function can handle the case that the # of cluster is 
%   larger than the # of seed cluster user gives)
%  maxerr = stopping criteria, you can set is as 0;
%
%  sampleCluster = K * n indicator
%

[Ndata, dims] = size(X);

% Initial prototype assignment (arbitrary)
randp = randperm(Ndata);
means = X(randp(1:K),:);
[~,means]=kmeans(X,K);


%display('ini means');
A = zeros(Ndata, K);
%display('ini A');
for i=1:Ndata
    A(i,:)=assignOverlap(X(i,:), means,zeros(1,K), 0);
end

iter = 0;
breakflag = 0;
oldmeans = means;
while 1
    %display('assign new means');
  
    means = prototypeOverlap(X, A ,oldmeans);
    
    %display('assign new A');
    Anew = zeros(Ndata, K);
    for i=1:Ndata
        Anew(i,:)=assignOverlap(X(i,:), means, zeros(1,K), A(i,:));
    end
    
    if find(sum(Anew,1)==0)
       disp('warning: an empty cluster, assign the nearest node into it');
       xx = find(sum(Anew,1)==0);
       for emp = 1:length(xx)
            for j=1:Ndata
                % Euclidean distance from data to each prototype
                dist(j) = norm(X(j,:)-means(xx(emp),:))^2;
            end
            index_min = find(~(dist-min(dist)));
            Anew(index_min,xx(emp))=1;
       end
    end
  
    if sum(sum(abs(Anew-A)))<=maxerr
        breakflag = 1;
    end
    
    oldmeans = means;
    A = Anew;
    
    if iter>1000 || breakflag==1;
        break;
    end
    iter = iter+1;
    
    
end
    sampleCluster = A';
end


