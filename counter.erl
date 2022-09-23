-module(counter).

-behaviour(gen_server).

-record(state, {counter_incs :: list()}).

-export([start/0, stop/1, increment/1, number_of_increments_last_minute/2, value/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-define(WINDOW_SIZE,60*1000).

%% gen_server callbacks

init([]) -> 
	{ok, #state{counter_incs = [{erlang:monotonic_time(millisecond),0}]}}.
	
handle_call(value, _From, State=#state{counter_incs = [{_, Value}|_]}) ->
	{reply, Value, State};
	
handle_call({number_of_increments, CurrentTime}, _From, State=#state{counter_incs = CounterList}) ->
	Reply = increments(CurrentTime, CounterList, 0),
	{reply, Reply, State};
	
handle_call({increment,Time}, _From, State=#state{counter_incs = [{_,Value}|_] = CounterList}) ->
	NewState = State#state{counter_incs = [{Time,Value + 1} | CounterList]},
	{reply, ok, NewState};
	
handle_call(terminate, _From, State) ->
	{stop, normal, ok, State}.
	
handle_cast(_Msg, State) ->
	{noreply, State}.
	
handle_info(_Msg, State) ->
    {noreply, State}.
	
terminate(normal, _State) ->
	ok.
	
	
%% Counter API
start() -> 
	{ok,CounterPid} = gen_server:start(?MODULE, [], []),
	CounterPid.
	
stop(Pid) ->
	gen_server:call(Pid, terminate).

increment(Pid) ->
    gen_server:call(Pid, {increment, erlang:monotonic_time(millisecond)}).
	
number_of_increments_last_minute(Pid, Accuracy)
  when is_integer(Accuracy), Accuracy >=0, Accuracy =< 3 ->
	Time = case Accuracy of
				0 -> erlang:monotonic_time(second)*1000;
				3 -> erlang:monotonic_time(millisecond);				
				_ -> int_round(erlang:monotonic_time(millisecond), Accuracy)
		   end,
	gen_server:call(Pid, {number_of_increments,Time});

number_of_increments_last_minute(_Pid, _) ->
	{error,not_supported_accuracy}.
	
value(Pid) ->
	gen_server:call(Pid, value).

%% Internal functions
	
increments(_,[],Acc) ->
	Acc;
increments(Time,[{IncTime,IncValue}|CounterList],Acc) 
  when IncTime >= Time - ?WINDOW_SIZE, IncValue > 0 ->		
	increments(Time, CounterList, Acc + 1);
increments(_,_,Acc)	->
	Acc.
	
int_pow(_, 0) ->
	1;
int_pow(X, 1) ->
	X;
int_pow(X, Y) ->
	X*int_pow(X, Y-1).

int_round(X, Accuracy) ->
	Rem = X div int_pow(10,Accuracy - 1) rem 10,
	case Rem > 4 of
		true -> 
			(X div int_pow(10,Accuracy) + 1) * int_pow(10, Accuracy);
		false ->
		    X div int_pow(10,Accuracy) * int_pow(10, Accuracy)
	end.