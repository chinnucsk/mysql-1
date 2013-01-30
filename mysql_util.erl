%% Copyright (c) 2009
%% Bill Warnecke <bill@rupture.com>
%% Jacob Vorreuter <jacob.vorreuter@gmail.com>
%%
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%%
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
-module(mysql_util).
-export([length_coded_binary/1, length_coded_string/1]).
-compile(export_all).

-include("mysql.hrl").

length_coded_binary(<<>>) -> {<<>>, <<>>};
length_coded_binary(<<FirstByte:8, Tail/binary>>) ->
	if
		FirstByte =< 250 -> {FirstByte, Tail};
		FirstByte == 251 -> {undefined, Tail};
		FirstByte == 252 ->
			<<Word:16/little, Tail1/binary>> = Tail,
			{Word, Tail1};
		FirstByte == 253 ->
			<<Word:24/little, Tail1/binary>> = Tail,
			{Word, Tail1};
		FirstByte == 254 ->
			<<Word:64/little, Tail1/binary>> = Tail,
			{Word, Tail1};
		true ->
			exit(poorly_formatted_length_encoded_binary)
	end.

length_coded_string(<<>>) -> {<<>>, <<>>};
length_coded_string(Bin) ->
	case length_coded_binary(Bin) of
		{undefined, Rest} ->
			{undefined, Rest};
		{Length, Rest} ->
			case Rest of
				<<String:Length/binary, Rest1/binary>> ->
					{String, Rest1};
				_ ->
					exit(poorly_formatted_length_coded_string)
			end
	end.
