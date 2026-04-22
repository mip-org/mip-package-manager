function loaded = is_loaded(package)
%IS_LOADED   Check if a package is loaded, directly or indirectly.
%
% Accepts the canonical FQN (e.g. 'gh/mip-org/core/chebfun') or the
% shorter user-facing form ('mip-org/core/chebfun'); both are
% canonicalized before the lookup.

package = mip.parse.canonical_fqn(package);
MIP_LOADED_PACKAGES = mip.state.key_value_get('MIP_LOADED_PACKAGES');
loaded = ismember(package, MIP_LOADED_PACKAGES);

end
