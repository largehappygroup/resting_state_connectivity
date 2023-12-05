for i=1:numel(fnames)
    disp(fnames{i})
    data = niftiread(fnames{3});
    data_2d = reshape(data, numel(mask), size(data,4));
    data_2d_brain = data_2d(brain_idx,:);
    timecourse = squeeze(data_2d_brain(1500, :));
    figure;
    plot(timecourse)
    filename = sprintf("%s", fnames{i});
    title(filename)
%     filename = sprintf("mnt/timecourses/%s.png", fnames{f});
%     saveas(gcf, filename)
end