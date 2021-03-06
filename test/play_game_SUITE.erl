%% Copyright (c) 2019-2020, Sergei Semichev <chessvegas@chessvegas.com>. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%    http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(play_game_SUITE).
-include_lib("common_test/include/ct.hrl").
-include("binbo_test_lib.hrl").


-export([all/0]).
-export([groups/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).
-export([move_all_pieces/1,
	checkmate_white/1, checkmate_black/1,
	stalemate_white/1, stalemate_black/1,
	castling_kingside/1, castling_queenside/1,
	castling_white_after_king_move/1,
	castling_white_after_rook_move/1,
	castling_black_after_king_move/1,
	castling_black_after_rook_move/1,
	castling_white_when_attacked/1,
	castling_black_when_attacked/1,
	enpassant_moves/1, simple_game/1,
	set_game_state/1
]).


%% all/0
all() -> [{group, games}].

%% groups/0
groups() ->
	[{games, [parallel], [
		move_all_pieces,
		checkmate_white, checkmate_black,
		stalemate_white, stalemate_black,
		castling_kingside, castling_queenside,
		castling_white_after_king_move,
		castling_black_after_king_move,
		castling_white_after_rook_move,
		castling_black_after_rook_move,
		castling_white_when_attacked,
		castling_black_when_attacked,
		enpassant_moves, simple_game,
		set_game_state
	]}].

%% init_per_suite/1
init_per_suite(Config) ->
	ok = binbo_test_lib:all_group_testcases_exported(?MODULE),
	{ok, _} = binbo:start(),
	Config.

%% end_per_suite/1
end_per_suite(_Config) ->
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


%%%------------------------------------------------------------------------------
%%%   Testcases
%%%------------------------------------------------------------------------------

%% move_all_pieces/1
move_all_pieces(Config) ->
	Pid = get_pid(Config),
	% Init game from initial position
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
		% white and black rook
		, <<"h1g1">>, <<"h8g8">>
		, <<"a1d1">>, <<"a8d8">>
		% white and black king
		, <<"e1f1">>, <<"e8f8">>
	]),
	ok.

%% checkmate_white/1
checkmate_white(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid, <<"rnbqkbnr/3ppppp/ppp5/8/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq -">>),
	{ok, <<"rnbqkbnr/3ppppp/ppp5/8/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1">>} = binbo:get_fen(Pid),
	{ok, checkmate} = binbo:move(Pid, <<"c4f7">>),
	{ok,checkmate} = binbo:game_status(Pid),
	ok.

%% checkmate_black/1
checkmate_black(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid, <<"rnb1k1nr/pppp1ppp/8/2b1p3/P6q/NP6/2PPPPPP/R1BQKBNR b KQkq -">>),
	{ok, <<"rnb1k1nr/pppp1ppp/8/2b1p3/P6q/NP6/2PPPPPP/R1BQKBNR b KQkq - 0 1">>} = binbo:get_fen(Pid),
	{ok, checkmate} = binbo:move(Pid, <<"h4f2">>),
	{ok, checkmate} = binbo:game_status(Pid),
	ok.

%% stalemate_white/1
stalemate_white(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid, <<"k7/8/8/8/7Q/8/3K4/1R6 w - -">>),
	{ok, <<"k7/8/8/8/7Q/8/3K4/1R6 w - - 0 1">>} = binbo:get_fen(Pid),
	{ok, {draw,stalemate}} = binbo:move(Pid, <<"h4h7">>),
	{ok, {draw,stalemate}} = binbo:game_status(Pid),
	ok.

%% stalemate_black/1
stalemate_black(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid, <<"1q2b1b1/8/8/8/8/7k/8/K7 b - -">>),
	{ok, {draw,stalemate}} = binbo:move(Pid, <<"e8g6">>),
	{ok, {draw,stalemate}} = binbo:game_status(Pid),
	ok.

%% castling_kingside/1
castling_kingside(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1qppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP1QPPP/R3K2R w KQkq -">>),
	% White castling
	{ok, continue} = binbo:move(Pid, <<"e1g1">>),
	% Black castling
	{ok, continue} = binbo:move(Pid, <<"e8g8">>),
	{ok, continue} = binbo:game_status(Pid),
	ok.

%% castling_queenside/1
castling_queenside(Config) ->
	Pid = get_pid(Config),
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1qppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP1QPPP/R3K2R w KQkq -">>),
	% White castling
	{ok, continue} = binbo:move(Pid, <<"e1c1">>),
	% Black castling
	{ok, continue} = binbo:move(Pid, <<"e8c8">>),
	ok.

%% castling_white_after_king_move/1
castling_white_after_king_move(Config) ->
	Pid = get_pid(Config),
	Fen = <<"r3k2r/ppp1qppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP1QPPP/R3K2R w KQkq -">>,
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"e1d2">>, % White king moves from E1
		<<"a7a6">>, % Any black move
		<<"d2e1">>, % White king comes back to E1
		<<"a6a5">>  % Any black move
	]),
	% No castling allowed
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1g1">>}} = binbo:move(Pid, <<"e1g1">>),
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1c1">>}} = binbo:move(Pid, <<"e1c1">>),
	ok.

%% castling_black_after_king_move/1
castling_black_after_king_move(Config) ->
	Pid = get_pid(Config),
	Fen = <<"r3k2r/ppp1qppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP1QPPP/R3K2R b KQkq -">>,
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"e8d7">>, % Black king moves from E8
		<<"a2a3">>, % Any white move
		<<"d7e8">>, % Black king comes back to E8
		<<"a3a4">>  % Any white move
	]),
	% No castling allowed
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8g8">>}} = binbo:move(Pid, <<"e8g8">>),
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8c8">>}} = binbo:move(Pid, <<"e8c8">>),
	ok.

%% castling_white_after_rook_move/1
castling_white_after_rook_move(Config) ->
	Pid = get_pid(Config),
	Fen = <<"r3k2r/ppp1qppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP1QPPP/R3K2R w KQkq -">>,
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"h1g1">>, % White Rook moves from H1
		<<"a7a6">>, % Any black move
		<<"g1h1">>, % White rook comes back to H1
		<<"a6a5">>  % Any black move
	]),
	% Castling kingside not allowed
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1g1">>}} = binbo:move(Pid, <<"e1g1">>),

	% Load new game
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"a1b1">>, % White Rook moves from A1
		<<"a7a6">>, % Any black move
		<<"b1a1">>, % White rook comes back to A1
		<<"a6a5">>  % Any black move
	]),
	% Castling queenside not allowed
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1c1">>}} = binbo:move(Pid, <<"e1c1">>),

	% Load new game
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"a1b1">>, % White Rook moves from A1
		<<"a7a6">>, % Any black move
		<<"b1a1">>, % White rook comes back to A1
		<<"a6a5">>, % Any black move
		<<"h1g1">>, % White Rook moves from H1
		<<"h7h6">>, % Any black move
		<<"g1h1">>, % White rook comes back to H1
		<<"h6h5">>  % Any black move
	]),
	% Castling kingside not allowed
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1g1">>}} = binbo:move(Pid, <<"e1g1">>),
	% Castling queenside not allowed
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1c1">>}} = binbo:move(Pid, <<"e1c1">>),
	ok.

%% castling_black_after_rook_move/1
castling_black_after_rook_move(Config) ->
	Pid = get_pid(Config),
	Fen = <<"r3k2r/ppp1qppp/2np1n2/2b1p1B1/2B1P1b1/2NP1N2/PPP1QPPP/R3K2R b KQkq -">>,
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"h8g8">>, % Black rook moves from H1
		<<"a2a3">>, % Any white move
		<<"g8h8">>, % Black rook comes back to H1
		<<"a3a4">>  % Any white move
	]),
	% Castling kingside not allowed
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8g8">>}} = binbo:move(Pid, <<"e8g8">>),

	% Load new game
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"a8b8">>, % Black rook moves from A1
		<<"a2a3">>, % Any white move
		<<"b8a8">>, % Black rook comes back to A1
		<<"a3a4">>  % Any white move
	]),
	% Castling queenside not allowed
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8c8">>}} = binbo:move(Pid, <<"e8c8">>),

	% Load new game
	{ok, continue} = binbo:new_game(Pid, Fen),
	ok = make_legal_moves(Pid, [
		<<"a8b8">>, % Black rook moves from A1
		<<"a2a3">>, % Any white move
		<<"b8a8">>, % Black rook comes back to A1
		<<"a3a4">>, % Any white move
		<<"h8g8">>, % Black rook moves from H1
		<<"h2h3">>, % Any white move
		<<"g8h8">>, % Black rook comes back to H1
		<<"h3h4">>  % Any white move
	]),
	% Castling kingside not allowed
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8g8">>}} = binbo:move(Pid, <<"e8g8">>),
	% Castling queenside not allowed
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8c8">>}} = binbo:move(Pid, <<"e8c8">>),
	ok.


%% castling_white_when_attacked/1
castling_white_when_attacked(Config) ->
	Pid = get_pid(Config),
	% New game, white king is in check
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/pppbq1pp/n2p1p1n/4p1B1/1bB1P3/N2P1P1N/PPP1Q1PP/R3K2R w KQkq -">>),
	% No castling allowed
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1g1">>}} = binbo:move(Pid, <<"e1g1">>),
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1c1">>}} = binbo:move(Pid, <<"e1c1">>),

	% New game, G1 is attacked. Castling kingside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/pppbq1pp/n2p1p1n/2b1p1B1/2B1P3/N2P1P1N/PPP1Q1PP/R3K2R w KQkq -">>),
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1g1">>}} = binbo:move(Pid, <<"e1g1">>),

	% New game, F1 is attacked. Castling kingside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/pppbq1pp/n2p1p2/b3p1B1/2B1P3/N1PP1PnN/PP2Q1PP/R3K2R w KQkq -">>),
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1g1">>}} = binbo:move(Pid, <<"e1g1">>),

	% New game, C1 is attacked. Castling queenside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1q1pp/n2p1pbn/4p1b1/2B1P2B/N1PP1P1N/PP2Q1PP/R3K2R w KQkq -">>),
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1c1">>}} = binbo:move(Pid, <<"e1c1">>),

	% New game, D1 is attacked. Castling queenside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1q1pp/n2p1p1n/4p1b1/b1B1P2B/N1PP1P1N/PP2Q1PP/R3K2R w KQkq -">>),
	{error, {{invalid_move, 'WHITE_KING'}, <<"e1c1">>}} = binbo:move(Pid, <<"e1c1">>),

	% New game, B1 is attacked. Castling queenside is allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1q1pp/nb3pbn/3PP3/2B4B/N1P2P1N/PP2Q1PP/R3K2R w KQkq -">>),
	{ok, continue} = binbo:move(Pid, <<"e1c1">>),
	ok.

%% castling_black_when_attacked/1
castling_black_when_attacked(Config) ->
	Pid = get_pid(Config),
	% New game, black king is in check
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1q1pp/nb3pbn/3PP3/Q6B/N1P2P1N/PP2B1PP/R3K2R b KQkq -">>),
	% No castling allowed
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8g8">>}} = binbo:move(Pid, <<"e8g8">>),
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8c8">>}} = binbo:move(Pid, <<"e8c8">>),

	% New game, G8 is attacked. Castling kingside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1q1pp/nb3pbn/4P3/3P3B/NQP2P1N/PP2B1PP/R3K2R b KQkq -">>),
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8g8">>}} = binbo:move(Pid, <<"e8g8">>),

	% New game, F8 is attacked. Castling kingside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1qbpp/nb3pNn/4P3/3P3B/NQP2P2/PP2B1PP/R3K2R b KQkq -">>),
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8g8">>}} = binbo:move(Pid, <<"e8g8">>),

	% New game, C8 is attacked. Castling queenside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp1qbpp/nb3p1n/4P3/3PN2B/N1P2P1B/PPQ3PP/R3K2R b KQkq -">>),
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8c8">>}} = binbo:move(Pid, <<"e8c8">>),

	% New game, D8 is attacked. Castling queenside not allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/ppp2bpp/nb2q2n/4Pp2/3P3B/N1P2P1B/PPQ1N1PP/R3K2R b KQkq -">>),
	{error, {{invalid_move, 'BLACK_KING'}, <<"e8c8">>}} = binbo:move(Pid, <<"e8c8">>),

	% New game, B8 is attacked. Castling queenside is allowed
	{ok, continue} = binbo:new_game(Pid, <<"r3k2r/pp3bpp/nbp1q2n/5p2/3P4/N1P1PPBB/PPQ1N1PP/R3K2R b KQkq -">>),
	{ok, continue} = binbo:move(Pid, <<"e8c8">>),
	ok.

%% enpassant_moves/1
enpassant_moves(Config) ->
	Pid = get_pid(Config),
	% New game, black king is in check
	{ok, continue} = binbo:new_game(Pid),
	ok = make_legal_moves(Pid, [
		  <<"g2g4">>, <<"a7a5">>
		, <<"g4g5">>, <<"a5a4">>
		, <<"b2b4">>, <<"a4b3">> % black pawn enpassant move
		, <<"c2b3">>, <<"h7h5">>
		, <<"g5h6">> % white pawn enpassant move
	]),
	ok.

%% simple_game/1
simple_game(Config) ->
	Pid = get_pid(Config),
	InitialFen = <<"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1">>,
	InitialFen = binbo_fen:initial(),
	{ok, continue} = binbo:new_game(Pid),
	{ok, InitialFen} = binbo:get_fen(Pid),
	{ok, white} = binbo:side_to_move(Pid),
	{ok, continue} = binbo:game_status(Pid),

	{ok, IntMovelist} = binbo:all_legal_moves(Pid),
	{ok, IntMovelist2} = binbo:all_legal_moves(Pid, int),
	true = (IntMovelist =:= IntMovelist2),
	{ok, BinMovelist} = binbo:all_legal_moves(Pid, bin),
	{ok, StrMovelist} = binbo:all_legal_moves(Pid, str),

	20 = erlang:length(IntMovelist),
	20 = erlang:length(BinMovelist),
	20 = erlang:length(StrMovelist),
	ok = check_int_movelist(IntMovelist),
	ok = check_bin_movelist(BinMovelist),
	ok = check_str_movelist(StrMovelist),

	{ok, continue} = binbo:move(Pid, "e2e4"),
	{ok, black} = binbo:side_to_move(Pid),
	{ok, continue} = binbo:game_status(Pid),
	{ok, <<"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1">>} = binbo:get_fen(Pid),

	{ok, continue} = binbo:move(Pid, "e7e5"),
	{ok, white} = binbo:side_to_move(Pid),
	{ok, continue} = binbo:game_status(Pid),
	{ok, <<"rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2">>} = binbo:get_fen(Pid),

	{ok, continue} = binbo:new_game(Pid),
	{ok, continue} = binbo:san_move(Pid, <<"e4">>),
	{ok, <<"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1">>} = binbo:get_fen(Pid),
	{ok, continue} = binbo:san_move(Pid, "e5"),
	{ok, <<"rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2">>} = binbo:get_fen(Pid),

	ok = binbo:game_draw(Pid),
	{ok,{draw,{manual,undefined}}} = binbo:game_status(Pid),
	{error,{already_has_status,{draw,{manual,undefined}}}} = binbo:game_draw(Pid),

	{ok, continue} = binbo:new_game(Pid),
	ok = binbo:game_draw(Pid, for_test),
	{ok, {draw, {manual, for_test}}} = binbo:game_status(Pid),
	{error, {already_has_status, {draw, {manual, for_test}}}} = binbo:game_draw(Pid),

	ok = binbo:print_board(Pid),
	ok = binbo:print_board(Pid, [unicode, flip]),
	ok.

%% set_game_state/1
set_game_state(Config) ->
	Pid = get_pid(Config),
	% Game is not initialized yet
	undefined = binbo:game_state(Pid),
	{error, {bad_game, undefined}} = binbo:game_status(Pid),
	{error, {bad_game, undefined}} = binbo:set_game_state(Pid, undefined),
	% Start new game
	{ok, continue} = binbo:new_game(Pid),
	{ok, continue} = binbo:game_status(Pid),
	Game = binbo:game_state(Pid),
	true = erlang:is_map(Game),
	% Set undefined state
	{error, {bad_game, undefined}} = binbo:set_game_state(Pid, undefined),
	% Set normal game state
	{ok, continue} = binbo:set_game_state(Pid, Game),
	{ok, continue} = binbo:game_status(Pid),
	% Set undefined state again
	{error, {bad_game, undefined}} = binbo:set_game_state(Pid, undefined),
	% Save game state as binary
	BinGame = erlang:term_to_binary(Game),
	% Convert from binary and set state
	Game2 = erlang:binary_to_term(BinGame),
	true = erlang:is_map(Game2),
	{ok, continue} = binbo:set_game_state(Pid, Game2),
	{ok, continue} = binbo:game_status(Pid),
	ok.


%%%------------------------------------------------------------------------------
%%%   Internal helpers
%%%------------------------------------------------------------------------------

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
			{error, Reason}
	end.

%% check_int_movelist/1
check_int_movelist([]) -> ok;
check_int_movelist([{From,To}|Tail]) ->
	true = (erlang:is_integer(From) andalso (From >= 0) andalso (From =< 63)),
	true = (erlang:is_integer(To) andalso (To >= 0) andalso (To =< 63)),
	true = (From =/= To),
	check_int_movelist(Tail).

%% check_bin_movelist/1
check_bin_movelist([]) -> ok;
check_bin_movelist([{From,To}|Tail]) ->
	true = (erlang:is_binary(From) andalso (erlang:byte_size(From) =:= 2)),
	true = (erlang:is_binary(To) andalso (erlang:byte_size(To) =:= 2)),
	true = (From =/= To),
	check_bin_movelist(Tail).


%% check_str_movelist/1
check_str_movelist([]) -> ok;
check_str_movelist([{From,To}|Tail]) ->
	true = (erlang:is_list(From) andalso (erlang:length(From) =:= 2)),
	true = (erlang:is_list(To) andalso (erlang:length(To) =:= 2)),
	true = (From =/= To),
	check_str_movelist(Tail).
