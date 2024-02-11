# What is CC-SAuth

CC-SAuth (ComputerCraft Secure Authentication) is a system for user authentication with name, password and 2FA in Minecraft using Computercraft.

It is totaly overkill, over the top and borderline useless. I was told not to do it, they begged me not to do it and i still did it!

Included in this repo are:
* The library and daemon for RNS (rednet secure for encrypted network traffic using AES encryption)
* Libraries needed for TOTP and QR-code generation for facilitate 2FA
* An implimentation of the sauth api


# IMPORTANT

As of now the project is not finished and consists of half broken implimentations and test code snippets.

# Credits

This project is using code from these people:

* [zyxkad's](https://github.com/zyxkad) implimentation of AES found [here](https://forums.computercraft.cc/index.php?topic=487.0)
* GravityScore's implimentation of SHA-256 found [here](https://www.computercraft.info/forums2/index.php?/topic/8169-sha-256-in-pure-lua/)
* [mpeterv's](https://github.com/mpeterv) implimentation of SHA-1 found [here](https://github.com/mpeterv/sha1?tab=readme-ov-file)
* [speedata's](https://github.com/speedata) qrcode library found [here](http://speedata.github.io/luaqrcode/)
* [aiq's](https://github.com/aiq) basexx library found [here](https://github.com/aiq/basexx)
* [tilkinsc's](https://github.com/tilkinsc) implimentation of OTP found [here](https://github.com/tilkinsc/LuaOTP/tree/master)

# License

All the code that doesnt stem from the sources mentioned above is licensed under GPL-3. You are free to modify and share the code. I also give no waranty for the security or functionality of this code.