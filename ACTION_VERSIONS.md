# GitHub Actions Version Tracking

Current versions used in workflows (as of October 13, 2025):

## Production (In Use)

| Action | Pinned Version | Latest in Major | Notes |
|--------|----------------|-----------------|-------|
| actions/checkout | **v5** | v5.0.0 | ✅ Auto-updates patch/minor |
| actions/create-github-app-token | **v2** | v2.1.4 | ⚠️ v3 beta available |
| aws-actions/configure-aws-credentials | **v5** | v5.1.0 | ✅ Auto-updates patch/minor |
| autero1/action-terragrunt | **v3** | v3.0.2 | ✅ Auto-updates patch/minor |
| hashicorp/setup-terraform | **v3** | v3.x | ✅ Auto-updates patch/minor |

## Watch List (Upcoming Releases)

### actions/create-github-app-token v3 (Beta)

**Status**: Beta available, stable release pending

**When to upgrade**: After v3.0.0 stable is released

**Check**: https://github.com/actions/create-github-app-token/releases

**Migration notes**: Review changelog for breaking changes before upgrading

## Update Schedule

**Monthly**: Check for new stable releases of all actions

**Before upgrade**:
1. Review release notes and changelog
2. Check for breaking changes
3. Test in non-production workflow first
4. Update version in workflow file
5. Create PR with #patch tag (or #minor/#major if breaking)

## Version Pin Strategy

We pin to major versions (e.g., v3, v5) to:
- ✅ Get security patches automatically (patch updates)
- ✅ Get new features automatically (minor updates within major version)
- ✅ Avoid breaking changes (major version locked)
- ✅ Stay current with bug fixes and improvements
- ✅ Review changes only before major version bumps

Example: `uses: actions/checkout@v5` automatically gets v5.0.1, v5.1.0, etc.

## Links

- [actions/checkout](https://github.com/actions/checkout)
- [actions/create-github-app-token](https://github.com/actions/create-github-app-token)
- [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
- [autero1/action-terragrunt](https://github.com/autero1/action-terragrunt)
- [hashicorp/setup-terraform](https://github.com/hashicorp/setup-terraform)

