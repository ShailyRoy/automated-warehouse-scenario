%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%    AUTOMATED WAREHOUSE PROJECT     %%%%%%%%%%%%%%
%%%%%%%%%%%%%        (Spring 2025)        %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#const n=50.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%    PARSING INPUT    %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parse nodes
nodeAt(NDI, pair(X,Y)) :- init(object(node,NDI), value(at,pair(X,Y))).
pair(X,Y) :- init(object(node,NDI), value(at,pair(X,Y))).
node(NDI) :- init(object(node,NDI), value(at,pair(X,Y))).

% Parse highways
highway(NDI) :- init(object(highway,NDI), value(at,pair(X,Y))).

% Parse picking stations
pickingStationAt(PSI,NDI) :- init(object(pickingStation,PSI), value(at,pair(X,Y))), init(object(node,NDI), value(at,pair(X,Y))).
pickingStation(PSI) :- init(object(pickingStation,PSI), value(at,pair(X,Y))), init(object(node,NDI), value(at,pair(X,Y))).

% Parse robots
robotAt(RI, object(node,ND), 0) :- init(object(robot,RI), value(at,pair(X,Y))), nodeAt(ND, pair(X,Y)).
robot(RI) :- init(object(robot,RI), value(at,pair(X,Y))).

% Parse shelves
shelfOn(SI, object(node,ND), 0) :- init(object(shelf,SI), value(at,pair(X,Y))), nodeAt(ND, pair(X,Y)).
shelf(SI) :- init(object(shelf,SI), value(at,pair(X,Y))).

% Parse products
productOn(PRI, object(shelf,SI), with(quantity,PQ), 0) :- init(object(product,PRI), value(on,pair(SI,PQ))).
product(PRI) :- init(object(product,PRI), value(on,pair(SI,PQ))).

% Parse orders
orderAt(OI, object(node,ND), contains(PRI,PQ), 0) :-
    init(object(order,OI), value(pickingStation,PKI)),
    pickingStationAt(PKI,ND),
    init(object(order,OI), value(line,pair(PRI,PQ))).
order(OI) :- init(object(order,OI), value(pickingStation,PKI)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%    WAREHOUSE COUNTS    %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate various warehouse statistics
numColumns(NC) :- NC = #count{ X : init(object(node,I), value(at,pair(X,Y))) }.
numRows(NR) :- NR = #count{ Y : init(object(node,I), value(at,pair(X,Y))) }.
numNodes(ND) :- ND = #count{ I : init(object(node,I), value(at,pair(X,Y))) }.
numShelves(ND) :- ND = #count{ I : init(object(shelf,I), value(at,pair(X,Y))) }.
numProducts(ND) :- ND = #count{ I : init(object(product,I), value(on,pair(SI,PQ))) }.
numPickingStation(ND) :- ND = #count{ I : init(object(pickingStation,I), value(at,pair(X,Y))) }.
numOrders(ND) :- ND = #count{ I : init(object(order,I), value(pickingStation,J)) }.
numRobots(ND) :- ND = #count{ I : init(object(robot,I), value(at,pair(X,Y))) }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%    GENERATING ACTIONS     %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

move(0,1; 0,-1; -1,0; 1,0).

{robotMove(R, move(DX,DY), T) : move(DX,DY)}1 :- R=1..NR, numRobots(NR), T=0..TN, TN=n-1.
{pickUpShelf(R,SI,T) : shelf(SI)}1 :- R=1..NR, numRobots(NR), T=0..TN, TN=n-1.
{putDownShelf(R,SI,T) : shelf(SI)}1 :- R=1..NR, numRobots(NR), T=0..TN, TN=n-1.
{deliver(R,OI,with(SI,PR,DQ),T) :
    orderAt(OI,object(node,ND),contains(PR,OQ),T),
    productOn(PR,object(shelf,SI),with(quantity,PQ),T),
    DQ=1..PQ}1 :- R=1..NR, numRobots(NR), T=0..TN, TN=n-1.

% Map to occurs/3
occurs(object(robot,R), move(DX,DY), T) :- robotMove(R,move(DX,DY),T).
occurs(object(robot,R), pickup, T) :- pickUpShelf(R,_,T).
occurs(object(robot,R), putdown, T) :- putDownShelf(R,_,T).
occurs(object(robot,R), deliver(OI,PRI,DQ), T) :- deliver(R,OI,with(SI,PRI,DQ),T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%    ACTION CONSTRAINTS     %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Only one action per robot per timestep
:- occurs(object(robot,R),A1,T), occurs(object(robot,R),A2,T), A1 != A2.

% Robot movement boundaries
:- robotAt(RI,object(node,ND),T), robotMove(R,move(DX,DY),T), nodeAt(ND,pair(X,Y)), X+DX<1.
:- robotAt(RI,object(node,ND),T), robotMove(R,move(DX,DY),T), nodeAt(ND,pair(X,Y)), Y+DY<1.
:- robotAt(RI,object(node,ND),T), robotMove(R,move(DX,DY),T), nodeAt(ND,pair(X,Y)), X+DX>NC, numColumns(NC).
:- robotAt(RI,object(node,ND),T), robotMove(R,move(DX,DY),T), nodeAt(ND,pair(X,Y)), Y+DY>NR, numRows(NR).

% Picking up shelves
:- 2{pickUpShelf(R,S,T) : robot(R)}, shelf(S).
:- pickUpShelf(RI,S1,T), shelfOn(S2,object(robot,RI),T).
:- pickUpShelf(R1,S,T), shelfOn(S,object(robot,R2),T).
:- pickUpShelf(RI,S,T), shelfOn(S,object(node,ND),T), not robotAt(RI,object(node,ND),T).

% Putting down shelves
:- 2{putDownShelf(R,S,T) : robot(R)}, shelf(S).
:- putDownShelf(RI,S,T), not shelfOn(S,object(robot,RI),T).
:- putDownShelf(RI,S,T), robotAt(RI,object(node,ND),T), highway(ND).

% Delivering products
:- deliver(R,OI,with(_,PR,_),T), orderAt(OI,object(node,ND),contains(PR,_),T), not robotAt(R,object(node,ND),T).
:- deliver(R,OI,with(SI,PR,_),T), productOn(PR,object(shelf,SI),with(quantity,_),T), not shelfOn(SI,object(robot,R),T).
:- deliver(R,OI,with(SI,PR,DQ),T), orderAt(OI,object(node,ND),contains(PR,OQ),T), DQ>OQ.
:- deliver(R,OI,with(SI,PR,DQ),T), productOn(PR,object(shelf,SI),with(quantity,PQ),T), DQ>PQ.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%    STATES CONSTRAINTS     %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Picking stations must not be highways
:- pickingStationAt(_,NDI), highway(NDI).

% Shelves must not be on highways
:- shelfOn(S,object(node,NDI),_), highway(NDI).

% Robot constraints
:- 2{robotAt(R,object(node,ND),T) : node(ND)}, robot(R), T=0..n.
:- 2{robotAt(R,object(node,ND),T) : robot(R)}, node(ND), T=0..n.
:- robotAt(R1,object(node,ND1),T), robotAt(R1,object(node,ND2),T+1), robotAt(R2,object(node,ND2),T), robotAt(R2,object(node,ND1),T+1), R1!=R2.

% Shelf constraints
:- 2{shelfOn(S,object(robot,NR),T) : robot(NR)}, shelf(S), T=0..n.
:- 2{shelfOn(S,object(robot,NR),T) : shelf(S)}, robot(NR), T=0..n.
:- 2{shelfOn(S,object(node,ND),T) : node(ND)}, shelf(S), T=0..n.
:- 2{shelfOn(S,object(node,ND),T) : shelf(S)}, node(ND), T=0..n.
:- shelfOn(S,object(node,_),T), shelfOn(S,object(robot,_),T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%      ACTIONS EFFECTS      %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Robot moving
robotAt(R,object(node,NEW_ND),T+1) :- robotAt(R,object(node,ND),T), nodeAt(ND,pair(X,Y)), nodeAt(NEW_ND,pair(X+DX,Y+DY)), robotMove(R,move(DX,DY),T).

% Picking up shelves
shelfOn(S,object(robot,RI),T+1) :- pickUpShelf(RI,S,T), shelfOn(S,object(node,ND),T), robotAt(RI,object(node,ND),T).

% Putting down shelves
shelfOn(S,object(node,ND),T+1) :- putDownShelf(RI,S,T), shelfOn(S,object(robot,RI),T), robotAt(RI,object(node,ND),T).

% Delivering
orderAt(OI,object(node,ND),contains(PR,OU-DQ),T+1) :- deliver(R,OI,with(SI,PR,DQ),T), orderAt(OI,object(node,ND),contains(PR,OU),T).
productOn(PR,object(shelf,SI),with(quantity,PQ-DQ),T+1) :- deliver(R,OI,with(SI,PR,DQ),T), productOn(PR,object(shelf,SI),with(quantity,PQ),T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%      LAW OF INERTIA       %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

robotAt(R,object(node,ND),T+1) :- robotAt(R,object(node,ND),T), not robotMove(R,move(_,_),T), T<n.
shelfOn(S,object(node,ND),T+1) :- shelfOn(S,object(node,ND),T), not pickUpShelf(_,S,T), T<n.
shelfOn(S,object(robot,RI),T+1) :- shelfOn(S,object(robot,RI),T), not putDownShelf(RI,S,T), T<n.
orderAt(OI,object(node,ND),contains(PR,OU),T+1) :- orderAt(OI,object(node,ND),contains(PR,OU),T), not deliver(_,OI,with(_,PR,_),T), T<n.
productOn(PR,object(shelf,SI),with(quantity,PQ),T+1) :- productOn(PR,object(shelf,SI),with(quantity,PQ),T), not deliver(_,_,with(SI,PR,_),T), T<n.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%      OPTIMIZATION         %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Fulfill all orders by final time
:- not orderAt(OI,object(node,_),contains(PR,0),n), orderAt(OI,object(node,_),contains(PR,_),0).

numActions(N) :- N = #sum{1,O,A,T : occurs(O,A,T)}.
timeTaken(N-1) :- N = #count{T : occurs(O,A,T)}.

#minimize{1,O,A,T : occurs(O,A,T)}.
#minimize{T : occurs(O,A,T)}.

#show occurs/3.
#show numActions/1.
#show timeTaken/1.

