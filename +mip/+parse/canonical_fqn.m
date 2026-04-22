function out = canonical_fqn(package)
%CANONICAL_FQN   Canonicalize a package FQN to its canonical internal form.
%
% Accepts either a canonical FQN or the user-facing 3-part shorthand
% (which omits the 'gh/' prefix). Returns the canonical FQN. Non-FQN
% inputs (bare names) are returned unchanged.
%
% This is used at API boundaries where callers may pass either form —
% primarily the state lookup functions (is_loaded, is_installed, etc).
%
% Args:
%   package - FQN string (canonical or 3-part shorthand) or bare name
%
% Returns:
%   out - Canonical FQN string (or the original input if it isn't an FQN)

try
    r = mip.parse.parse_package_arg(package);
    if r.is_fqn
        out = r.fqn;
    else
        out = package;
    end
catch
    out = package;
end

end
