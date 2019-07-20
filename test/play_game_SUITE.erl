-module(play_game_SUITE).
-include_lib("common_test/include/ct.hrl").
-include("binbo_test_lib.hrl").


-export([all/0]).
-export([groups/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).
-export([move_all_pieces/1]).


%% all/0
all() -> [{group, games}].

%% groups/0
groups() ->
	[{games, [parallel], [move_all_pieces]}].

%% init_per_suite/1
init_per_suite(Config) ->
	{ok, _} = binbo:start(),
	Config.

%% end_per_suite/1
end_per_suite(_Config) ->
	ok = binbo:stop(),
	ok.

%% init_per_testcase/2
init_per_testcase(_TestCase, Config) ->
	{ok, Pid} = binbo:new_server(),
	[{pid, Pid} | Config].

%% end_per_testcase/2
end_per_testcase(_TestCase, Config) ->
	Pid = get_pid(Config),
	ok = binbo:stop_server(Pid),
	ok.

%% get_pid/1
get_pid(Config) ->
	?value(pid, Config).

%% make_legal_moves/1
make_legal_moves(_Pid, []) ->
	ok;
make_legal_moves(Pid, [Move | Tail]) ->
	case binbo:move(Pid, Move) of
		{ok, continue} ->
			make_legal_moves(Pid, Tail);
		{error, Reason} ->
			{error, {Reason, Move}}
	end.



%% move_all_pieces/1
move_all_pieces(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid),
	ok = make_legal_moves(Pid, [
		% white and black pawn push
		<<"a2a3">>, <<"a7a6">>
		, <<"c2c3">>, <<"c7c6">>
		% white and black pawn double push
		, <<"e2e4">>, <<"e7e5">>
		, <<"d2d4">>, <<"d7d5">>
		% white and black bishop (light squares)
		, <<"f1e2">>, <<"f8e7">>
		% white and black bishop (dark squares)
		, <<"c1e3">>, <<"c8e6">>
		% white and black knight
		, <<"g1h3">>, <<"g8h6">>
		, <<"b1d2">>, <<"b8d7">>
		% white and black queen
		, <<"d1a4">>, <<"d8b6">>
	]),
	ok.
