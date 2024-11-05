#!/usr/bin/bash

archiveTypes=()    # Global array for storing valid archive types
languageTypes=()   # Global array for storing valid programming languages

# Function to check if the file path is valid
check_path() {
  if [ ! -e "$1" ]; then
    echo "Error: Path $1 does not exist."
    exit 1
  fi
}

# Function to check if a value is numeric
is_numeric() {
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: $1 is not a valid number."
    exit 1
  fi
}

# Function to check valid student ID range
check_student_id_range() {
  if [ "$1" -ge "$2" ]; then
    echo "Error: Start ID ($1) must be less than End ID ($2)."
    exit 1
  fi
}

# Function to check the archive types and store them
check_archive_types() {
  if [[ "$1" == "true" ]]; then
    archiveTypes=()  # Clear the array to avoid duplicates

    # Split the input into an array
    IFS=' ' read -r -a archive_array <<< "$2"
    
    for archive in "${archive_array[@]}"; do

      if [[ "$archive" =~ ^(zip|rar|tar)$ ]]; then
        archiveTypes+=("$archive")  # Add valid types to global array
      else
        echo "Error: Invalid archive type '$archive'. Expected 'zip' or 'rar'."
        exit 1
      fi

    done
  fi
}

# Function to check the programming languages and store them
check_languages() {
  # Split the input into an array (space-separated)
  IFS=' ' read -r -a lang_array <<< "$1"

  for lang in "${lang_array[@]}"; do
  
    if [[ "$lang" =~ ^(c|cpp|python|sh)$ ]]; then
      # If the language is python, store 'py' instead
      if [[ "$lang" == "python" ]]; then
        languageTypes+=("py")
      else
        # Store valid programming languages in the global array
        languageTypes+=("$lang")
      fi
    else
      echo "Error: Invalid programming language '$lang'. Expected 'c', 'cpp', 'python', or 'sh'."
      exit 1
    fi
  done
}


# Function to read and validate the input file
InputFileChecker() {
  # Read the input file
  input_file="$1"
  lineOffset=0  # Initialize line offset

  # Line 1: Check if archive is allowed
  read -r isArchivedAllowed < <(sed -n '1p' "$input_file")

  if [[ "$isArchivedAllowed" != "true" && "$isArchivedAllowed" != "false" ]]; then
    echo "Error: Line 1 should be 'true' or 'false'."
    exit 1
  fi

  if [[ "$isArchivedAllowed" == "true" ]]; then
    # Line 2: Check archive types
    read -r archiveTypes < <(sed -n '2p' "$input_file")
    check_archive_types "$isArchivedAllowed" "$archiveTypes"

    # Line 3: Check allowed programming languages
    read -r languageType < <(sed -n '3p' "$input_file")
    check_languages "$languageType"

    # No line offset in this case
    lineOffset=0
  else
    # Line 2: Check programming languages directly if no archive types
    read -r languageType < <(sed -n '2p' "$input_file")
    check_languages "$languageType"

    # Add an offset of 1 because there's no archive types
    lineOffset=1
  fi

  # Adjust the line numbers for subsequent reads
  # Line 4 (or 3 with offset): Total marks
  read -r totalMarks < <(sed -n "$((4 - lineOffset))p" "$input_file")
  is_numeric "$totalMarks"

  # Line 5 (or 4 with offset): Penalty for unmatched lines
  read -r unmatchedPenalty < <(sed -n "$((5 - lineOffset))p" "$input_file")
  is_numeric "$unmatchedPenalty"

  # Line 6 (or 5 with offset): Directory where submissions are stored
  read -r assignmentDirPath < <(sed -n "$((6 - lineOffset))p" "$input_file")
  check_path "$assignmentDirPath"

  # Line 7 (or 6 with offset): Valid student ID range
  read -r idRange < <(sed -n "$((7 - lineOffset))p" "$input_file")
  startId=$(echo "$idRange" | awk '{print $1}')
  endId=$(echo "$idRange" | awk '{print $2}')
  is_numeric "$startId"
  is_numeric "$endId"
  check_student_id_range "$startId" "$endId"

  # Line 8 (or 7 with offset): Expected output file path
  read -r outputFilePath < <(sed -n "$((8 - lineOffset))p" "$input_file")
  check_path "$outputFilePath"

  # Line 9 (or 8 with offset): Submission guideline violation penalty
  read -r submissionPenalty < <(sed -n "$((9 - lineOffset))p" "$input_file")
  echo "input_checker said $submissionPenalty"
  is_numeric "$submissionPenalty"

  # Line 10 (or 9 with offset): Plagiarism file path
  read -r plagFilePath < <(sed -n "$((10 - lineOffset))p" "$input_file")
  check_path "$plagFilePath"

  # Line 11 (or 10 with offset): Plagiarism penalty
  read -r plagPenalty < <(sed -n "$((11 - lineOffset))p" "$input_file")
  is_numeric "$plagPenalty"

  # All validations passed, initialize global variables
  echo "Input file is valid. Global variables have been initialized."
  export isArchivedAllowed totalMarks unmatchedPenalty assignmentDirPath startId endId outputFilePath submissionPenalty plagFilePath plagPenalty
  export archiveTypes languageTypes
}
