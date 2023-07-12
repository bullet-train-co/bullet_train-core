#!/usr/bin/env bash

# Get names of modified files compared to the main branch.
DIFF_DATA=$(git diff --name-status main)

# Same as .split(/\s/) in Ruby.
SPLIT_DIFF_DATA=(${DIFF_DATA//[[:space]]/ }) 

# Get the length since we want to specifically use `i` in the for loop below.
DATA_LENGTH=${#SPLIT_DIFF_DATA[@]}

# Retrieve all gem names that were modified.
for (( i=0; i < DATA_LENGTH; i++ ))
do
  if [[ ${SPLIT_DIFF_DATA[i]} =~ bullet_train* ]]
  then
    PATH_PARTS=(${SPLIT_DIFF_DATA[i]//\// })
    GEM_NAME=${PATH_PARTS[0]}

    # Ensure we don't duplicate gem names in the array.
    if [[ ! " ${MODIFIED_GEMS[*]} " =~ " ${GEM_NAME} " ]]
    then
      MODIFIED_GEMS[i]=$GEM_NAME
    fi
  fi
done

# Run the tests.
for gem in ${MODIFIED_GEMS[@]}
do
  echo "Running minitest suite for $gem"
  cd $gem && bundle install && bundle exec rails test
  echo ""
  cd ..
done

echo "Finished running Minitest Suite"
exit 0
