pathname = '~/fmri/three_studies_raw';
files = dir(pathname); for i=3:numel(files) datadirs{i-2} = files(i).name; end

% for loop through all folders
for i=1:numel(datadirs)
    physio_path = sprintf('~/fmri/three_studies_raw/%s/physio',datadirs{i});
    
    physio_files={};
    if exist(physio_path,'dir')    
        inner_dir = dir(physio_path);
        
        for i=3:numel(inner_dir)
            datapath = sprintf("%s/%s", physio_path, inner_dir(i).name);
            physio_files{i-2} = datapath; 
        end
        
        for i=1:numel(physio_files)
            regressor = importdata(physio_files{i});


            disp(size(regressor))
        end
    end
end



% function resample_files(pathnames)
%     for i=1:numel(pathnames)
% 
%         regressor = importdata(pathnames{i});
%         disp(size(regressor))
%     end
% end





