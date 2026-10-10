/*  family.pl: a four-generation family tree with rules for derived
    relationships

    the facts state only who is whose parent and who is male or female;
    every other relationship (grandparent, sibling, cousin, aunt, ancestor,
    and so on) is derived by rules, and the query predicates at the end
    collect the answers into sorted lists without duplicates

    load it with:  swipl family.pl
*/

:- module(family, [
    person/1, parent/2, male/1, female/1,
    child/2, father/2, mother/2, son/2, daughter/2,
    generations/3, grandparent/2, grandfather/2, grandmother/2,
    grandchild/2, great_grandparent/2,
    ancestor/2, descendant/2,
    sibling/2, full_sibling/2, half_sibling/2, brother/2, sister/2,
    aunt_or_uncle/2, aunt/2, uncle/2, niece_or_nephew/2,
    great_aunt_or_uncle/2, cousin_once_removed/2,
    cousin/2, second_cousin/2, co_parents/2, partner/2,
    parent_in_law/2, child_in_law/2,
    children_of/2, parents_of/2, partners_of/2, siblings_of/2, cousins_of/2,
    aunts_of/2, uncles_of/2,
    grandchildren_of/2, grandparents_of/2,
    descendants_of/2, ancestors_of/2,
    is_cousin/2, relationship/3, generation_of/2,
    print_tree/1, known_person/1
]).

% ------------------------------------------------------------------ facts

% parent(Parent, Child)

% generation 1 to generation 2
parent(arthur, james).    parent(margaret, james).
parent(arthur, susan).    parent(margaret, susan).
parent(arthur, robert).   parent(margaret, robert).
parent(walter, linda).    parent(eleanor, linda).
parent(walter, paul).     parent(eleanor, paul).

% generation 2 to generation 3
parent(james, emily).     parent(linda, emily).
parent(james, daniel).    parent(linda, daniel).
parent(susan, olivia).    parent(george, olivia).
parent(susan, henry).     parent(george, henry).
parent(robert, sophie).   parent(diane, sophie).    % robert's first partner
parent(robert, lucas).    parent(karen, lucas).     % robert's second partner
parent(paul, mia).        parent(rachel, mia).
parent(paul, owen).       parent(rachel, owen).

% generation 3 to generation 4
parent(emily, noah).      parent(thomas, noah).
parent(emily, ava).       parent(thomas, ava).
parent(olivia, leo).      parent(marcus, leo).

male(arthur).   male(walter).   male(james).   male(robert).  male(paul).
male(george).   male(daniel).   male(henry).   male(lucas).   male(owen).
male(thomas).   male(marcus).   male(noah).    male(leo).

female(margaret). female(eleanor). female(susan).  female(linda).
female(diane).    female(karen).   female(rachel). female(emily).
female(olivia).   female(sophie).  female(mia).    female(ava).

person(X) :- male(X).
person(X) :- female(X).

% ------------------------------------------------------------ direct rules

child(C, P)    :- parent(P, C).
father(F, C)   :- parent(F, C), male(F).
mother(M, C)   :- parent(M, C), female(M).
son(S, P)      :- parent(P, S), male(S).
daughter(D, P) :- parent(P, D), female(D).

% two people who share a child
co_parents(X, Y) :- parent(X, C), parent(Y, C), X @< Y.

% --------------------------------------------------------- recursive rules

% generations(A, D, N): A is N generations above D
% the base case is a parent (one generation); the recursive case steps down
% one parent and adds one to the count found below it
generations(A, D, 1) :- parent(A, D).
generations(A, D, N) :- parent(A, X), generations(X, D, N0), N is N0 + 1.

% grandparent is the recursive rule fixed at two generations
grandparent(G, C)        :- generations(G, C, 2).
grandfather(G, C)        :- grandparent(G, C), male(G).
grandmother(G, C)        :- grandparent(G, C), female(G).
grandchild(C, G)         :- grandparent(G, C).
great_grandparent(G, C)  :- generations(G, C, 3).

% ancestor(A, D): A is a parent of D, or a parent of an ancestor of D
ancestor(A, D) :- parent(A, D).
ancestor(A, D) :- parent(A, X), ancestor(X, D).

descendant(D, A) :- ancestor(A, D).

% ---------------------------------------------------------- sibling rules

% siblings share at least one parent; X \== Y stops a person matching
% themselves through their own parent
sibling(X, Y) :- parent(P, X), parent(P, Y), X \== Y.

% full siblings share two different parents
full_sibling(X, Y) :-
    parent(P1, X), parent(P1, Y),
    parent(P2, X), parent(P2, Y),
    P1 @< P2, X \== Y.

% half siblings share exactly one parent
half_sibling(X, Y) :- sibling(X, Y), \+ full_sibling(X, Y).

brother(B, X) :- sibling(B, X), male(B).
sister(S, X)  :- sibling(S, X), female(S).

% ---------------------------------------------------- extended family rules

aunt_or_uncle(A, C)  :- parent(P, C), sibling(A, P).
aunt(A, C)           :- aunt_or_uncle(A, C), female(A).
uncle(U, C)          :- aunt_or_uncle(U, C), male(U).
niece_or_nephew(N, A) :- aunt_or_uncle(A, N).

% cousins have parents who are siblings; the last check keeps a person's
% own siblings out of the answer even in a tree where two families are
% related more than one way
cousin(X, Y) :-
    parent(PX, X), parent(PY, Y),
    sibling(PX, PY),
    X \== Y, \+ sibling(X, Y).

% second cousins have parents who are first cousins
second_cousin(X, Y) :-
    parent(PX, X), parent(PY, Y),
    cousin(PX, PY),
    X \== Y.

% a grandparent's sibling
great_aunt_or_uncle(A, C) :- grandparent(G, C), sibling(A, G).

% the child of a cousin, seen from either side
cousin_once_removed(X, Y) :- parent(P, Y), cousin(X, P).
cousin_once_removed(X, Y) :- parent(P, X), cousin(P, Y).

% partners are people who share a child
partner(X, Y) :- co_parents(X, Y).
partner(X, Y) :- co_parents(Y, X).

% in-laws through a partner
parent_in_law(X, Y) :- partner(Y, P), parent(X, P), \+ parent(X, Y).
child_in_law(X, Y)  :- parent_in_law(Y, X).

% --------------------------------------------------------- query helpers

% each helper collects every answer with findall and sorts the list, which
% removes the duplicates a rule produces when it succeeds more than once
% (siblings, for instance, are found once through each shared parent)

children_of(P, Cs)       :- findall(C, child(C, P), L), sort(L, Cs).
parents_of(C, Ps)        :- findall(P, parent(P, C), L), sort(L, Ps).
partners_of(X, Ps)       :- findall(Y, partner(X, Y), L), sort(L, Ps).
siblings_of(X, Ss)       :- findall(S, sibling(S, X), L), sort(L, Ss).
cousins_of(X, Cs)        :- findall(C, cousin(C, X), L), sort(L, Cs).
aunts_of(X, As)          :- findall(A, aunt(A, X), L), sort(L, As).
uncles_of(X, Us)         :- findall(U, uncle(U, X), L), sort(L, Us).
grandchildren_of(G, Cs)  :- findall(C, grandchild(C, G), L), sort(L, Cs).
grandparents_of(C, Gs)   :- findall(G, grandparent(G, C), L), sort(L, Gs).
descendants_of(A, Ds)    :- findall(D, descendant(D, A), L), sort(L, Ds).
ancestors_of(D, As)      :- findall(A, ancestor(A, D), L), sort(L, As).

% is_cousin(X, Y) succeeds once, without the repeated answers cousin/2
% gives when both parents link the two people
is_cousin(X, Y) :- once(cousin(X, Y)).

known_person(X) :- atom(X), person(X).

% generation_of(X, N): one more than the parent furthest down the tree; a
% person with no recorded parents takes the generation of a partner who has
% them, and otherwise counts as generation 1
generation_of(X, N) :-
    parent(_, X), !,
    findall(G, (parent(P, X), generation_of(P, G)), Gs),
    max_list(Gs, Top),
    N is Top + 1.
generation_of(X, N) :-
    partner(X, P), parent(_, P), !,
    generation_of(P, N).
generation_of(_, 1).

% relationship(X, Y, R): R names what X is to Y, checking the closest
% relationships first; the cut keeps only the first name that applies
relationship(X, X, self) :- !.
relationship(X, Y, R) :- relation_rule(X, Y, R), !.
relationship(X, Y, related) :- ancestor(A, X), ancestor(A, Y), !.
relationship(_, _, not_related).

relation_rule(X, Y, father)              :- father(X, Y).
relation_rule(X, Y, mother)              :- mother(X, Y).
relation_rule(X, Y, son)                 :- son(X, Y).
relation_rule(X, Y, daughter)            :- daughter(X, Y).
relation_rule(X, Y, partner)             :- partner(X, Y).
relation_rule(X, Y, half_brother)        :- half_sibling(X, Y), male(X).
relation_rule(X, Y, half_sister)         :- half_sibling(X, Y), female(X).
relation_rule(X, Y, brother)             :- brother(X, Y).
relation_rule(X, Y, sister)              :- sister(X, Y).
relation_rule(X, Y, grandfather)         :- grandfather(X, Y).
relation_rule(X, Y, grandmother)         :- grandmother(X, Y).
relation_rule(X, Y, grandson)            :- grandchild(X, Y), male(X).
relation_rule(X, Y, granddaughter)       :- grandchild(X, Y), female(X).
relation_rule(X, Y, uncle)               :- uncle(X, Y).
relation_rule(X, Y, aunt)                :- aunt(X, Y).
relation_rule(X, Y, nephew)              :- niece_or_nephew(X, Y), male(X).
relation_rule(X, Y, niece)               :- niece_or_nephew(X, Y), female(X).
relation_rule(X, Y, cousin)              :- cousin(X, Y).
relation_rule(X, Y, great_grandfather)   :- great_grandparent(X, Y), male(X).
relation_rule(X, Y, great_grandmother)   :- great_grandparent(X, Y), female(X).
relation_rule(X, Y, great_grandson)      :- great_grandparent(Y, X), male(X).
relation_rule(X, Y, great_granddaughter) :- great_grandparent(Y, X), female(X).
relation_rule(X, Y, great_uncle)         :- great_aunt_or_uncle(X, Y), male(X).
relation_rule(X, Y, great_aunt)          :- great_aunt_or_uncle(X, Y), female(X).
relation_rule(X, Y, great_nephew)        :- great_aunt_or_uncle(Y, X), male(X).
relation_rule(X, Y, great_niece)         :- great_aunt_or_uncle(Y, X), female(X).
relation_rule(X, Y, cousin_once_removed) :- cousin_once_removed(X, Y).
relation_rule(X, Y, second_cousin)       :- second_cousin(X, Y).
relation_rule(X, Y, father_in_law)       :- parent_in_law(X, Y), male(X).
relation_rule(X, Y, mother_in_law)       :- parent_in_law(X, Y), female(X).
relation_rule(X, Y, son_in_law)          :- child_in_law(X, Y), male(X).
relation_rule(X, Y, daughter_in_law)     :- child_in_law(X, Y), female(X).
relation_rule(X, Y, ancestor)            :- ancestor(X, Y).
relation_rule(X, Y, descendant)          :- descendant(X, Y).

% ------------------------------------------------------------ tree printing

% print_tree(P) prints P and every descendant, one generation per level of
% indentation, recursing into each child's own children; a person's partners
% (the other parents of their children) follow their name
print_tree(Root) :-
    partner_text(Root, With),
    format("~w~s~n", [Root, With]),
    children_of(Root, Kids),
    print_children(Kids, "").

print_children([], _).
print_children([K | Ks], Indent) :-
    ( Ks == [] -> Branch = "`-- ", Next = "    " ; Branch = "|-- ", Next = "|   " ),
    partner_text(K, With),
    format("~s~s~w~s~n", [Indent, Branch, K, With]),
    string_concat(Indent, Next, Deeper),
    children_of(K, Grandkids),
    print_children(Grandkids, Deeper),
    print_children(Ks, Indent).

partner_text(X, Text) :-
    partners_of(X, Ps),
    (   Ps == []
    ->  Text = ""
    ;   atomic_list_concat(Ps, ', ', Names),
        format(string(Text), " + ~w", [Names])
    ).
