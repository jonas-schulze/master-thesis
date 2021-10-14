function d = projectdir(varargin)
    [~, base] = system('git rev-parse --show-toplevel');
    path = {strtrim(base), varargin{:}};
    path = cellfun(@char, path, 'UniformOutput', false);
    d = strjoin(path, filesep);
end
