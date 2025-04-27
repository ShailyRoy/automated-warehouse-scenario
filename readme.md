📦 Automated Warehouse Scenario (Spring 2025)
This project implements the Automated Warehouse Scenario using Answer Set Programming (ASP) with Clingo, based on the specifications provided in course description. It models robot movement, shelf pickup, product delivery, and order fulfillment in a warehouse environment.

📄 Files Included

File	Description
warehouse_project.lp	Main ASP file (combined: parsing, counting, action generation, constraints, effects, and optimization)
simpleInstances/inst1.asp to inst5.asp	Example warehouse instances to test your solution
run.py	Python script to select and solve an instance interactively
⚙ Requirements
Clingo (ASP solver)
➔ Install from: https://potassco.org/clingo/

Python 3.x (only if using the helper script run.py)

🚀 How to Run
➔ Solve manually with Clingo:

Example (solving instance 1):
clingo warehouse_project.lp simpleInstances/inst1.asp -c n=50
n=50 defines the planning horizon (maximum steps).

You can adjust n if needed.

➔ Solve automatically with Python script:
Run the helper script:


python run.py

The script will:

Ask you to select an instance (1–5),

Automatically increase the planning horizon if needed,

Display the plan when a solution is found.

📈 Output Format
The ASP program outputs:

occurs/3: List of actions by each robot over time (move, pickup, putdown, deliver),

numActions/1: Total number of actions taken,

timeTaken/1: Total number of time steps needed.

Example output:

occurs(object(robot,1),move(0,1),0)
occurs(object(robot,1),pickup,1)
occurs(object(robot,1),move(1,0),2)
...
numActions(31)
timeTaken(18)

🛡 Project Details
Only hard constraints are used (no weak constraints).


Optimization Goals: Minimize total number of actions and minimize makespan (time steps).

Problem Features: Grid boundaries, shelf pickups, deliveries at picking stations, and warehouse safety rules are correctly enforced.

