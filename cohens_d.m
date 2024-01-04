function d = cohens_d(data1, data2)
    meanDifference = mean(data2) - mean(data1);
    pooledStd = sqrt(((std(data1).^2) + (std(data2).^2)) / 2);
    d = meanDifference / pooledStd;
end