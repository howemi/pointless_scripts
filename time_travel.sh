#!/bin/bash

# Function to print usage
usage() {
    echo "Usage: $0 <days_in_past> <max_commits_per_day> <exclude_weekends: true/false>"
    exit 1
}

# Check for valid input
if [ "$#" -ne 3 ]; then
    usage
fi

# Assign input arguments
DAYS_IN_PAST=$1
MAX_COMMITS=$2
EXCLUDE_WEEKENDS=$3

# Validate inputs
if ! [[ "$DAYS_IN_PAST" =~ ^[0-9]+$ ]] || ! [[ "$MAX_COMMITS" =~ ^[0-9]+$ ]]; then
    echo "Error: days_in_past and max_commits_per_day must be positive integers."
    exit 1
fi

if [[ "$EXCLUDE_WEEKENDS" != "true" && "$EXCLUDE_WEEKENDS" != "false" ]]; then
    echo "Error: exclude_weekends must be either 'true' or 'false'."
    exit 1
fi

# Create an empty git repository
REPO_DIR="auto_commits_repo"
rm -rf "$REPO_DIR"
mkdir "$REPO_DIR"
cd "$REPO_DIR" || exit 1
git init

# Get today's date
TODAY=$(date +%s)

# Set the start date to DAYS_IN_PAST days ago
START_DATE=$(date -d "-$DAYS_IN_PAST days" +%s)

# Iterate through days from START_DATE to TODAY
CURRENT_DATE=$START_DATE
while [ "$CURRENT_DATE" -le "$TODAY" ]; do
    # Check if weekend exclusion is enabled
    if [ "$EXCLUDE_WEEKENDS" == "true" ]; then
        DAY_OF_WEEK=$(date -d "@$CURRENT_DATE" +%u) # 1 = Monday, ..., 7 = Sunday
        if [ "$DAY_OF_WEEK" -ge 6 ]; then
            CURRENT_DATE=$(date -d "@$(($CURRENT_DATE + 86400))" +%s)
            continue
        fi
    fi

    # Set system time (requires sudo privileges)
    sudo timedatectl set-ntp false
    sudo timedatectl set-time "$(date -d "@$CURRENT_DATE" "+%Y-%m-%d %H:%M:%S")"

    # Generate a random number of commits (0 to MAX_COMMITS)
    NUM_COMMITS=$((RANDOM % (MAX_COMMITS + 1)))

    # Create commits
    for ((i = 1; i <= NUM_COMMITS; i++)); do
        echo "code: Commit #$i on $(date -d "@$CURRENT_DATE" +%Y-%m-%d)" >> file.txt
        git add file.txt
        git commit -m "Commit #$i on $(date -d "@$CURRENT_DATE" +%Y-%m-%d)"
    done

    # Move to the next day
    CURRENT_DATE=$(date -d "@$(($CURRENT_DATE + 86400))" +%s)

done

# Restore system time to current time
sudo timedatectl set-ntp true

# Print completion message
echo "Git repository with simulated commits created in $REPO_DIR."
