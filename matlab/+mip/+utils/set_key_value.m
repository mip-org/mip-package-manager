function set_key_value(key, value)
%SET_KEY_VALUE   Write the value for a given key to persistent storage.
%
% The persistent storage used by this function is unaffected by the "clear all"
% command.

setappdata(0, key, value)

end
