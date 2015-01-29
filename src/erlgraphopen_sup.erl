-module(erlgraphopen_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================
-define(MAX_RESTART,    5).
-define(MAX_TIME,      60).
-define(DEF_PORT,    6666).

%%----------------------------------------------------------------------
%% Supervisor behaviour callbacks
%%----------------------------------------------------------------------
init([]) ->
  Port = get_app_env(listen_port, ?DEF_PORT),

  {ok,
    {_SupFlags = {one_for_one, ?MAX_RESTART, ?MAX_TIME},
      [
        % TCP Listener
        {   tcp_server_sup,                          % Id       = internal id
          {tcp_listener_server,start_link,[Port]}, % StartFun = {M, F, A}
          permanent,                               % Restart  = permanent | transient | temporary
          2000,                                    % Shutdown = brutal_kill | int() >= 0 | infinity
          worker,                                  % Type     = worker | supervisor
          [tcp_listener]                           % Modules  = [Module] | dynamic
        },
        % Client instance supervisor
        {   tcp_client_sup,
          {tcp_client_sup,start_link,[]},
          permanent,                               % Restart  = permanent | transient | temporary
          infinity,                                % Shutdown = brutal_kill | int() >= 0 | infinity
          supervisor,                              % Type     = worker | supervisor
          []                                       % Modules  = [Module] | dynamic
        }
      ]
    }
  }.

%%----------------------------------------------------------------------
%% Internal functions
%%----------------------------------------------------------------------
get_app_env(Opt, Default) ->
  case application:get_env(application:get_application(), Opt) of
    {ok, Val} -> Val;
    _ ->
      case init:get_argument(Opt) of
        [[Val | _]] -> Val;
        error       -> Default
      end
  end.


