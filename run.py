import os
import subprocess

# Initialize flags and variables
instance_chosen = False
current_time = 10
instance_number = 1

# Display the available instances
while not instance_chosen:
    print("\n", "-" * 40)
    print(" Select an instance file to run")
    print("-" * 40)
    for idx in range(1, 6):
        print(f"  {idx}: inst{idx}.asp")
    print("-" * 40)

    user_input = input("Enter the instance number (1-5): ").strip()

    if user_input.isdigit() and 1 <= int(user_input) <= 5:
        instance_number = int(user_input)
        instance_chosen = True
    else:
        print("\n[!] Invalid input. Please select a number between 1 and 5.\n")

print("\n\n")
print("=" * 15, "Running Clingo", "=" * 15)
print("\n\n")

# Run Clingo until solution is found
while instance_chosen:
    instance_path = os.path.join("simpleInstances", f"inst{instance_number}.asp")
    command = ["clingo", "warehouse_control.lp", instance_path, "-c", f"n={current_time}"]

    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output, error = process.communicate()
    output_text = output.decode('utf-8')

    if 'UNSATISFIABLE' in output_text.split():
        current_time += 2
    else:
        print(output_text)
        instance_chosen = False
