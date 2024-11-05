#!/usr/bin/bash

# Source the input file checker script
source ./input_file_checker.sh


# Main Script
if [ $# -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file_path="$1"

# Call the InputFileChecker function with the input file path
InputFileChecker "$input_file_path"

# Debugging output

echo "moving to submission handler"

echo "Current working directory: $(pwd)"

original_dir=$(pwd)

source ./submission_handler.sh
# Call the handleSubmission function
# echo "main said $submissionPenalty"

handleSubmission