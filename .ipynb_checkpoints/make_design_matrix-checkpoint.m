function X = make_design_matrix(path)
    % mean offset, linear, and quadratic trends
    n = 600; % num volumes
    mean_offset = ones(n,1);
    linear_trend = (1:n)';
    quad_trend = (1:n)'.^2;

    % load parameters (clip to 600 volumes)
    Motion = importdata(path);
    Motion = Motion(1:600, :);
    dMP = diff(Motion);
    dMP = [dMP(1,:); dMP];

    X = [mean_offset, linear_trend, quad_trend, Motion, dMP];
end