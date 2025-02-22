# Fetch all branches
git fetch --all
# Checkout the master branch
git checkout -f master
# Stash changes
#git stash save --all
# Reset to the latest upstream head
git clean -fdx
git reset --hard "@{u}"