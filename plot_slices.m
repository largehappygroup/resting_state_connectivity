function plot_slices(seed, brain, mni_brain)
    num_slices = size(brain,3);
    slices = round(linspace(15,num_slices-20, 6));
    
    disp(num_slices)
    t = tiledlayout(1,6, 'Padding','compact', 'TileSpacing','compact');
    for i=1:numel(slices)
        disp(slices(i))
        ax = nexttile(t);
        slice = brain(:,:,slices(i));
        mni_slice = mni_brain(:,:,slices(i));
        [rows,cols] = find(slice);
        % subplot(1,6,i);
        imshow(mni_slice, 'InitialMagnification', 'fit');
        hold on;
        plot(cols, rows, 'r.');
        camroll(+90)
        hold off;
    end
    save_title = sprintf("figures/seed_%d_slices.png", seed);
    saveas(gcf, save_title);
    
end