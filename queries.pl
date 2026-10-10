/*  queries.pl: runs the sample queries and prints each one with its answers
    in the same form as the SWI-Prolog prompt

    run with:  swipl queries.pl
    the output is saved in sample_queries.txt, and tests.pl checks that a
    fresh run still matches it
*/

:- use_module(family).
:- initialization(main, main).

% sample(Heading, QueryText)
sample("Basic facts", "parent(arthur, james).").
sample("Basic facts", "male(mary).").
sample("Children of a person", "children_of(james, Children).").
sample("Children of a person", "child(C, robert).").
sample("Parents and partners", "parents_of(lucas, Parents).").
sample("Parents and partners", "partners_of(robert, Partners).").
sample("Grandparents (recursive rule)", "grandparent(arthur, emily).").
sample("Grandparents (recursive rule)", "grandparent(G, noah).").
sample("Grandparents (recursive rule)", "grandchildren_of(margaret, Grandchildren).").
sample("Grandparents (recursive rule)", "generations(margaret, leo, N).").
sample("Siblings of a person", "sibling(S, emily).").
sample("Siblings of a person", "siblings_of(emily, Siblings).").
sample("Siblings of a person", "siblings_of(sophie, Siblings).").
sample("Siblings of a person", "half_sibling(sophie, lucas).").
sample("Siblings of a person", "sibling(emily, olivia).").
sample("Cousins", "is_cousin(emily, mia).").
sample("Cousins", "is_cousin(emily, daniel).").
sample("Cousins", "cousins_of(emily, Cousins).").
sample("Cousins", "second_cousin(noah, leo).").
sample("Aunts and uncles", "aunts_of(emily, Aunts).").
sample("Aunts and uncles", "uncles_of(emily, Uncles).").
sample("Descendants and ancestors (recursive rule)", "descendants_of(walter, Descendants).").
sample("Descendants and ancestors (recursive rule)", "ancestors_of(leo, Ancestors).").
sample("Descendants and ancestors (recursive rule)", "ancestor(eleanor, ava).").
sample("Naming a relationship", "relationship(lucas, sophie, R).").
sample("Naming a relationship", "relationship(robert, noah, R).").
sample("Naming a relationship", "relationship(olivia, noah, R).").
sample("Naming a relationship", "relationship(thomas, james, R).").
sample("Family tree from one person (recursive printing)", "print_tree(walter).").

main :-
    forall(sample(Heading, Text), run_sample(Heading, Text)).

:- dynamic last_heading/1.

run_sample(Heading, Text) :-
    (   last_heading(Heading)
    ->  true
    ;   retractall(last_heading(_)),
        assertz(last_heading(Heading)),
        format("~n% ~s~n", [Heading])
    ),
    format("~n?- ~s~n", [Text]),
    term_string(Goal, Text, [variable_names(Names)]),
    findall(Names, Goal, Answers),
    print_answers(Names, Answers).

% no answers prints false; a query without variables prints true; otherwise
% each answer is printed the way the prompt shows it, separated by ;
print_answers(_, []) :- !, format("false.~n").
print_answers([], _) :- !, format("true.~n").
print_answers(_, Answers) :- print_each(Answers).

print_each([A]) :- !, print_bindings(A), format(".~n").
print_each([A | As]) :- print_bindings(A), format(" ;~n"), print_each(As).

print_bindings(Bindings) :-
    maplist(binding_text, Bindings, Parts),
    atomic_list_concat(Parts, ',\n', Text),
    format("~w", [Text]).

binding_text(Name = Value, Text) :-
    format(atom(Text), "~w = ~W", [Name, Value, [spacing(next_argument), quoted(true)]]).
