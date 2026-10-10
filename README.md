# Family Tree in Prolog

MSCS 632 Advanced Programming Languages. A four-generation family tree in
SWI-Prolog. The facts state only who is whose parent and who is male or
female; every other relationship is derived by rules, and the recursive rules
answer questions about indirect relationships such as all the descendants of
a person.

## Files

| File | What it holds |
|---|---|
| `family.pl` | the facts, the rules and the query helpers |
| `queries.pl` | runs the sample queries and prints them as the Prolog prompt would |
| `sample_queries.txt` | the saved output of `queries.pl`: every sample query with its expected answer |
| `tests.pl` | 41 unit tests (plunit), including a check that `queries.pl` still prints `sample_queries.txt` |
| `menu.pl` | a console menu for asking questions without writing queries |
| `web.pl` | a browser view served by SWI-Prolog's HTTP library |

## The family

Twenty-six people over four generations. Two founding couples (arthur and
margaret, walter and eleanor) have children who marry into each other's
families. Robert has a child with each of two partners, so his children are
half siblings. Some people married into the family and have no recorded
parents.

```
arthur + margaret                     walter + eleanor
|-- james + linda                     |-- linda + james
|   |-- daniel                        |   |-- daniel
|   `-- emily + thomas                |   `-- emily + thomas
|       |-- ava                       |       |-- ava
|       `-- noah                      |       `-- noah
|-- robert + diane, karen             `-- paul + rachel
|   |-- lucas                             |-- mia
|   `-- sophie                            `-- owen
`-- susan + george
    |-- henry
    `-- olivia + marcus
        `-- leo
```

## Rules

| Rule | Definition |
|---|---|
| `child/2`, `father/2`, `mother/2`, `son/2`, `daughter/2` | one `parent` fact plus a gender |
| `generations(A, D, N)` | recursive: A is N generations above D |
| `grandparent/2` | `generations(G, C, 2)`; `great_grandparent/2` is `generations(G, C, 3)` |
| `ancestor/2`, `descendant/2` | recursive: a parent, or a parent of an ancestor |
| `sibling/2` | shares a parent, and is not the same person |
| `full_sibling/2`, `half_sibling/2` | share two parents, or exactly one |
| `aunt/2`, `uncle/2`, `niece_or_nephew/2` | sibling of a parent |
| `cousin/2` | parents are siblings, and not siblings themselves |
| `second_cousin/2`, `cousin_once_removed/2`, `great_aunt_or_uncle/2` | built on `cousin` and `grandparent` |
| `partner/2`, `parent_in_law/2`, `child_in_law/2` | through a shared child |
| `relationship(X, Y, R)` | names what X is to Y, closest relationship first |
| `print_tree(P)` | recursive: prints P and every descendant as an indented tree |

The query helpers (`children_of/2`, `siblings_of/2`, `cousins_of/2`,
`descendants_of/2`, `ancestors_of/2` and others) collect every answer into a
sorted list. Sorting matters because a rule like `sibling/2` succeeds once for
each shared parent, so `sibling(S, emily)` answers `daniel` twice while
`siblings_of(emily, L)` gives `[daniel]`.

## Running

Install SWI-Prolog 9 or newer: `brew install swi-prolog` on macOS, the
installer from swi-prolog.org on Windows, or `sudo apt install swi-prolog`
on Ubuntu or WSL.

```bash
swipl family.pl                        # load the tree and ask your own queries
swipl queries.pl                       # print every sample query and its answers
swipl -g run_tests -t halt tests.pl    # run the tests
swipl menu.pl                          # console menu
swipl web.pl                           # browser view at http://localhost:8000
```

Some queries to try after `swipl family.pl`:

```prolog
?- children_of(james, Children).
Children = [daniel, emily].

?- siblings_of(sophie, Siblings).
Siblings = [lucas].

?- is_cousin(emily, mia).
true.

?- descendants_of(walter, Descendants).
Descendants = [ava, daniel, emily, linda, mia, noah, owen, paul].

?- relationship(robert, noah, R).
R = great_uncle.
```

`sample_queries.txt` has the full list with expected output.

## The browser view

`swipl web.pl` starts a small web server written in Prolog and opens the page.
The family is laid out by generation, with partners grouped together. Choose
a question and one or two people, or click a name, and the answer appears
along with the Prolog query that produced it; the people in the answer are
highlighted in the layout. Stop the server with Ctrl+C.
