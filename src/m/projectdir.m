function d = projectdir(varargin)
    [~, base] = system('git rev-parse --show-toplevel');
    path = {strtrim(base), varargin{:}};
    d = strjoin(path, filesep);
end
