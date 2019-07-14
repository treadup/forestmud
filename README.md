# ForestMUD
ForestMUD is the start of a simple TCP MUD server written in Erlang.
Users telnet into the server and can interact with the game.

## Compiling and Running
Start the Erlang shell

    erl

Then use the following command in the Erlang shell to compile the program.

    c("forestmud").

To start the server listening on port 7000 use execute the following
command in the Erlang shell.

    forestmud:accept(7000).

## Connecting to the server
Use the following telnet command to connect to the server running locally.

    telnet localhost 7000
