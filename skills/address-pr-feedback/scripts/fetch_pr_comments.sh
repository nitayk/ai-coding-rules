#!/bin/bash
# Fetch PR comments from the current branch's open PR with detailed review comments

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    echo "Error: Not in a git repository or no branch checked out"
    exit 1
fi

# Get PR number for current branch
PR_NUMBER=$(gh pr view --json number -q .number 2>&1)

if [ -z "$PR_NUMBER" ] || [[ "$PR_NUMBER" == "no pull requests found"* ]]; then
    echo "Error: No open PR found for branch '$CURRENT_BRANCH'"
    exit 1
fi

# Get repository owner and name
REPO_INFO=$(gh repo view --json owner,name -q '.owner.login + "/" + .name' 2>&1)
if [ -z "$REPO_INFO" ]; then
    echo "Error: Unable to determine repository information"
    exit 1
fi

OWNER=$(echo "$REPO_INFO" | cut -d'/' -f1)
REPO=$(echo "$REPO_INFO" | cut -d'/' -f2)

# Fetch comprehensive PR information including review comments
# First, get basic PR info
PR_BASIC=$(gh pr view "$PR_NUMBER" --json number,title,body,author,createdAt --repo "$OWNER/$REPO" 2>&1)

# Then fetch detailed review comments using GraphQL
REVIEW_COMMENTS=$(gh api graphql --paginate -f query='
query($owner:String!, $repo:String!, $pr:Int!, $cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviews(first:50, after:$cursor) {
        nodes {
          author { login }
          body
          state
          createdAt
          comments(first:100) {
            nodes {
              author { login }
              body
              path
              line
              originalLine
              diffHunk
              createdAt
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
      comments(first:100) {
        nodes {
          author { login }
          body
          createdAt
          isMinimized
        }
      }
    }
  }
}
' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER" 2>&1)

# Combine and output results
echo "{"
echo "  \"pr_number\": $PR_NUMBER,"
echo "  \"owner\": \"$OWNER\","
echo "  \"repo\": \"$REPO\","
echo "  \"basic_info\": $PR_BASIC,"
echo "  \"review_comments\": $REVIEW_COMMENTS"
echo "}"
