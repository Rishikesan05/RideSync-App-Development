# Expert Git Push (History Reconstruction)

## Purpose
Establishing a high-density contribution history by backdating commits and maintaining strict branched development.

## Instructions
1.  **Hard Code Audit**:
    -   Run `dart analyze` (must be 0 issues).
    -   Audit for secrets (API keys, private endpoints).
2.  **Timeline Discovery**:
    -   Identify genesis date (e.g., March 15).
    -   Plan daily milestones from genesis to today.
3.  **App-Only Filter**:
    -   Stage source code and platform configs.
    -   **PRESERVE**: Always stage `.agents/` and `.metadata`.
    -   **EXCLUDE**: `build/`, `node_modules/`, internal AI backups.
4.  **Daily Expert Branched Flow**:
    -   Loop through every day in the timeline.
    -   Create `feature/*` or `chore/*` branches for milestones.
    -   Commit backdated (`GIT_AUTHOR_DATE`).
    -   Merge to `develop`, then periodically to `main`.
5.  **Build Validation**:
    -   Before the final push, run `flutter clean && flutter pub get`.
    -   Verify that no "v1 embedding" errors occur.
6.  **Final Universal Push**:
    -   Force-push `main` and `develop`.
    -   Set upstream tracking for all branches.

## Rules
-   **Identity**: Use the user's Git email (e.g., `bsrishi2003@gmail.com`).
-   **Density**: 100% daily coverage. No gaps in the graph.
