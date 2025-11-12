#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <gnetgen_input_file> <dimacs_output_file>"
  exit 1
fi

# Input and output file paths from the arguments
GNETGEN_INPUT_FILE="$1"        # Input file for GNETGEN
DIMACS_OUTPUT_FILE="$2"        # Output file in DIMACS format

# Temporary file to hold the GNETGEN output
TEMP_GNETGEN_OUTPUT="gnetgen_output.txt"
TEMP_DIMACS_FILE="dimacs_unsorted.txt"

# Run GNETGEN with the provided input file and save the output
echo "Running GNETGEN..."
./gnetgen < "$GNETGEN_INPUT_FILE" > "$TEMP_GNETGEN_OUTPUT"

MAX_NODE=0
TOTAL_ARCS=0

# Convert GNETGEN output to DIMACS format
echo "Converting GNETGEN output to DIMACS format..."

# Prepare the output file
{
  echo "c Converted from GNETGEN output"
  echo "c"

  # Read through the GNETGEN output and convert
  while IFS= read -r line; do
    # Skip empty lines or comments
    [[ -z "$line" || "$line" =~ ^c ]] && continue

    # Stop processing if we reach the "END" line
    if [[ "$line" =~ ^END ]]; then
      break
    fi

    # Process sections
    if [[ "$line" =~ ^SUPPLY ]]; then
      SUPPLY_SECTION=1
      continue
    fi

    if [[ "$line" =~ ^ARCS ]]; then
      SUPPLY_SECTION=0
      ARCS_SECTION=1
      continue
    fi

    if [[ "$line" =~ ^DEMAND ]]; then
      SUPPLY_SECTION=0
      ARCS_SECTION=0
      DEMAND_SECTION=1
      continue
    fi

    # Parse supply data
    if [[ $SUPPLY_SECTION -eq 1 ]]; then
      read NODE SUPPLY_AMOUNT<<<"$line"

      # we give supply amount a factor of 10
      SUPPLY_AMOUNT=$(echo "$SUPPLY_AMOUNT * 10" | bc)
      echo "n $NODE $SUPPLY_AMOUNT"

      MAX_NODE=$(($NODE > $MAX_NODE ? $NODE : $MAX_NODE))
    fi

    # Parse arc data
    if [[ $ARCS_SECTION -eq 1 ]]; then
      read SRC TGT COST CAP EFF<<<"$line"
      TOTAL_ARCS=$((TOTAL_ARCS + 1))
      echo "a $SRC $TGT 0.0 $CAP $COST $EFF"

      # Update MAX_NODE based on src and tgt
      MAX_NODE=$(($SRC > $MAX_NODE ? $SRC : $MAX_NODE))
      MAX_NODE=$(($TGT > $MAX_NODE ? $TGT : $MAX_NODE))
    fi

    # Parse demand data
    if [[ $DEMAND_SECTION -eq 1 ]]; then
      read NODE DEMAND_AMOUNT<<<"$line"
      echo "n $NODE -$DEMAND_AMOUNT"

      MAX_NODE=$(($NODE > $MAX_NODE ? $NODE : $MAX_NODE))
    fi
  done < "$TEMP_GNETGEN_OUTPUT"

 # Add the problem line with nodes and arcs count
  echo "p min $MAX_NODE $TOTAL_ARCS"

} > "$TEMP_DIMACS_FILE"

# Extract and process the GNETGEN output in the correct order
{
  # Grep for all comment lines (lines starting with 'c')
  grep '^c ' "$TEMP_DIMACS_FILE"

  # Grep for the problem line (lines starting with 'p')
  grep '^p ' "$TEMP_DIMACS_FILE"

  # Grep for node lines (lines starting with 'n')
  grep '^n ' "$TEMP_DIMACS_FILE"

  # Grep for arc lines (lines starting with 'a')
  grep '^a ' "$TEMP_DIMACS_FILE"

} > "$DIMACS_OUTPUT_FILE"


# Clean up
rm "$TEMP_GNETGEN_OUTPUT"
rm "$TEMP_DIMACS_FILE"
gzip "$DIMACS_OUTPUT_FILE"

# Done
echo "c DIMACS format conversion complete!"
echo "c The file has been saved to $DIMACS_OUTPUT_FILE."
