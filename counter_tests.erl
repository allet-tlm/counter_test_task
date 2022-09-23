-module(counter_tests).
-include_lib("eunit/include/eunit.hrl").

counter_test_() ->
	{setup,
	 fun start/0,
	 fun stop/1,
	 fun (SetupData) ->
	     [counter_increment(SetupData),
		  counter_increments_last_minute(SetupData, 0),
		  counter_increments_last_minute(SetupData, 1),
		  counter_increments_last_minute(SetupData, 2),
		  counter_increments_last_minute(SetupData, 3),
		  counter_not_supported_accuracy(SetupData)]
	 end}.
	
start() ->
	counter:start().
	
stop(Pid) ->
	counter:stop(Pid).
	
counter_increment(Pid) ->
    IncRes = counter:increment(Pid),
	IncValue = counter:value(Pid),
	[?_assertEqual(ok, IncRes),
	 ?_assertEqual(1, IncValue)].
	 
counter_increments_last_minute(Pid, Accuracy) ->
	timer:sleep(61*1000),
	IncStep = 10000000,
	[counter:increment(Pid)|| _ <- lists:seq(1,IncStep)],
	IncValue = counter:value(Pid),
	NInc = counter:number_of_increments_last_minute(Pid,Accuracy),
	[?_assertEqual(IncStep*(Accuracy + 1) + 1, IncValue),
	 ?_assertEqual(10000000, NInc)].
	 
counter_not_supported_accuracy(Pid) ->
	Error = counter:number_of_increments_last_minute(Pid,4),
	Error1 = counter:number_of_increments_last_minute(Pid,-1),
	[?_assertEqual({error,not_supported_accuracy},Error),
	 ?_assertEqual({error,not_supported_accuracy},Error1)].	 
