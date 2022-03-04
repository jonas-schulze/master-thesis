default_update!(_, G%\sk%, F%\skmi%, G%\skmi%) = G%\sk% + F%\skmi% + (-G%\skmi%) # out-of-place
default_update!(U%\sk%::Array, G%\sk%, F%\skmi%, G%\skmi%) = @. U%\sk% = G%\sk% + F%\skmi% - G%\skmi% # in-place
