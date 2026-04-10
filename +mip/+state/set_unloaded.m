function set_unloaded(fqn)
%SET_UNLOADED   Remove a package from all load-state lists atomically.
%
% Removes fqn from MIP_LOADED_PACKAGES, MIP_DIRECTLY_LOADED_PACKAGES,
% and MIP_STICKY_PACKAGES in a single call.

    mip.state.key_value_remove('MIP_STICKY_PACKAGES', fqn);
    mip.state.key_value_remove('MIP_DIRECTLY_LOADED_PACKAGES', fqn);
    mip.state.key_value_remove('MIP_LOADED_PACKAGES', fqn);
end
