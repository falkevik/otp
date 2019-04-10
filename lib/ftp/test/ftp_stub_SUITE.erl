%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2005-2019. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%
%%
-module(ftp_stub_SUITE).

-include_lib("common_test/include/ct.hrl").

%% Note: This directive should only be used in test suites.
-compile(export_all).

-define(FTP_USER, "anonymous").
-define(FTP_PASS, "nopass").

suite() ->
    [{ct_hooks,[ts_install_cth]},
     {timetrap,{seconds,20}}
    ].

all() ->
    [welcome_banner].

groups() ->
    [].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, Config) ->
    Config.


init_per_testcase(welcome_banner, Config) ->
    {ok, P} = gen_tcp:listen(0, []),
    {ok, {_, Port}} = inet:sockname(P),
    Fun =
	fun() ->
	    {ok, S} = gen_tcp:accept(P),
	    gen_tcp:send(S, <<"220-welcome to test ftp server\r\n">>),
	    ct:sleep({seconds, 1}),
	    gen_tcp:send(S, <<"220-welcome next line test\r\n">>),
	    ct:sleep({seconds, 1}),
	    gen_tcp:send(S, <<"220-welcome last line test\r\n">>),
	    ct:sleep({seconds, 1}),
	    gen_tcp:send(S, <<"220 \r\n">>),
	    receive
		stop -> ok
	    end
	end,
    ServerPid = spawn_link(Fun),
    [{banner_port,Port},
     {banner_server_pid, ServerPid},
     {banner_server_sock, P}
     | Config];

init_per_testcase(_, Config) ->
    Config.

end_per_testcase(welcome_banner, Config) ->
    Pid = proplists:get_value(banner_server_pid, Config),
    Pid ! stop,
    ok;
end_per_testcase(_, _) ->
    ok.

%%-------------------------------------------------------------------------
%% Test cases starts here.
%%-------------------------------------------------------------------------
welcome_banner()->
    [{doc, "Test parsing of welcome banner"}].

welcome_banner(Config) ->
    Port = proplists:get_value(banner_port, Config),
    {ok, Pid} = ftp:open("localhost", [{port, Port}]),
    ok = ftp:close(Pid),			% logoff
    {error,eclosed} = ftp:pwd(Pid),		% check logoff result
    ok.
