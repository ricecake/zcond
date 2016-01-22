-module(zccond_test).

-export([open/2,start/0]).
-export([stop/1,receiver/1]).

open(Addr,Port) ->
   {ok,S} = gen_udp:open(Port, [
		   {broadcast, true},
		   {reuseaddr, true},
		   {multicast_ttl, 32}, 
		   {multicast_loop, false},
		   {add_membership,{Addr,{0,0,0,0}}},
		   binary
	   ]),
   inet:setopts(S,[{add_membership,{Addr,{0,0,0,0}}}]),
   S.

close(S) -> gen_udp:close(S).

start() ->
   S=open({239,0,0,239}, 1970),
   Pid=spawn(?MODULE,do_rec(S),[S]),
   gen_udp:controlling_process(S,Pid),
   {S,Pid}.

stop({S,Pid}) ->
   close(S),
   Pid ! stop.

do_rec(S) ->
	erlang:send_after(1000, self(), tick),
	receiver(S).

receiver(S) ->
	receive
		tick ->
			Res = gen_udp:send(S, {239,0,0,239}, 1970, <<"butts">>),
			erlang:send_after(1000, self(), tick),
			io:format("Tick ~p~n", [Res]),
			receiver(S);
		{udp, _Socket, IP, InPortNo, Packet} ->
			io:format("~n~nFrom: ~p~nPort: ~p~nData: ~p~n",[IP,InPortNo, Packet]),
			receiver(S);
		stop -> true;
		AnythingElse ->
			io:format("RECEIVED: ~p~n",[AnythingElse]),
			receiver(S)
	end.


