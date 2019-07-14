-module(forestmud).
-export([accept/1]).

%% Starts the ForestMUD server listening for incoming connections on the given Port.
accept(Port) ->
    {ok, Socket} = gen_tcp:listen(Port, [list, {active, true}, {packet, line}, {reuseaddr, true}]),
    io:format("ForestMUD server listening on port ~p~n", [Port]),
    Game = spawn(fun () -> game_loop([], maps:new()) end),
    server_loop(Socket, Game).

game_loop(Clients, State) ->
    receive
        {user_init, Client} ->
            % Where you start should probably be randomized and should be tied
            % to your location in the game State.
            Client ! {output, "You are standing in a forest grove\n"},
            game_loop([Client|Clients], State);
        {remove, Client} ->
            game_loop(Clients -- [Client], State);
        {input, Client, Input} ->
            {UpdatedClients, UpdatedState} = handle_input(string:trim(Input), Client, Clients, State),
            game_loop(UpdatedClients, UpdatedState)
        after 33 ->   % 30 frames per second
            % Right now we don't do anything when the game receives a tick.
            game_loop(Clients, State)
    end.

handle_input("quit", Client, Clients, State) ->
    Client ! {shutdown, "Till the next time\n"},
    {Clients -- [Client], State};
handle_input(_Input, _Client, Clients, State) ->
    % One of the first things that we want to handle is the "quit" command.
    {Clients, State}.

%% Accepts incoming socket connections and passes them of to a separate Client process
server_loop(Socket, Game) ->
    {ok, Connection} = gen_tcp:accept(Socket),
    Client = spawn(fun () -> client_loop(Connection, Game) end),
    gen_tcp:controlling_process(Connection, Client),
    io:format("New connection ~p~n", [Connection]),
    Game ! {user_init, Client},
    server_loop(Socket, Game).

% Handles communication with a client.
client_loop(Connection, Game) ->
    receive
        {tcp, Connection, Input} ->
            Game ! { input, self(), Input},
            client_loop(Connection, Game);
        {tcp_closed, Connection} ->
            io:format("Connection closed ~p~n", [Connection]),
            Game ! {remove, self()};
        {output, Output} ->
            gen_tcp:send(Connection, Output),
            client_loop(Connection, Game);
        {shutdown, Output} ->
            io:format("Client quitting ~n"),
            gen_tcp:send(Connection, Output),
            gen_tcp:close(Connection)
    end.
