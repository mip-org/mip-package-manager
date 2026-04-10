function depFqn = resolve_dependency(depName)
%RESOLVE_DEPENDENCY   Resolve a dependency name to a fully qualified name.
%
% If depName is already a FQN, return as-is.
% If bare, resolve to mip-org/core/<name>.
%
% Bare-name dependencies always resolve to mip-org/core. To depend on a
% package from a different channel, use the fully qualified name in
% mip.yaml.
%
% Args:
%   depName - Dependency name (bare or FQN)
%
% Returns:
%   depFqn - Fully qualified name

result = mip.parse.parse_package_arg(depName);

if result.is_fqn
    depFqn = depName;
    return
end

depFqn = mip.parse.make_fqn('mip-org', 'core', result.name);

end
