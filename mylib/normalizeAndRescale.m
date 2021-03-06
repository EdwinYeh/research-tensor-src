function [newU, newV, newA, newE]= normalizeAndRescale(U,V,A,E)
    [rU, cU] = size(U);
    [rV, cV] = size(V);
    newU = zeros(rU, cU);
    newV = zeros(rV, cV);
    %Normalize U
    for row = 1:rU
        allZero = false;
        sumOfRow = sum(abs(U(row,:)));
        if sumOfRow <= 10^-12;
            allZero = true;
        end
        if allZero == true
            newU(row,:) = ones(1, cU)/cU;
        else
            newU(row,:) = U(row,:)/sumOfRow;
        end
    end
    
    %Normalize V
    for row = 1:rV
        allZero = false;
        sumOfRow = sum(abs(V(row,:)));
        if sumOfRow <= 10^-12;
            allZero = true;
        end
        if allZero == true
            newV(row,:) = ones(1, cV)/cV;
        else
            newV(row,:) = V(row,:)/sumOfRow;
        end
    end
%     disp(size(U));
%     disp(size(V));
%     disp(size(A));
%     disp(size(E));
    %Rescale A & E
    Nu = U\newU;
    Nv = newV'/V';
    
    newA = Nu\A;
    newE = (E'/Nv)';
end