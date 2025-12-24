# Git aliases ported from oh-my-zsh git plugin
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
{
  aliases = {
    # Basic
    g = "git";
    ga = "git add";
    gaa = "git add --all";
    gapa = "git add --patch";
    gau = "git add --update";

    # Branch
    gb = "git branch";
    gba = "git branch --all";
    gbd = "git branch --delete";
    gbD = "git branch --delete --force";
    gbr = "git branch --remote";
    gbnm = "git branch --no-merged";

    # Checkout / Switch (use functions for main/develop detection)
    gco = "git checkout";
    gcb = "git checkout -b";
    gcm = "git checkout $(git_main_branch)";
    gcd = "git checkout $(git_develop_branch)";
    gsw = "git switch";
    gswc = "git switch --create";
    gswm = "git switch $(git_main_branch)";
    gswd = "git switch $(git_develop_branch)";

    # Commit
    gc = "git commit --verbose";
    "gc!" = "git commit --verbose --amend";
    gca = "git commit --verbose --all";
    "gca!" = "git commit --verbose --all --amend";
    gcam = "git commit --all --message";
    gcmsg = "git commit --message";
    "gcan!" = "git commit --verbose --all --no-edit --amend";
    "gcn!" = "git commit --verbose --no-edit --amend";

    # Cherry-pick
    gcp = "git cherry-pick";
    gcpa = "git cherry-pick --abort";
    gcpc = "git cherry-pick --continue";

    # Diff
    gd = "git diff";
    gds = "git diff --staged";
    gdca = "git diff --cached";
    gdw = "git diff --word-diff";

    # Fetch
    gf = "git fetch";
    gfa = "git fetch --all --tags --prune";
    gfo = "git fetch origin";

    # Log
    glo = "git log --oneline --decorate";
    glog = "git log --oneline --decorate --graph";
    gloga = "git log --oneline --decorate --graph --all";
    glg = "git log --stat";
    glgp = "git log --stat --patch";

    # Merge
    gm = "git merge";
    gma = "git merge --abort";
    gmc = "git merge --continue";
    gmff = "git merge --ff-only";
    gmom = "git merge origin/$(git_main_branch)";
    gmum = "git merge upstream/$(git_main_branch)";

    # Pull
    gl = "git pull";
    gpr = "git pull --rebase";
    gpra = "git pull --rebase --autostash";
    gprom = "git pull --rebase origin $(git_main_branch)";
    gprum = "git pull --rebase upstream $(git_main_branch)";

    # Push
    gp = "git push";
    gpf = "git push --force-with-lease --force-if-includes";
    "gpf!" = "git push --force";
    gpsup = "git push --set-upstream origin $(git branch --show-current)";
    gpd = "git push --dry-run";

    # Rebase
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase --interactive";
    grbs = "git rebase --skip";
    grbm = "git rebase $(git_main_branch)";
    grbd = "git rebase $(git_develop_branch)";
    grbom = "git rebase origin/$(git_main_branch)";
    grbum = "git rebase upstream/$(git_main_branch)";

    # Remote
    gr = "git remote";
    grv = "git remote --verbose";
    gra = "git remote add";
    grrm = "git remote remove";

    # Reset
    grh = "git reset";
    grhh = "git reset --hard";
    grhs = "git reset --soft";
    groh = "git reset origin/$(git branch --show-current) --hard";

    # Restore
    grs = "git restore";
    grst = "git restore --staged";

    # Stash
    gsta = "git stash push";
    gstaa = "git stash apply";
    gstc = "git stash clear";
    gstd = "git stash drop";
    gstl = "git stash list";
    gstp = "git stash pop";
    gsts = "git stash show --patch";

    # Status
    gst = "git status";
    gss = "git status --short";
    gsb = "git status --short --branch";

    # Show
    gsh = "git show";

    # Tag
    gta = "git tag --annotate";
    gtv = "git tag | sort -V";

    # Worktree
    gwt = "git worktree";
    gwta = "git worktree add";
    gwtls = "git worktree list";
    gwtrm = "git worktree remove";

    # Misc utilities
    grt = ''cd "$(git rev-parse --show-toplevel || echo .)"'';
    gbl = "git blame -w";
    gclean = "git clean --interactive -d";
    gcl = "git clone --recurse-submodules";
    gcount = "git shortlog --summary --numbered";
    grev = "git revert";
  };

  # Shell functions for branch detection (from oh-my-zsh)
  initContent = ''
    # Check if main exists and use instead of master
    function git_main_branch() {
      command git rev-parse --git-dir &>/dev/null || return
      local ref
      for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
        if command git show-ref -q --verify "$ref"; then
          echo "''${ref:t}"
          return 0
        fi
      done
      # Fallback
      echo master
      return 1
    }

    # Check for develop branch
    function git_develop_branch() {
      command git rev-parse --git-dir &>/dev/null || return
      local branch
      for branch in dev devel develop development; do
        if command git show-ref -q --verify "refs/heads/$branch"; then
          echo "$branch"
          return 0
        fi
      done
      echo develop
      return 1
    }

    # Get current branch name
    function git_current_branch() {
      git branch --show-current
    }
  '';
}
