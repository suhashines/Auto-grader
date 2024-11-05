#!/usr/bin/bash

# Global Variables
markFile="marks.csv"   #the mark file is in the same directory as the submission handler

echo "student_id ,marks,deductions,total_marks,remarks" > "$markFile"

# Helper Functions

# Function to write marks to the file
markFileWriter() {
    local student_id="$1"
    local marks="$2"
    local deducted_marks="$3"
    local remarks="$4"
    
    # Use the absolute path to marks.csv
    echo "$student_id,$marks,$deducted_marks,$totalMarks,$remarks" >> "$original_dir/marks.csv"
}


# Function to calculate marks deduction
calculateMarksDeduction() {
    local submissionViolationCount="$1"
    local outputMismatchedCount="$2"
    local marks_deducted=$((submissionViolationCount * submissionPenalty + outputMismatchedCount * unmatchedPenalty))
    echo "$marks_deducted"
}

# Function to validate student ID
isValidId() {
    local student_id="$1"
    if [[ "$student_id" =~ ^[0-9]+$ ]] && [ "$student_id" -ge "$startId" ] && [ "$student_id" -le "$endId" ]; then
        return 0  # true
    fi
    return 1  # false
}

# Function to handle directory submissions
handleDirectorySubmission() {

    local dir="$1"
    local remarks="$2"
    local submissionPenaltyCount="$3"

    if [ -z "$(ls -A "$dir")" ]; then
        markFileWriter "$(basename "$dir")" 0 0 "missing submission"
        return
    fi

    echo "submission is not missing"
    
    assignment=$(ls "$dir")  # Assuming only one file in the directory

    echo "assignment $assignment"
    
    # Get the basename and extension of the found file
    file_basename=$(basename "$assignment")
    file_name="${file_basename%%.*}"  # Get the name before the first dot
    file_extension="${file_basename#*.}"  # Get the extension after the first dot

    if isValidId "$file_name"; then
        found=0
        for type in "${languageTypes[@]}"; do
            if [[ "$type" == "$file_extension" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            remarks+=" case#3"
            markFileWriter "$file_name" 0 "$totalMarks" "$remarks"
            # Move to issues
            mv "$dir" "$original_dir/issues/"  # Use the global variable
            return
        fi

        echo "submission is valid"

        # Change to the directory to execute the file
        cd "$dir" || exit
        evaluate "$assignment" "$remarks" "$submissionPenaltyCount"
        # Change back to the original directory
        cd - || exit
        # Move the directory to checked
        mv "$dir" "$original_dir/checked/"  # Use the global variable
    else
        markFileWriter "$(basename "$dir")" 0 100 " case#5"
        # Move to issues
        mv "$dir" "$original_dir/issues/"  # Use the global variable
    fi
}


# Function to evaluate the submitted file
evaluate() {
    local file="$1"
    local remarks="$2"
    local submissionPenaltyCount="$3"

    echo "evaluate said submission penalty count $submissionPenaltyCount"
    echo "evaluate said submission penalty $submissionPenalty"

    sid=$(basename "$file")

    sid_="${file_basename%%.*}"  # Get the name before the first dot
    
    # Load plagiarism file
    if grep -q "$sid_" "$plagFilePath"; then
        deducted=$((totalMarks * plagPenalty / 100))
        marks=$((totalMarks - deducted))
        markFileWriter "$sid_" "$marks" "$deducted" "plagiarism detected"
        return
    fi

    # Determine the file extension
    file_extension="${file##*.}"

    # Create a temporary directory for execution
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT  # Clean up the temp directory on exit

    # Copy the file to the temporary directory
    cp "$file" "$temp_dir"

    # Execute the file based on its extension
    case "$file_extension" in
        c)
            gcc "$temp_dir/$(basename "$file")" -o "$temp_dir/${sid}_output" 2> "$temp_dir/${sid}_error.txt"
            if [ $? -eq 0 ]; then
                "$temp_dir/${sid}_output" > "$temp_dir/${sid}_output.txt"
            else
                markFileWriter "$sid_" 0 "$totalMarks" "Compilation error: $(< "$temp_dir/${sid}_error.txt")"
                return
            fi
            ;;
        cpp)
            g++ "$temp_dir/$(basename "$file")" -o "$temp_dir/${sid}_output" 2> "$temp_dir/${sid}_error.txt"
            if [ $? -eq 0 ]; then
                "$temp_dir/${sid}_output" > "$temp_dir/${sid}_output.txt"
            else
                markFileWriter "$sid_" 0 "$totalMarks" "Compilation error: $(< "$temp_dir/${sid}_error.txt")"
                return
            fi
            ;;
        py)
            python3 "$temp_dir/$(basename "$file")" > "$temp_dir/${sid}_output.txt" 2> "$temp_dir/${sid}_error.txt"
            if [ $? -ne 0 ]; then
                markFileWriter "$sid_" 0 "$totalMarks" "Runtime error: $(< "$temp_dir/${sid}_error.txt")"
                return
            fi
            ;;
        sh)
            bash "$temp_dir/$(basename "$file")" > "$temp_dir/${sid}_output.txt" 2> "$temp_dir/${sid}_error.txt"
            if [ $? -ne 0 ]; then
                markFileWriter "$sid_" 0 "$totalMarks" "Runtime error: $(< "$temp_dir/${sid}_error.txt")"
                return
            fi
            ;;
        *)
            markFileWriter "$sid_" 0 "$totalMarks" "Unsupported file type: $file_extension"
            return
            ;;
    esac

    # Count mismatches and calculate marks
    mismatchCount=$(countMismatch "$temp_dir/${sid}_output.txt")

    deducted_marks=$(calculateMarksDeduction "$submissionPenaltyCount" "$mismatchCount")
    marks=$((totalMarks - deducted_marks))
    
    if((mismatchCount!=0)); then
        remarks+="$mismatchCount mismatches"
    fi
    
    markFileWriter "$sid_" "$marks" "$deducted_marks" "$remarks"
}




# Function to count mismatches
countMismatch() {
    local fileName="$1"
    local expected_output
    expected_output=$(<"$outputFilePath")
    local mismatch=0

    while IFS= read -r line; do
        if ! grep -qF "$line" <<< "$expected_output"; then
            ((mismatch++))
        fi
    done < "$fileName"

    echo "$mismatch"
}

# Main function to handle submissions
handleSubmission() {
    # Create folders if they do not exist
    mkdir -p issues checked

    # Clear the folders
    rm -rf issues/* checked/*

    echo "$original_dir"

    # Change to the assignment directory temporarily
    pushd "$assignmentDirPath" || exit

    for ((id=startId; id<=endId; id++)); do
        # Find the first file matching the student ID in the current directory only
    # Find the first file matching the student ID in the current directory only
    found_file=$(find . -maxdepth 1 \( -name "$id.*" -o -name "$id" \) -print -quit)



    echo "found_file $found_file"

        if [ -z "$found_file" ]; then
            # Assignment not submitted
            markFileWriter "$id" 0 0 "missing submission"
            continue
        fi

        # Get the basename and extension of the found file
       file_basename=$(basename "$found_file")
       
       file_name="${file_basename%%.*}"  # Get the name before the first dot
       file_extension="${file_basename#*.}"  # Get the extension after the first dot

        echo "Basename: $file_basename"
        echo "File name: $file_name"
        echo "File extension: $file_extension"


        if [[ "$file_extension" == "zip" || "$file_extension" == "tar" || "$file_extension" == "rar" ]]; then
            # Handle archived files
            archive_sid="${file_basename%.*}"  # Name without extension

            echo "working with zip file"
            # Check if the file extension is in the allowed archive types
            found=0
            for type in "${archiveTypes[@]}"; do
                if [[ "$type" == "$file_extension" ]]; then
                    found=1
                    break
                fi
            done

            # if [[ $found -eq 0 ]]; then
            #     # Invalid archive type
            #     marks=0
            #     deducted_marks=$totalMarks
            #     markFileWriter "$archive_sid" "$marks" "$deducted_marks" " case#2"
            #     mv -f "$found_file" "$original_dir/issues/"  # Use absolute path
            #     continue
            # fi

            # Create a directory for unarchiving using the original basename
            unarchive_dir="$archive_sid"  # Use the original basename
            mkdir -p "$unarchive_dir"

            # Unarchive the file
            case "$file_extension" in
                zip)
                    unzip -q "$found_file" -d "$unarchive_dir"  # Unzip the file
                    ;;
                tar)
                    tar -xf "$found_file" -C "$unarchive_dir"  # Untar the file
                    ;;
                rar)
                    unrar x -o+ "$found_file" "$unarchive_dir"  # Unrar the file (ensure unrar is installed)
                    ;;
            esac


            # Check if there's a directory inside the unarchive_dir
            unarchived_content=$(find "$unarchive_dir" -mindepth 1 -maxdepth 1)

           # If there's only one directory inside, move its contents up and rename the outer directory
            if [ $(echo "$unarchived_content" | wc -l) -eq 1 ] && [ -d "$unarchived_content" ]; then
                inner_dir_name=$(basename "$unarchived_content")  # Get the name of the inner directory
                
                # Move the contents of the inner directory to the outer one
                mv "$unarchived_content"/* "$unarchive_dir/"
                rmdir "$unarchived_content"  # Remove the now-empty inner directory
                
                # Rename the outer directory to match the inner directory's name
                mv "$unarchive_dir" "$(dirname "$unarchive_dir")/$inner_dir_name"
                
                unarchive_dir="$(dirname "$unarchive_dir")/$inner_dir_name"  # Update the unarchive_dir to reflect the new name
            fi


            if [[ $found -eq 0 || $isArchivedAllowed == false ]]; then
                # Invalid archive type
                marks=0
                deducted_marks=$totalMarks
                markFileWriter "$archive_sid" "$marks" "$deducted_marks" " case#2"
                mv -f "$unarchive_dir" "$original_dir/issues/"  # Use absolute path
                continue
            fi

            unarchive_sid=$(basename "$unarchive_dir")

            if isValidId "$unarchive_sid"; then
                remark=""
                submissionPenaltyCount=0

                if [ "$unarchive_sid" != "$archive_sid" ]; then
                    remark=" case#4"
                    submissionPenaltyCount=1
                fi

                echo "unarchive sid $unarchive_sid"

                handleDirectorySubmission "$unarchive_sid" "$remark" "$submissionPenaltyCount"
            else
                # Unarchived student ID is not valid
                mv -f "$unarchive_dir" "$original_dir/issues/"  # Use absolute path
            fi

        elif [ -d "$found_file" ]; then
            # Handle directory submissions
            echo "dealing with directory"
            handleDirectorySubmission "$found_file" " case#1" 1

        else
            # Handle individual file submissions
            echo "handling individual file submission"
            file_student_id="$file_name"
            echo " student_id $file_student_id"
            mkdir -p "$file_student_id"  # Create a folder with the student ID
            echo "found_file : $file_basename"
            mv -f "$file_basename" "$file_student_id/"  # Move the file into the newly created folder in the current directory
            current_dir=$(pwd)
            echo "sending to handler function : $current_dir/$file_student_id"
            
            handleDirectorySubmission "$current_dir/$file_student_id" "" 0  # No previous remarks, no previous penalties
        fi
    done

    popd || exit  # Return to the original directory
}


