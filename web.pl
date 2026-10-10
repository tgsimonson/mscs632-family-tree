/*  web.pl: a browser view of family.pl, served by SWI-Prolog's own HTTP
    library, with no JavaScript

    the page lays out the family by generation and has a form for each kind
    of question; every answer comes from the same rules and query helpers
    the console uses, and the Prolog query behind it is shown with it

    run with:  swipl web.pl            (then open http://localhost:8000)
               swipl web.pl 8080       (another port)
*/

:- use_module(library(http/http_server)).
:- use_module(library(www_browser)).
:- use_module(family).
:- initialization(main, main).

:- http_handler(root(.), home, []).

main :-
    current_prolog_flag(argv, Argv),
    (   Argv = [PortText | _], atom_number(PortText, Port) -> true ; Port = 8000 ),
    catch(http_server([port(Port)]), E,
          ( print_message(error, E),
            format(user_error, "could not start the server on port ~w~n", [Port]),
            halt(1) )),
    format(string(URL), "http://localhost:~w/", [Port]),
    format("family tree viewer at ~s~npress Ctrl+C to stop~n", [URL]),
    % opening a browser is a convenience: on a machine without one (wsl, a
    % server) it fails or throws, and the server keeps running either way
    ignore(catch(www_open_url(URL), _, true)),
    thread_get_message(_).           % keep the main thread alive

% ------------------------------------------------------------- questions

% question(Key, Label, NeedsSecondPerson)
question(children,      "Children of",                        false).
question(parents,       "Parents of",                         false).
question(siblings,      "Siblings of",                        false).
question(cousins,       "Cousins of",                         false).
question(is_cousin,     "Is A a cousin of B?",                true).
question(grandparents,  "Grandparents of",                    false).
question(grandchildren, "Grandchildren of",                   false).
question(descendants,   "Descendants of (recursive)",         false).
question(ancestors,     "Ancestors of (recursive)",           false).
question(relationship,  "How is A related to B?",             true).
question(tree,          "Family tree from (recursive)",       false).

% answer(Key, A, B, Query, People, Text): runs one question
answer(children, A, _, Q, L, T)      :- list_answer(children_of, A, Q, L, "children", T).
answer(parents, A, _, Q, L, T)       :- list_answer(parents_of, A, Q, L, "parents", T).
answer(siblings, A, _, Q, L, T)      :- list_answer(siblings_of, A, Q, L, "siblings", T).
answer(cousins, A, _, Q, L, T)       :- list_answer(cousins_of, A, Q, L, "cousins", T).
answer(grandparents, A, _, Q, L, T)  :- list_answer(grandparents_of, A, Q, L, "grandparents", T).
answer(grandchildren, A, _, Q, L, T) :- list_answer(grandchildren_of, A, Q, L, "grandchildren", T).
answer(descendants, A, _, Q, L, T)   :- list_answer(descendants_of, A, Q, L, "descendants", T).
answer(ancestors, A, _, Q, L, T)     :- list_answer(ancestors_of, A, Q, L, "ancestors", T).
answer(is_cousin, A, B, Q, L, T) :-
    format(string(Q), "?- is_cousin(~w, ~w).", [A, B]),
    (   is_cousin(A, B)
    ->  L = [A, B], format(string(T), "true: ~w and ~w are cousins", [A, B])
    ;   L = [], format(string(T), "false: ~w and ~w are not cousins", [A, B])
    ).
answer(relationship, A, B, Q, [A, B], T) :-
    format(string(Q), "?- relationship(~w, ~w, R).", [A, B]),
    relationship(A, B, R),
    describe(A, B, R, T).
answer(tree, A, _, Q, L, T) :-
    format(string(Q), "?- print_tree(~w).", [A]),
    descendants_of(A, L),
    with_output_to(string(T), print_tree(A)).

list_answer(Helper, A, Query, List, Noun, Text) :-
    format(string(Query), "?- ~w(~w, X).", [Helper, A]),
    call(Helper, A, List),
    length(List, N),
    (   N =:= 0
    ->  format(string(Text), "~w has no recorded ~w", [A, Noun])
    ;   format(string(Text), "~w ~w", [N, Noun])
    ).

describe(A, _, self, T) :- !, format(string(T), "that is ~w twice", [A]).
describe(A, B, related, T) :- !,
    format(string(T), "~w and ~w share an ancestor, more distantly than this program names", [A, B]).
describe(A, B, not_related, T) :- !,
    format(string(T), "~w and ~w are not related by blood or by a shared child", [A, B]).
describe(A, B, R, T) :-
    atomic_list_concat(Words, '_', R),
    atomic_list_concat(Words, ' ', Name),
    format(string(T), "~w is ~w's ~w", [A, B, Name]).

% ------------------------------------------------------------- the page

home(Request) :-
    findall(K, question(K, _, _), Keys),
    http_parameters(Request, [
        q(Q, [default(cousins), oneof(Keys)]),
        a(A0, [default(emily)]),
        b(B0, [default(mia)])
    ]),
    valid_person(A0, emily, A),
    valid_person(B0, mia, B),
    answer(Q, A, B, Query, People, Text),
    question(Q, Label, NeedsB),
    ( NeedsB == true -> Marked = B ; Marked = none ),
    reply_html_page(
        [title('Family Tree'), \style],
        [ div(class(page),
              [ header([h1('Family Tree'),
                        p(class(sub), 'facts, rules and recursive queries in SWI-Prolog')]),
                div(class(layout),
                    [ section(class(panel), [h2('Ask'), \form(Q, A, B),
                                             \result(Label, Query, People, Text, Q)]),
                      section(class(panel), [h2('Generations'), p(class(hint),
                              'click a name to ask about that person; highlighted names are in the answer'),
                              \generations(Q, A, Marked, People)])
                    ])
              ])
        ]).

valid_person(Text, Default, Person) :-
    atom_string(P, Text),
    ( known_person(P) -> Person = P ; Person = Default ).

form(Q, A, B) -->
    { findall(P, person(P), Ps0), msort(Ps0, Ps) },
    html(form([action('/'), method(get), class(ask)],
              [ label(['Question', select(name(q), \options_q(Q))]),
                label(['Person A', select(name(a), \options_p(Ps, A))]),
                label(['Person B (for the two-person questions)', select(name(b), \options_p(Ps, B))]),
                button(type(submit), 'Ask')
              ])).

options_q(Selected) -->
    { findall(K-L, question(K, L, _), Pairs) },
    options_from(Pairs, Selected).
options_p(People, Selected) -->
    { findall(P-P, member(P, People), Pairs) },
    options_from(Pairs, Selected).

options_from([], _) --> [].
options_from([K-L | Rest], Selected) -->
    (   { K == Selected }
    ->  html(option([value(K), selected(selected)], L))
    ;   html(option(value(K), L))
    ),
    options_from(Rest, Selected).

result(Label, Query, People, Text, Q) -->
    html(div(class(result),
             [ p(class(label), Label),
               pre(class(query), Query),
               \result_body(Q, People, Text)
             ])).

result_body(tree, _, Text) --> !, html(pre(class(tree), Text)).
result_body(_, People, Text) -->
    html([p(class(answer), Text), div(class(chips), \chips(People))]).

chips([]) --> [].
chips([P | Ps]) --> html(span(class(chip), P)), chips(Ps).

% one row per generation, each row made of family units: a person together
% with everyone linked to them as a partner
generations(Q, A, B, Hits) -->
    { findall(G, (person(P), generation_of(P, G)), Gs0), sort(Gs0, Gs) },
    generation_rows(Gs, Q, A, B, Hits).

generation_rows([], _, _, _, _) --> [].
generation_rows([G | Gs], Q, A, B, Hits) -->
    { units_in_generation(G, Units) },
    html(div(class(generation),
             [ span(class(gen_label), ['Generation ', G]),
               div(class(units), \units(Units, Q, A, B, Hits))
             ])),
    generation_rows(Gs, Q, A, B, Hits).

units_in_generation(G, Units) :-
    findall(U, (person(P), generation_of(P, G), family_unit(P, U)), Us),
    sort(Us, Distinct),
    findall(Key-U, (member(U, Distinct), U = [First | _], parents_of(First, Ps), Key = Ps-First), Keyed),
    keysort(Keyed, Sorted),
    pairs_values(Sorted, Units).

% everyone reachable from P through partner links, in a fixed order so that
% each unit is found once whichever member it is built from;
% members born into the tree come first, then partners, each group by name
family_unit(P, Unit) :-
    unit_closure([P], [], Members),
    findall(Rank-M, (member(M, Members), ( parent(_, M) -> Rank = 0 ; Rank = 1 )), Ranked),
    msort(Ranked, Sorted),
    pairs_values(Sorted, Unit).

unit_closure([], Seen, Seen).
unit_closure([X | Xs], Seen, Members) :-
    (   memberchk(X, Seen)
    ->  unit_closure(Xs, Seen, Members)
    ;   findall(Y, partner(X, Y), Ys),
        append(Xs, Ys, Next),
        unit_closure(Next, [X | Seen], Members)
    ).

units([], _, _, _, _) --> [].
units([U | Us], Q, A, B, Hits) -->
    html(div(class(unit), \people(U, Q, A, B, Hits))),
    units(Us, Q, A, B, Hits).

people([], _, _, _, _) --> [].
people([P | Ps], Q, A, B, Hits) -->
    { person_class(P, A, B, Hits, Class),
      ( B == none -> BLink = mia ; BLink = B ),
      format(atom(Href), "/?q=~w&a=~w&b=~w", [Q, P, BLink]),
      parents_of(P, Parents),
      (   Parents == []
      ->  Sub = ''
      ;   atomic_list_concat(Parents, ' & ', ParentText),
          atom_concat('child of ', ParentText, Sub)
      )
    },
    html(a([class(Class), href(Href)], [span(class(name), P), span(class(of), Sub)])),
    people(Ps, Q, A, B, Hits).

person_class(P, A, _, _, 'person selected') :- P == A, !.
person_class(P, _, B, _, 'person second') :- P == B, !.
person_class(P, _, _, Hits, 'person hit') :- memberchk(P, Hits), !.
person_class(_, _, _, _, person).

style -->
    html(style(\['
:root { --bg:#F5F6F1; --panel:#FFFFFF; --ink:#1D2A22; --muted:#66756B; --line:#DCE2DA;
        --moss:#2F6B4F; --moss-soft:#E2EEE6; --slate:#3D5A80; --slate-soft:#E3EAF3; }
* { box-sizing:border-box; }
body { margin:0; background:var(--bg); color:var(--ink);
       font:15px/1.45 "Avenir Next","Segoe UI","Helvetica Neue",Arial,sans-serif; }
.page { max-width:1240px; margin:0 auto; padding:28px 24px 40px; }
header h1 { margin:0; font-size:28px; letter-spacing:-0.5px; }
.sub { margin:4px 0 22px; color:var(--muted); }
.layout { display:grid; grid-template-columns:360px 1fr; gap:20px; align-items:start; }
.panel { background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:18px 20px; }
h2 { margin:0 0 12px; font-size:13px; letter-spacing:1.2px; text-transform:uppercase; color:var(--muted); }
.ask label { display:block; font-size:13px; color:var(--muted); margin-bottom:12px; }
.ask select { display:block; width:100%; margin-top:4px; padding:7px 8px; font-size:15px;
              border:1px solid var(--line); border-radius:6px; background:var(--bg); color:var(--ink); }
.ask button { background:var(--moss); color:#fff; border:0; border-radius:6px; padding:9px 22px;
              font-size:15px; font-weight:600; cursor:pointer; }
.result { margin-top:18px; border-top:1px solid var(--line); padding-top:14px; }
.result .label { margin:0; font-weight:600; }
.query { background:#1D2A22; color:#CFE8D8; padding:9px 12px; border-radius:6px; margin:8px 0;
         font:13px/1.4 Menlo,Consolas,monospace; white-space:pre-wrap; }
.answer { margin:6px 0 8px; }
.tree { font:13px/1.35 Menlo,Consolas,monospace; background:var(--moss-soft); padding:10px 12px;
        border-radius:6px; overflow-x:auto; }
.chips { display:flex; flex-wrap:wrap; gap:6px; }
.chip { background:var(--moss-soft); color:var(--moss); border-radius:999px; padding:3px 11px;
        font-weight:600; font-size:14px; }
.hint { margin:-6px 0 14px; color:var(--muted); font-size:13px; }
.generation { display:grid; grid-template-columns:110px 1fr; gap:12px; padding:12px 0;
              border-top:1px solid var(--line); }
.generation:first-of-type { border-top:0; }
.gen_label { font-size:12px; letter-spacing:1px; text-transform:uppercase; color:var(--muted); padding-top:10px; }
.units { display:flex; flex-wrap:wrap; gap:10px; }
.unit { display:flex; gap:4px; padding:4px; border:1px dashed var(--line); border-radius:9px; }
.person { display:flex; flex-direction:column; min-width:92px; padding:6px 10px; border-radius:7px;
          text-decoration:none; color:var(--ink); background:var(--bg); border:1px solid transparent; }
.person:hover { border-color:var(--moss); }
.person .name { font-weight:600; }
.person .of { font-size:11px; color:var(--muted); }
.person.hit { background:var(--moss-soft); border-color:var(--moss); }
.person.hit .name { color:var(--moss); }
.person.selected { background:var(--moss); }
.person.selected .name, .person.selected .of { color:#fff; }
.person.second { background:var(--slate-soft); border-color:var(--slate); }
.person.second .name { color:var(--slate); }
@media (max-width:900px) { .layout { grid-template-columns:1fr; } }
'])).
