module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end

module type FUNCTOR = sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end

module Option_monad : MONAD with type 'a t = 'a option = struct
  type 'a t = 'a option

  let return x = Some x

  let bind m f =
    match m with
    | None -> None
    | Some x -> f x
end

module List_monad : MONAD with type 'a t = 'a list = struct
  type 'a t = 'a list

  let return x = [x]

  let bind m f = List.concat (List.map f m)
end

module Result_monad (Error : sig type t end) : MONAD with type 'a t = ('a, Error.t) result = struct
  type 'a t = ('a, Error.t) result

  let return x = Ok x

  let bind m f =
    match m with
    | Error e -> Error e
    | Ok x -> f x
end

module Option_functor : FUNCTOR with type 'a t = 'a option = struct
  type 'a t = 'a option

  let map f = function
    | None -> None
    | Some x -> Some (f x)
end

module List_functor : FUNCTOR with type 'a t = 'a list = struct
  type 'a t = 'a list

  let map = List.map
end

module Infix = struct
  let (>>=) = Option_monad.bind
  let (>>|) m f = Option_functor.map f m
  let (let*) = Option_monad.bind
  let (and*) x y = Option_monad.bind x (fun a -> Option_monad.bind y (fun b -> Option_monad.return (a, b)))
end

let sequence_option lst =
  let rec aux acc = function
    | [] -> Some (List.rev acc)
    | None :: _ -> None
    | Some x :: xs -> aux (x :: acc) xs
  in
  aux [] lst

let traverse_option f lst =
  let rec aux acc = function
    | [] -> Some (List.rev acc)
    | x :: xs ->
        match f x with
        | None -> None
        | Some y -> aux (y :: acc) xs
  in
  aux [] lst

let filter_map f lst =
  let rec aux acc = function
    | [] -> List.rev acc
    | x :: xs ->
        match f x with
        | None -> aux acc xs
        | Some y -> aux (y :: acc) xs
  in
  aux [] lst

let partition_either lst =
  let rec aux lefts rights = function
    | [] -> (List.rev lefts, List.rev rights)
    | Ok x :: xs -> aux lefts (x :: rights) xs
    | Error e :: xs -> aux (e :: lefts) rights xs
  in
  aux [] [] lst

let fold_left_option f init lst =
  let rec aux acc = function
    | [] -> Some acc
    | x :: xs ->
        match f acc x with
        | None -> None
        | Some new_acc -> aux new_acc xs
  in
  aux init lst

let rec iterate n f x =
  if n <= 0 then x
  else iterate (n - 1) f (f x)

let unfold f seed =
  let rec aux acc s =
    match f s with
    | None -> List.rev acc
    | Some (x, s') -> aux (x :: acc) s'
  in
  aux [] seed

let take n lst =
  let rec aux acc n = function
    | [] -> List.rev acc
    | x :: xs ->
        if n <= 0 then List.rev acc
        else aux (x :: acc) (n - 1) xs
  in
  aux [] n lst

let drop n lst =
  let rec aux n = function
    | [] -> []
    | _ :: xs as lst ->
        if n <= 0 then lst
        else aux (n - 1) xs
  in
  aux n lst

let split_at n lst =
  (take n lst, drop n lst)

let group_by eq lst =
  let rec aux current groups = function
    | [] ->
        begin match current with
        | [] -> List.rev groups
        | _ -> List.rev (List.rev current :: groups)
        end
    | x :: xs ->
        match current with
        | [] -> aux [x] groups xs
        | y :: _ ->
            if eq x y then aux (x :: current) groups xs
            else aux [x] (List.rev current :: groups) xs
  in
  aux [] [] lst

let distinct lst =
  let rec aux seen acc = function
    | [] -> List.rev acc
    | x :: xs ->
        if List.mem x seen then aux seen acc xs
        else aux (x :: seen) (x :: acc) xs
  in
  aux [] [] lst

let intersperse sep lst =
  let rec aux acc = function
    | [] -> List.rev acc
    | [x] -> List.rev (x :: acc)
    | x :: xs -> aux (sep :: x :: acc) xs
  in
  aux [] lst

let intercalate sep lists =
  List.concat (intersperse sep lists)
