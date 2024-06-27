%%%% -*- Mode: Prolog -*-
%%%% Perotti Samuele 899817


%%%% Definizione predicati dinamici
:- dynamic istanza/3.
:- dynamic classe/3.


%%%% def_class/2: Definisce la struttura di una classe e la memorizza nella.
%%%% base di conoscenza di prolog.
def_class(Class, Parents) :-
    atom(Class),
    is_list(Parents),
    %%%% Controllo che Class non estenda se stessa
    \+ member(Class, Parents),
    %%%% Controllo se le classi da estendere esistono
    %%%% e sono effettivamente classi
    remove_duplicates(Parents, Parents_new),
    parental_control(Parents_new),
    Term =.. [classe, Class, Parents_new, []], !,
    assert_class(Term).


%%%% def_class/3: Definisce la struttura di una classe e la memorizza
%%%% nella base di conoscenza di Prolog. Questa ridefinizione accetta
%%%% come parametro anche i fields e methods (Parts).
def_class(Class, Parents, Parts) :-
    atom(Class),
    is_list(Parents),
    %%%% controllo che Class non estenda se stesso
    \+ member(Class, Parents),
    %%%% Controllo se le classi da estendere esistono
    %%%% e sono effettivamente classi
    remove_duplicates(Parents, Parents_new),
    parental_control(Parents_new),
    get_supclasses_from_list(Parents_new, Supclasses),
    append(Parents_new, Supclasses, Supclasses_new),
    manipulate_part(Parts, Class, Supclasses_new, NewParts),
    Term =.. [classe, Class, Parents_new, NewParts], !,
    assert_class(Term).


%%%% make/2: Crea una nuova istanza di una classe.
make(InstanceName, Class) :-
    make(InstanceName, Class, []), !.


%%%% make/3: <instance-name> è un simbolo o una variabile istanziata
%%%% con un simbolo allora lo si associa, nella base dati,
%%%% al termine che rappresenta la nuova istanza.
make(InstanceName, Class, Fields) :-
    atom(InstanceName), !,
    is_class(Class),
    get_supclasses(Class, Supclasses),
    append([Class], Supclasses, AllClasses),
    check_fields(Fields, AllClasses),
    Term =.. [istanza, InstanceName, Class, Fields],
    retractall(istanza(InstanceName, _, _)),
    assert(Term).


%%%% make/3: <instance-name> è una variabile non istanziata allora questa
%%%% viene unificata con il termine che rappresenta la nuova istanza.
make(InstanceName, Class, Fields) :-
    var(InstanceName),
    %%%% Se nella base dati esistono istanze, InstanceName viene
    %%%% unificata con quelle istanze che hanno classe=Class e fields=Fields
    call(istanza(_, Class, Fields)), !,
    is_class(Class),
    get_supclasses(Class, Supclasses),
    append([Class], Supclasses, AllClasses),
    check_fields(Fields, AllClasses),
    call(istanza(InstanceName, Class, Fields)).


%%%% make/3: <instance-name> deve essere un termine che unifica
%%%% con la nuova istanza appena creata.
%%%% Ha successo solo se il primo argomento funziona.
make(InstanceName, Class, Fields) :-
    %%%% InstanceName unifica con un'istanza "fittizzia" senza nome
    %%%% che ha classe=Class e fields=Fields
    InstanceName =.. [istanza, _, Class, Fields],
    is_class(Class),
    get_supclasses(Class, Supclasses),
    append([Class], Supclasses, AllClasses),
    check_fields(Fields, AllClasses),
    write('Note: You can pass this anonymous instance as a field value').


%%%% field/3: Estrae il valore di un campo da una classe
field(InstanceName, FieldName, Result) :-
    atom(InstanceName), !,
    inst(InstanceName, Instance),
    Instance =.. [istanza, InstanceName, Class, Fields],
    search_in_instance(FieldName, Fields, Class, Result).
field(istanza(InstanceName, Class, Fields), FieldName, Result) :-
    var(InstanceName), !,
    search_in_instance(FieldName, Fields, Class, Result).
field(istanza(_, Class, Fields), FieldName, Result) :-
    search_in_instance(FieldName, Fields, Class, Result), !.
field(Term, FieldName, Result) :-
    Term =.. [inst, InstanceName, _], !,
    field(InstanceName, FieldName, Result).


%%%% fieldx/3: Estrae il valore da una classe
%%%% percorrendo una catena di attributi
fieldx(istanza(InstanceName, Class, Fields), [Field_name | Rest], Result) :-
    field(istanza(InstanceName, Class, Fields), Field_name, Y),
    length(Rest, L),
    L > 0, !,
    inst(Y, Instance), !,
    fieldx(Instance, Rest, Result).
fieldx(InstanceName, Field_names, Result) :-
    atom(InstanceName), !,
    inst(InstanceName, Instance),
    fieldx(Instance, Field_names, Result).
fieldx(istanza(InstanceName, Class, Fields), [Field | _] , Result):-
    field(istanza(InstanceName, Class, Fields), Field, Result), !.
fieldx(InstanceName, [Field | _], Result) :-
    atom(InstanceName), !,
    inst(InstanceName, Instance),
    field(Instance, Field, Result).
fieldx(Term, Field_names, Result) :-
    Term =.. [inst, InstanceName, _], !,
    fieldx(InstanceName, Field_names, Result).


%%%% is_instance/1: Ha successo se l'oggetto passatogli è un'istanza
%%%% di una classe qualunque.
is_instance(InstanceName) :-
    atom(InstanceName), !,
    write('Do not use the instance reference!'),
    fail.

is_instance(InstanceTerm) :-
    callable(InstanceTerm),
    InstanceTerm =.. [istanza, _, _, _],
    call(InstanceTerm).


%%%% is_instance/2: Ha successo se l'oggetto passatogli è un'istanza
%%%% di una classe che ha SupClass come superclasse
is_instance(InstanceName, Class) :-
    atom(InstanceName), !,
    inst(InstanceName, Instance),
    is_instance(Instance, Class).

is_instance(InstanceTerm, Class) :-
    get_class(InstanceTerm, Class), !.

is_instance(InstanceTerm, Class) :-
    is_class(Class),
    get_class(InstanceTerm, HisClass),
    get_supclasses(HisClass, SupClasses),
    member(Class, SupClasses), !.

is_instance(_, SupClass) :-
    \+ is_class(SupClass),
    write('Error: '),
    write(SupClass),
    writeln(' is not a Class!'),
    fail, !.
is_instance(InstanceName, _) :-
    \+ is_instance(InstanceName),
    write('Error: '),
    write(InstanceName),
    writeln(' is not an asserted Instance!'),
    fail, !.


%%%% inst/2: recupera un'istanza dato il nome con cui è stata creata da make
inst(InstanceName, Instance) :-
    call(istanza(InstanceName, Class, Fields)), !,
    Instance = istanza(InstanceName, Class, Fields).
inst(Instance, Instance) :-
    callable(Instance),
    _ =.. [istanza, _, _, _].


%%%% manipulate_part/2: Visita Part, se trova un field chiama
%%%% check_field_subtype, se trova un method chiama create_method.
manipulate_part([], _, _, []).
manipulate_part([Part | RestParts], Class, Supclasses, [NewPart | NPRest]) :-
    functor(Part, field, _), !,
    %%%% Prima controllo che il valore sia del tipo definito
    check_defclass_field_type(Part),
    %%%% Controllo che il tipo definito sia subtype del campo nelle superclassi
    check_field_subtype(Part, Supclasses, NewPart),
    manipulate_part(RestParts, Class, Supclasses, NPRest).
manipulate_part([Part | RestParts], Class, Supclasses, [Part | NPRest]) :-
    functor(Part, method, _), !,
    create_method(Class, Part),
    manipulate_part(RestParts, Class, Supclasses, NPRest).


%%%% check_defclass_field_type/1: Controllo che il value sia del tipo definito
check_defclass_field_type(Field) :-
    functor(Field, field, _),
    arg(2, Field, Term),
    functor(Term, make, _), !,
    write('Error: Use previously created instances!'),
    fail.

check_defclass_field_type(Field) :-
    functor(Field, field, 2), !.

check_defclass_field_type(Field) :-
    functor(Field, field, 3),
    arg(2, Field, Value),
    arg(3, Field, Type),
    Value \= undefined,
    Type \= undefined, !,
    is_this_the_type(Value, Type).

check_defclass_field_type(Field) :-
    functor(Field, field, 3),
    arg(2, Field, undefined), !.

check_defclass_field_type(Field) :-
    functor(Field, field, 3),
    arg(3, Field, undefined), !.


%%%% check_field_subtype/2: Controlla che il tipo del field passato
%%%% sia un subtype del campo omonimo definito nella prima supclasses che lo ha
check_field_subtype(P, [], P) :- !.

%%%% caso in cui arity è 2 per entrambi i campi (nuovo ed ereditato),
%%%% value puo' essere di qualsiasi tipo
check_field_subtype(Field, Supclasses, Field) :-
    functor(Field, _, Arity),
    arg(1, Field, Field_name),
    search_value_in_supclasses(Supclasses, Field_name, ResultField),
    functor(ResultField, _, Arity),
    Arity = 2, !.

%%%% caso in cui arity è 3 per entrambi, il tipo del field della sottoclasse
%%%% deve essere un subtype di quello ereditato
check_field_subtype(Field, Supclasses, Field) :-
    functor(Field, _, Arity),
    arg(1, Field, Field_name),
    search_value_in_supclasses(Supclasses, Field_name, ResultField),
    functor(ResultField, _, Arity),
    Arity = 3,
    arg(3, Field, Type1),
    arg(3, ResultField, Type2),
    subtypep(Type1, Type2), !.

%%%% caso in cui arity del nuovo field è 2, allora controllo che value sia
%%%% del tipo della superclasse da cui viene ereditato field
check_field_subtype(Field, Supclasses, Field2) :-
    functor(Field, _, Arity1),
    arg(1, Field, Field_name),
    search_value_in_supclasses(Supclasses, Field_name, ResultField),
    functor(ResultField, _, Arity2),
    Arity1 \= Arity2,
    Arity1 = 2,
    arg(2, Field, Field_value),
    arg(3, ResultField, Supertype),
    is_this_the_type(Field_value, Supertype), !,
    Field2 =.. [field, Field_name, Field_value, Supertype].

%%%% caso in cui il nuovo field ha arità 3 e il field della superclasse ha
%%%% arità 2. Vuol dire che passa da undefined a defined. Ok.
check_field_subtype(Field, Supclasses, Field) :-
    functor(Field, _, Arity1),
    arg(1, Field, Field_name),
    search_value_in_supclasses(Supclasses, Field_name, ResultField),
    functor(ResultField, _, Arity2),
    Arity1 \= Arity2,
    Arity1 = 3, !.

%%%% caso in cui non esiste il nuovo field nelle superclassi. Dà success.
check_field_subtype(Field, Supclasses, Field) :-
    arg(1, Field, Field_name),
    \+ search_value_in_supclasses(Supclasses, Field_name, _).


%%%% Ridefinizione is_this_the_type/2 per gestire casi in cui Type è una Classe
is_this_the_type(Value, Type) :-
    is_class(Type),
    is_instance(Value), !,
    get_class(Value, HisClass),
    get_supclasses(HisClass, SupClasses),
    append([HisClass], SupClasses, AllClasses),
    member(Type, AllClasses), !.

is_this_the_type(Value, Type) :-
    is_class(Type),
    \+ is_instance(Value), !,
    write('Error: '),
    write(Value),
    write(' is not an instance!'),
    fail.

%%%% is_this_the_type/2: Vero se value è del tipo Type
is_this_the_type(Value, Type) :-
    is_of_type(Type, Value), !.

is_this_the_type(Value, Type) :-
    write('Error: '),
    write(Value),
    write(' is not of type '),
    writeln(Type), fail.


%%%% subtypep/2: Vero se il primo argomento è uguale o è un sottotipo
%%%% del secondo argomento.
subtypep(Type, Type) :- !.
subtypep(Type1, Type2) :-
    Type1 = integer,
    Type2 = number, !.
subtypep(Type1, Type2) :-
    Type1 = float,
    Type2 = number, !.
subtypep(Type1, Type2) :-
    Type1 = integer,
    Type2 = float, !.
subtypep(Type1, Type2) :-
    get_supclasses(Type1, Classes),
    member(Type2, Classes), !.
subtypep(Type1, Type2) :-
    write('Error: '),
    write(Type1),
    write(' is not a subtype of '),
    writeln(Type2), fail.


%%%% create_method/2: Crea e asserisce i due predicati che gestiranno
%%%% le chiamate del metodo 'Method_name'.
%%%% Il primo predicato asserito è il metodo verio e proprio, il secondo serve
%%%% per cercare all interno della classe di instance e le sue superclassi
%%%% (in ordine di ereditarietà) la classe che ha definito il metodo così
%%%% da poterlo eseguire.
create_method(Class, Method) :-
    arg(1, Method, Method_name),
    arg(2, Method, Arguments_list),
    arg(3, Method, Body),
    length(Arguments_list, 0), !,
    term_to_atom(Body, BodyAtom),
    string_to_atom(BodyString, BodyAtom),
    replace_word_in_string("this", "Instance", BodyString, BodyNewString),
    string_to_atom(BodyNewString, BodyNewAtom),
    atomic_list_concat([Method_name, '(Instance) :-',
			'is_instance(Instance, ', Class, '), !,',
			BodyNewAtom, '.'], Method_string_1),
    term_to_atom(MethodTerm1, Method_string_1),
    asserta(MethodTerm1).


%%%% Ridefinizione di create_method/2 per gestire e creare
%%%% metodi che richiedono argomenti
create_method(Class, Method) :-
    arg(1, Method, Method_name),
    arg(2, Method, Arguments_list),
    arg(3, Method, Body),
    atomic_list_concat(['Instance', ', '], Method_head_1),
    concatenate_with_commas(Arguments_list, Method_head_1, Method_head_2),
    term_to_atom(Body, BodyAtom),
    string_to_atom(BodyString, BodyAtom),
    replace_word_in_string("this", "Instance", BodyString, BodyNewString),
    string_to_atom(BodyNewString, BodyNewAtom),
    atomic_list_concat([Method_name, '(', Method_head_2,
			') :- ',
			'is_instance(Instance, ', Class, '), !,',
			BodyNewAtom, '.'],
		       Method_string_1),
    term_to_atom(MethodTerm1, Method_string_1),
    assertz(MethodTerm1).


%%%% get_class/2: Data un istanza restituisce il nome della sua classe
get_class(InstanceName, Class) :-
    atom(InstanceName), !,
    inst(InstanceName, InstanceTerm),
    get_class(InstanceTerm, Class).
get_class(InstanceTerm, Class) :-
    InstanceTerm =.. [istanza, _, HisClass, _],
    Class = HisClass.


%%%% check_fields/2: Controlla che i campi a cui sono stati assegnati valori
%%%% in Fields durante la make esistano e che siano del tipo corretto
check_fields([], _) :- !.
check_fields([FieldName = _ | RestFields], AllClasses) :-
    search_value_in_supclasses(AllClasses, FieldName, ResultField),
    functor(ResultField, _, Arity),
    Arity = 2, !,
    check_fields(RestFields, AllClasses).
check_fields([FieldName = Value | RestFields], AllClasses) :-
    search_value_in_supclasses(AllClasses, FieldName, ResultField),
    functor(ResultField, _, Arity),
    Arity = 3,
    arg(3, ResultField, Type),
    is_this_the_type(Value, Type),
    check_fields(RestFields, AllClasses).


%%%% search_in_instance/4: Unifica con Result il valore del campo (che ha
%%%% Field_name come nome) assegnato durante la creazione di un'istanza da make
search_in_instance(FieldName, [], Class, Result) :-
    get_supclasses(Class, SupClassi),
    append([Class], SupClassi, SupClassiDup),
    remove_duplicates(SupClassiDup, SupClassiClean),
    \+ length(SupClassiClean, 0), !,
    search_value_in_supclasses(SupClassiClean, FieldName, ResultField),
    arg(2, ResultField, Result).
search_in_instance(FieldName, [FieldName = Value | _], _, Result) :-
    Value = Result, !.
search_in_instance(FieldName, [_ = _ | Rest_fields], Class, Result) :-
    search_in_instance(FieldName, Rest_fields, Class, Result).


%%%% search_value_in_supclasses/3: Cerca il valore assegnato a FieldName,
%%%% chiamando search_in_class per ogni classe nella lista
search_value_in_supclasses([], _, _) :- !, fail.
search_value_in_supclasses([Class | _], FieldName, ResultField) :-
    search_in_class(FieldName, ResultField, Class), !.
search_value_in_supclasses([_ | Rest], FieldName, ResultField) :-
    search_value_in_supclasses(Rest, FieldName, ResultField), !.


%%%% search_in_class/3: Cerca e restituisce se presente il valore assegnato
%%%% a FieldName nella classe Class
search_in_class(FieldName, ResultField, Class) :-
    classe(Class, _, Parts),
    search_in_parts(Parts, FieldName, ResultField).


%%%% search_in_parts/3: Effettiva ricerca richiesta da search_in_class.
%%%% Cerca in Parts il campo Nome_campo e unifica Result con il suo value
search_in_parts([Field | _], Nome_campo, ResultField) :-
    functor(Field, field, _),
    arg(1, Field, Field_name),
    Field_name = Nome_campo, !,
    ResultField = Field.
search_in_parts([_ | Rest], Nome_campo, ResultField) :-
    search_in_parts(Rest, Nome_campo, ResultField).


%%%% assert_class/2: Controlla se la classe che si vuole definire non sia
%%%% già definita nella base di conoscenza di prolog, se lo è,
%%%% stampa un messaggio di errore, altrimenti la asserisce.
assert_class(Term) :-
    Term =.. [classe, Class_name, _, _],
    is_class(Class_name), !,
    write('Error: Class '),
    write(Class_name),
    writeln(' is already defined!'),
    fail.
assert_class(Term) :-
    assert(Term).


%%%% get_supclasses/2: Unifica con il secondo argomento una lista contenente
%%%% TUTTE le superclassi della classe passata al predicato.
%%%% La lista contiene le superclassi secondo una visita in PROFONDITA'
%%%% del grafo delle gerarchie.
get_supclasses(Class, Supclassi) :-
    call(classe(Class, Parents, _)),
    get_supclasses_from_list(Parents, Supclassi).


%%%% get_supclasses_from_list/2: Data una lista di classi restituisce
%%%% la lista contenente le loro superclassi, mantenendo l'ereditarietà
%%%% dato che visita il grafo dei parents in profondità come da consegna.
get_supclasses_from_list([], []) :- !.
get_supclasses_from_list(Parents, Supclasses) :-
    bagof(X, supclasses(Parents, X), Bag),
    remove_duplicates(Bag, Supclasses).


%%% supclasses/2: Metodo di appoggio per get_supclasses_from_list
supclasses([Class | _], Result) :-
    classe(Class, _, _),
    Result = Class.
supclasses([Class | Parents], Result) :-
    classe(Class, HisParents, _),
    append(HisParents, Parents, Parents_list),
    supclasses(Parents_list, Result).


%%%% parental_control/1: Controlla se le Classi passate sono definite
%%%% come classi nella base di conoscenza di Prolog,
%%%% altrimenti stampa un messaggio di errore.
parental_control([]).
parental_control([Class | Rest]) :-
    is_class(Class),
    parental_control(Rest).
parental_control([Not_class]) :-
    \+ is_class(Not_class),
    write('Error: Parent '),
    write(Not_class),
    writeln(' is not a class!'),
    fail.


%%%% is_class/1: Ha successo se l'atomo passatogli è il nome di una classe
%%%% presente nella base dati di Prolog.
is_class(Class) :-
    atom(Class),
    classe(Class, _, _).


%%%% remove_duplicates/2: Rimuove gli elementi duplicati presenti nella
%%%% lista nel primo argomento e restituisce una lista senza duplicati,
%%%% che mantiene l'ordine iniziale.
remove_duplicates([], []).
remove_duplicates([X | Xs], Out) :-
    member(X, Xs), !,
    remove_duplicates(Xs, Out).
remove_duplicates([X | Xs], [X | Out]) :-
    remove_duplicates(Xs, Out).


%%%% replace_word_in_string/4: Predicato per sostituire una parola con un'altra
%%%% all'interno di un atomo (usato per sostituire this con Instance)
replace_word_in_string(OldWord, NewWord, InputString, OutputString) :-
    atomic_list_concat(Split, OldWord, InputString),
    atomic_list_concat(Split, NewWord, OutputString),
    NewWord \= OldWord.


%%%% concatenate_with_commas/3: Restituisce gli elementi di una lista
%%%% concatenati tra loro e separati da virgola (Restituisce un atomo)
concatenate_with_commas([], Acc, Acc) :- !.
concatenate_with_commas([Item], Acc, Result) :-
    term_to_atom(Item, ItemAtom),
    atomic_list_concat([Acc, ItemAtom, ' '], Result), !.
concatenate_with_commas([First|Rest], Acc, Result) :-
    term_to_atom(First, FirstAtom),
    atomic_list_concat([Acc, FirstAtom, ', '], NewAcc),
    concatenate_with_commas(Rest, NewAcc, Result).
%%%% end of file --- oop.pl

