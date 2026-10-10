/*  tests.pl: unit tests for family.pl using plunit, which ships with
    SWI-Prolog

    run with:  swipl -g run_tests -t halt tests.pl
*/

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module(library(process)).
:- use_module(family).

:- begin_tests(facts).

test(parent_fact, [nondet]) :- parent(arthur, james).
test(unknown_person, [fail]) :- person(mary).
test(everyone_has_a_gender, [true(Missing == [])]) :-
    findall(X, ((parent(X, _) ; parent(_, X)), \+ male(X), \+ female(X)), Missing).
test(nobody_is_both, [fail]) :- male(X), female(X).

:- end_tests(facts).

:- begin_tests(children_and_parents).

test(children_of, [true(Cs == [daniel, emily])]) :- children_of(james, Cs).
test(no_children, [true(Cs == [])]) :- children_of(daniel, Cs).
test(father, [nondet, true(F == james)]) :- father(F, emily).
test(mother, [true(M == karen)]) :- mother(M, lucas).
test(partners, [true(Ps == [diane, karen])]) :- partners_of(robert, Ps).

:- end_tests(children_and_parents).

:- begin_tests(grandparents).

test(grandparent_yes) :- grandparent(arthur, emily), !.
test(grandparent_no, [fail]) :- grandparent(arthur, james).
test(grandparents_of, [true(Gs == [arthur, eleanor, margaret, walter])]) :-
    grandparents_of(emily, Gs).
test(grandchildren_of, [true(Cs == [daniel, emily, henry, lucas, olivia, sophie])]) :-
    grandchildren_of(arthur, Cs).
test(generations, [nondet, true(N == 3)]) :- generations(margaret, leo, N).
test(great_grandparent) :- great_grandparent(walter, ava), !.

:- end_tests(grandparents).

:- begin_tests(siblings).

test(full_siblings) :- full_sibling(emily, daniel), !.
test(half_siblings, [nondet]) :- half_sibling(sophie, lucas).
test(not_siblings, [fail]) :- sibling(emily, olivia).
test(not_own_sibling, [fail]) :- sibling(emily, emily).
test(raw_rule_repeats, [true(L == [daniel, daniel])]) :- findall(S, sibling(S, emily), L).
test(siblings_of_removes_repeats, [true(L == [daniel])]) :- siblings_of(emily, L).
test(only_child, [true(L == [])]) :- siblings_of(leo, L).

:- end_tests(siblings).

:- begin_tests(cousins).

test(cousins_of, [true(Cs == [henry, lucas, mia, olivia, owen, sophie])]) :- cousins_of(emily, Cs).
test(cousin_both_ways) :- is_cousin(mia, emily), is_cousin(emily, mia).
test(sibling_is_not_cousin, [fail]) :- is_cousin(emily, daniel).
test(half_sibling_children_are_cousins) :- is_cousin(sophie, olivia).
test(second_cousins) :- second_cousin(noah, leo), !.
test(no_cousins, [true(Cs == [])]) :- cousins_of(arthur, Cs).

:- end_tests(cousins).

:- begin_tests(recursion).

test(descendants_of, [true(Ds == [ava, daniel, emily, linda, mia, noah, owen, paul])]) :-
    descendants_of(walter, Ds).
test(ancestors_of, [true(As == [arthur, george, marcus, margaret, olivia, susan])]) :-
    ancestors_of(leo, As).
test(ancestor_across_four_generations) :- ancestor(eleanor, ava), !.
test(no_ancestors, [true(As == [])]) :- ancestors_of(arthur, As).
test(generation_of, [true(N == 4)]) :- generation_of(noah, N).

:- end_tests(recursion).

:- begin_tests(relationship_names).

test(half_brother, [true(R == half_brother)]) :- relationship(lucas, sophie, R).
test(great_uncle, [true(R == great_uncle)]) :- relationship(robert, noah, R).
test(great_nephew, [true(R == great_nephew)]) :- relationship(noah, robert, R).
test(cousin_once_removed, [true(R == cousin_once_removed)]) :- relationship(olivia, noah, R).
test(son_in_law, [true(R == son_in_law)]) :- relationship(thomas, james, R).
test(grandmother, [true(R == grandmother)]) :- relationship(eleanor, emily, R).
test(not_related, [true(R == not_related)]) :- relationship(diane, karen, R).

:- end_tests(relationship_names).

:- begin_tests(sample_queries).

% the saved sample output must match a fresh run of queries.pl
test(matches_saved_output) :-
    read_file_to_string('sample_queries.txt', Saved, []),
    process_create(path(swipl), ['queries.pl'], [stdout(pipe(Out))]),
    read_string(Out, _, Fresh),
    close(Out),
    lines(Fresh, FreshLines),
    lines(Saved, SavedLines),
    assertion(FreshLines == SavedLines).

% splits text into lines, dropping carriage returns so the comparison also
% holds when git has converted the file to windows line endings
lines(Text, Lines) :-
    split_string(Text, "\n", "\r", Lines0),
    exclude(==(""), Lines0, Lines).

:- end_tests(sample_queries).
