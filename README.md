# OOΠ
## Perotti Samuele, <s.perotti4@campus.unimib.it>

Questo programma Prolog è un'estensione per implementare il paradigma
orientato agli oggetti. Consente la creazione di classi, istanze,
campi e metodi, supportando l'ereditarietà.

## Spiegazioni sul Funzionamento
 - Quando si va a definire una classe con **def\_class**, quest'ultima
 viene asserita nella base dati prolog nella forma
 ***classe(class-name, [parents], [parts])***, dove parts è un insieme
 di definizioni di metodi e campi.\
**def_class** inoltre trova, se presenti, i metodi all'interno di
parts e li asserisce nella base dati effettuando i seguenti passaggi:

	- Prima sostituisce "this" con "Instance"
	- Poi viene creato un Term del tipo ***Method_name(Instance, arg\*) :-  
	is_instance(Instance, \<class-name>), Body, !.***
	- Infine viene effettuato un ***asserta*** di questo termine
	per inserirlo in cima nella base dati prolog

	Ho scelto di asserire i metodi in questa maniera durante
	l'esecuzione del predicato **def_class**, e non durante
	l'esecuzione del predicato **make**, così da non dover
	asserire tutti i metodi della classe e delle superclassi ogni
	volta che viene creata un'istanza. In questa maniera i metodi
	vengono definiti e creati direttamente da **def_class** e
	gestiscono loro l'ereditarietà in base all'Instance passata
	come argomento.


 - Quando si va a creare un'istanza con **make**, viene creata
 un'istanza nella forma ***istanza(instance-name, class, fields)***,
 dove in fields sono presenti ***SOLAMENTE*** le assegnazioni fatte
 durante l'esecuzione di make. Se a dei campi non sono stati assegnati
 dei valori durante la creazione dell'istanza, e quindi sono tenuti i
 valori di default assegnati durante la definizione della classe,
 questi ultimi verranno recuperati direttamente dalla classe (o
 superclassi) durante l'esecuzione dei predicati field e fieldx.\
 Ho scelto di fare cosi per evitare ridondanza nei dati.

## Note Importanti

- Dato che non ero molto sicuro su quale opzione preferiste,
 ho deciso di implementare ***ENTRAMBE*** 
le metodologie per passare un'istanza ad una
primitiva. Ovvero, sia per nome che per termine; Dunque le chiamate:
	
	***?- field(p, name, R).***

	***?- inst(p, X), field(X, name, R).***

	Sono **EQUIVALENTI**; Esattamente come:

	***?- talk(p).***

	***?- inst(p, X), talk(X).***

	Il passaggio per **Termine** (ovvero anteponendo *inst/2*) resta
	comunque ***preferibile***.
- Usare ***undefined*** se si vuole definire un campo all'interno di
defclass e non si vuole associargli un valore di default:\
***def_class(person, [], [field(name, undefined, string)])***

- Se si esegue una ***make*** con il nome di un'istanza già presente nella 
base di dati, la precedente istanza viene ***eliminata*** per fare spazio a 
quella nuova.
Questo si traduce in un'esperienza più ***fluida*** per l'utente nell'utilizzo
dell'estensione OOΠ.\
	Nel caso in cui l'istanza eliminata rappresentasse il valore di
	qualcosa, come ad esempio un *campo* in ***def_class*** o di un'altra
	***istanza***, non sussiste alcun problema
	se l'assegnamento era stato fatto per Termine (anteponendo inst/2);
	Infatti, se si accede a questa istanza, il valore sarà quello
	precedente, in quanto passando per Termine, ne è stata salvata una
	copia (come un passaggio per ***VALORE***).\
Al contrario, se ***NON*** si è anteposto *inst/2*, il valore dell'istanza
rifletterà l'assegnazione più recente, che può anche essere di una classe
differente, creando così possibili errori. Per questo motivo, il passaggio per
Termine è ***preferibile***, come indicato in precedenza.

## Struttura dei File

Il file Prolog `oop.pl` contiene predicati per definire classi, creare
 istanze, gestire campi ed eseguire metodi. Le funzionalità principali
 del sistema sono:

- **def_class/2 e def_class/3**: Definiscono la struttura di una
classe con campi e metodi opzionali.
- **make/2 e make/3**: Creano istanze di classi con assegnazioni ai
campi opzionali.
- **is_class/1**: Verifica se l' oggetto passato è una classe 
- **is_instance/1 e is_instance/2**: Verificano se un oggetto è
un'istanza di una classe o sottoclasse.
- **inst/2**: Recupera un'istanza dato il nome con cui è stata creata
- **field/3 e fieldx/3**: Accedono al valore di un campo in un'istanza
o attraversano una catena di attributi.

## Primitive Implementate

- ### def_class
	Definisce la struttura di una classe e la memorizza nella
	“base di conoscenza” di Prolog.	
La sua sintassi è:\
***def_class ’(’ \<class-name> ’,’ \<parents> ’)’***\
***def_class ’(’ \<class-name> ’,’ \<parents> ’,’ \<parts> ’)’***\
dove \<class-name> è un atomo (simbolo) e \<parents> è una lista
(possibilmente vuota) di atomi (simboli), e \<parts> è una lista di
metodi e campi.

- ### make
	Crea una nuova istanza di una classe. La sintassi è:\
***make ’(’ \<instance-name> ’,’\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\<class-name> ’,’\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;’[’ [ \<field-name> ’=’ \<value>\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
[ ’,’ \<field-name> ’=’ \<value> ]\* ]\*\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;’]’\
’)’***\
dove \<class-name> e \<field-name> sono simboli, mentre \<value> è un
	qualunque termine Prolog.

- ### is_class
	Ha successo se l’atomo passatogli è il nome di una classe. La
	sintassi è:\
***is_class ’(’ \<class-name> ’)’***
dove \<class-name> è un simbolo

- ### is_instance
	Ha successo se l’oggetto passatogli è l’istanza di una classe.
	La sintassi è:\
***is_instance ’(’ \<value> ’)’***\
***is_instance ’(’ \<value> ’,’ \<class-name> ’)’***
dove \<class-name> è un simbolo e \<value> è un valore qualunque.
is_instance/1 ha successo se
\<value> è un’istanza qualunque; is_instance/2 ha successo se \<value>
	è un’istanza di una classe che ha \<class-name> come superclasse.

- ### inst
	Recupera un’istanza dato il nome con cui è stata creata da make.\
***inst ’(’ \<instance-name> ’,’ \<instance> ’)’***
dove \<instance-name> è un simbolo e \<instance> è un termine che
	rappresenta un’istanza (o, ovviamente, una variabile logica).

- ### field
	Estrae il valore di un campo da una classe. La sintassi è:\
***field ’(’ \<instance> ’,’ \<field-name> ’,’ \<result> ’)’***
dove \<instance> è un’istanza di una classe (nel caso più semplice un
	simbolo) e \<field-name> è un
simbolo. Il valore recuperato viene unificato con \<result> ed è il
	valore associato a \<field-name>
nell’istanza (tale valore potrebbe anche essere ereditato dalla classe
	o da uno dei suoi antenati).

- ### fieldx
	Estrae il valore da una classe percorrendo una catena di
	attributi. La sintassi è:\
***fieldx ’(’ \<instance> ’,’ \<field-names> ’,’ \<result> ’)’***
dove \<instance> è un’istanza di una classe (nel caso più semplice un
	simbolo) e \<field-namea> è
una lista non vuota di simboli, che rappresentano attributi nei vari
	oggetti recuperati. Il valore recuperato viene unificato con
	\<result> ed è il valore associato all’ultimo elemento di \<field-names>
nell’ultima istanza (tale valore potrebbe anche essere ereditato dalla
	classe o da uno dei suoi antenati). 



## Esempi PDF & Test

?- def_class(person, [], [field(name, 'Eve'), field(age, 21, integer)]).\
**true**.

?- def_class(student, [person], [field(name, 'Eva Lu Ator'),
field(university, 'Berkeley'), method(talk, [], (write('My name is '),
field(this, name, N), writeln(N), write('My age is '), field(this,
age, A), writeln(A)))]).\
**true**.

?- make(eve, person).\
**true**.

?- make(adam, person, [name = 'Adam']).\
**true**.

?- make(s1, student, [name = 'Eduardo De Filippo', age = 108]).\
**true**.

?- make(s2, student).\
**true**

?- make(s3, student, [name = 'Harry Potter', age = "12"]).\
**false**

?- field(eve, age, A).\
**A = 21**.

***OR***

?- inst(eve, X), field(X, age, A).\
***X = istanza(eve, person, []),\
A = 21.***

?- field(s1, age, A).\
**A = 108.**

?- field(s2, name, N).\
**N = 'Eva Lu Ator'**.

?- field(eve, address, Address).\
**false**.

?- talk(s1).\
**My name is Eduardo De Filippo\
My age is 108**.

***OR***

?- inst(s1, X), talk(X).\
***My name is Eduardo De Filippo\
My age is 108\
X = istanza(s1, student, [name='Eduardo De Filippo', age=108]).***

?- talk(eve).\
**false.**

?- def_class(studente_bicocca, [student], 
[method(talk, [], (write('Mi chiamo '), field(this, name, N), 
writeln(N), writeln('e studio alla Bicocca.'))), 
method(to_string, [ResultingString], 
(with_output_to(string(ResultingString), (field(this, name, N), 
field(this, university, U), format('#<~w Student ~w>', [U, N]))))), 
field(university, 'UNIMIB')]).\
**true.**

?- make(ernesto, studente_bicocca, [name = 'Ernesto']).\
**true.**

?- talk(ernesto).\
**Mi chiamo Ernesto\
e studio alla Bicocca**.

?- to_string(ernesto, S).\
**S = "\#\<UNIMIB Student Ernesto>".**

?- def_class(other, [], [field(user, undefined, student), method(talk, [],
(fieldx(this, [user, university], U), write('Universita: '), write(U)))]).\
***true.***

?- inst(s1, Student), make(o, other, [user = Student]).\
***Student = istanza(s1, student, [name='Eduardo De Filippo', age=108]).***

?- inst(o, O), talk(O).\
***Universita: Berkeley\
O = istanza(o, other, [user=istanza(s1, student, [name='Eduardo De Filippo',
age=108])]).***

?- make(s1, classe_distaccata_da_student).\
***true.***

?- inst(o, O), talk(O).\
***Universita: Berkeley***\
% Restituisce "university" dell'istanza\
% ***INIZIALMENTE*** passata\
% perché salvata nell'istanza "o"

?- def_class(using_integers, [], [field(x, 41, integer)]).\
***true.***

?- def_class(using_reals, [using_integers], [field(x, 42.0, float)]).\
***Error: float is not of a subtype of integer\
false.***

?- def_class(a, [], [field(numero, 8, integer)]).\
***true.***

?- def_class(b, [a], [field(numero, 9)]).\
***true.***

?- def_class(c, [b], [field(numero, "Ciao", string)]).\
***Error: string is not a subtype of integer\
false.***

## Credits

- Perotti Samuele, <s.perotti4@campus.unimib.it>
- UNIMIB, Programming Languages Course
