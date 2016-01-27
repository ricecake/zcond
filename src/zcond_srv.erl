-module(zcond_srv).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([
	start_link/0
]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, #{}, []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(Args) ->
	{ok, Socket} = gen_udp:open(1970, [
		{broadcast, true},
		{reuseaddr, true},
		{multicast_ttl, 32},
		{multicast_loop, true},
		{add_membership, {{239,0,0,239}, {0,0,0,0}}},
		binary
	]),
	Name = erlang:atom_to_binary(node(), utf8),
	Announce = <<"butt", 1:8, 0:8, (size(Name)):8, Name/binary>>
	erlang:send_after(1000, self(), tick),
	{ok, Args#{ socket => Socket, announce => Announce }}.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(tick, #{ socket := Socket, announce := Announce } = State) ->
	gen_udp:send(Socket, {239,0,0,239}, 1970, Announce),
	erlang:send_after(1000, self(), tick),
	{noreply, State};
handle_info({udp, _Socket, IP, 1970, Announce}, #{ socket := Socket, announce := Announce } = State) ->
	{noreply, State};
handle_info({udp, _Socket, IP, 1970, <<"butt", 1:8, 0:8, Size:8, Name:Size/binary>>}, #{ socket := Socket } = State) ->
	io:format("GOT ~p~n", [{IP, Name}]),
	gen_udp:send(Socket, IP, 1970, <<"butt", 1:8, 1:8, "HELLO">>),
	{noreply, State};
handle_info({udp, _Socket, _IP, 1970, <<"butt", 1:8, 1:8, Rest/binary>>}, State) ->
	io:format("GOT ~s~n", [Rest]),
	{noreply, State};
handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
