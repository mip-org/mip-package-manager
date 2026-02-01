function pinned = is_pinned(package)
%IS_PINNED   Check if a package is pinned.

MIP_PINNED_PACKAGES = mip.utils.key_value_get('MIP_PINNED_PACKAGES');
pinned = ismember(package, MIP_PINNED_PACKAGES);

end
