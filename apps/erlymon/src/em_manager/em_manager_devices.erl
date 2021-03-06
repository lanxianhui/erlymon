%%%-------------------------------------------------------------------
%%% @author Sergey Penkovsky
%%% @copyright (C) 2015, Sergey Penkovsky <sergey.penkovsky@gmail.com>
%%% @doc
%%%    Erlymon is an open source GPS tracking system for various GPS tracking devices.
%%%
%%%    Copyright (C) 2015, Sergey Penkovsky <sergey.penkovsky@gmail.com>.
%%%
%%%    This file is part of Erlymon.
%%%
%%%    Erlymon is free software: you can redistribute it and/or  modify
%%%    it under the terms of the GNU Affero General Public License, version 3,
%%%    as published by the Free Software Foundation.
%%%
%%%    Erlymon is distributed in the hope that it will be useful,
%%%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%%%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%%    GNU Affero General Public License for more details.
%%%
%%%    You should have received a copy of the GNU Affero General Public License
%%%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%% @end
%%%-------------------------------------------------------------------
-module(em_manager_devices).
-author("Sergey Penkovsky <sergey.penkovsky@gmail.com>").

-behaviour(gen_server).


-include("em_records.hrl").

-include_lib("stdlib/include/ms_transform.hrl").


%% API
-export([start_link/0]).

-export([
         count/0,
         get/0,
         get_by_uid/1,
         get_by_id/1,
         create/1,
         update/1,
         delete/1
        ]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {cache :: any()}).

%%%===================================================================
%%% API
%%%===================================================================
-spec(count() -> {ok, integer()} | {error, string()}).
count() ->
    gen_server:call(?SERVER, count).

-spec(get() -> {ok, [Rec :: #device{}]} | {error, string()}).
get() ->
    gen_server:call(?SERVER, {get}).

-spec(get_by_uid(UniqueId :: string()) -> {ok, Rec :: #device{}} | {error, string()}).
get_by_uid(UniquiId) ->
    gen_server:call(?SERVER, {get, UniquiId}).

-spec(get_by_id(Id :: integer()) -> {ok, Rec :: #device{}} | {error, string()}).
get_by_id(Id) ->
    gen_server:call(?SERVER, {get, Id}).

-spec(create(Device :: #device{}) -> {ok, #device{}} | {error, string()}).
create(Device) ->
    gen_server:call(?SERVER, {create, Device}).

-spec(update(Device :: #device{}) -> {ok, #device{}} | {error, string()}).
update(Device) ->
    gen_server:call(?SERVER, {update, Device}).

-spec(delete(Device :: #device{}) -> {ok, #device{}} | {error, string()}).
delete(Device) ->
    gen_server:call(?SERVER, {delete, Device}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
             {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
             {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
             {stop, Reason :: term()} | ignore).
init([]) ->
    em_logger:info("Init devices manager"),
    Cache = ets:new(devices, [set, private, {keypos, 2}]),
    {ok, Items} = em_storage:get_devices(),
    lists:foreach(fun(Item) ->
                          ets:insert_new(Cache, Item),
                          do_update_status(Item)
                  end, Items),
    em_logger:info("Loaded ~w device(s)", [length(ets:tab2list(Cache))]),
    {ok, #state{cache = Cache}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
                  State :: #state{}) ->
             {reply, Reply :: term(), NewState :: #state{}} |
             {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
             {noreply, NewState :: #state{}} |
             {noreply, NewState :: #state{}, timeout() | hibernate} |
             {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
             {stop, Reason :: term(), NewState :: #state{}}).
handle_call(count, _From, State) ->
    do_count_devices(State);
handle_call({get}, _From, State) ->
    do_get_devices(State);
handle_call({get, Id}, _From, State) when is_integer(Id) ->
    do_get_device_by_id(State, Id);
handle_call({get, UniqueId}, _From, State) when is_binary(UniqueId) ->
    do_get_device_by_uid(State, UniqueId);
handle_call({create, Device}, _From, State) ->
    do_create_device(State, Device);
handle_call({update, Device}, _From, State) ->
    do_update_device(State, Device);
handle_call({delete, Device}, _From, State) ->
    do_delete_device(State, Device);
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
             {noreply, NewState :: #state{}} |
             {noreply, NewState :: #state{}, timeout() | hibernate} |
             {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
             {noreply, NewState :: #state{}} |
             {noreply, NewState :: #state{}, timeout() | hibernate} |
             {stop, Reason :: term(), NewState :: #state{}}).
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
                State :: #state{}) -> term()).
terminate(_Reason, #state{cache = Cache}) ->
    ets:delete(Cache),
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
                  Extra :: term()) ->
             {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_count_devices(State = #state{cache = Cache}) ->
    Info = ets:info(Cache),
    {size, Size} = proplists:lookup(size, Info),
    {reply, {ok, Size}, State}.


do_get_devices(State = #state{cache = Cache}) ->
    {reply, {ok, ets:tab2list(Cache)}, State}.

do_get_device_by_id(State = #state{cache = Cache}, Id) ->
    case ets:lookup(Cache, Id) of
        [] ->
            {reply, {error, <<"Access is denied">>}, State};
        [Item | _] ->
            {reply, {ok, Item}, State}
    end.

do_get_device_by_uid(State = #state{cache = Cache}, Uid) ->
    Match = ets:fun2ms(fun(Device = #device{uniqueId = UniqueId}) when UniqueId =:= Uid -> Device end),
    case ets:select(Cache, Match) of
        [] ->
            {reply, {error, <<"Access is denied">>}, State};
        [Item | _] ->
            {reply, {ok, Item}, State}
    end.

do_create_device(State = #state{cache = Cache}, DeviceModel) ->
    case em_storage:create_device(DeviceModel) of
        {ok, Device} ->
            case ets:insert_new(Cache, Device) of
                true ->
                    {reply, {ok, Device}, State};
                false ->
                    {reply, {error, <<"Error sync in devices cache">>}, State}
            end;
        Reason ->
            {reply, Reason, State}
    end.

do_update_device(State = #state{cache = Cache}, DeviceModel) ->
    case em_storage:update_device(DeviceModel) of
        {ok, Device} ->
            case ets:insert(Cache, Device) of
                true ->
                    {reply, {ok, Device}, State};
                false -> {reply, {error, <<"Error sync in devices cache">>}, State}
            end;
        Reason ->
            {reply, Reason, State}
    end.

do_delete_device(State = #state{cache = Cache}, DeviceModel) ->
    case em_storage:delete_device(DeviceModel) of
        {ok, Device} ->
            case ets:delete(Cache, Device#device.id) of
                true ->
                    {reply, {ok, Device}, State};
                false -> {reply, {error, <<"Error sync in devices cache">>}, State}
            end;
        Reason ->
            {reply, Reason, State}
    end.

do_update_status(#device{id = Id, status = Status}) when Status /= ?STATUS_OFFLINE ->
    em_timer:create(Id, fun() ->
                                Model = #device{
                                           id = Id,
                                           name = undefined,
                                           uniqueId = undefined,
                                           status = ?STATUS_OFFLINE,
                                           lastUpdate = undefined,
                                           positionId = undefined
                                          },
                                {ok, Res} = em_manager_devices:update(Model),
                                em_logger:info("DEVICE: ~w", [Res]),
                                em_manager_event:broadcast(Res)
                        end, 300000);
do_update_status(_) ->
    ok.