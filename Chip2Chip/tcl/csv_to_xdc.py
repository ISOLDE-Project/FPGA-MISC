import pandas as pd
import argparse

def generate_constraints_file(input_file, output_file):
    """
    Reads a CSV file and generates an XDC constraints file.
    
    :param input_file: Path to the input CSV file.
    :param output_file: Path to the output XDC file.
    """
    try:
        # Read the CSV file
        df = pd.read_csv(input_file)

        # Ensure necessary columns exist
        required_columns = ['pin_type', 'pin_number', 'port_name']
        if not all(col in df.columns for col in required_columns):
            raise ValueError(f"CSV must contain columns: {required_columns}")

        # Open the output file and write constraints
        with open(output_file, 'w') as f:
            f.write(f"# Generated file!! DO NOT edit!!\n\n")
            for _, row in df.iterrows():
                f.write(f"set_property {row['pin_type']} {row['pin_number']} [get_ports {{{row['port_name']}}}]\n")

        print(f"Constraints file '{output_file}' generated successfully.")

    except Exception as e:
        print(f"Error: {e}")

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Convert a CSV file to an XDC constraints file.")
    parser.add_argument("input_csv", help="Path to the input CSV file.")
    parser.add_argument("output_xdc", help="Path to the output XDC file.")
    
    args = parser.parse_args()
    
    # Call the function with parsed arguments
    generate_constraints_file(args.input_csv, args.output_xdc)

if __name__ == "__main__":
    main()
