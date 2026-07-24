-module(supervisor).
-export([start_link/0, init/1, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

-record(state, {
    children = [],
    max_restarts = 5,
    max_time = 60
}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

handle_call({add_child, ChildSpec}, _From, State) ->
    NewChildren = [ChildSpec | State#state.children],
    {reply, ok, State#state{children = NewChildren}};

handle_call({remove_child, ChildId}, _From, State) ->
    NewChildren = lists:keydelete(ChildId, 1, State#state.children),
    {reply, ok, State#state{children = NewChildren}};

handle_call(get_children, _From, State) ->
    {reply, State#state.children, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

-module(gen_worker).
-export([start_link/1, init/1, handle_call/3, handle_cast/2, terminate/2]).
-behaviour(gen_server).

-record(worker_state, {
    id,
    data
}).

start_link(WorkerId) ->
    gen_server:start_link(?MODULE, [WorkerId], []).

init([WorkerId]) ->
    {ok, #worker_state{id = WorkerId, data = #{}}}.

handle_call({set, Key, Value}, _From, State) ->
    NewData = maps:put(Key, Value, State#worker_state.data),
    {reply, ok, State#worker_state{data = NewData}};

handle_call({get, Key}, _From, State) ->
    Value = maps:get(Key, State#worker_state.data, undefined),
    {reply, Value, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

-module(pubsub).
-export([start_link/0, init/1, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

-record(pubsub_state, {
    subscribers = #{}
}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #pubsub_state{}}.

handle_call({subscribe, Topic, Pid}, _From, State) ->
    Subs = maps:get(Topic, State#pubsub_state.subscribers, []),
    NewSubs = [Pid | Subs],
    NewState = State#pubsub_state{
        subscribers = maps:put(Topic, NewSubs, State#pubsub_state.subscribers)
    },
    {reply, ok, NewState};

handle_call({unsubscribe, Topic, Pid}, _From, State) ->
    Subs = maps:get(Topic, State#pubsub_state.subscribers, []),
    NewSubs = lists:delete(Pid, Subs),
    NewState = State#pubsub_state{
        subscribers = maps:put(Topic, NewSubs, State#pubsub_state.subscribers)
    },
    {reply, ok, NewState};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast({publish, Topic, Message}, State) ->
    Subs = maps:get(Topic, State#pubsub_state.subscribers, []),
    lists:foreach(fun(Pid) -> Pid ! {message, Topic, Message} end, Subs),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

-module(queue_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

-record(queue_state, {
    items = []
}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #queue_state{}}.

handle_call(dequeue, _From, State = #queue_state{items = []}) ->
    {reply, {error, empty}, State};

handle_call(dequeue, _From, State = #queue_state{items = [H|T]}) ->
    {reply, {ok, H}, State#queue_state{items = T}};

handle_call(size, _From, State) ->
    {reply, length(State#queue_state.items), State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast({enqueue, Item}, State) ->
    NewItems = State#queue_state.items ++ [Item],
    {noreply, State#queue_state{items = NewItems}};

handle_cast(_Msg, State) ->
    {noreply, State}.

-module(utils).
-export([map/2, filter/2, fold/3, partition/2, zip/2]).

map(F, List) ->
    lists:map(F, List).

filter(Pred, List) ->
    lists:filter(Pred, List).

fold(F, Acc, List) ->
    lists:foldl(F, Acc, List).

partition(Pred, List) ->
    lists:partition(Pred, List).

zip(List1, List2) ->
    lists:zip(List1, List2).
