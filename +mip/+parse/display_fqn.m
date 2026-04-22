function out = display_fqn(fqn)
%DISPLAY_FQN   Convert an internal FQN to its user-facing display form.
%
% GitHub channel packages are stored internally with a leading 'gh/'
% source-type prefix (e.g. 'gh/mip-org/core/chebfun'). Users see and
% type the shortened 3-part form ('mip-org/core/chebfun'). Other
% source types (e.g. 'local/mypkg', 'fex/some_pkg') are returned
% unchanged.
%
% Args:
%   fqn - Internal fully qualified name
%
% Returns:
%   out - User-facing display form

if startsWith(fqn, 'gh/')
    out = fqn(4:end);
else
    out = fqn;
end

end
