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
-module(em_data_manager).
-author("Sergey Penkovsky <sergey.penkovsky@gmail.com>").

-include("em_records.hrl").

%% API
-export([
  init/0
]).

-export([
  get_server/0,
  update_server/1
]).

-export([
  create_user/1,
  update_user/1,
  update_user/3,
  delete_user/1,
  check_user/2,
  get_users/0
]).

-export([
  link_device/1,
  unlink_device/1,
  create_device/1,
  create_device/3,
  update_device/1,
  update_device/4,
  delete_device/1,
  delete_device/2,
  get_devices/1,
  get_device_by_uid/1,
  get_all_devices/0
]).

-export([
  create_position/2,
  get_positions/3,
  get_last_position/2
]).



init() ->
    em_storage:ensure_index(users, #{<<"key">> => #{<<"id">> => 1}, <<"name">> => <<"id_1">>, <<"unique">> => true}),
    em_storage:ensure_index(users, #{<<"key">> => #{<<"email">> => 1}, <<"name">> => <<"email_1">>, <<"unique">> => true}),

    em_storage:ensure_index(devices, #{<<"key">> => #{<<"id">> => 1}, <<"name">> => <<"id_1">>, <<"unique">> => true}),
    em_storage:ensure_index(devices, #{<<"key">> => #{<<"uniqueId">> => 1}, <<"name">> => <<"uniqueId_1">>, <<"unique">> => true}),

    em_storage:ensure_index(servers, #{<<"key">> => #{<<"id">> => 1}, <<"name">> => <<"id_1">>, <<"unique">> => true}),

    em_storage:ensure_index(messages, #{<<"key">> => #{<<"id">> => 1}, <<"name">> => <<"id_1">>, <<"unique">> => true}),
    em_storage:ensure_index(messages, #{<<"key">> => #{<<"deviceId">> => 1, <<"fixTime">> => 1, <<"imei">> => 1}, <<"name">> => <<"deviceId_1_fixTime_1_imei_1">>, <<"unique">> => true}),
    case em_storage_server:get() of
        null ->
            em_storage_server:create(true, 0, 0, 0),
            Admin = em_storage_user:create(<<"admin">>, <<"admin">>, <<"admin">>, true),
            Device = em_storage_device:create(<<"test1">>, <<"123456789012345">>),
            %%link_device(maps:get(<<"id">>, Admin), maps:get(<<"id">>, Device)),
            em_logger:info("Create account admin: username: ~s, password: ~s", [maps:get(<<"email">>, Admin), maps:get(<<"password">>, Admin)]);
        _ ->
            em_logger:info("Storage already init")
    end.


get_server() ->
  em_storage:get_server().

update_server(Server) ->
    em_storage:update_server(Server).

create_position(DeviceModel, PositionModel) ->
      case em_storage:create_position(PositionModel) of
        {ok, Position} ->
          em_storage:update_device(DeviceModel#device{positionId = Position#position.id}),
          case em_storage:get_device_by_id(DeviceModel#device.id) of
            {ok, Device} ->
              em_manager_event:broadcast(Device, Position),
              {ok, Position};
            _ ->
              {ok, Position}
          end;
        Reason ->
          Reason
      end.

create_message(DeviceId, Protocol, MessageParams) ->
    case em_storage_message:get(DeviceId, maps:get(<<"deviceTime">>, MessageParams)) of
      #{} ->
        case em_storage_message:create(DeviceId, Protocol, MessageParams) of
          null ->
            null;
          Message ->
            em_storage_device:update(DeviceId, #{
              <<"positionId">> => maps:get(<<"id">>, Message)
            }),
            Device = em_storage_device:get_by_id(DeviceId),
            em_manager_event:broadcast(convert_date_in_device(Device), convert_date_in_message(maps:remove(<<"_id">>, Message))),
            Message
        end;
      _ ->
        null
    end.

get_positions(DeviceId, TimeFrom, TimeTo) ->
    em_storage:get_positions(DeviceId, TimeFrom, TimeTo).

get_last_position(PositionId, DeviceId) ->
    em_storage:get_last_position(PositionId,  DeviceId).


convert_date_in_message(Message) ->
  %% deviceTime: "2016-01-09T14:56:18.000+0000"
  %% fixTime: "2016-01-09T14:56:18.000+0000"
  %% serverTime: "2016-01-09T14:57:16.000+0000"
  {ok, DeviceTime} = em_helper_time:format(<<"%Y-%m-%dT%H:%M:%S.000%z">>, maps:get(<<"deviceTime">>, Message)),
  {ok, FixTime} = em_helper_time:format(<<"%Y-%m-%dT%H:%M:%S.000%z">>, maps:get(<<"fixTime">>, Message)),
  {ok, ServerTime} = em_helper_time:format(<<"%Y-%m-%dT%H:%M:%S.000%z">>, maps:get(<<"serverTime">>, Message)),
  NewMessage0 = maps:put(<<"deviceTime">>, DeviceTime, Message),
  NewMessage1 = maps:put(<<"fixTime">>, FixTime, NewMessage0),
  maps:put(<<"serverTime">>, ServerTime, NewMessage1).

create_user(User) ->
    case em_storage:get_user_by_email(User#user.email) of
      {error, _Reason} ->
            em_storage:create_user(User);
        _ ->
          {error, <<"Duplicate email">>}
    end.

update_user(User) ->
  em_storage:update_user(User).



update_user(UserId, Field, Value) ->
    em_storage_user:update(UserId, Field, Value).

delete_user(User) ->
    em_storage:delete_user(User).

check_user(Email, Password) ->
  CheckPass = fun(Password, User = #user{hashPassword = HashPassword}) ->
                case Password =:= HashPassword of
                  true -> {ok, User};
                  false -> {error, <<"Access is denied">>}
                end
              end,
  case em_storage:get_user_by_email(Email) of
    {ok, User} -> CheckPass(em_password:hash(Password), User);
    Reason -> Reason
  end.

get_users() ->
    em_storage:get_users().



create_device(Device) ->
    em_storage:create_device(Device).

create_device(UserId, DeviceName, DeviceUniqueId) ->
    case em_storage_device:create(DeviceName, DeviceUniqueId) of
        null ->
            null;
        Device = #{<<"id">> := DeviceId} ->
            em_storage_permission:create(UserId, DeviceId),
            Device
    end.

update_device(Device) ->
    em_storage:update_device(Device).

update_device(UserId, DeviceId, Field, Value) ->
    case em_storage_permission:get(UserId, DeviceId) of
        null ->
            false;
        _ ->
            em_storage_device:update(DeviceId, Field, Value),
            true
    end.

delete_device(Device) ->
    em_storage:delete_device(Device).

delete_device(UserId, DeviceId) ->
    case em_storage_permission:get(UserId, DeviceId) of
        null ->
            false;
        _ ->
            em_storage_device:delete(DeviceId),
            em_storage_permission:delete(DeviceId),
            true
    end.


get_devices(UserId) ->
  Callback = fun(Permission = #permission{deviceId = DeviceId}, Acc) ->
                em_logger:info("PERMISSION: ~w", [Permission]),
                case em_storage:get_device_by_id(DeviceId) of
                  {ok, Device} ->
                    [Device | Acc];
                  {error, _Reason} ->
                    Acc
                end
             end,
  {ok, Permissions} = em_storage:get_permissions_by_user_id(UserId),
  Devices = lists:foldl(Callback, [], Permissions),
  {ok, Devices}.


get_device_by_uid(UniqueId) ->
  em_storage:get_device_by_uid(UniqueId).


get_all_devices() ->
    em_storage:get_devices().

convert_date_in_device(Device) ->
  {ok, Date} = em_helper_time:format(<<"%Y-%m-%dT%H:%M:%S.000%z">>, maps:get(<<"lastUpdate">>, Device)),
  maps:put(<<"lastUpdate">>, Date, Device).

link_device(Permission) ->
    em_storage:create_permission(Permission).

unlink_device(Permission) ->
  em_storage:delete_permission(Permission).