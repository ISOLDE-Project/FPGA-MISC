import pandas as pd
import argparse

def modify_csv(input_file, output_file):
    """
    Reads a CSV file, swaps specific port names, and writes the modified CSV to a new file.
    
    :param input_file: Path to the input CSV file.
    :param output_file: Path to the output CSV file.
    """
    try:
        # Read the CSV file
        df = pd.read_csv(input_file)
        
        # Ensure the 'port_name' column exists
        if 'port_name' not in df.columns:
            raise ValueError("CSV must contain a 'port_name' column.")

        # Convert to string to avoid issues with numerical data
        df['port_name'] = df['port_name'].astype(str)

        #### RX <-> TX Swaps #########################################    
        df['port_name'] = df['port_name'].str.replace('axi_c2c_selio_tx_data_out', 'TEMP_REPLACE', regex=True)
        df['port_name'] = df['port_name'].str.replace('axi_c2c_selio_rx_data_in', 'axi_c2c_selio_tx_data_out', regex=True)
        df['port_name'] = df['port_name'].str.replace('TEMP_REPLACE', 'axi_c2c_selio_rx_data_in', regex=True)

        #### RX_CLK <-> TX_CLK Swaps #################################
        df['port_name'] = df['port_name'].str.replace('axi_c2c_selio_tx_diff_clk_out', 'TEMP_REPLACE', regex=True)
        df['port_name'] = df['port_name'].str.replace('axi_c2c_selio_rx_diff_clk_in', 'axi_c2c_selio_tx_diff_clk_out', regex=True)
        df['port_name'] = df['port_name'].str.replace('TEMP_REPLACE', 'axi_c2c_selio_rx_diff_clk_in', regex=True)

        # Save the modified DataFrame to the output CSV file
        df.to_csv(output_file, index=False)
        print(f"Modified CSV saved as '{output_file}'.")

    except Exception as e:
        print(f"Error: {e}")

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Modify a CSV file by swapping specific port names.")
    parser.add_argument("input_csv", help="Path to the input CSV file.")
    parser.add_argument("output_csv", help="Path to the output CSV file.")

    args = parser.parse_args()

    # Call the function with parsed arguments
    modify_csv(args.input_csv, args.output_csv)

if __name__ == "__main__":
    main()
