function h = gitdescribe()
    [~, h] = system('git rev-list HEAD -n1');
    h = strtrim(h);
end
