module FunctionalUtils

let map f list = List.map f list

let filter pred list = List.filter pred list

let fold reducer init list = List.fold reducer init list

let reduce reducer list = List.reduce reducer list

let flatMap f list = List.collect f list

let partition pred list = List.partition pred list

let groupBy keySelector list = List.groupBy keySelector list

let sortBy keySelector list = List.sortBy keySelector list

let distinct list = List.distinct list

let take n list = List.take n list

let skip n list = List.skip n list

let zip list1 list2 = List.zip list1 list2

let unzip list = List.unzip list

let reverse list = List.rev list

let head list = List.head list

let tail list = List.tail list

let isEmpty list = List.isEmpty list

let length list = List.length list

let sum list = List.sum list

let average list = List.average list

let max list = List.max list

let min list = List.min list

let find pred list = List.find pred list

let tryFind pred list = List.tryFind pred list

let exists pred list = List.exists pred list

let forall pred list = List.forall pred list

let iter action list = List.iter action list

let iteri action list = List.iteri action list

let mapi f list = List.mapi f list

let choose f list = List.choose f list

let except list1 list2 =
    list1 |> List.filter (fun x -> not (List.contains x list2))

let intersect list1 list2 =
    list1 |> List.filter (fun x -> List.contains x list2)

let union list1 list2 =
    List.append list1 list2 |> List.distinct

let chunk size list =
    list |> List.chunkBySize size

let window size list =
    list |> List.windowed size

let pairwise list =
    list |> List.pairwise

let scan folder state list =
    List.scan folder state list

let unfold generator state =
    List.unfold generator state

let init n initializer =
    List.init n initializer

let replicate n value =
    List.replicate n value

let cons head tail =
    head :: tail

let append list1 list2 =
    List.append list1 list2

let concat lists =
    List.concat lists

let compareWith comparer list1 list2 =
    List.compareWith comparer list1 list2

let equalsWith comparer list1 list2 =
    List.compareWith comparer list1 list2 = 0

let splitAt index list =
    List.splitAt index list

let transpose lists =
    List.transpose lists

let permute indexer list =
    List.permute indexer list

type Result<'T,'E> =
    | Ok of 'T
    | Error of 'E

module Result =
    let bind f result =
        match result with
        | Ok value -> f value
        | Error e -> Error e

    let map f result =
        match result with
        | Ok value -> Ok (f value)
        | Error e -> Error e

    let mapError f result =
        match result with
        | Ok value -> Ok value
        | Error e -> Error (f e)

    let isOk result =
        match result with
        | Ok _ -> true
        | Error _ -> false

    let isError result =
        match result with
        | Ok _ -> false
        | Error _ -> true

    let defaultValue def result =
        match result with
        | Ok value -> value
        | Error _ -> def

    let defaultWith defThunk result =
        match result with
        | Ok value -> value
        | Error _ -> defThunk()

type Option<'T> with
    member this.IsSome =
        match this with
        | Some _ -> true
        | None -> false

    member this.IsNone =
        match this with
        | Some _ -> false
        | None -> true

module Option =
    let getOr defaultValue opt =
        match opt with
        | Some value -> value
        | None -> defaultValue

    let orElse alternative opt =
        match opt with
        | Some _ -> opt
        | None -> alternative

let pipe value f = f value

let compose f g x = f (g x)

let flip f x y = f y x

let curry f x y = f (x, y)

let uncurry f (x, y) = f x y

let constant value = fun _ -> value

let identity value = value

let tap f value =
    f value
    value

let tee f value =
    f value |> ignore
    value
