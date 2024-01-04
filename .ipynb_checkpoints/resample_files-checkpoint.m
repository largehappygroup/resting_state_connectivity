function resample_files(pathnames)
    for i=1:numel(pathnames)
        
        regressor = importdata(pathnames{i});
        disp(size(regressor))
    end
end