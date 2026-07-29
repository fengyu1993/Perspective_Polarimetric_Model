function N_best = getRefinedSurfaceNormal(N, N_desired)
    fields = fieldnames(N);
    numCandidates = length(fields);
    [H, W, ~] = size(N_desired);
    N_candidates = zeros(H, W, 3, numCandidates);
    for k = 1 : numCandidates
        N_candidates(:, :, :, k) = N.(fields{k});
    end
    dotProducts = sum(N_candidates .* N_desired, 3);
    [~, bestIdx] = max(dotProducts, [], 4);
    [X, Y] = meshgrid(1:W, 1:H);
    N_best = zeros(H, W, 3);
    for c = 1 : 3 
        linearIdx = sub2ind([H, W, numCandidates], Y(:), X(:), bestIdx(:));
        channelData = N_candidates(:, :, c, :);
        N_best(:, :, c) = reshape(channelData(linearIdx), H, W);
    end
end