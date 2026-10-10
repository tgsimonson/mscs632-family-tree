/*  menu.pl: a console menu over family.pl, for asking questions without
    typing Prolog queries

    run with:  swipl menu.pl
*/

:- use_module(family).
:- use_module(library(readutil)).
:- initialization(main, main).

main :-
    count_people(N),
    format("~nFamily tree: ~w people over four generations~n", [N]),
    format("names are lower case, for example emily~n"),
    show_menu,
    loop.

count_people(N) :- findall(P, person(P), Ps), length(Ps, N).

loop :-
    ask("choice (m for the menu)", Choice),
    (   member(Choice, ["0", "q", "quit"])
    ->  format("goodbye~n")
    ;   member(Choice, ["m", "", "?"])
    ->  show_menu,
        loop
    ;   (   catch(choose(Choice), back_to_menu, format("  back to the menu~n"))
        ->  true
        ;   format("  please enter a number from the menu~n"),
            show_menu
        ),
        loop
    ).

show_menu :-
    format("~n  1  children of a person~n"),
    format("  2  parents of a person~n"),
    format("  3  siblings of a person~n"),
    format("  4  cousins of a person~n"),
    format("  5  is one person a cousin of another?~n"),
    format("  6  grandparents and grandchildren of a person~n"),
    format("  7  descendants of a person~n"),
    format("  8  ancestors of a person~n"),
    format("  9  how are two people related?~n"),
    format(" 10  family tree from a person~n"),
    format(" 11  list everyone~n"),
    format("  0  quit~n").

% reads one line after a prompt, trimmed; end of input counts as quit
ask(Prompt, Answer) :-
    format("~n~w> ", [Prompt]),
    flush_output,
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  Answer = "0"
    ;   normalize_space(string(Answer), Line)
    ).

% asks for a name until it is someone in the tree
% a blank answer, 0 or m goes back to the menu instead
ask_person(Prompt, Person) :-
    format(string(Full), "~w (blank for the menu)", [Prompt]),
    ask(Full, Text),
    (   member(Text, ["", "0", "m"])
    ->  throw(back_to_menu)
    ;   true
    ),
    string_lower(Text, Lower),
    atom_string(Candidate, Lower),
    (   known_person(Candidate)
    ->  Person = Candidate
    ;   format("  ~w is not in the family tree~n", [Text]),
        list_everyone,
        ask_person(Prompt, Person)
    ).

choose("1")  :- ask_person("person", P), children_of(P, L), say_list("children of", P, L).
choose("2")  :- ask_person("person", P), parents_of(P, L), say_list("parents of", P, L).
choose("3")  :- ask_person("person", P), siblings_of(P, L), say_list("siblings of", P, L),
                findall(H, half_sibling(H, P), Hs), sort(Hs, Half),
                ( Half == [] -> true ; say_list("  of those, half siblings of", P, Half) ).
choose("4")  :- ask_person("person", P), cousins_of(P, L), say_list("cousins of", P, L).
choose("5")  :- ask_person("first person", A), ask_person("second person", B),
                (   is_cousin(A, B)
                ->  format("  yes, ~w and ~w are cousins~n", [A, B])
                ;   format("  no, ~w and ~w are not cousins~n", [A, B])
                ).
choose("6")  :- ask_person("person", P),
                grandparents_of(P, Gs), say_list("grandparents of", P, Gs),
                grandchildren_of(P, Cs), say_list("grandchildren of", P, Cs).
choose("7")  :- ask_person("person", P), descendants_of(P, L), say_list("descendants of", P, L).
choose("8")  :- ask_person("person", P), ancestors_of(P, L), say_list("ancestors of", P, L).
choose("9")  :- ask_person("first person", A), ask_person("second person", B),
                relationship(A, B, R), describe(A, B, R).
choose("10") :- ask_person("person", P), nl, print_tree(P).
choose("11") :- list_everyone.

say_list(What, P, []) :- !, format("  ~w ~w: none~n", [What, P]).
say_list(What, P, L) :-
    atomic_list_concat(L, ', ', Text),
    length(L, N),
    format("  ~w ~w (~w): ~w~n", [What, P, N, Text]).

describe(A, _, self) :- !, format("  that is ~w twice~n", [A]).
describe(A, B, related) :- !,
    format("  ~w and ~w share an ancestor, more distantly than this program names~n", [A, B]).
describe(A, B, not_related) :- !,
    format("  ~w and ~w are not related by blood or by a shared child in this tree~n", [A, B]).
describe(A, B, R) :-
    atomic_list_concat(Words, '_', R),
    atomic_list_concat(Words, ' ', Name),
    format("  ~w is ~w's ~w~n", [A, B, Name]).

list_everyone :-
    findall(G-P, (person(P), generation_of(P, G)), Pairs),
    keysort(Pairs, Sorted),
    format("  people in the tree, by generation:~n"),
    forall(between(1, 4, G),
           (   findall(P, member(G-P, Sorted), Ps),
               msort(Ps, Names),
               atomic_list_concat(Names, ', ', Text),
               format("    ~w: ~w~n", [G, Text])
           )).
