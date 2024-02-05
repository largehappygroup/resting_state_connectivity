function plot_slices(seed, brain, mni_brain, studyname)
    num_slices = size(brain,3);
    slices = round(linspace(15,num_slices-20, 6));
    
    disp(num_slices)
    t = tiledlayout(1,6, 'Padding','compact', 'TileSpacing','compact');
    for i=1:numel(slices)
        disp(slices(i))
        ax = nexttile(t);
        slice = brain(:,:,slices(i));
        mni_slice = mni_brain(:,:,slices(i));
        % [rows,cols] = find(slice);
        
        imshow(mni_slice, 'InitialMagnification', 'fit');
        hold on;
        alpha_mask = slice ~= 0;
        h = imagesc(slice, 'AlphaData', alpha_mask);
        axis image off;  % Adjust axis and turn off axis labels
        % imshow(slice);
        % colormap(ax, "default");
        
        % plot(cols, rows, 'r.');
        camroll(+90)
        hold off;
    end
    save_title = sprintf("/home/zachkaras/fmri/results/%s_seed_%d_slices.png", studyname, seed);
    saveas(gcf, save_title);
    
end