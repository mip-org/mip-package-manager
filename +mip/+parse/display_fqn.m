function out = display_fqn(fqn)
%DISPLAY_FQN   Convert an internal FQN to its user-facing display form.
%
% Non-channel packages are stored internally with a leading '_' org
% (e.g. '_/local/mypkg', '_/fex/some_pkg'). Users see and type the
% shortened 2-part form ('local/mypkg', 'fex/some_pkg'). Channel
% packages are returned unchanged.
%
% Args:
%   fqn - Internal fully qualified name
%
% Returns:
%   out - User-facing display form

if startsWith(fqn, '_/')
    out = fqn(3:end);
else
    out = fqn;
end

end
