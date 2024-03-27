% zipping nifti files 

files = dir("/home/zachkaras/fmri/preprocessed");

for i=3:numel(files)
    % disp(files(i).name)
    compress_file = sprintf("gzip /home/zachkaras/fmri/preprocessed/%s", files(i).name);
    disp(compress_file)
    system(compress_file);
end