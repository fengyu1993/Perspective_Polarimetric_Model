function n_est = getNormalFromEigen(M)
    MM = M' * M;
    [EV, ED] = eig(MM);
    EW = diag(ED);
    [~, min_idx] = min(EW);
    n = EV(:, min_idx);
    if n(3) > 0
        n_est = -n;
    else
        n_est = n;
    end
end