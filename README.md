# Nebulosa

Nebulosa is an IRC Client that's accessible from a web browser.. even remotely.

It works by creating a web server and passing messages using Socket.io between the IRC Client / WebServer and the Web Interface

## Why would you do *that*?

Nebulosa tries to meet the needs of more advanced users rather than trying to be simple and easy to use.

Its architecture provides:

- A completely customizable HTML5 User Interface
- Remote access from any compatible device.. just host Nebulosa on a server and connect to it.
  - As such, Nebulosa can act as a BNC
- Coffeescript and Javascript "scripts" enable for automation and new features (kinda like mIRC "remotes")

### What's missing

- Implementation of all commands (WebInterface)
- Message customization options (bold/underline/colors)
- Randomly colored nicknames
- Script management (either Coffeescript or Javascript)